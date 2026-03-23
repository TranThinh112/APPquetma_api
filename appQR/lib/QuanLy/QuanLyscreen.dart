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
import 'package:flutter/services.dart';
import '../data/api_service.dart';
import '../models/BillScreen.dart';


class QuanLyScreen extends StatefulWidget {
  const QuanLyScreen({super.key});

  @override
  State<QuanLyScreen> createState() => _QuanLyScreenState();
}
class _Header extends StatelessWidget {
  final String text;
  const _Header(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final String text;
  const _Cell(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Text(
        text,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
class OrderModel {
  final String id;
  final String noigui;
  final String noinhan;
  final String sanpham;
  final double soKg;
  final String trangthai;
  final DateTime thoigiantao;
  final DateTime? thoigiandongbao;

  OrderModel({
    required this.id,
    required this.noigui,
    required this.noinhan,
    required this.sanpham,
    required this.soKg,
    required this.trangthai,
    required this.thoigiantao,
    this.thoigiandongbao,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] ?? '',
      noigui: json['noiGui'] ?? '',
      noinhan: json['noiNhan'] ?? '',
      sanpham: json['sanPham'] ?? '',
      soKg: (json['soKg'] as num?)?.toDouble() ?? 0,
      trangthai: json['trangThai'] ?? '',
      thoigiantao: DateTime.tryParse(json['thoiGianTao'] ?? '') ?? DateTime.now(),
      thoigiandongbao: json['thoiGianDongBao'] != null
          ? DateTime.tryParse(json['thoiGianDongBao'].toString())
          : null,
    );
  }
}
class _QuanLyScreenState extends State<QuanLyScreen> {
  final TextEditingController searchController = TextEditingController();
  List<OrderModel> allOrders = [];
  List<OrderModel> filteredList = [];
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
      final data = await ApiService.getOrderQL();
      setState(() {
        allOrders = data;
        filteredList = data;
      });
    } catch (e) {
      debugPrint('Error refreshing list: $e');
    }
  }

  void _search(String keyword) {
    setState(() {
      if (keyword.isEmpty) {
        filteredList = allOrders;
      } else {
        filteredList = allOrders
            .where((o) => o.id.toUpperCase().contains(keyword.toUpperCase()))
            .toList();
      }
    });
  }
  //
  // List<TOModel> _searchID(List<TOModel> list, String keyword) {
  //   if (keyword.isEmpty) return list;
  //   final upper = keyword.toUpperCase();
  //   return list.where((to) => to.maTO.toUpperCase().contains(upper)).toList();
  // }

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
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                        fillColor: isDark ? Colors.grey[900] : Colors.grey[50],
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
                      0: const FixedColumnWidth(150), //1 id
                      1: const FixedColumnWidth(70),//2 NG
                      2: const FixedColumnWidth(80),//3 NN
                      3: const FixedColumnWidth(100),//4 SP
                      4: const FixedColumnWidth(50),//5 KG
                      5: const FixedColumnWidth(90,), //6tt
                      6: const FixedColumnWidth(110,), // 7
                      7: const FixedColumnWidth(110,), // 8
                      8: const FixedColumnWidth(60,), // 8
                    },
                    children: [
                      // Header row
                      TableRow(
                        decoration: BoxDecoration(color: Colors.orange[100]),
                        children: const [
                          _Header('Mã Đơn'),
                          _Header('Nơi gửi'),
                          _Header('Nơi nhận'),
                          _Header('Sản Phẩm'),
                          _Header('KG'),
                          _Header('Trạng Thái'),
                          _Header('Thời Gian Tạo'),
                          _Header('T/Gian Đóng'),
                          _Header('View'),
                        ],
                      ),
                      // Data rows
                      ...filteredList.map((o) {
                        // final isPacked = to.trangThai == 'Inbound';
                        return TableRow(
                          children: [
                            _Cell(o.id),
                            _Cell(o.noigui),
                            _Cell(o.noinhan),
                            _Cell(o.sanpham),
                            _Cell(o.soKg.toStringAsFixed(1)),

                            /// STATUS
                            Padding(
                              padding: const EdgeInsets.all(6),
                              child: o.trangthai.isEmpty
                                  ? const SizedBox() // 🔥 trống hoàn toàn
                                  : Container(
                                alignment: Alignment.center,
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                decoration: BoxDecoration(
                                  color: o.trangthai == 'InBound'
                                      ? Colors.green
                                      : Colors.orange,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  o.trangthai,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ),

                            _Cell(formatTime(o.thoigiantao)),
                            _Cell(o.thoigiandongbao != null
                                ? formatTime(o.thoigiandongbao!)
                                : '—'),

                            /// VIEW
                            Center(
                              child: SizedBox(
                                width: 40,
                                height: 40,
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => BillScreen(order: o),
                                      ),
                                    );
                                  },
                                  child: const Icon(Icons.visibility, color: Colors.blue),
                                ),
                              ),
                            ),

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
