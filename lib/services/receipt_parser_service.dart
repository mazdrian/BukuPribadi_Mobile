import '../models/transaction.dart';

/// Holds the parsed result from a receipt/payment note
class ParsedReceipt {
  final double? amount;
  final String? description;
  final DateTime? date;
  final String? categoryId;
  final TransactionType type;
  final String rawText;
  final List<ReceiptLineItem> lineItems;

  ParsedReceipt({
    this.amount,
    this.description,
    this.date,
    this.categoryId,
    this.type = TransactionType.expense,
    required this.rawText,
    this.lineItems = const [],
  });
}

/// Represents a single line item found on a receipt
class ReceiptLineItem {
  final String name;
  final double price;
  final int quantity;

  ReceiptLineItem({
    required this.name,
    required this.price,
    this.quantity = 1,
  });

  double get total => price * quantity;
}

/// Service to parse OCR text from receipts and extract transaction data
class ReceiptParserService {
  /// Main entry point: parse raw OCR text into structured receipt data
  ParsedReceipt parse(String rawText) {
    final lines = rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final amount = _extractTotalAmount(lines, rawText);
    final date = _extractDate(rawText);
    final lineItems = _extractLineItems(lines);
    final description = _extractDescription(lines, lineItems);
    final categoryId = _guessCategory(rawText, lineItems);

    return ParsedReceipt(
      amount: amount ??
          (lineItems.isNotEmpty
              ? lineItems.fold<double>(0, (sum, item) => sum + item.total)
              : null),
      description: description,
      date: date,
      categoryId: categoryId,
      type: TransactionType.expense,
      rawText: rawText,
      lineItems: lineItems,
    );
  }

  /// Extract the total/grand total amount from the receipt
  double? _extractTotalAmount(List<String> lines, String rawText) {
    // Priority patterns for total amount (check these first)
    final totalPatterns = [
      // Indonesian patterns
      RegExp(
          r'(?:grand\s*total|total\s*bayar|total\s*pembayaran|total\s*belanja|total\s*harga|jumlah\s*bayar|total\s*akhir|total\s*tagihan)\s*[:\.]?\s*[Rr][Pp]\.?\s*([\d.,]+)',
          caseSensitive: false),
      RegExp(
          r'(?:grand\s*total|total\s*bayar|total\s*pembayaran|total\s*belanja|total\s*harga|jumlah\s*bayar|total\s*akhir|total\s*tagihan)\s*[:\.]?\s*([\d.,]+)',
          caseSensitive: false),
      // English patterns
      RegExp(
          r'(?:grand\s*total|total\s*amount|total\s*due|amount\s*due|total\s*paid|net\s*total|balance\s*due)\s*[:\.]?\s*[\$£€]?\s*([\d.,]+)',
          caseSensitive: false),
      // Simple "TOTAL" at start of line
      RegExp(r'^total\s*[:\.]?\s*[Rr][Pp]\.?\s*([\d.,]+)',
          caseSensitive: false, multiLine: true),
      RegExp(r'^total\s*[:\.]?\s*[\$£€]?\s*([\d.,]+)',
          caseSensitive: false, multiLine: true),
    ];

    for (final pattern in totalPatterns) {
      final match = pattern.firstMatch(rawText);
      if (match != null) {
        final parsed = _parseNumber(match.group(1)!);
        if (parsed != null && parsed > 0) return parsed;
      }
    }

    // Fallback: find the largest number on a line containing price-like patterns
    double? largest;
    for (final line in lines) {
      final priceMatches = RegExp(
              r'[Rr][Pp]\.?\s*([\d.,]+)|\$([\d.,]+)|([\d]{1,3}(?:[.,]\d{3})+)')
          .allMatches(line);
      for (final m in priceMatches) {
        final numStr = m.group(1) ?? m.group(2) ?? m.group(3);
        if (numStr != null) {
          final parsed = _parseNumber(numStr);
          if (parsed != null &&
              parsed > 0 &&
              (largest == null || parsed > largest)) {
            largest = parsed;
          }
        }
      }
    }
    return largest;
  }

