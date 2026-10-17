class TaskStatus {
  TaskStatus._();

  static const String todo = 'To Do';
  static const String inProgress = 'In Progress';
  static const String done = 'Done';

  static const List<String> values = [todo, inProgress, done];

  /// Chuyển trạng thái kế tiếp theo luồng Kanban:
  /// 'To Do' -> 'In Progress' -> 'Done' -> null.
  static String? next(String s) {
    switch (s) {
      case todo:
        return inProgress;
      case inProgress:
        return done;
      default:
        return null;
    }
  }

  /// Quay về trạng thái trước đó:
  /// 'Done' -> 'In Progress' -> 'To Do' -> null.
  static String? previous(String s) {
    switch (s) {
      case done:
        return inProgress;
      case inProgress:
        return todo;
      default:
        return null;
    }
  }

  /// Chuẩn hoá trạng thái task. Nếu giá trị lạ hoặc không khớp thì trả về [todo].
  static String normalize(String s) {
    final trimmed = s.trim();
    if (trimmed == todo || trimmed.toLowerCase() == 'to do') {
      return todo;
    }
    if (trimmed == inProgress || trimmed.toLowerCase() == 'in progress') {
      return inProgress;
    }
    if (trimmed == done || trimmed.toLowerCase() == 'done') {
      return done;
    }
    return todo;
  }
}
