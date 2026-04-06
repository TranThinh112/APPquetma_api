

import 'package:appqr1/models/Oders_model.dart';
import 'package:appqr1/models/appbar_logo.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/to_model.dart';
import '../TaoDon/TaoDon_logic.dart';
import '../models/appbar_logo.dart';
import '../TaoDon/TaoDon_logic.dart';
import '../data/api_service.dart';
import '../models/Oders_model.dart';
import 'package:audioplayers/audioplayers.dart';


class TaoDonScreen extends StatefulWidget {
  const TaoDonScreen({super.key});

  @override
  State<TaoDonScreen> createState() => _TaoDonScreenState();
}
// ko cho usser nhap vao chu, tu nhay 0 khi nhap .6 cho khoi luong
class DecimalFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    String text = newValue.text;

    // nếu nhập bắt đầu bằng "."
    if (text.startsWith('.')) {
      text = '0$text';
    }

    // chỉ cho số + 1 dấu .
    if (!RegExp(r'^\d*\.?\d*$').hasMatch(text)) {
      return oldValue;
    }

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
//format gia tien
class CurrencyInputFormatter extends TextInputFormatter {
  final NumberFormat formatter = NumberFormat.decimalPattern('vi');

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    if (newValue.text.isEmpty) return newValue;

    // bỏ hết ký tự không phải số
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // parse an toàn
    int value = int.tryParse(newText) ?? 0;
    // format
    String formatted = formatter.format(value);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
class _TaoDonScreenState extends State<TaoDonScreen> {
  final AudioPlayer player = AudioPlayer();
   String maDon = "";
   final  sender = TextEditingController();
   final  in4sender = TextEditingController();
   final  receiver = TextEditingController();
   final  in4receiver = TextEditingController();
   final  nameproduct = TextEditingController();
   final  weight = TextEditingController();
   final  price = TextEditingController();
   String KhuVucGui = "";
   String KhuVucNhan= "";
   final _formkey = GlobalKey<FormState>();


