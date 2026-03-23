import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:barcode_widget/barcode_widget.dart';
import '../data/api_service.dart';
import '../QuanLy/QuanLyscreen.dart';

class BillScreen extends StatelessWidget {
  final OrderModel order;
  const BillScreen({super.key, required this.order});

  //format cho time
  String formatTime(DateTime time) {
    return "${time.day}-${time.month}-${time.year} "
        "${time.hour}:${time.minute.toString().padLeft(2, '0')}";
  }
  @override
  Widget build(BuildContext context) {
    const myDivider = Divider(
      thickness: 1,
      color: Colors.black,
    );
    const myVerticalDivider = VerticalDivider(
      thickness: 1,
        color: Colors.black,
    );
    double w = MediaQuery.of(context).size.width;
    // double h = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: Center(
      child: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 500,),
             child: Container(
               // height: h * 0.6,  // 60% chiều dọc
              width: w * 0.9,   // 90% chiều ngang
              //  width: double.infinity,
              padding: const EdgeInsets.fromLTRB(10,10,2,10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black,width: 2.0,style: BorderStyle.solid),
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                // Barcode
                  Center(
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
                    child: Text(
                      "Mã vận đơn: ${order.id}",
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  myDivider,
                  // Mã tuyế

                   Center(
                    child:  Text(
                      "${order.noinhan}",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),

                  myDivider,
                  // IntrinsicHeight(
                   Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // BÊN TRÁI - Người gửi
                      Expanded(
                        child: Text(
                              "Từ: ${order.noigui}\nĐịa chỉ: ...",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                        ),

                        const SizedBox(width: 10),
                        // Nội dung
                        Container(
                          width: 1,
                          height: 50, // 👈 set tay (đơn giản + ổn định)
                          color: Colors.black,
                        ),
                        myVerticalDivider,
                        const SizedBox(width: 10),

                        // BÊN PHẢI - Người nhận
                      Expanded(
                        child: Text(
                          "Đến: ${order.noinhan}\nĐịa chỉ: ...",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
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
                        child: Text(
                          "Nội dung: ${order.sanpham}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),

                      const SizedBox(width: 10),

                      Container(
                        width: 1,
                        height: 150,
                        color: Colors.black,
                      ),

                      myVerticalDivider,
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
                            Text(
                              order.noigui,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            myDivider,
                            const Text(
                              "Ngày đặt:",
                              style: TextStyle(fontSize: 10),
                            ),
                            Text(
                              formatTime(order.thoigiantao),
                              style: const TextStyle(fontSize: 12),
                            ),
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
                      child: Text(
                        "92.400 VND",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 30, // 👈 set tay (đơn giản + ổn định)
                      color: Colors.black,
                    ),
                    myVerticalDivider,
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: Text(
                        "Khoi luong: ${order.soKg}kg",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
              ),
        ),
            ),
          ),
        ),
      ),
    );
  }
}