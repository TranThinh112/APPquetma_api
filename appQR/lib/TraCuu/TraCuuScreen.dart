import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/Oders_model.dart';
import '../models/BillScreen.dart';

class TraCuuScreen extends StatefulWidget{
    const TraCuuScreen({super.key});

    @override
    _TraCuuScreenState createState() => _TraCuuScreenState();
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
      child: Text(
        text,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _TraCuuScreenState extends State<TraCuuScreen> {
  final TextEditingController searchController = TextEditingController();
  List<OrderModel> allOrders = [];
  List<OrderModel> filteredList = [];
  final Set<String> _selectedTOs = {};

  void _search(String keyword) {
    _sortList(filteredList);
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
  void _sortList(List<OrderModel> list) {
    list.sort((a, b) {
      // 1. Ưu tiên trạng thái
      int getPriority(String status) {
        switch (status) {
          case 'Inbound':
            return 0;
          case 'Ountbound':
            return 1;
          default:
            return 2;
        }
      }
      int priorityCompare =
      getPriority(a.trangthai).compareTo(getPriority(b.trangthai));

      if (priorityCompare != 0) {
        return priorityCompare;
      }
      // 2. Nếu cùng trạng thái → sort theo thời gian (mới nhất trước)
      DateTime timeA = a.thoigiantao ?? DateTime(1970);
      DateTime timeB = b.thoigiantao ?? DateTime(1970);

      return timeB.compareTo(timeA); // DESC
    });
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
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
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
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Quay lại',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
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
            Container(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20),
                  Row(
                  children: [
                    Text(
                      'Nhập mã đơn: ',
                      style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  SizedBox(width: 220),
                    //nut quet mau cam
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
                  SizedBox(height: 10),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10), //thu vien 2 bên
                    child: SizedBox(
                      height: 200,
                      child:  TextField(
                        maxLines: 5,
                        maxLength: 1000,
                        keyboardType: TextInputType.multiline,
                        textAlignVertical: TextAlignVertical.top,

                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black, // chữ nhập
                        ),

                        decoration: InputDecoration(
                          hintText: "Nhập mã đơn...",
                          hintStyle: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey,
                          ),

                          filled: true,
                          fillColor: isDark ? Colors.grey[900] : Colors.white, // nền

                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              width: 2,
                              color: isDark ? Colors.grey[600]! : Colors.black,
                            ),
                          ),

                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              width: 2,
                              color: Colors.orange, // giữ màu SPX
                            ),
                          ),
                        ),
                      )
                    ),
                  ),
                  SizedBox(height: 2),
                Row(
                  children: [
                    SizedBox(width: 10),
                     SizedBox(
                      width: 100, // 👈 full ngang
                      height: 30,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white70, // màu
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10), // bo góc
                          ),
                        ),
                        onPressed: () {
                          print("gaf!");
                        },
                        child: Text(
                          "Xem",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10), //khoang cach giua cac nut
                    SizedBox(
                      width: 100,
                      height: 30,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white70, // màu
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10), // bo góc
                          ),
                        ),
                        onPressed: () {
                          print("gaf!");
                        },
                        child: Text(
                          "In",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    SizedBox(
                      width: 150, // 👈 full ngang
                      height: 30,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[400], // màu
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10), // bo góc
                          ),
                        ),
                        onPressed: () {
                          print("not!");
                        },
                        child: Text(
                          "Confirm",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ),
                    ]
                  ),
                ],
              ),
            ),
        const SizedBox(height: 20),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Table(
                border: TableBorder.all(color: Colors.grey[400]!, width: 1),
                defaultColumnWidth: const IntrinsicColumnWidth(),
                columnWidths: {
                  0: const FixedColumnWidth(160), //1 id
                  1: const FixedColumnWidth(70),//2 NG
                  2: const FixedColumnWidth(80),//3 NN
                  3: const FixedColumnWidth(100),//4 SP
                  4: const FixedColumnWidth(50),//5 KG
                  5: const FixedColumnWidth(90,), //6tt
                  6: const FixedColumnWidth(120,), // 7
                  7: const FixedColumnWidth(120,), // 8
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

