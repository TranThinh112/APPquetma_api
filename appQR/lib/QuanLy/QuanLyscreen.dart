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
import 'dart:async';
import '../data/api_service.dart';
import '../models/to_model.dart';
import '../models/Oders_model.dart';
import '../QuanLy/QuangLy_logic.dart';
import '../models/BillTo.dart';
import '../models/appbar_logo.dart';


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
  int currentPage = 1;
  bool isLoading = false;
  bool hasMore = true;
  String keyword = ""; //du lieu search
  int tongDon =0; //tonh he thon
  int donInbound = 0; //tong don inbound
  bool _isScanning = false;


  List<OrderModel> orders = [];
  Timer? _debounce;
  @override
  void initState() {
    super.initState();
    loadPage(1);
  }
//load page
  Future<void> loadPage(int page) async {
    if (isLoading) return;

    setState(() => isLoading = true);

    final res = await ApiService.getOrderQL(page,keyword);
    if (!mounted) return;
    setState(() {
      orders = res['orders'];   // 🔥 đúng data
      currentPage = page;
      isLoading = false;
      hasMore = orders.length == 10;
      if (keyword.isEmpty) {
        tongDon = res['total'];
        donInbound = res['inbound'];
      }
    });
  }

  /// Format thời gian hiển thị
  String formatTime(DateTime? time) {
    if (time == null) return '';
    final year = (time.year % 100).toString().padLeft(2,'0');
    return "$year/${time.month}/${time.day} ${time.hour}:${time.minute.toString().padLeft(2, '0')}";
  }
  //ham tim kiem don hang
  Future<void> scanToSearch() async {
    _isScanning = false;
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

                  onDetect: (capture) async {
                  if (_isScanning) return;

                  final code = capture.barcodes.first.rawValue?.trim() ?? '';
                  if (code.isEmpty) return;
                  _isScanning = true;

                  final keywordScan = code.toUpperCase();
                  final result = search(orders, keyword);
                  //set text dau tien
                  setState(() {
                    searchController.value = TextEditingValue(
                      text: keywordScan,
                      selection: TextSelection.collapsed(offset: keywordScan.length),
                    );
                    keyword = keywordScan;
                  });
                  //dong camera sau khi quet
                  Navigator.pop(ctx);
                  scanController.dispose();
                  //goi api
                  await loadPage(1);

                  if (!mounted) return;

                  setState(() {
                    filteredList = search(orders, keyword);
                  });

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
    _debounce?.cancel();   // QUAN TRỌNG
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
           HeaderWidget(),

            // ── Thanh tìm kiếm + nút quét ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: searchController,

                      onChanged: (value) {
                        if (_debounce?.isActive ?? false) {
                          _debounce!.cancel();
                        }
                        _debounce = Timer(const Duration(milliseconds: 300), () {
                          keyword = value;
                          loadPage(1);
                          if(!mounted) return;
                          setState(() {
                            filteredList = search(orders, value);
                          });
                        });
                      },
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
                  //nut quet ma
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
              child: RefreshIndicator(
                  onRefresh: () async{
                    await loadPage(1);
                  },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Table(
                    border: TableBorder.all(color: Colors.grey[400]!, width: 1),
                    // defaultColumnWidth: const IntrinsicColumnWidth(),
                    columnWidths: {
                      0: const FixedColumnWidth(175), //1 id
                      1: const FixedColumnWidth(80),//3 NN
                      2: const FixedColumnWidth(50),//5 KG
                      3: const FixedColumnWidth(120,), //6tt
                      4: const FixedColumnWidth(125,), // 7
                      5: const FixedColumnWidth(150),//ma to
                      6: const FixedColumnWidth(60,), // 9view
                    },
                    children: [
                      // Header row
                      TableRow(
                        decoration: BoxDecoration(color: Colors.orange[100]),
                        children: const [
                          _Header('Mã Đơn'),
                          _Header('Nơi đi'),
                          _Header('KG'),
                          _Header('Trạng Thái'),
                          _Header('T/Gian Đóng'),
                          _Header('Mã TO'),
                          _Header('View'),
                        ],
                      ),
                      // Data rows
                      ...orders.map((o) {
                        bool hasTO = o.maTO != null && o.maTO!.isNotEmpty;
                        // final isPacked = to.trangThai == 'Inbound';
                        return TableRow(
                          children: [
                            _Cell(o.id),
                            _Cell(o.noinhan),
                            _Cell(o.soKi.toStringAsFixed(1)),
                            /// STATUS
                            Padding(
                              padding: const EdgeInsets.all(6),
                              child: o.trangthai == null || o.trangthai!.isEmpty
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
                                  o.trangthai!,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ),

                            // _Cell(formatTime(o.thoigiantao)),
                            _Cell(o.thoigiandongbao != null
                                ? formatTime(o.thoigiandongbao!)
                                : '—'),
                            _Cell(o.maTO!),
                            /// VIEW

                        Center(
                            child: SizedBox(
                              width: 40,
                              height: 40,
                              child: InkWell(
                                onTap: hasTO
                                ? () {
                                  final to = TOModel(
                                    maTO: o.maTO!,
                                    diaDiemGiaoHang: "",
                                    packer: "",
                                    totalWeight: o.soKi,
                                    ngayTao: DateTime.now(),
                                    completeTime: o.thoigiandongbao,
                                    danhSachGoiHang: [],
                                  );

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                    builder: (_) => BillTO(TO: to),
                                    ),
                                  );
                                }
                                    : null, // 🔥 disable nếu không có TO
                                child: Icon(Icons.visibility, color: hasTO ? Colors.blue : Colors.grey, // 🔥 đổi màu),
                              ),
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
            ),
            //nut chuyen trang
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: currentPage > 1
                      ? () => loadPage(currentPage - 1)
                      : null,
                ),

                Text("Trang $currentPage"),

                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: hasMore
                      ? () => loadPage(currentPage + 1)
                      : null,
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

}
