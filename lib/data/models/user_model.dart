import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

/// Model đại diện cho người dùng trong ứng dụng.
///
/// Được sử dụng xuyên suốt app — từ DataSource đến Repository đến BLoC.
/// Không chứa logic UI hay logic Firebase ngoài factory [fromFirebaseUser].
class UserModel extends Equatable {
  final String id;
  final String fullName;
  final String email;
  final String? photoUrl;
  final DateTime createdAt;

  /// Phương thức đăng nhập: 'email' hoặc 'google'.
  final String loginProvider;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.photoUrl,
    required this.createdAt,
    required this.loginProvider,
  });

  /// Chuyển sang Map để lưu vào Firestore hoặc SQLite.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
      'loginProvider': loginProvider,
    };
  }

  /// Tạo từ Map (đọc từ Firestore hoặc SQLite).
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      fullName: map['fullName'] as String,
      email: map['email'] as String,
      photoUrl: map['photoUrl'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      loginProvider: map['loginProvider'] as String? ?? 'email',
    );
  }

  /// Tạo từ Firebase User — dùng khi đăng ký email/password.
  ///
  /// [fullName] được truyền riêng vì Firebase User không có field này.
  /// [loginProvider] mặc định là 'email'.
  factory UserModel.fromFirebaseUser(
    fb.User user, {
    required String fullName,
    String loginProvider = 'email',
  }) {
    return UserModel(
      id: user.uid,
      fullName: fullName,
      email: user.email ?? '',
      photoUrl: user.photoURL,
      createdAt: DateTime.now(),
      loginProvider: loginProvider,
    );
  }

  /// Tạo bản sao với một số field thay đổi.
  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? photoUrl,
    DateTime? createdAt,
    String? loginProvider,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      loginProvider: loginProvider ?? this.loginProvider,
    );
  }

  @override
  List<Object?> get props =>
      [id, fullName, email, photoUrl, createdAt, loginProvider];

  @override
  String toString() => 'UserModel(id: $id, email: $email, '
      'fullName: $fullName, provider: $loginProvider)';
}
