import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:barcode_widget/barcode_widget.dart';
import '../data/api_service.dart';
import '../QuanLy/QuanLyscreen.dart';
import '../models/Oders_model.dart';
import 'package:intl/intl.dart'; //format tiền, ngày giừo
import 'dart:ui' as ui; //xử lý ảnh
import 'dart:io'; //tạo, ghi file
import 'package:path_provider/path_provider.dart'; //Lấy đường dẫn lưu file trong máy
import 'package:share_plus/share_plus.dart'; //mở menu share, gửi file sang app khác
import 'package:flutter/rendering.dart';//Dùng cho: RenderRepaintBoundary để chụp
import 'dart:typed_data'; //xử lý dữ liệu nhị phân (binary)


//data co san ko update, luon co dinh
class BillScreen extends StatelessWidget {
  final OrderModel order;
  //format gia tien
  final formatter = NumberFormat('#,###', 'vi_VN');
  final GlobalKey _billKey = GlobalKey();
  BillScreen({super.key, required this.order});
//hàm share
  Future<void> shareBill() async {
    try {
      RenderRepaintBoundary boundary =
      _billKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      ui.Image image = await boundary.toImage(pixelRatio: 3);
      ByteData? byteData =
      await image.toByteData(format: ui.ImageByteFormat.png);

      final pngBytes = byteData!.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/bill.png');
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles([XFile(file.path)], text: "Bill SPX");
    } catch (e) {
      print("Lỗi share: $e");
    }
  }
  //format cho time
  String formatTime(DateTime time) {
    return "${time.day}-${time.month}-${time.year} "
        "${time.hour}:${time.minute.toString().padLeft(2, '0')}";
  }

  @override
  //cố định cho ext
  Widget _boldText(String text) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.bold),
    );
  }
  Widget build(BuildContext context) {
    const myDivider = Divider(
      thickness: 2,
      color: Colors.black,
    );
    const myVerticalDivider = VerticalDivider(
      thickness: 2,
        color: Colors.black,
    );
    double w = MediaQuery.of(context).size.width;
    return Material(
      color: Colors.transparent,
        child: Center(
          child: Container(
          constraints: const BoxConstraints(maxWidth: 300),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 10),
                // Barcode
                  Align(
                    alignment: Alignment.center,
                    child: BarcodeWidget(
                      barcode: Barcode.code128(),
                      data: order.id,
                      width: 250,
                      height: 70,
                      drawText: false,
                    ),
                  ),
                  const SizedBox(height: 10),
                   Center(
                     child: _boldText("Mã Vận Đơn: ${order.id}"),
                  ),
                  myDivider,

                   Center(
                    child:  _boldText("${order.noinhan}"),
                  ),

                  myDivider,
                  // IntrinsicHeight(
                   Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // BÊN TRÁI - Người gửi
                      Expanded(
                        child: _boldText( "Từ: ${order.nguoigui}\nĐịa chỉ: ${order.diachigui}")
                        ),

                        const SizedBox(width: 10),
                        // Nội dung
                        Container(
                          width: 2,
                          height: 120,
                          color: Colors.black,
                        ),
                        // myVerticalDivider,
                        const SizedBox(width: 10),

                        // BÊN PHẢI - Người nhận
                      Expanded(
                        child: _boldText("Đến: ${order.nguoinhan}\nĐịa chỉ: ${order.diachinhan}")
                      ),
                      ],
                    ),
                    myDivider,
                    // Noi dung, QR, Sort, Time
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// LEFT - Nội dung
                      Expanded(
                        flex: 2,
                        child: _boldText( "Nội dung: ${order.sanpham}")
                      ),

                      const SizedBox(width: 10),
                      Container(
                        width: 2,
                        height: 190,
                        color: Colors.black,
                      ),
                      // myVerticalDivider,
                      const SizedBox(width: 10),

                      /// RIGHT - QR
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            QrImageView(
                              data: order.id,
                              size: 100,
                            ),
                            const SizedBox(height: 5),
                            myDivider,
                            //noi gui
                            _boldText(order.noigui),
                            myDivider,
                            const Text(
                              "Ngày đặt:",
                              style: TextStyle(fontSize: 12),
                            ),
                            _boldText(formatTime(order.thoigiantao!)),
                          ],
                        ),
                      ),
                    ],
                  ),
            // Ngày
                myDivider,
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          _boldText("${formatter.format(order.giatien)} VND"),
                          //  GTC nếu > 3 triệu
                          SizedBox(width: 5),
                          if (order.giatien > 3000000) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                "GTC",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      width: 2,
                      height: 30,
                      color: Colors.black,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: _boldText(
                        "Khối lượng: ${order.soKi}kg",
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        ),
    );
  }//build
}