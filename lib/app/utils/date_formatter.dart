/// Định dạng ngày kiểu Việt Nam `dd/MM/yyyy` — tránh thêm package `intl`
/// chỉ để hiển thị deadline User Story.
String formatDateVi(DateTime date) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(date.day)}/${two(date.month)}/${date.year}';
}
