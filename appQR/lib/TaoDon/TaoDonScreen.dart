import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/to_model.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';


class TaoDonScreen extends StatefulWidget {
  const TaoDonScreen({super.key});

  @override
  State<TaoDonScreen> createState() => _TaoDonScreenState();
}
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
  @override
  Widget build(BuildContext context) {
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
                //nut quay lai
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
                    ]
                  ),
                ),
                //LOgo
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
              SizedBox( height: 50,),
              TextField(
                // controller: username,
                decoration: InputDecoration(
                  labelText: "Người gửi",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),
              SizedBox( height: 20,),
              TextField(
                // controller: username,
                decoration: InputDecoration(
                  labelText: "Thông tin, địa chỉ ",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.person_pin_circle ),
                ),
              ),
              SizedBox( height: 20,),
              TextField(
                // controller: username,
                decoration: InputDecoration(
                  labelText: "Người nhận",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),
              SizedBox( height: 20,),
              TextField(
                // controller: username,
                decoration: InputDecoration(
                  labelText: "Thông tin, địa chỉ",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.person_pin_circle ),
                ),
              ),
              SizedBox(height: 20),
              Row(
              children: [
                SizedBox(width: 20),
                  Align(
                    alignment: Alignment.centerLeft, // hoặc center
                    child: SizedBox(
                      width: 150,
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: "Khối lượng",
                          suffixText: "KG",
                          prefixIcon: const Icon(Icons.scale),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),

                          ),
                        ),
                      ),
                    ),
                  ),
                SizedBox(width: 50),
                Align(
                  alignment: Alignment.centerLeft, // hoặc center
                  child: SizedBox(
                    width: 150,
                    child: TextField(
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        CurrencyInputFormatter(), // 👈 thêm dòng này
                      ],
                      decoration: InputDecoration(
                        labelText: "Giá Tiền ",
                        suffixText: "VND",
                        prefixIcon: const Icon(Icons.money),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ),
          ],
              ),
              SizedBox(height: 20),
              SizedBox(
                      width: 150, // 👈 full ngang
                      height: 50,
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
          ],
        ),
      ),
    );
  }
}