/// =============================================================
/// File: scan_to_logic.dart
/// Mô tả: Logic xử lý cho màn hình "Scan TO" - Quét mã bao hàng.
///        Tách riêng khỏi UI.
/// =============================================================

/// Kết quả quét mã TO
enum ScanTOResult {
  success,       // Quét thành công
  empty,         // Mã trống
  duplicate,     // Trùng mã vừa quét
  invalidFormat, // Sai định dạng mã TO
}

/// Logic chính cho Scan TO
class ScanTOLogic {
  String result = "";
  String type = "";

  /// Validate mã TO: TO + yyMMdd + 4 ký tự chữ/số
  bool isValidTO(String code) {
    final regex = RegExp(r'^TO\d{6}[A-Z0-9]{4}$', caseSensitive: false);
    return regex.hasMatch(code.trim());
  }

  /// Xử lý mã quét — trả về kết quả để UI phản hồi
  ScanTOResult processCode(String code, String codeType) {
    code = code.trim().toUpperCase();

    if (code.isEmpty) return ScanTOResult.empty;
    if (code == result) return ScanTOResult.duplicate;
    if (!isValidTO(code)) return ScanTOResult.invalidFormat;

    // ✅ Hợp lệ
    result = code;
    type = codeType;
    return ScanTOResult.success;
  }
}