   final Map<String, TextEditingController> controllers = {
     "sender": TextEditingController(),
     "in4sender": TextEditingController(),
     "receiver": TextEditingController(),
     "in4receiver": TextEditingController(),
     "nameproduct": TextEditingController(),
     "weight": TextEditingController(),
     "price": TextEditingController(),
   };
//dispose: xoa tai nguyen khi dung xong
   @override
   void dispose() {
     controllers.forEach((key, controller) => controller.dispose());
     super.dispose();
   }
  @override
  void initState() {
    super.initState();
    maDon = TaoDonLogic().randomMa(); //  lấy từ logic
  }
  Future<void> _playBeep() async {
    try {
      await player.stop();
      await player.play(AssetSource('beep.mp3'));
    } catch (_) {}
  }
  Future<void> _playErrorSound() async {
    try {
      await player.stop();
      await player.play(AssetSource('error.mp3'));
    } catch (_) {}
  }
  void input() async{
     final logic = TaoDonLogic();
     //xoa dau cham

     String MVD = maDon;
    String NG = sender.text;
    String TTNG = in4sender.text;
    String NN = receiver.text;
    String TTNN = in4receiver.text;
    String SP = nameproduct.text;
    String KG = weight.text;
    String Gia = price.text;
     if(!_formkey.currentState!.validate ()){
       return;
     }
     //xu ly gia tien
     int giaTien = int.tryParse(
         price.text.replaceAll('.', '')
     ) ?? 0;
     //maping du lieu
     String KhuVucGui = logic.getRegionFromAddress(TTNG);
     String KhuVucNhan = logic.getRegionFromAddress(TTNN);
     //tao model gui len
     OrderModel order = OrderModel(
       id: maDon,
       noigui: KhuVucGui,
       noinhan: KhuVucNhan,
       sanpham: nameproduct.text,
       soKi: double.tryParse(weight.text) ?? 0,
       nguoigui: sender.text,
       nguoinhan: receiver.text,
       diachigui: in4sender.text,
       diachinhan: in4receiver.text,
       giatien: giaTien,
     );
     print(order.toJson());
     bool success = await ApiService.createOrder(order);

     if (success) {
       print("Gửi thành công 🚀");
       _playBeep();
     } else {
       print("Lỗi ❌");
       _playErrorSound();
     }

  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SingleChildScrollView(
          child: Column(
            children: [
              HeaderWidget(),
                  SizedBox(width: 10,),
                  Padding(
                      padding:  const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
                      child: Form(
                        key: _formkey,
                          child: Column(
                            children: [
                              Align(
                                alignment: Alignment.center,
                                child: SizedBox(
                                  width: 360,
                                  child: Text("Mã vận đơn: $maDon",
                                    style: TextStyle(fontSize: 15,color: Colors.black, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              SizedBox(height: 10),
                               TextFormField(
                                    controller: sender,
                                    decoration: InputDecoration(
                                      labelText: "Người gửi",
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                      //giamr chieu cao chu loi
                                      errorStyle: TextStyle(height: 0.8),
                                        helperText: "",
                                      prefixIcon: const Icon(Icons.person_outline),
                                    ),
                                    validator: (value){
                                      if( value == null || value.trim().isEmpty){
                                        return "Người gửi không để trống";
                                      }
                                      return null;
                                    }
                                  ),
                              // SizedBox(height: 10),
                             TextFormField(
                                    controller: in4sender,
                                    decoration: InputDecoration(
                                      labelText: "Thông tin, địa chỉ ",
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                      errorStyle: TextStyle(height: 0.8),
                                      helperText: "",
                                      prefixIcon: const Icon(Icons.person_pin_circle ),
                                    ),
                               validator: (value){
                                      if( value == null || value.trim().isEmpty){
                                        return "Vui lòng nhập thông tin";
                                      }
                                      return null;
                                    }
                                  ),
                              // SizedBox(height: 10),
                              TextFormField(
                                    controller: receiver,
                                    decoration: InputDecoration(
                                      labelText: "Người nhận",
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                      errorStyle: TextStyle(height: 0.8),
                                      helperText: "",
                                      prefixIcon: const Icon(Icons.person_outline),
                                    ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty){
                                    return "Người nhận không để trống";
                                  }
                                  return null;
                                }
                                  ),
                              // SizedBox(height: 10),
                              TextFormField(
                                    controller: in4receiver,
                                    decoration: InputDecoration(
                                      labelText: "Thông tin, địa chỉ ",
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                      errorStyle: TextStyle(height: 0.8),
                                      helperText: "",
                                      prefixIcon: const Icon(Icons.person_pin_circle ),
                                    ),
                                      validator: (value){
                                      if( value == null || value.trim().isEmpty){
                                        return "Vui lòng nhập thông tin";
                                      }
                                      return null;
                                    }
                                  ),
                              // SizedBox(height: 10),
                              TextFormField(
                                    controller: nameproduct,
                                    decoration: InputDecoration(
                                      labelText: "Thông tin sản phẩm ",
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                      errorStyle: TextStyle(height: 0.8),
                                      helperText: "",
                                      prefixIcon: const Icon(Icons.production_quantity_limits_rounded ),
                                    ),
                                    validator: (value){
                                      if( value == null || value.trim().isEmpty){
                                        return "Vui lòng nhập tên sản phẩm";
                                      }
                                      return null;
                                    }
                                  ),
                          // SizedBox(height: 10),
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SizedBox(
                                  width: 160,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                    TextFormField(
                                    controller: weight,
                                        // TextInputType.numberWithOptions(decimal: true), chi cho nhap so
                                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                                    inputFormatters: [
                                      //chan du lieu: ^: bat dau chuoi, \d* 0 or nhieu so, \d.?: co the co 1 dau . , \d*: 0 or nhieu so phia sau
                                      DecimalFormatter(),
                                    ],
                                    decoration: InputDecoration(
                                      labelText: "Khối lượng",
                                      suffixText: "KG",
                                      prefixIcon: const Icon(Icons.scale),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10)),
                                      errorStyle: TextStyle(height: 0.8),
                                      helperText: "",
                                      isDense: true,
                                      // contentPadding: EdgeInsets.symmetric(vertical: 10),
                                    ),
                                    validator: (value){
                                      if( value == null || value.trim().isEmpty){
                                        return "Khối luượng ko trống";
                                      }
                                      return null;
                                    }
                                  ),
                                  ]
                                  ),
                                ),
                                SizedBox(width: 4),
                                SizedBox(
                                width: 160,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TextFormField(
                                    controller: price,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      CurrencyInputFormatter(),
                                    ],
                                    decoration: InputDecoration(
                                    labelText: "Giá Tiền ",
                                    suffixText: "VND",
                                    prefixIcon: const Icon(Icons.money),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                      errorStyle: TextStyle(height: 0.8),
                                      helperText: "",
                                      isDense: true,
                                      // contentPadding: EdgeInsets.symmetric(vertical: 10),
                                    ),
                                    validator: (value){
                                      if(value == null || value.trim().isEmpty){
                                        return "Giá tiền ko trống";
                                      }
                                      return null;
                                      }
                                    )
                                  ],
                                ),
                              ),
                            ]
                        ),
                        SizedBox(height: 10),
                        SizedBox(
                          width: 150,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange[400], // màu
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10), // bo góc
                              ),
                            ),
                            onPressed: input,
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
                      ),
                  ),
          ]
          ),
      )
    );
  }
}