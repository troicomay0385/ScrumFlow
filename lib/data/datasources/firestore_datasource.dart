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

  /// Tìm hồ sơ người dùng theo email — dùng khi Product Owner thêm
  /// thành viên vào project bằng email.
  ///
  /// Trả về `null` nếu không có user nào đăng ký với email này.
  Future<UserModel?> findUserByEmail(String email) async {
    final snapshot =
        await _usersCollection.where('email', isEqualTo: email).limit(1).get();

    if (snapshot.docs.isEmpty) return null;
    return UserModel.fromMap(snapshot.docs.first.data());
  }

  /// Đọc nhiều hồ sơ người dùng theo danh sách UID (dùng khi hiển thị
  /// danh sách thành viên project — mỗi thành viên cần avatar/tên/email).
  ///
  /// UID không tồn tại (user đã bị xoá) sẽ bị bỏ qua thay vì throw.
  Future<Map<String, UserModel>> getUserProfiles(List<String> uids) async {
    if (uids.isEmpty) return {};

    final results = await Future.wait(uids.map((uid) => getUserProfile(uid)));

    final map = <String, UserModel>{};
    for (var i = 0; i < uids.length; i++) {
      final user = results[i];
      if (user != null) map[uids[i]] = user;
    }
    return map;
  }
}
