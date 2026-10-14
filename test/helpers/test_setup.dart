import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// Thiết lập chung cho widget test.
///
/// Không cho `google_fonts` tải font qua mạng trong test (môi trường test
/// chặn HTTP) — chữ sẽ hiển thị bằng font mặc định, không ảnh hưởng tới
/// việc kiểm tra layout/hành vi.
void setUpWidgetTestEnvironment() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
}
