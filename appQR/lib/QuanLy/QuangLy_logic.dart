import 'package:appqr1/models/BillTo.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/services.dart';
import '../data/api_service.dart';
import '../models/Oders_model.dart';
import '../QuanLy/QuanLyscreen.dart';
import '../models/Oders_model.dart';

Future<List<OrderModel>> refreshList() async {
  final res = await ApiService.getOrderQL(1,"");

  final List<OrderModel> data = res['orders']; //  lấy đúng list

  sortList(data);
  return data;
}
List<OrderModel> search(List<OrderModel> list, String keyword) {
  if (keyword.isEmpty) return list;

  return list
      .where((o) => o.id.toUpperCase().contains(keyword.toUpperCase()))
      .toList();
}
//sap xep theo trang thais

void sortList(List<OrderModel> list) {
  int getPriority(String? status) {
    switch (status?.toLowerCase()) {
      case 'Inbound':
        return 0;
      case 'Outbound':
        return 1;
      default:
        return 2;
    }
  }
  list.sort((a, b) {
    /// 1. Ưu tiên trạng thái
    int priorityCompare =
    getPriority(a.trangthai).compareTo(getPriority(b.trangthai));

    if (priorityCompare != 0) {
      return priorityCompare;
    }
    /// 2. Nếu cùng trạng thái → sort theo thời gian (mới nhất trước)
    DateTime timeA = a.thoigiandongbao ?? DateTime(1970);
    DateTime timeB = b.thoigiandongbao ?? DateTime(1970);

    return timeB.compareTo(timeA); // DESC
  });
}
