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
  static const double maxWeight = 10.0; // Tối đa 10 KG

  factory TOModel.fromJson(Map<String, dynamic> json) {
    var rawDsg = json['danhSachGoiHang'];
    List<String> listGoiHang = [];
    if (rawDsg is String) {
      // Server lưu dạng chuỗi, có thể bị bọc thêm dấu ngoặc kép → loại bỏ
      String cleaned = rawDsg.replaceAll('"', '').trim();
      listGoiHang = cleaned.isEmpty ? [] : cleaned.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    } else if (rawDsg is List) {
      listGoiHang = List<String>.from(rawDsg);
    }

    return TOModel(
      maTO: json['maTO'] ?? '',
      danhSachGoiHang: listGoiHang,
      diaDiemGiaoHang: json['diaDiemGiaoHang'] ?? '',
      trangThai: json['trangThai'] ?? 'Packing',
      packer: json['packer'] ?? '',
      totalWeight: (json['totalWeight'] ?? 0.0).toDouble(),
      ngayTao: json['ngayTao'] != null ? DateTime.tryParse(json['ngayTao'].toString()) : null,
      completeTime: json['completeTime'] != null ? DateTime.tryParse(json['completeTime'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maTO': maTO,
      'danhSachGoiHang': danhSachGoiHang,
      'diaDiemGiaoHang': diaDiemGiaoHang,
      'trangThai': trangThai,
      'packer': packer,
      'totalWeight': totalWeight,
      'ngayTao': ngayTao.toIso8601String(),
      'completeTime': completeTime?.toIso8601String(),
    };
  }
}
