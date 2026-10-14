import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Đọc dependency tuỳ chọn từ cây widget: trả về `null` thay vì throw khi
/// chưa được cung cấp (vd. widget test chỉ dựng một phần cây provider).
T? maybeRead<T>(BuildContext context) {
  try {
    return context.read<T>();
  } on ProviderNotFoundException {
    return null;
  }
}
