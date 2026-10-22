import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:scrumflow/app/authorization/project_role.dart';
import 'package:scrumflow/data/models/project_member_display.dart';
import 'package:scrumflow/data/models/project_member_model.dart';
import 'package:scrumflow/data/models/task_model.dart';
import 'package:scrumflow/data/models/user_model.dart';
import 'package:scrumflow/data/services/performance_score_service.dart';
import 'package:scrumflow/domain/ai/core/ai_training_pipeline.dart';
import 'package:scrumflow/domain/ai/core/baseline_models.dart';
import 'package:scrumflow/domain/ai/core/dataset.dart';
import 'package:scrumflow/domain/ai/core/explainer.dart';
import 'package:scrumflow/domain/ai/core/logistic_regression.dart';
import 'package:scrumflow/domain/ai/core/metrics.dart';
import 'package:scrumflow/domain/ai/core/standardizer.dart';

void main() {
  group('LogisticRegression & Toán học lõi', () {
    test('Sigmoid ổn định số học với ±1e6, ±500, 0 và NaN', () {
      expect(LogisticRegression.sigmoid(0.0), closeTo(0.5, 1e-12));
      expect(LogisticRegression.sigmoid(1e6), equals(1.0));
      expect(LogisticRegression.sigmoid(-1e6), equals(0.0));
      expect(LogisticRegression.sigmoid(500.0), closeTo(1.0, 1e-12));
      expect(LogisticRegression.sigmoid(-500.0), closeTo(0.0, 1e-12));
      expect(LogisticRegression.sigmoid(double.nan), equals(0.5));
      expect(LogisticRegression.sigmoid(1e6).isNaN, isFalse);
      expect(LogisticRegression.sigmoid(-1e6).isNaN, isFalse);
    });

    test(
      'Kiểm tra đạo hàm giải tích khớp sai phân hữu hạn (Gradient Check)',
      () {
        final rng = Random(12345);
        const dim = 6;
        final X = List<List<double>>.generate(
          25,
          (_) =>
              List<double>.generate(dim, (_) => rng.nextDouble() * 4.0 - 2.0),
        );
        final y = List<int>.generate(25, (_) => rng.nextBool() ? 1 : 0);

        final model = LogisticRegression(
          weights: List<double>.generate(dim, (_) => rng.nextDouble() - 0.5),
          bias: 0.15,
        );

        final (anaW, anaB) = model.computeAnalyticalGradient(
          X,
          y,
          l2Lambda: 0.05,
          posWeight: 1.2,
          negWeight: 0.9,
        );
        final (numW, numB) = model.computeNumericalGradient(
          X,
          y,
          l2Lambda: 0.05,
          posWeight: 1.2,
          negWeight: 0.9,
          epsilon: 1e-6,
        );

        for (int j = 0; j < dim; j++) {
          expect(
            anaW[j],
            closeTo(numW[j], 1e-6),
            reason: 'Gradient theo w[$j] phải khớp sai phân hữu hạn',
          );
        }
        expect(anaB, closeTo(numB, 1e-6));
      },
    );

    test('Hội tụ trên tập dữ liệu tách tuyến tính rõ ràng', () {
      final rng = Random(77);
      final X = <List<double>>[];
      final y = <int>[];

      for (int i = 0; i < 120; i++) {
        final isPos = i >= 60;
        final x1 = isPos ? (1.5 + rng.nextDouble()) : (-1.5 - rng.nextDouble());
        final x2 = isPos ? (1.0 + rng.nextDouble()) : (-1.0 - rng.nextDouble());
        X.add([x1, x2]);
        y.add(isPos ? 1 : 0);
      }

      final model = LogisticRegression.initialized(
        dimension: 2,
        rng: Random(7),
      );
      final history = model.fit(
        trainX: X,
        trainY: y,
        rng: Random(7),
        epochs: 80,
        learningRate: 0.15,
        l2Lambda: 0.001,
        patience: 0,
      );

      expect(history.finalLoss, lessThan(history.initialLoss * 0.25));

      int correct = 0;
      for (int i = 0; i < X.length; i++) {
        if (model.predictClass(X[i]) == y[i]) correct++;
      }
      expect(correct / X.length, greaterThanOrEqualTo(0.99));
    });

    test('Cùng seed cho ra đúng cùng một bộ trọng số và bias', () {
      final rngData = Random(99);
      final X = List<List<double>>.generate(
        60,
        (_) => [rngData.nextDouble(), rngData.nextDouble() * 2 - 1],
      );
      final y = List<int>.generate(60, (i) => i % 2);

      final m1 = LogisticRegression.initialized(dimension: 2, rng: Random(42));
      m1.fit(trainX: X, trainY: y, rng: Random(42), epochs: 30);

      final m2 = LogisticRegression.initialized(dimension: 2, rng: Random(42));
      m2.fit(trainX: X, trainY: y, rng: Random(42), epochs: 30);

      expect(m1.weights, equals(m2.weights));
      expect(m1.bias, equals(m2.bias));
    });

    test('toJson / fromJson round-trip và kiểm tra schemaVersion', () {
      final model = LogisticRegression(
        weights: const [0.42, -1.15, 0.08],
        bias: -0.23,
      );
      final json = model.toJson();
      final restored = LogisticRegression.fromJson(json);

      expect(restored.weights, equals(model.weights));
      expect(restored.bias, equals(model.bias));

      expect(
        () => LogisticRegression.fromJson({
          'schemaVersion': 999,
          'weights': [1.0],
          'bias': 0.0,
        }),
        throwsFormatException,
      );
    });
  });

  group('Standardizer & Dataset', () {
    test('Standardizer xử lý an toàn cột có phương sai bằng 0 (hằng số)', () {
      final X = [
        [1.0, 5.0, 10.0],
        [2.0, 5.0, 20.0],
        [3.0, 5.0, 30.0],
      ];
      final std = Standardizer.fit(X);
      expect(std.means[1], equals(5.0));
      expect(std.stds[1], equals(1.0)); // phương sai 0 được gán std = 1.0

      final transformed = std.transform([2.0, 5.0, 20.0]);
      expect(transformed, everyElement(isNot(isNaN)));
      expect(transformed[0], closeTo(0.0, 1e-9));
      expect(transformed[1], closeTo(0.0, 1e-9));
      expect(transformed[2], closeTo(0.0, 1e-9));

      final restored = Standardizer.fromJson(std.toJson());
      expect(restored.means, equals(std.means));
      expect(restored.stds, equals(std.stds));
    });

    test(
      'Dataset rỗng hoặc chỉ có 1 lớp không bị crash khi split / k-fold',
      () {
        final emptyDs = Dataset(samples: const []);
        final (eTrain, eTest) = emptyDs.stratifiedSplit(rng: Random(1));
        expect(eTrain.isEmpty, isTrue);
        expect(eTest.isEmpty, isTrue);
        expect(emptyDs.stratifiedKFold(k: 5, rng: Random(1)).length, equals(1));

        final oneClassSamples = List<LabeledSample>.generate(
          10,
          (i) => LabeledSample(features: [i.toDouble(), 1.0], label: 1),
        );
        final oneClassDs = Dataset(samples: oneClassSamples);
        final (oTrain, oTest) = oneClassDs.stratifiedSplit(
          testRatio: 0.2,
          rng: Random(2),
        );
        expect(oTrain.length + oTest.length, equals(10));
        expect(oTrain.positiveRatio, equals(1.0));

        final folds = oneClassDs.stratifiedKFold(k: 5, rng: Random(2));
        expect(folds.length, equals(5));
      },
    );
  });

  group('MetricsCalculator & Explainer', () {
    test('Metrics khớp tuyệt đối với ví dụ tính tay', () {
      // 4 mẫu:
      // y = [1, 1, 0, 0], probs = [0.9, 0.4, 0.7, 0.1] với ngưỡng 0.5
      // Dự đoán: [1, 0, 1, 0] -> TP=1, FN=1, FP=1, TN=1
      final labels = [1, 1, 0, 0];
      final probs = [0.9, 0.4, 0.7, 0.1];
      final m = MetricsCalculator.evaluate(
        labels: labels,
        probabilities: probs,
      );

      expect(m.confusionMatrix.tp, equals(1));
      expect(m.confusionMatrix.fn, equals(1));
      expect(m.confusionMatrix.fp, equals(1));
      expect(m.confusionMatrix.tn, equals(1));
      expect(m.accuracy, closeTo(0.5, 1e-9));
      expect(m.precision, closeTo(0.5, 1e-9));
      expect(m.recall, closeTo(0.5, 1e-9));
      expect(m.f1, closeTo(0.5, 1e-9));

      // Cặp (pos, neg):
      // (0.9 vs 0.7) -> thắng; (0.9 vs 0.1) -> thắng;
      // (0.4 vs 0.7) -> thua; (0.4 vs 0.1) -> thắng => 3/4 = 0.75
      expect(m.rocAuc, closeTo(0.75, 1e-9));
    });

    test(
      'ROC-AUC = 0.5 với dự đoán hằng số/ngẫu nhiên đồng hạng và = 1.0 với dự đoán hoàn hảo',
      () {
        final labels = [1, 0, 1, 0, 1, 0];
        final constantProbs = [0.5, 0.5, 0.5, 0.5, 0.5, 0.5];
        expect(
          MetricsCalculator.computeRocAuc(labels, constantProbs),
          closeTo(0.5, 1e-9),
        );

        final perfectProbs = [0.95, 0.10, 0.85, 0.20, 0.90, 0.05];
        expect(
          MetricsCalculator.computeRocAuc(labels, perfectProbs),
          closeTo(1.0, 1e-9),
        );
      },
    );

    test('Explainer đảm bảo tổng đóng góp + bias = logit', () {
      final std = Standardizer(
        means: List<double>.filled(10, 1.0),
        stds: List<double>.filled(10, 2.0),
      );
      final model = LogisticRegression(
        weights: const [0.3, -0.5, 0.8, -0.2, 0.1, 0.4, -0.9, 0.6, 0.2, 0.7],
        bias: -0.15,
      );
      final raw = [3.0, 2.0, 1.0, 0.8, 2.0, 0.5, 0.9, 0.4, 0.6, 0.0];

      final exp = Explainer.explain(
        model: model,
        standardizer: std,
        rawFeatures: raw,
        topK: 3,
      );

      final sumContrib = exp.contributions.fold<double>(
        0.0,
        (s, c) => s + c.contribution,
      );
      expect(sumContrib + exp.bias, closeTo(exp.logit, 1e-9));
      expect(exp.topContributors.length, equals(3));
      expect(
        exp.topContributors[0].magnitude,
        greaterThanOrEqualTo(exp.topContributors[1].magnitude),
      );
    });
  });

  group('Khớp công thức Baseline (b) với PerformanceScoreService (US-057/058)', () {
    test(
      'HardcodedFormulaBaseline cho kết quả finalScore khớp 100% PerformanceScoreService',
      () {
        final now = DateTime(2026, 10, 22, 12);
        final members = [
          ProjectMemberDisplay(
            membership: ProjectMemberModel(
              id: 'p1_u1',
              projectId: 'p1',
              userId: 'u1',
              role: ProjectRole.member,
              createdBy: 'u0',
              createdAt: now,
              updatedAt: now,
            ),
            user: UserModel(
              id: 'u1',
              fullName: 'Phạm Duy',
              email: 'duy@scrumflow.com',
              loginProvider: 'email',
              createdAt: now,
            ),
          ),
          ProjectMemberDisplay(
            membership: ProjectMemberModel(
              id: 'p1_u2',
              projectId: 'p1',
              userId: 'u2',
              role: ProjectRole.sm,
              createdBy: 'u0',
              createdAt: now,
              updatedAt: now,
            ),
            user: UserModel(
              id: 'u2',
              fullName: 'Nguyễn Hiếu',
              email: 'hieu@scrumflow.com',
              loginProvider: 'email',
              createdAt: now,
            ),
          ),
        ];

        final tasks = [
          // u1: 2 đúng hạn, 1 trễ hạn, 2 đang làm
          TaskModel(
            id: 't1',
            storyId: 's1',
            title: 'T1',
            description: '',
            status: 'Done',
            assigneeId: 'u1',
            deadline: now.subtract(const Duration(days: 2)),
            createdAt: now.subtract(const Duration(days: 5)),
            updatedAt: now.subtract(const Duration(days: 3)), // đúng hạn
          ),
          TaskModel(
            id: 't2',
            storyId: 's1',
            title: 'T2',
            description: '',
            status: 'Done',
            assigneeId: 'u1',
            deadline: now.subtract(const Duration(days: 3)),
            createdAt: now.subtract(const Duration(days: 6)),
            updatedAt: now.subtract(const Duration(days: 1)), // trễ hạn
          ),
          TaskModel(
            id: 't3',
            storyId: 's1',
            title: 'T3',
            description: '',
            status: 'In Progress',
            assigneeId: 'u1',
            createdAt: now,
            updatedAt: now,
          ),
          TaskModel(
            id: 't4',
            storyId: 's1',
            title: 'T4',
            description: '',
            status: 'In Progress',
            assigneeId: 'u1',
            createdAt: now,
            updatedAt: now,
          ),
        ];

        const service = PerformanceScoreService();
        const baseline = HardcodedFormulaBaseline();

        final serviceScores = service.calculateScores(
          members: members,
          allProjectTasks: tasks,
          now: now,
        );

        for (final s in serviceScores) {
          final replicaScore = baseline.calculateMemberFinalScore(
            completedOnTime: s.completedOnTimeTasks,
            completedOverdue: s.completedOverdueTasks,
            inProgress: s.inProgressTasks,
          );
          expect(
            replicaScore,
            closeTo(s.finalScore, 1e-12),
            reason:
                'Điểm của ${s.userId} phải khớp tuyệt đối với PerformanceScoreService',
          );
        }
      },
    );

    test('TrainedRiskModelArtifact serialize / deserialize toàn vẹn', () {
      final ds = Dataset(
        samples: [
          LabeledSample(features: List<double>.filled(10, 0.5), label: 0),
          LabeledSample(features: List<double>.filled(10, 1.5), label: 1),
          LabeledSample(features: List<double>.filled(10, 0.2), label: 0),
          LabeledSample(features: List<double>.filled(10, 1.8), label: 1),
        ],
      );
      final artifact = AiTrainingPipeline.trainAndEvaluate(
        trainPool: ds,
        holdoutTest: ds,
        rng: Random(11),
        epochs: 10,
      );

      final restored = TrainedRiskModelArtifact.fromJson(artifact.toJson());
      expect(restored.model.weights, equals(artifact.model.weights));
      expect(restored.testMetrics.rocAuc, equals(artifact.testMetrics.rocAuc));
    });
  });
}
