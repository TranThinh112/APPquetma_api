/// =============================================================
/// File: to_model.dart
/// Mô tả: Model dữ liệu cho bao hàng (Transfer Order - TO).
///
/// Thuộc tính:
///   - maTO           : Mã TO (VD: TO2603AB1X) - định dạng TO2603 + 4 ký tự ngẫu nhiên
///   - danhSachGoiHang : Danh sách mã gói hàng nhỏ trong bao
///   - diaDiemGiaoHang : Địa điểm giao hàng
///   - trangThai      : Trạng thái bao hàng (Packing / Packed)
///   - ngayTao        : Ngày tạo bao hàng
///   - totalWeight    : Tổng trọng lượng (KG) của bao hàng
///   - soLuongDonHang : Getter - số gói hàng trong bao
///   - maxGoiHang     : Hằng số - tối đa 5 gói hàng / bao
///   - maxWeight      : Hằng số - tối đa 20 KG / bao
/// =============================================================
class TOModel {
  final String maTO; // Mã TO
  final List<String> danhSachGoiHang; // Danh sách mã gói hàng
  final String diaDiemGiaoHang; // Địa điểm giao
  final String trangThai; // Packing / Packed
  final DateTime ngayTao; // Thời gian tạo
  final DateTime? completeTime; // Thời gian hoàn thành
  final String packer; // Người đóng gói
  final double totalWeight; // Tổng KG

  TOModel({
    required this.maTO,
    required this.danhSachGoiHang,
    this.diaDiemGiaoHang = '',
    this.trangThai = 'Packing',
    this.packer = '',
    this.totalWeight = 0.0,
    DateTime? ngayTao,
    this.completeTime,
  }) : ngayTao = ngayTao ?? DateTime.now();

  int get soLuongDonHang => danhSachGoiHang.length;

  static const int maxGoiHang = 5; // Tối đa 5 kiện hàng
  static const double maxWeight = 10.0; // Tối đa 1bvcvbgnjm nbvc0 KG
}
