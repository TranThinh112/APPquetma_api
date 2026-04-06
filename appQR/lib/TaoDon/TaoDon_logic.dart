import 'dart:math';
import 'package:appqr1/models/Oders_model.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'TaoDonScreen.dart';
import 'package:diacritic/diacritic.dart';

class TaoDonLogic{

  // String madon
//random ma don
  String getMonthCode(int month) {
    if (month >= 1 && month <= 9) {
      return month.toString();// 01 → 09
    }

    switch (month) {
      case 10:
        return 'A';
      case 11:
        return 'B';
      case 12:
        return 'C';
      default:
        return '00';
    }
  }
  //ham random sau qua logic
  String randomMa() {
    final now = DateTime.now();
    int year = now.year;
    int yearCodeNum;

    if (year % 10 == 0) {
      // năm tròn chục
      yearCodeNum = year % 100;
    } else {
      // lấy số cuối rồi thêm 0 phía trước
      yearCodeNum = year % 10;
    }
    final yearCode = yearCodeNum.toString().padLeft(2, '0');
    final month = getMonthCode(now.month);
    const chars = '01234567890123456789';
    final rng = Random();

    final rand = String.fromCharCodes(
      Iterable.generate(8, (_) => chars.codeUnitAt(rng.nextInt(chars.length))),
    );

    final id = 'SPXVN$yearCode$rand$month';

    // print("ma Don: $id");
    return id;
  }
  /// 1. DATA: 63 tỉnh → vùng
 
  final Map<String, String> provinceToRegion = {
    // Đông Nam Bộ
    'ho chi minh': 'HCM',
    'binh duong': 'HCM',
    'dong nai': 'HCM',
    'ba ria vung tau': 'HCM',
    'tay ninh': 'HCM',
    'binh phuoc': 'HCM',

    // Miền Tây
    'can tho': 'CT',
    'an giang': 'CT',
    'kien giang': 'CT',
    'dong thap': 'CT',
    'ca mau': 'CT',
    'bac lieu': 'CT',
    'soc trang': 'CT',
    'vinh long': 'CT',
    'tra vinh': 'CT',
    'hau giang': 'CT',
    'tien giang': 'CT',
    'ben tre': 'CT',
    'long an': 'CT',

    // khu da nẵng
    'da nang': 'DN',
    'thua thien hue': 'DN',
    'quang nam': 'DN',
    'quang tri': 'DN',

    // Miền Trung
    'quang ngai': 'MT',
    'binh dinh': 'MT',
    'phu yen': 'MT',
    'khanh hoa': 'MT',
    'ninh thuan': 'MT',
    'binh thuan': 'MT',
    'quang binh': 'MT',
    'ha tinh': 'MT',
    'nghe an': 'MT',
    'thanh hoa': 'MT',
    'kon tum' : 'MT',
    'gia lai': 'MT',
    'dak lak': 'MT',
    'dak nong': 'MT',
    'lam dong': 'MT',

    // Miền Bắc
    'ha noi': 'HN',
    'hai phong': 'HN',
    'bac ninh': 'HN',
    'hai duong': 'HN',
    'hung yen': 'HN',
    'nam dinh': 'HN',
    'thai binh': 'HN',
    'ninh binh': 'HN',
    'vinh phuc': 'HN',
    'phu tho': 'HN',
    'thai nguyen': 'HN',
    'bac giang': 'HN',
    'lao cai': 'HN',
    'yen bai': 'HN',
    'tuyen quang': 'HN',
    'cao bang': 'HN',
    'lang son': 'HN',
    'son la': 'HN',
    'dien bien': 'HN',
    'lai chau': 'HN',
    'ha giang': 'HN',
    'bac kan': 'HN',
    'hoa binh': 'HN',
    'quang ninh': 'HN',
    'ha nam': "HN"
  };

 
  /// 2. ALIAS (viết tắt / TP)
 
  final Map<String, String> provinceAlias = {
    'hcm': 'ho chi minh',
    'sg': 'ho chi minh',
    'sai gon': 'ho chi minh',
    'bd' : 'binh duong',
    'pleiku': 'gia lai',
    'nha trang': 'khanh hoa',
    'pleiku': 'gia lai',
    'buon ma thuot': 'dak lak',
    'nghi son': 'thanh hoa',

    'hn': 'ha noi',

    'dn': 'da nang',

    'hue': 'thua thien hue',
    'vt': 'ba ria vung tau',
    'vung tau': 'ba ria vung tau',
    'ba ria': 'ba ria vung tau',
  };

 
  /// 3. NORMALIZE
 
  String normalize(String input) {
    return removeDiacritics(input.toLowerCase())
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .trim();
  }

 
  /// 4. APPLY ALIAS
 
  String applyAlias(String input) {
    return provinceAlias[input] ?? input;
  }

 
  /// 5. Kiểm tra độ dài để match đúng  (FUZZY)
  int levenshtein(String s1, String s2) {
    int m = s1.length, n = s2.length;
    List<List<int>> dp =
    List.generate(m + 1, (_) => List.filled(n + 1, 0));

    for (int i = 0; i <= m; i++) dp[i][0] = i;
    for (int j = 0; j <= n; j++) dp[0][j] = j;

    for (int i = 1; i <= m; i++) {
      for (int j = 1; j <= n; j++) {
        int cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        dp[i][j] = [
          dp[i - 1][j] + 1,
          dp[i][j - 1] + 1,
          dp[i - 1][j - 1] + cost
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return dp[m][n];
  }

 
  /// 6. EXTRACT PROVINCE
 
  String extractProvince(String address) {
    String temp = normalize(address);

    // 🔥 alias trước
    temp = applyAlias(temp);

    // ✅ contains (nhanh)
    for (String province in provinceToRegion.keys) {
      if (temp.contains(province)|| province.contains(temp)) {
        return province;
      }
    }

    // 🔥 fuzzy fallback
    int minDist = 999;
    String bestMatch = 'unknown';

    for (String province in provinceToRegion.keys) {
      int dist = levenshtein(temp, province);

      if (dist < minDist) {
        minDist = dist;
        bestMatch = province;
      }
    }

    return minDist <= 5 ? bestMatch : 'unknown';
  }

 
  /// 7. MAP REGION
 
  String mapRegion(String province) {
    return provinceToRegion[province] ?? 'unknown';
  }

 
  /// 8. FINAL FUNCTION
 
  String getRegionFromAddress(String address) {
    String province = extractProvince(address);
    return mapRegion(province);
  }



}