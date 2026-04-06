class OrderModel {
  final String id;
  final String noigui;
  final String noinhan;
  final String sanpham;
  double soKi;
  final String? trangthai;
  final DateTime? thoigiantao;
  final DateTime? thoigiandongbao;
  final String nguoigui;
  final String nguoinhan;
  final String diachigui;
  final String diachinhan;
  final int giatien;
  final String? maTO;

  OrderModel({
    required this.id,
    required this.noigui,
    required this.noinhan,
    required this.sanpham,
    required this.soKi,
    this.trangthai,
    this.thoigiantao,
    this.thoigiandongbao,
    required this.nguoigui,
    required this.nguoinhan,
    required this.diachigui,
    required this.diachinhan,
    required this.giatien,
    this.maTO
  });
//doc tu json
  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] ?? '',
      noigui: json['noiGui'] ?? '',
      noinhan: json['noiNhan'] ?? '',
      sanpham: json['sanPham'] ?? '',
      soKi: double.tryParse(json['soKi']?.toString() ?? '0') ?? 0,
      trangthai: json['trangThai'] ?? '',
      thoigiantao: DateTime.tryParse(json['thoiGianTao'] ?? '') ?? DateTime.now(),
      thoigiandongbao: json['thoiGianDongBao'] != null
          ? DateTime.tryParse(json['thoiGianDongBao'].toString())
          : null,
      nguoigui: json['nguoiGui'] ?? '',
      diachigui: json['diaChiGui'] ?? '',

      nguoinhan: json['nguoiNhan'] ?? '',
      diachinhan: json['diaChiNhan'] ?? '',
      giatien: int.tryParse(json['giaTien']?.toString() ?? '0') ?? 0,
      maTO: json['maTO'] ?? '',
    );
  }
  // // chuyen sang json
  Map<String, dynamic> toJson() {
    final data = {
      "id": id,
      "noiGui": noigui,
      "noiNhan": noinhan,
      "sanPham": sanpham,
      "soKi": soKi,
      "thoiGianTao": thoigiantao?.toIso8601String(),
      "thoiGianDongBao": thoigiandongbao?.toIso8601String(),
      "nguoiGui": nguoigui,
      "nguoiNhan": nguoinhan,
      "diaChiGui": diachigui,
      "diaChiNhan": diachinhan,
      "giaTien": giatien,
    };
    if (trangthai != null) data["trangThai"] = trangthai;
    if (thoigiantao != null) {
      data["thoiGianTao"] = thoigiantao!.toIso8601String();
    }
    if (thoigiandongbao != null) {
      data["thoiGianDongBao"] =
          thoigiandongbao!.toIso8601String();
    }
    if (maTO != null) data["maTO"] = maTO;

    return data;
  }
}