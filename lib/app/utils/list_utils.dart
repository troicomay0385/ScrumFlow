/// Chia nhỏ một danh sách [list] thành các danh sách con có kích thước tối đa là [size].
List<List<T>> chunkList<T>(List<T> list, int size) {
  if (size <= 0) {
    throw ArgumentError.value(size, 'size', 'Kích thước chunk phải lớn hơn 0');
  }
  if (list.isEmpty) return [];

  final chunks = <List<T>>[];
  for (int i = 0; i < list.length; i += size) {
    final end = (i + size < list.length) ? i + size : list.length;
    chunks.add(list.sublist(i, end));
  }
  return chunks;
}
