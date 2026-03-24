import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/to_model.dart';
import '../data/to_database.dart';

/// Hàm upload 1 TO lên API server
Future<void> uploadTOToServer(TOModel to) async {
  final url = Uri.parse('https://your-api-server.com/api/transfer_orders'); // Thay URL thật
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'maTO': to.maTO,
      'danhSachGoiHang': to.danhSachGoiHang,
      'diaDiemGiaoHang': to.diaDiemGiaoHang,
      'trangThai': to.trangThai,
      'packer': to.packer,
      'ngayTao': to.ngayTao.toIso8601String(),
      'completeTime': to.completeTime?.toIso8601String(),
      'totalWeight': to.totalWeight,
    }),
  );
  if (response.statusCode == 200 || response.statusCode == 201) {
    print('Upload thành công TO: ${to.maTO}');
  } else {
    print('Lỗi upload TO: ${to.maTO} - ${response.body}');
  }
}

/// Hàm upload toàn bộ TO từ local database lên API server
Future<void> uploadAllTOsToServer() async {
  final allTOs = await TODatabase.instance.getAllTOs();
  for (final to in allTOs) {
    await uploadTOToServer(to);
  }
}
