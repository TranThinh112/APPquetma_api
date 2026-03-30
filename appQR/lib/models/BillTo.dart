import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:barcode_widget/barcode_widget.dart';
import '../data/api_service.dart';
import '../QuanLy/QuanLyscreen.dart';
import '../models/to_model.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui; //xử lý ảnh
import 'dart:io'; //tạo, ghi file
import 'package:path_provider/path_provider.dart'; //Lấy đường dẫn lưu file trong máy
import 'package:share_plus/share_plus.dart'; //mở menu share, gửi file sang app khác
import 'package:flutter/rendering.dart';//Dùng cho: RenderRepaintBoundary để chụp
import 'dart:typed_data'; //xử lý dữ liệu nhị phân (binary)

class BillTO extends StatelessWidget {
  final TOModel TO;
  final GlobalKey _billKey = GlobalKey();
  BillTO({super.key, required this.TO});
  //ham sahr
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
  String formatTime(DateTime? time) {
    if(time ==null) return '-';
    return "${time.day}-${time.month}-${time.year} "
        "${time.hour}:${time.minute.toString().padLeft(2, '0')}";
  }
//co dinh kieu text
  @override
  Widget _boldText(String text) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.bold),
    );
  }
  Widget build(BuildContext context) {
    const myVerticalDivider = VerticalDivider(
      thickness: 2,
      color: Colors.black,
    );
    double w = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: shareBill,
          ),
        ],
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Center(
              child: Container(
                width: w * 0.9,// 90% chiều ngang
                //  width: double.infinity,
                padding: const EdgeInsets.fromLTRB(10,10,2,10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black,width: 2.0,style: BorderStyle.solid),
                ),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      // Barcode
                       BarcodeWidget(
                        barcode: Barcode.code128(),
                        data: TO.maTO,
                        width: 250,
                        height: 70,
                        drawText: false,
                      ),
                        SizedBox(height: 5),
                        _boldText("Mã TO: ${TO.maTO}"),
                        SizedBox(height: 5),
                        _boldText("Đến: ${TO.diaDiemGiaoHang}"),
                        SizedBox(height: 5),
                        _boldText("Packer: ${TO.packer}"),
                        SizedBox(height: 5),
                        _boldText("Số lượng: ${TO.soLuongDonHang}"),
                      SizedBox(height: 5),
                        _boldText("Số kí: ${TO.totalWeight}kg"),
                      SizedBox(height: 5),
                        _boldText( "Ngày tạo: ${formatTime(TO.ngayTao)}"),
                        SizedBox(height: 5),
                        _boldText( "Ngày Đóng: ${formatTime(TO.completeTime)}"),
                        ],
                      ),
                    ),
                      SizedBox(width: 10),
                      Container(
                        width: 2 ,
                        height: 240,
                        color: Colors.black,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 1,
                        child: Center(
                          child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(height: 20),
                            _boldText("Đến: ${TO.diaDiemGiaoHang}"),
                          SizedBox(height: 30),
                          QrImageView(
                            data: TO.maTO,
                            size: 100,
                            ),
                          ],
                        ),
                        ),
                      ),
                  ],
                ),
                ),
              ),
          ),
        ),
      );
  }
}