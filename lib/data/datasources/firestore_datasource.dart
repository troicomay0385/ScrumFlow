import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';

/// DataSource cho Cloud Firestore.
///
/// **Đây là nơi duy nhất import `cloud_firestore`.**
///
/// Quản lý hồ sơ người dùng trong collection `users/{uid}`.
/// Không chứa logic authentication — chỉ CRUD dữ liệu profile.
class FirestoreDataSource {
  final FirebaseFirestore _firestore;

  FirestoreDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Reference đến collection 'users'.
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  /// Tạo hồ sơ người dùng mới trong Firestore.
  ///
  /// Document ID = [user.id] (Firebase UID).
  /// Nếu document đã tồn tại, sẽ bị ghi đè.
  Future<void> createUserProfile(UserModel user) async {
    await _usersCollection.doc(user.id).set(user.toMap());
  }

  /// Đọc hồ sơ người dùng từ Firestore.
  ///
  /// Trả về [UserModel] nếu tìm thấy, `null` nếu chưa có profile.
  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _usersCollection.doc(uid).get();

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    return UserModel.fromMap(doc.data()!);
  }

  /// Kiểm tra hồ sơ người dùng đã tồn tại chưa.
  ///
  /// Dùng khi đăng nhập Google lần đầu — nếu chưa có profile
  /// thì cần tạo mới mà không hỏi lại thông tin.
  Future<bool> userProfileExists(String uid) async {
    final doc = await _usersCollection.doc(uid).get();
    return doc.exists;
  }
}
