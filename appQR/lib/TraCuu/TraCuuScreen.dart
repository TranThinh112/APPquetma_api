import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/Oders_model.dart';
import '../models/BillScreen.dart';
import '../models/appbar_logo.dart';
import './TraCuu_logic.dart';

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
  final TextEditingController searchController = TextEditingController(); //lau du lieu tu scan or quet ma
  List<OrderModel> allOrders = [];
  List<OrderModel> filteredList = [];
  final Set<String> _selectedTOs = {};
  final AudioPlayer player = AudioPlayer();
  bool isProcessing = false;
  final logic = TraCuuLogic();
  bool _justSuccess = false;
  bool _isScanning = false;

  // Center message overlay
  String? centerMessage;
  Color? centerMessageColor;
  Timer? _messageTimer;

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
      int priorityCompare = getPriority(a.trangthai!).compareTo(getPriority(b.trangthai!));
      if (priorityCompare != 0) {
        return priorityCompare;
      }
      // 2. Nếu cùng trạng thái → sort theo thời gian (mới nhất trước)
      DateTime timeA = a.thoigiantao ?? DateTime(1970);
      DateTime timeB = b.thoigiantao ?? DateTime(1970);
      return timeB.compareTo(timeA); // DESC
    });
  }
  //tiếng khi thành cong
  Future<void> _playBeep() async {
    try {
      await player.stop();
      await player.play(AssetSource('beep.mp3'));
    } catch (_) {}
  }
//tieng khi loi
  Future<void> _playErrorSound() async {
    try {
      await player.stop();
      await player.play(AssetSource('error.mp3'));
    } catch (_) {}
  }
