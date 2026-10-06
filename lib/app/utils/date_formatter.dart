/// Định dạng ngày kiểu Việt Nam `dd/MM/yyyy` — tránh thêm package `intl`
/// chỉ để hiển thị deadline User Story.
String formatDateVi(DateTime date) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(date.day)}/${two(date.month)}/${date.year}';
}

/// Thời gian tương đối cho bình luận: "Vừa xong", "5 phút trước",
/// "2 giờ trước", "3 ngày trước"; cũ hơn 7 ngày thì hiện ngày `dd/MM/yyyy`.
String formatRelativeTimeVi(DateTime time, {DateTime? now}) {
  final diff = (now ?? DateTime.now()).difference(time);
  if (diff.inMinutes < 1) return 'Vừa xong';
  if (diff.inHours < 1) return '${diff.inMinutes} phút trước';
  if (diff.inDays < 1) return '${diff.inHours} giờ trước';
  if (diff.inDays <= 7) return '${diff.inDays} ngày trước';
  return formatDateVi(time);
}
