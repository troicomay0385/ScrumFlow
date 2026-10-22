import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/ai/core/ai_training_pipeline.dart';
import '../../domain/ai/core/feature_spec.dart';

/// Kho lưu trữ cục bộ (`shared_preferences`) cho mô hình AI dự đoán rủi ro
/// đã huấn luyện (`TrainedRiskModelArtifact`) theo từng dự án (`projectId`).
///
/// Đảm bảo:
/// - Khoá lưu trữ gắn kèm `currentSchemaVersion`.
/// - Nếu dữ liệu JSON bị hỏng, thiếu trường hoặc lệch số chiều đặc trưng,
///   tự động bỏ qua an toàn (trả về `null`) để hệ thống huấn luyện lại mô hình mới,
///   tuyệt đối không gây crash ứng dụng.
class AiModelStore {
  static const String _keyPrefix = 'scrumflow_ai_risk_model';

  final Future<SharedPreferences> Function() _prefsProvider;

  AiModelStore({Future<SharedPreferences> Function()? prefsProvider})
    : _prefsProvider = prefsProvider ?? SharedPreferences.getInstance;

  /// Tạo khoá lưu trữ theo `projectId` và phiên bản schema hiện tại.
  static String storageKeyForProject(String projectId) {
    final sanitizedId = projectId.trim().isEmpty ? 'default' : projectId.trim();
    return '${_keyPrefix}_v${TrainedRiskModelArtifact.currentSchemaVersion}_$sanitizedId';
  }

  /// Đọc mô hình đã lưu của dự án. Trả về `null` nếu chưa có hoặc dữ liệu hỏng.
  Future<TrainedRiskModelArtifact?> loadModel(String projectId) async {
    try {
      final prefs = await _prefsProvider();
      final key = storageKeyForProject(projectId);
      final rawJson = prefs.getString(key);
      if (rawJson == null || rawJson.trim().isEmpty) {
        return null;
      }

      final decoded = jsonDecode(rawJson);
      if (decoded is! Map<String, dynamic>) {
        await prefs.remove(key);
        return null;
      }

      final artifact = TrainedRiskModelArtifact.fromJson(decoded);
      if (artifact.schemaVersion !=
              TrainedRiskModelArtifact.currentSchemaVersion ||
          artifact.model.dimension != TaskFeatureSpec.featureCount ||
          artifact.standardizer.dimension != TaskFeatureSpec.featureCount) {
        await prefs.remove(key);
        return null;
      }

      return artifact;
    } catch (_) {
      // Dữ liệu hỏng hoặc sai định dạng → xóa an toàn và trả về null
      try {
        final prefs = await _prefsProvider();
        await prefs.remove(storageKeyForProject(projectId));
      } catch (_) {}
      return null;
    }
  }

  /// Lưu mô hình đã huấn luyện xuống `shared_preferences`.
  Future<void> saveModel(
    String projectId,
    TrainedRiskModelArtifact artifact,
  ) async {
    final prefs = await _prefsProvider();
    final key = storageKeyForProject(projectId);
    final rawJson = jsonEncode(artifact.toJson());
    await prefs.setString(key, rawJson);
  }

  /// Xóa mô hình đã lưu của dự án (dùng khi đặt lại mô hình mặc định).
  Future<void> clearModel(String projectId) async {
    final prefs = await _prefsProvider();
    final key = storageKeyForProject(projectId);
    await prefs.remove(key);
  }
}