//hien loi
  void _showCenterMessage(String text, Color color,
      {Duration duration = const Duration(milliseconds: 900)}) {
    _messageTimer?.cancel();
    setState(() {
      centerMessage = text;
      centerMessageColor = color;
    });
    _messageTimer = Timer(duration, () {
      if (!mounted) return;
      setState(() => centerMessage = null);
    });
  }
  //loc du lieu trung
  List<OrderModel> uniqueList(List<OrderModel> list) {
    final seen = <String>{};

    return list.where((item) {
      if (seen.contains(item.id)) {
        return false;
      } else {
        seen.add(item.id);
        return true;
      }
    }).toList();
  }
  //xử lý sự kiện users nhapaj
  Future<void> _onManualInput() async {
    final input = searchController.text.trim();

    if (input.isEmpty) {
      _showCenterMessage("Vui lòng nhập mã", Colors.orange);
      setState(() {
        allOrders.clear();
        filteredList.clear();
      });
      return;
    }

    FocusScope.of(context).unfocus();

    final codes = input
        .split(RegExp(r'[\s,]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    // ========================
    // 🧪 1. VALIDATE FORMAT
    // ========================
    List<String> invalidCodes = [];

    for (final code in codes) {
      if (!logic.isValidSPX(code)) {
        invalidCodes.add(code);
      }
    }

    if (invalidCodes.isNotEmpty) {
      _showCenterMessage(
        "Sai định dạng:\n${invalidCodes.join('\n')}",
        Colors.red,
      );
      await _playErrorSound();
      return;
    }

    setState(() => isProcessing = true);

    // ========================
    // 🚀 2. XỬ LÝ SONG SONG + GIỮ CHECK
    // ========================
    List<String> notFoundCodes = [];

    final results = await Future.wait(codes.map((code) async {
      final result = await logic.processCode(code);

      if (result == ScanResult.notFound) {
        notFoundCodes.add(code); // 🔥giữ lại check
        return null;
      }

      if (result == ScanResult.success) {
        final data = await logic.refreshList(code);
        if (data != null && data['order'] != null) {
          return data['order'] as OrderModel;
        }
      }

      return null;
    }));

    // ========================
    // 🧪 3. CHECK NOT FOUND
    // ========================
    if (notFoundCodes.isNotEmpty) {
      setState(() => isProcessing = false);

      _showCenterMessage(
        "Không tìm thấy:\n${notFoundCodes.join('\n')}",
        Colors.red,
      );
      await _playErrorSound();
      return;
    }


    //  LẤY KẾT QUẢ

    List<OrderModel> tempOrders =
    results.whereType<OrderModel>().toList();

    // 🔥 LOẠI TRÙNG

    final uniqueResult = uniqueList(tempOrders);

    setState(() {
      allOrders = tempOrders;
      filteredList = uniqueResult;
      isProcessing = false;
    });

    _showCenterMessage('Tìm mã thành công', Colors.green);
    _playBeep();
  }

  //xu ly ket qua thanh cong, 3 truong hop loi: sai cau truc, ko tim thay ma, textfield trong
  Future<void> _handleScanResult(ScanResult result) async {
    switch (result) {
      case ScanResult.success:
        setState(() {
          _justSuccess = true;
        });
        _showCenterMessage('Tìm mã thành công', Colors.green);
        await _playBeep();
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          setState(() {
            _justSuccess = false;
          });
        });
        break;
      case ScanResult.invalidFormat:
         _playErrorSound();
        break;
      case ScanResult.notFound:
         _playErrorSound();
        break;
      case ScanResult.empty:
        break;
    }
  }
  /// Tự động refresh khi quay lại màn hình
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }
  /// Format thời gian hiển thị
  String formatTime(DateTime? time) {
    if (time == null) return '';
    final year = (time.year % 100).toString().padLeft(2,'0');
    return "$year/${time.month}/${time.day} ${time.hour}:${time.minute.toString().padLeft(2, '0')}";
  }
  //ham trung gian lay data tu logic sang UI
  Future<void> loadData(String id) async {
    final data = await logic.refreshList(id);
    if (data == null) return;
    final order = data['order'] as OrderModel;
    setState(() {
      final exists = allOrders.any((o) => o.id == order.id);

      if (!exists) {
        allOrders.insert(0, order);
        filteredList = List.from(allOrders);
      }
    });
  }

  Future<void> _scanToSearch() async {
    _isScanning = false;
    final scanController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal, // cau jinh quet normal: vua phai
      facing: CameraFacing.back, //su dung camnerasau
      returnImage: false, //chi lay ma, ko tra ve anh
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
                  if (_isScanning) return;
                  final code = capture.barcodes.first.rawValue?.trim() ?? '';
                  if (code.isEmpty) return;
                  _isScanning = true;

                  final keyword = code.toUpperCase();
                  final current = searchController.text.trim();
                  //ghep chuoi
                  final newValue = current.isEmpty ? keyword : "$current $keyword";

                  setState(() {
                    searchController.value = TextEditingValue(
                      text: newValue,
                      selection:
                      TextSelection.collapsed(offset: newValue.length),
                    );
                  });

                  Navigator.pop(ctx);
                  scanController.dispose();
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
            Container(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(), //appber
                  SizedBox(height: 20),
                  Row(
                  children: [
                    SizedBox(width: 20),
                    Text(
                      'Nhập mã đơn: ',
                      style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                    // const Spacer(),
                    SizedBox(width: 210),
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
                        controller: searchController,
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
                      const SizedBox(width: 40),//khoang cach giua cac nut
                      SizedBox(
                        width: 100,
                        height: 30,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white70,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            print("xem ok");
                            if (filteredList.isEmpty) return;
                            final order = filteredList.first;
                            showGeneralDialog(
                              context: context,
                              barrierDismissible: true,
                              barrierLabel: "",
                              barrierColor: Colors.black54,
                              transitionDuration: Duration.zero,
                              pageBuilder: (context, animation, secondaryAnimation) {
                                return Center(
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 400,
                                      maxHeight: 700, //  GIỚI HẠN CHIỀU CAO
                                    ),
                                    child: Dialog(
                                      backgroundColor: Colors.transparent,
                                      insetPadding: const EdgeInsets.all(20),
                                      child: Container(
                                        padding: const EdgeInsets.fromLTRB(10, 1, 10, 10),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(16),
                                        ),

                                        // Scroll
                                        child: SingleChildScrollView(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.stretch, //giãn theo chiều ngang
                                            children: [
                                          SizedBox(height: 50),
                                              //  BILL (có thể nhiều cái)
                                            ...filteredList.map((order) => Padding(
                                                 padding: const EdgeInsets.only(bottom: 10),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                          // bilL
                                                  Container(
                                                    padding: const EdgeInsets.all(3),
                                                    decoration: BoxDecoration(
                                                      color: Colors.black,
                                                      borderRadius: BorderRadius.circular(14),
                                                    ),
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                        child: BillScreen(order: order),
                                                      ),
                                                   ),
                                                      SizedBox(height: 10),
                                                      // mã đơn ở mõi bill
                                                      Padding(
                                                        padding: const EdgeInsets.only(left: 4, bottom: 4),
                                                        child: Text(
                                                          order.id,
                                                          style: const TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              //nut xem trong TO
                                              Container(
                                                child: Padding(
                                                  padding: const EdgeInsets.only(left: 4, bottom: 4),
                                                  child:  ElevatedButton(
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Colors.orange, // màu
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(10), // bo góc
                                                      ),
                                                    ),
                                                    onPressed: (){
                                                      // print("xem ok")
                                                     Navigator.pop(context);
                                                    },
                                                    child: Text(
                                                      "OK",
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        color: Colors.black,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    )
                                                ),
                                              )
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                          child: const Text(
                            "Xem",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),  //khoang cach giua cac nut
                      // SizedBox(
                      //   width: 100,
                      //   height: 30,
                      //   child: ElevatedButton(
                      //     style: ElevatedButton.styleFrom(
                      //       backgroundColor: Colors.white70, // màu
                      //       shape: RoundedRectangleBorder(
                      //         borderRadius: BorderRadius.circular(10), // bo góc
                      //       ),
                      //     ),
                      //     onPressed: () {
                      //       print("gaf!");
                      //     },
                      //     child: Text(
                      //       "In",
                      //       style: TextStyle(
                      //         fontSize: 16,
                      //         color: Colors.black,
                      //         fontWeight: FontWeight.bold,
                      //       ),
                      //     ),
                      //   ),
                      // ),
                      const SizedBox(width: 90),  //khoang cach giua cac nut
                      SizedBox(
                        width: 120,
                        height: 30,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange, // màu
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10), // bo góc
                            ),
                          ),
                          onPressed: _onManualInput,
                            child: Text(
                              "Confirm",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                           ),
                        )
                      ),
                    ]
                  ),
                ]
              ),
            ),
            const SizedBox(height: 20),
            _buildIn4Orders(),
          ]
        ),
      )
    );
  }
  Widget _buildHeader() {
    return Stack(
      children: [
        HeaderWidget(),
        _buildCenterMessageOverlay(),
      ],
    );
  }