  /// Extract date from the receipt text
  DateTime? _extractDate(String rawText) {
    // Common date formats
    final datePatterns = [
      // DD/MM/YYYY or DD-MM-YYYY
      RegExp(r'(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{4})'),
      // YYYY/MM/DD or YYYY-MM-DD
      RegExp(r'(\d{4})[/\-.](\d{1,2})[/\-.](\d{1,2})'),
      // DD Mon YYYY (e.g., 07 Feb 2026, 7 Februari 2026)
      RegExp(
          r'(\d{1,2})\s+(Jan(?:uari)?|Feb(?:ruari)?|Mar(?:et)?|Apr(?:il)?|Me[iy]|Jun(?:i)?|Jul(?:i)?|A[gu](?:u?s(?:tus)?)?|Sep(?:tember)?|O[ck]t(?:ober)?|Nov(?:ember)?|De[cs](?:ember)?)\s+(\d{4})',
          caseSensitive: false),
    ];

    // DD/MM/YYYY or DD-MM-YYYY
    var match = datePatterns[0].firstMatch(rawText);
    if (match != null) {
      try {
        final day = int.parse(match.group(1)!);
        final month = int.parse(match.group(2)!);
        final year = int.parse(match.group(3)!);
        if (day >= 1 && day <= 31 && month >= 1 && month <= 12) {
          return DateTime(year, month, day);
        }
      } catch (_) {}
    }

    // YYYY-MM-DD
    match = datePatterns[1].firstMatch(rawText);
    if (match != null) {
      try {
        final year = int.parse(match.group(1)!);
        final month = int.parse(match.group(2)!);
        final day = int.parse(match.group(3)!);
        if (year > 2000 && day >= 1 && day <= 31 && month >= 1 && month <= 12) {
          return DateTime(year, month, day);
        }
      } catch (_) {}
    }

    // DD Mon YYYY
    match = datePatterns[2].firstMatch(rawText);
    if (match != null) {
      try {
        final day = int.parse(match.group(1)!);
        final monthStr = match.group(2)!.toLowerCase();
        final year = int.parse(match.group(3)!);
        final month = _parseMonth(monthStr);
        if (month != null && day >= 1 && day <= 31) {
          return DateTime(year, month, day);
        }
      } catch (_) {}
    }

    return null;
  }

  int? _parseMonth(String monthStr) {
    final m = monthStr.toLowerCase();
    if (m.startsWith('jan')) return 1;
    if (m.startsWith('feb')) return 2;
    if (m.startsWith('mar')) return 3;
    if (m.startsWith('apr')) return 4;
    if (m.startsWith('me')) return 5;
    if (m.startsWith('jun')) return 6;
    if (m.startsWith('jul')) return 7;
    if (m.startsWith('ag') || m.startsWith('au')) return 8;
    if (m.startsWith('sep')) return 9;
    if (m.startsWith('o')) return 10;
    if (m.startsWith('nov')) return 11;
    if (m.startsWith('de')) return 12;
    return null;
  }

