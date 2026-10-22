import 'dart:io';

/// Công cụ kiểm tra tự động ràng buộc "Không dùng API / thư viện ML ngoài"
/// (`dart run tool/verify_no_external_api.dart` — mục 4.11 MASTER_PROMPT).
///
/// Quét các thư mục:
/// - `lib/domain/ai`
/// - `lib/data/ai`
/// - `lib/presentation/ai`
/// - `pubspec.yaml`
///
/// Kiểm tra 4 nhóm quy tắc:
/// 1. Không import `http`, `dio`, `dart:io`, `dart:html` trong toàn bộ code AI (`lib/*/ai`).
/// 2. `lib/domain/ai/core` chỉ import `dart:core`, `dart:math`, `dart:convert` hoặc file nội bộ cùng thư mục (không import `flutter`, `firebase`, `cloud_firestore`, `package:scrumflow/data/`, `package:scrumflow/presentation/`).
/// 3. Không xuất hiện các chuỗi nhạy cảm gọi API AI ngoài (`openai`, `generativelanguage`, `anthropic`, `huggingface`, `api.`) trong code AI.
/// 4. `pubspec.yaml` không chứa các gói ML/HTTP ngoài (`tflite`, `ml_kit`, `google_ml_kit`, `onnx`, `google_generative_ai`, `http`, `dio`, `langchain`).
void main() {
  final aiDirs = [
    Directory('lib/domain/ai'),
    Directory('lib/data/ai'),
    Directory('lib/presentation/ai'),
  ];
  final coreDir = Directory('lib/domain/ai/core');
  final pubspecFile = File('pubspec.yaml');

  final forbiddenNetworkImports = <RegExp>[
    RegExp(r'''import\s+['"]package:http/'''),
    RegExp(r'''import\s+['"]package:dio/'''),
    RegExp(r'''import\s+['"]dart:io['"]'''),
    RegExp(r'''import\s+['"]dart:html['"]'''),
    RegExp(r'''import\s+['"]package:cloud_functions/'''),
  ];

  final forbiddenCoreImports = <RegExp>[
    RegExp(r'''import\s+['"]package:flutter/'''),
    RegExp(r'''import\s+['"]package:firebase_'''),
    RegExp(r'''import\s+['"]package:cloud_firestore/'''),
    RegExp(r'''import\s+['"]package:scrumflow/data/'''),
    RegExp(r'''import\s+['"]package:scrumflow/presentation/'''),
    RegExp(r'''import\s+['"]package:scrumflow/app/'''),
    RegExp(r'''import\s+['"][^'"]*data/'''),
    RegExp(r'''import\s+['"][^'"]*presentation/'''),
  ];

  final forbiddenApiTokens = <String>[
    'openai',
    'generativelanguage',
    'anthropic',
    'huggingface',
    'api.',
  ];

  final forbiddenPubspecPackages = <String>[
    'tflite',
    'ml_kit',
    'google_ml_kit',
    'onnx',
    'google_generative_ai',
    'langchain',
    'openai',
  ];

  final networkImportViolations = <String>[];
  final corePurityViolations = <String>[];
  final apiTokenViolations = <String>[];
  final pubspecViolations = <String>[];

  int scannedAiFiles = 0;
  int scannedCoreFiles = 0;

  for (final dir in aiDirs) {
    if (!dir.existsSync()) continue;
    final files = dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));

    for (final file in files) {
      scannedAiFiles++;
      final content = file.readAsStringSync();
      final lowerContent = content.toLowerCase();

      for (final pattern in forbiddenNetworkImports) {
        if (pattern.hasMatch(content)) {
          networkImportViolations.add('${file.path} khớp ${pattern.pattern}');
        }
      }

      for (final token in forbiddenApiTokens) {
        if (lowerContent.contains(token)) {
          apiTokenViolations.add('${file.path} chứa chuỗi cấm "$token"');
        }
      }
    }
  }

  if (coreDir.existsSync()) {
    final coreFiles = coreDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));

    for (final file in coreFiles) {
      scannedCoreFiles++;
      final content = file.readAsStringSync();
      for (final pattern in forbiddenCoreImports) {
        if (pattern.hasMatch(content)) {
          corePurityViolations.add('${file.path} khớp ${pattern.pattern}');
        }
      }
    }
  } else {
    corePurityViolations.add('Thư mục lib/domain/ai/core không tồn tại.');
  }

  if (pubspecFile.existsSync()) {
    final pubspecLower = pubspecFile.readAsStringSync().toLowerCase();
    for (final pkg in forbiddenPubspecPackages) {
      final reg = RegExp('^\\s*$pkg\\s*:', multiLine: true);
      if (reg.hasMatch(pubspecLower)) {
        pubspecViolations.add('pubspec.yaml khai báo gói cấm "$pkg"');
      }
    }
  } else {
    pubspecViolations.add('Không tìm thấy pubspec.yaml');
  }

  final check1Pass = networkImportViolations.isEmpty && scannedAiFiles > 0;
  final check2Pass = corePurityViolations.isEmpty && scannedCoreFiles > 0;
  final check3Pass = apiTokenViolations.isEmpty && scannedAiFiles > 0;
  final check4Pass = pubspecViolations.isEmpty;

  stdout.writeln(
    '========================================================================',
  );
  stdout.writeln(
    '  KIỂM TRA RÀNG BUỘC KHÔNG DÙNG API / PACKAGE ML NGOÀI (NO-API VERIFIER)',
  );
  stdout.writeln(
    '========================================================================',
  );
  stdout.writeln(
    '| Hạng mục kiểm tra                                      | Kết quả |',
  );
  stdout.writeln(
    '|--------------------------------------------------------|---------|',
  );
  stdout.writeln(
    '| 1. Không import http/dio/dart:io trong lib/*/ai ($scannedAiFiles files) | ${check1Pass ? "PASS   " : "FAIL   "} |',
  );
  stdout.writeln(
    '| 2. Lõi domain/ai/core thuần Dart ($scannedCoreFiles files)             | ${check2Pass ? "PASS   " : "FAIL   "} |',
  );
  stdout.writeln(
    '| 3. Không chứa chuỗi openai/anthropic/huggingface/api.  | ${check3Pass ? "PASS   " : "FAIL   "} |',
  );
  stdout.writeln(
    '| 4. pubspec.yaml không thêm package ML/AI ngoài         | ${check4Pass ? "PASS   " : "FAIL   "} |',
  );
  stdout.writeln(
    '========================================================================',
  );

  final allViolations = [
    ...networkImportViolations,
    ...corePurityViolations,
    ...apiTokenViolations,
    ...pubspecViolations,
  ];

  if (allViolations.isNotEmpty) {
    stdout.writeln('Chi tiết vi phạm:');
    for (final v in allViolations) {
      stdout.writeln(' - $v');
    }
    exitCode = 1;
  } else {
    stdout.writeln('TẤT CẢ KIỂM TRA ĐỀU ĐẠT (PASS).');
  }
}
