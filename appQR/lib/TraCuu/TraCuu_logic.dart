import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../models/to_model.dart';
import '../data/api_service.dart';
import '../TraCuu/TraCuuScreen.dart';
import '../models/Oders_model.dart';

enum ScanResult {
  success,          // Quét thành công
  empty,            // Mã trống
  invalidFormat,    // Sai định dạng
  notFound,         // Không tìm thấy trên server
}
class TraCuuLogic {
//kim tra ma
  /// Validate mã SPX: phải khớp SPXVN06 + 8-10 chữ số
  bool isValidSPX(String code) {
    final regex = RegExp(r'^SPXVN06\d{8,10}$', caseSensitive: false);
    return regex.hasMatch(code.trim());
  }

//ket qua quet
  Future<ScanResult> processCode(String code) async {
    code = code.trim().toUpperCase();

    //tra ve rong neu ko co don hang
    if (code.isEmpty) return ScanResult.empty;
    //tra ve fail neu kiem tra sai dinh dang
    if (!isValidSPX(code)) return ScanResult.invalidFormat;
    // Gọi API tìm đơn hàng
    final order = await ApiService.getOrder(code);
    if (order == null) return ScanResult.notFound;
    return ScanResult.success;
  }
  //hàm lâ 1 đơn
  Future<Map<String, OrderModel>> refreshList(String id) async {
    final data = await ApiService.getOrder(id);
    if (data == null) return {};
    return {
      "order": OrderModel.fromJson(data)
    };
  }
}