  /// Extract individual line items (item name + price)
  List<ReceiptLineItem> _extractLineItems(List<String> lines) {
    final items = <ReceiptLineItem>[];

    // Skip lines that are clearly headers/totals
    final skipPatterns = RegExp(
      r'^(total|subtotal|sub\s*total|grand\s*total|tax|pajak|ppn|diskon|discount|tunai|cash|kembalian|change|debit|credit|kartu|card|no\.?|tanggal|date|waktu|time|kasir|cashier|struk|receipt|terima\s*kasih|thank)',
      caseSensitive: false,
    );

    for (final line in lines) {
      if (skipPatterns.hasMatch(line)) continue;

      // Pattern: "Item name    Rp 10.000" or "Item name    10,000" or "Item name    $10.00"
      final priceMatch =
          RegExp(r'^(.+?)\s{2,}[Rr][Pp]\.?\s*([\d.,]+)\s*$').firstMatch(line);
      if (priceMatch != null) {
        final name = priceMatch.group(1)!.trim();
        final price = _parseNumber(priceMatch.group(2)!);
        if (price != null && price > 0 && name.isNotEmpty && name.length > 1) {
          // Check for quantity pattern like "2x" or "x2" in the name
          final qtyMatch = RegExp(r'(\d+)\s*[xX×]\s*').firstMatch(name);
          final qty =
              qtyMatch != null ? int.tryParse(qtyMatch.group(1)!) ?? 1 : 1;
          final cleanName =
              name.replaceAll(RegExp(r'\d+\s*[xX×]\s*'), '').trim();
          items.add(ReceiptLineItem(
              name: cleanName.isEmpty ? name : cleanName,
              price: price,
              quantity: qty));
          continue;
        }
      }

      // Pattern: "Item name    10.000" (number at end, no currency symbol)
      final numEndMatch = RegExp(
              r'^(.{3,}?)\s{2,}([\d]{1,3}(?:[.,]\d{3})+(?:[.,]\d{1,2})?)\s*$')
          .firstMatch(line);
      if (numEndMatch != null) {
        final name = numEndMatch.group(1)!.trim();
        final price = _parseNumber(numEndMatch.group(2)!);
        if (price != null && price > 0 && !skipPatterns.hasMatch(name)) {
          items.add(ReceiptLineItem(name: name, price: price));
        }
      }
    }

    return items;
  }

  /// Build a description from the receipt
  String? _extractDescription(
      List<String> lines, List<ReceiptLineItem> lineItems) {
    if (lineItems.isNotEmpty) {
      // Use line item names as description
      if (lineItems.length == 1) {
        return lineItems.first.name;
      }
      final itemNames = lineItems.take(3).map((i) => i.name).join(', ');
      if (lineItems.length > 3) {
        return '$itemNames, +${lineItems.length - 3} more';
      }
      return itemNames;
    }

    // Try to find a store name or first meaningful line
    if (lines.isNotEmpty) {
      // First non-empty line is often the store name
      for (final line in lines.take(3)) {
        if (line.length > 2 &&
            line.length < 60 &&
            !RegExp(r'^\d+$').hasMatch(line)) {
          return 'Purchase at $line';
        }
      }
    }

    return null;
  }

