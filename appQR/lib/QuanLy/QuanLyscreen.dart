/// =============================================================
/// File: danh_sach_to_screen.dart (CẬP NHẬP)
/// Mô tả: Màn hình "Created TO" - Danh sách bao hàng đã tạo.
///
/// Thay đổi mới:
///   - Lấy dữ liệu từ TODatabase (SQLite) thay vì TOStorage
///   - Thêm column KG (trọng lượng)
///   - Hiển thị: Mã TO | Số lượng | Địa điểm | Trạng thái | Trọng lượng (KG)
/// =============================================================
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/to_model.dart';
import '../data/to_database.dart';
import 'package:flutter/services.dart';


class QuanLyScreen extends StatefulWidget {
  const QuanLyScreen({super.key});

  @override
  State<QuanLyScreen> createState() => _QuanLyScreenState();
}

class _QuanLyScreenState extends State<QuanLyScreen> {
  final TextEditingController searchController = TextEditingController();
  List<TOModel> allTOs = [];
  List<TOModel> filteredList = [];
  final Set<String> _selectedTOs = {};

  @override
  void initState() {
    super.initState();
    _refreshList();
  }

  /// Tự động refresh khi quay lại màn hình
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshList();
  }

  Future<void> _refreshList() async {
    try {
      allTOs = await TODatabase.instance.getAllTOs();
      setState(() {
        filteredList = _searchID(allTOs, searchController.text);
      });
    } catch (e) {
      debugPrint('Error refreshing list: $e');
    }
  }

  void _search(String keyword) {
    setState(() {
      filteredList = _searchID(allTOs, keyword);
    });
  }

  List<TOModel> _searchID(List<TOModel> list, String keyword) {
    if (keyword.isEmpty) return list;
    final upper = keyword.toUpperCase();
    return list.where((to) => to.maTO.toUpperCase().contains(upper)).toList();
  }

  /// Format thời gian hiển thị
  String formatTime(DateTime? time) {
    if (time == null) return '';
    final year = (time.year % 100).toString().padLeft(2,'0');
    return "$year/${time.month}/${time.day} ${time.hour}:${time.minute.toString().padLeft(2, '0')}";
  }
  

  Future<void> _scanToSearch() async {
    final scanController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      returnImage: false,
      formats: [BarcodeFormat.qrCode, BarcodeFormat.code128],
    );

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Quét mã đơn hàng'),
          content: SizedBox(
            width: 280,
            height: 280,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: MobileScanner(
                controller: scanController,
                onDetect: (capture) {
                  if (capture.barcodes.isEmpty) return;
                  final code = capture.barcodes.first.rawValue?.trim() ?? '';
                  if (code.isNotEmpty) {
                    searchController.text = code.toUpperCase();
                    _search(code.toUpperCase());
                    scanController.dispose();
                    Navigator.pop(ctx);
                  }
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                scanController.dispose();
                Navigator.pop(ctx);
              },
              child : const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header cam với logo SPX ──
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.orange[600],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        TextButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Quay lại',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                        const Spacer(),

                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.inventory_2,
                          size: 50,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'SPX Express',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Thanh tìm kiếm + nút quét ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      onChanged: _search,
                      decoration: InputDecoration(
                        hintText: 'Tìm mã đơn',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.orange[600],
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: Colors.orange[600]!,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.orange[700],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      onPressed: _scanToSearch,
                      icon: const Icon(
                        Icons.qr_code_scanner,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Bảng dữ liệu (kéo ngang được) ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Table(
                    border: TableBorder.all(color: Colors.grey[400]!, width: 1),
                    defaultColumnWidth: const IntrinsicColumnWidth(),
                    columnWidths: {
                      0: const FixedColumnWidth(160), //1
                      1: const FixedColumnWidth(90),//2
                      2: const FixedColumnWidth(90),//3
                      3: const FixedColumnWidth(60),//4
                      4: const FixedColumnWidth(80),//5
                      5: const FixedColumnWidth(120,), //6
                      6: const FixedColumnWidth(120,), // 7
                      7: const FixedColumnWidth(40,), // 8
                    },
                    children: [
                      // Header row
                      TableRow(
                        decoration: BoxDecoration(color: Colors.orange[100]),
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(10),
                            child: Text(
                              'Mã Đơn',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.all(10),
                            child: Text(
                              'Nơi gửi',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.all(10),
                            child: Text(
                              'Nơi nhận',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.all(10),
                            child: Text(
                              'KG',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.all(10),
                            child: Text(
                              'Status',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.all(10),
                            child: Text(
                              'Create time',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.all(10),
                            child: Text(
                              'Inbound time',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.all(10),
                            child: Text(
                              '',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                      // Data rows
                      ...filteredList.map((to) {
                        final isPacked = to.trangThai == 'Inbound';
                        return TableRow(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: Text(
                                to.maTO,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: Text(
                                '${to.soLuongDonHang}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: Text(
                                to.diaDiemGiaoHang.isEmpty
                                    ? '—'
                                    : to.diaDiemGiaoHang,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isPacked ? Colors.green : Colors.red,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  to.trangThai,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: Text(
                                '${to.totalWeight.toStringAsFixed(1)}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: Text(
                                to.packer.isEmpty ? '—' : to.packer,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: Text(
                                formatTime(to.ngayTao),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),

                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: Text(
                                formatTime(to.completeTime),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            // Cột Sửa (chỉ hiện icon khi Packing)
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