//UI thanh thong tin
  Widget _buildIn4Orders(){
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
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
              5: const FixedColumnWidth(90,), //6status
              6: const FixedColumnWidth(120), // 7 time create
              7: const FixedColumnWidth(120), // 8time cpaked
              8: const FixedColumnWidth(140), // 8snender
              9: const FixedColumnWidth(140), // 9receive
            },
            children: [
              // Header row
              TableRow(
                decoration: BoxDecoration(color: Colors.orange[100]),
                children: const [
                  _Header('Mã Đơn'),
                  _Header('Nơi đi'),
                  _Header('Nơi đến'),
                  _Header('Sản Phẩm'),
                  _Header('KG'),
                  _Header('Status'),
                  _Header('Thời Gian Tạo'),
                  _Header('T/Gian Đóng'),
                  _Header('Người gửi'),
                  _Header('Người nhận'),
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
                      child: o.trangthai!.isEmpty || o.trangthai == null
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

                    _Cell(formatTime(o.thoigiantao)),
                    _Cell(o.thoigiandongbao != null
                        ? formatTime(o.thoigiandongbao!)
                        : '—'),
                    _Cell(o.nguoigui),
                    _Cell(o.nguoinhan),
                  ],
                );

              }
              ),
            ],
          ),
        ),
      ),
    );
  }
  //thonh bao cac trang thai
  Widget _buildCenterMessageOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: centerMessage == null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 250),
          opacity: centerMessage == null ? 0.0 : 1.0,
          child: Center(
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: (centerMessageColor ?? Colors.black87)
                    .withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                centerMessage ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

