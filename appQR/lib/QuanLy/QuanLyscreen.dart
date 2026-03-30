/// =============================================================
/// File: danh_sach_to_screen.dart (CẬP NHẬP)
/// Mô tả: Màn hình "Created TO" - Danh sách bao hàng đã tạo.
///
/// Thay đổi mới:
///   - Lấy dữ liệu từ TODatabase (SQLite) thay vì TOStorage
///   - Thêm column KG (trọng lượng)
///   - Hiển thị: Mã TO | Số lượng | Địa điểm | Trạng thái | Trọng lượng (KG)
/// =============================================================
import 'package:appqr1/models/BillTo.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/services.dart';
import '../data/api_service.dart';
import '../models/BillScreen.dart';
import '../models/Oders_model.dart';
import '../QuanLy/QuangLy_logic.dart';
// import '../models/BillTo.dart';/


class QuanLyScreen extends StatefulWidget {
  const QuanLyScreen({super.key});

  @override
  State<QuanLyScreen> createState() => QuanLyScreenState();
}
//format du lie header
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
//format du lieu cot
class _Cell extends StatelessWidget {
  final String text;
  const _Cell(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: SelectableText(
      text,
        textAlign: TextAlign.center,
      ),
    );
  }
}
class QuanLyScreenState extends State<QuanLyScreen> {
  final TextEditingController searchController = TextEditingController();
  List<OrderModel> allOrders = [];
  List<OrderModel> filteredList = [];
  final Set<String> _selectedTOs = {};

  @override
  void initState() {
    super.initState();
    loadData();
    // refreshList();
    loadOrders();
    inboundCount();
  }
  //lay du lieu tong don

  /// Tự động refresh khi quay lại màn hình
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    refreshList();
  }

  /// Format thời gian hiển thị
  String formatTime(DateTime? time) {
    if (time == null) return '';
    final year = (time.year % 100).toString().padLeft(2,'0');
    return "$year/${time.month}/${time.day} ${time.hour}:${time.minute.toString().padLeft(2, '0')}";
  }
//ham trung gian lay data tu logic sang UI
  Future<void> loadData() async {
    final data = await refreshList();
    final total = await loadOrders();
    final inbound = await inboundCount();

    setState(() {
      allOrders = data;
      filteredList = data;
      tongDon = total;
      donInbound = inbound;
    });
  }

  Future<void> scanToSearch() async {
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
                    final keyword = code.toUpperCase();
                    final result = search(allOrders, keyword);
                    setState(() {
                      searchController.text = keyword;
                      filteredList = result;
                    });
                    scanController.dispose();
                    Navigator.pop(context);
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
                      onChanged: (value) => setState(() {
                        filteredList = search(allOrders, value);
                      }),
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
                      onPressed: scanToSearch,
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
            Padding(
                padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Text("Tổng đơn: $tongDon"),
                  const Spacer(),
                  Text("Đã đóng: $donInbound/$tongDon"),
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
                    // defaultColumnWidth: const IntrinsicColumnWidth(),
                    columnWidths: {
                      0: const FixedColumnWidth(160), //1 id
                      1: const FixedColumnWidth(80),//3 NN
                      2: const FixedColumnWidth(50),//5 KG
                      3: const FixedColumnWidth(120,), //6tt
                      4: const FixedColumnWidth(120,), // 7
                      5: const FixedColumnWidth(120,), // 8
                      6: const FixedColumnWidth(125),//ma to
                      7: const FixedColumnWidth(60,), // 9
                    },
                    children: [
                      // Header row
                      TableRow(
                        decoration: BoxDecoration(color: Colors.orange[100]),
                        children: const [
                          _Header('Mã Đơn'),
                          _Header('Nơi nhận'),
                          _Header('KG'),
                          _Header('Trạng Thái'),
                          _Header('Thời Gian Tạo'),
                          _Header('T/Gian Đóng'),
                          _Header('Mã TO'),
                          _Header('View'),
                        ],
                      ),
                      // Data rows
                      ...filteredList.map((o) {
                        // final isPacked = to.trangThai == 'Inbound';
                        return TableRow(
                          children: [
                            _Cell(o.id),
                            _Cell(o.noinhan),
                            _Cell(o.soKi.toStringAsFixed(1)),
                            /// STATUS
                            Padding(
                              padding: const EdgeInsets.all(6),
                              child: o.trangthai.isEmpty
                                  ? const SizedBox() // 🔥 trống hoàn toàn
                                  : Container(
                                alignment: Alignment.center,
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                decoration: BoxDecoration(
                                  color: o.trangthai == 'Inbound'
                                      ? Colors.green
                                      : Colors.red,
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
                            _Cell(o.maTO),
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
