import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

// ── Model ─────────────────────────────────────────────────────────────────────

class AiTaskSuggestion {
  String title;
  String description;
  int estimateHours;
  String role;

  /// Checkbox state để user chọn/bỏ task trước khi tạo
  bool selected;

  AiTaskSuggestion({
    required this.title,
    required this.description,
    required this.estimateHours,
    required this.role,
    this.selected = true,
  });

  factory AiTaskSuggestion.fromJson(Map<String, dynamic> json) {
    return AiTaskSuggestion(
      title: (json['title'] as String? ?? '').trim(),
      description: (json['description'] as String? ?? '').trim(),
      estimateHours: (json['estimateHours'] as num? ?? 2).toInt().clamp(1, 16),
      role: (json['role'] as String? ?? 'Dev').trim(),
    );
  }
}

class AiSplitResult {
  final bool isFallback;
  final List<AiTaskSuggestion> tasks;

  const AiSplitResult({required this.isFallback, required this.tasks});
}

// ── Service ───────────────────────────────────────────────────────────────────

class AiSplitService {
  /// Base URL của AI backend (vd: https://scrumflow-ai.onrender.com)
  final String baseUrl;

  /// Timeout cho mỗi request
  final Duration timeout;

  AiSplitService({
    required this.baseUrl,
    this.timeout = const Duration(seconds: 30),
  });

  /// Lấy Firebase ID Token của user hiện tại để gửi Bearer header.
  /// Trả về `null` nếu chưa đăng nhập (không block request vì backend
  /// hiện chưa verify token, nhưng header vẫn được gửi để sẵn sàng).
  Future<String?> _getIdToken() async {
    try {
      return await FirebaseAuth.instance.currentUser?.getIdToken();
    } catch (_) {
      return null;
    }
  }

  /// Gọi `POST /api/ai/split-story`.
  /// Ném exception nếu network lỗi hoặc server trả về status ≥ 400.
  Future<AiSplitResult> splitStory({
    required String title,
    required String description,
    int maxTasks = 6,
  }) async {
    final token = await _getIdToken();

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final body = jsonEncode({
      'title': title,
      'description': description,
      'maxTasks': maxTasks,
    });

    final uri = Uri.parse('$baseUrl/api/ai/split-story');

    final response = await http
        .post(uri, headers: headers, body: body)
        .timeout(timeout);

    if (response.statusCode >= 400) {
      throw Exception('AI backend error ${response.statusCode}: ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final source = json['source'] as String? ?? 'fallback';
    final rawTasks = json['tasks'] as List<dynamic>? ?? [];

    final tasks = rawTasks
        .whereType<Map<String, dynamic>>()
        .map(AiTaskSuggestion.fromJson)
        .where((t) => t.title.isNotEmpty)
        .toList();

    return AiSplitResult(
      isFallback: source == 'fallback',
      tasks: tasks,
    );
  }
}