  /// Guess the category based on keywords in the receipt
  String? _guessCategory(String rawText, List<ReceiptLineItem> lineItems) {
    final text = rawText.toLowerCase();
    final allText =
        '$text ${lineItems.map((i) => i.name.toLowerCase()).join(' ')}';

    // Category keyword mapping
    final categoryKeywords = <String, List<String>>{
      'food': [
        'restaurant',
        'restoran',
        'cafe',
        'kafe',
        'coffee',
        'kopi',
        'makan',
        'food',
        'makanan',
        'minuman',
        'drink',
        'bakery',
        'roti',
        'nasi',
        'ayam',
        'sate',
        'mie',
        'pizza',
        'burger',
        'sushi',
        'warung',
        'kantin',
        'catering',
        'snack',
        'dessert',
        'es krim',
        'ice cream',
        'beverages',
        'tea',
        'teh',
        'juice',
        'jus',
        'starbucks',
        'mcdonald',
        'kfc',
        'gofood',
        'grabfood',
      ],
      'transport': [
        'transport',
        'transportasi',
        'grab',
        'gojek',
        'uber',
        'taxi',
        'taksi',
        'bus',
        'kereta',
        'train',
        'mrt',
        'lrt',
        'transjakarta',
        'bensin',
        'fuel',
        'gas',
        'spbu',
        'pertamina',
        'shell',
        'parkir',
        'parking',
        'tol',
        'toll',
        'ojek',
        'ojol',
        'angkot',
      ],
      'shopping': [
        'shop',
        'toko',
        'store',
        'mall',
        'supermarket',
        'minimarket',
        'indomaret',
        'alfamart',
        'hypermart',
        'carrefour',
        'giant',
        'tokopedia',
        'shopee',
        'lazada',
        'bukalapak',
        'blibli',
        'fashion',
        'baju',
        'sepatu',
        'shoes',
        'clothes',
        'elektronik',
        'electronic',
        'gadget',
        'handphone',
        'laptop',
        'accessories',
      ],
      'entertainment': [
        'entertainment',
        'hiburan',
        'cinema',
        'bioskop',
        'movie',
        'film',
        'game',
        'spotify',
        'netflix',
        'youtube',
        'disney',
        'concert',
        'konser',
        'tiket',
        'ticket',
        'wisata',
        'travel',
        'hotel',
        'resort',
        'karaoke',
        'bowling',
        'arcade',
      ],
      'bills': [
        'bill',
        'tagihan',
        'listrik',
        'electric',
        'pln',
        'air',
        'pdam',
        'water',
        'internet',
        'wifi',
        'telkom',
        'indihome',
        'pulsa',
        'paket data',
        'telepon',
        'phone',
        'tv cable',
        'insurance',
        'asuransi',
        'sewa',
        'rent',
        'iuran',
        'cicilan',
        'installment',
      ],
      'health': [
        'health',
        'kesehatan',
        'apotek',
        'pharmacy',
        'obat',
        'medicine',
        'dokter',
        'doctor',
        'rumah sakit',
        'hospital',
        'klinik',
        'clinic',
        'lab',
        'vitamin',
        'supplement',
        'gym',
        'fitness',
      ],
      'education': [
        'education',
        'pendidikan',
        'sekolah',
        'school',
        'universitas',
        'university',
        'kampus',
        'campus',
        'buku',
        'book',
        'kursus',
        'course',
        'les',
        'tuition',
        'seminar',
        'workshop',
        'training',
        'pelatihan',
        'udemy',
        'coursera',
      ],
    };

    // Score each category
    int bestScore = 0;
    String? bestCategory;

    for (final entry in categoryKeywords.entries) {
      int score = 0;
      for (final keyword in entry.value) {
        if (allText.contains(keyword)) {
          score += keyword.length; // Longer keywords get higher score
        }
      }
      if (score > bestScore) {
        bestScore = score;
        bestCategory = entry.key;
      }
    }

    return bestCategory;
  }

  /// Parse a number string that could use either . or , as thousand/decimal separator
  double? _parseNumber(String text) {
    // Remove spaces
    var cleaned = text.replaceAll(' ', '');

    if (cleaned.isEmpty) return null;

    // Indonesian format: 10.000 or 10.000,00 (dot = thousands, comma = decimal)
    // US format: 10,000 or 10,000.00 (comma = thousands, dot = decimal)

    // If it has both . and , determine which is the decimal separator
    if (cleaned.contains('.') && cleaned.contains(',')) {
      // The last separator is the decimal one
      final lastDot = cleaned.lastIndexOf('.');
      final lastComma = cleaned.lastIndexOf(',');
      if (lastComma > lastDot) {
        // Indonesian: 10.000,50 → remove dots, replace comma with dot
        cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');
      } else {
        // US: 10,000.50 → remove commas
        cleaned = cleaned.replaceAll(',', '');
      }
    } else if (cleaned.contains(',')) {
      // Could be "10,000" (thousands) or "10,50" (decimal)
      final parts = cleaned.split(',');
      if (parts.length == 2 && parts[1].length == 3) {
        // Likely thousands separator: 10,000
        cleaned = cleaned.replaceAll(',', '');
      } else if (parts.length == 2 && parts[1].length <= 2) {
        // Likely decimal: 10,50
        cleaned = cleaned.replaceAll(',', '.');
      } else {
        // Multiple commas = thousands: 1,000,000
        cleaned = cleaned.replaceAll(',', '');
      }
    } else if (cleaned.contains('.')) {
      final parts = cleaned.split('.');
      if (parts.length > 2) {
        // Multiple dots = thousands separator: 1.000.000
        cleaned = cleaned.replaceAll('.', '');
      } else if (parts.length == 2 && parts[1].length == 3) {
        // Single dot with 3 digits after = thousands: 10.000
        cleaned = cleaned.replaceAll('.', '');
      }
      // else: single dot with 1-2 digits after = decimal: 10.50 (keep as is)
    }

    return double.tryParse(cleaned);
  }
}
