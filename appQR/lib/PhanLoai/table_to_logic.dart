/// =============================================================
/// File: table_to_logic.dart
/// Mô tả: Logic xử lý cho màn hình "Table TO" - Danh sách bao hàng.
///        Tách riêng khỏi UI.
/// =============================================================
import '../models/to_model.dart';
// import '../data/to_database.dart';
import '../data/api_service.dart';
import 'package:flutter/foundation.dart';

/// Logic chính cho Table TO
class TableTOLogic {
  List<TOModel> allTOs = [];
  List<TOModel> filteredList = [];
  bool isDeleteMode = false;
  final Set<String> selectedTOs = {};

  /// Load tất cả TO từ server
  Future<void> refreshList() async {
    try {
      final serverData = await ApiService.getAllTOsFromServer();
      allTOs = serverData.map((e) => TOModel.fromJson(e)).toList();
      filteredList = _filterByKeyword(allTOs, '');
      _sortList(filteredList);
    } catch (e) {
      debugPrint('Error refreshing list: $e');
    }
  }
  //sap xep
  void _sortList(List<TOModel> list) {
    list.sort((a, b) {
      // 1. Ưu tiên trạng thái
      int getPriority(String status) {
        switch (status) {
          case 'Packed':
            return 0;
          case 'Packing':
            return 1;
          default:
            return 2;
        }
      }
      int priorityCompare =
      getPriority(a.trangThai).compareTo(getPriority(b.trangThai));

      if (priorityCompare != 0) {
        return priorityCompare;
      }

      // 2. Nếu cùng trạng thái → sort theo thời gian (mới nhất trước)
      DateTime timeA = a.ngayTao ?? DateTime(1970);
      DateTime timeB = b.ngayTao ?? DateTime(1970);

      return timeB.compareTo(timeA); // DESC
    });
  }

  /// Tìm kiếm theo từ khóa
  void search(String keyword) {
    filteredList = _filterByKeyword(allTOs, keyword);
    _sortList(filteredList);
  }

  List<TOModel> _filterByKeyword(List<TOModel> list, String keyword) {
    if (keyword.isEmpty) return list;
    final upper = keyword.toUpperCase();
    return list.where((to) => to.maTO.toUpperCase().contains(upper)).toList();
  }

  /// Format thời gian hiển thị: yy/M/d HH:mm
  String formatTime(DateTime? time) {
    if (time == null) return '';
    final year = (time.year % 100).toString().padLeft(2, '0');
    return "$year/${time.month}/${time.day} ${time.hour}:${time.minute.toString().padLeft(2, '0')}";
  }

  /// Toggle chọn/bỏ chọn TO để xóa
  void toggleSelect(String maTO) {
    if (selectedTOs.contains(maTO)) {
      selectedTOs.remove(maTO);
    } else {
      selectedTOs.add(maTO);
    }
  }

  /// Xóa tất cả TO đã chọn trên server
  Future<void> deleteSelectedTOs() async {
    for (final maTO in selectedTOs) {
      await ApiService.deleteTOOnServer(maTO);
    }
    selectedTOs.clear();
    isDeleteMode = false;
    await refreshList();
  }

  /// Toggle chế độ xóa
  void toggleDeleteMode() {
    isDeleteMode = !isDeleteMode;
    selectedTOs.clear();
  }

  /// Hủy chế độ xóa
  void cancelDeleteMode() {
    isDeleteMode = false;
    selectedTOs.clear();
  }
}
