import 'package:intl/intl.dart';

/// Utility Functions
/// Helper functions for date formatting, calculations, and data manipulation

class Utils {
  /// Format date to Indonesian locale
  static String formatDate(DateTime date, {String format = 'medium'}) {
    try {
      switch (format) {
        case 'short':
          return DateFormat('dd/MM/yyyy').format(date);
        case 'long':
          return DateFormat('dd MMMM yyyy', 'id_ID').format(date);
        case 'medium':
        default:
          return DateFormat('dd MMM yyyy', 'id_ID').format(date);
      }
    } catch (e) {
      return '-';
    }
  }

  /// Calculate days remaining between two dates
  static int getDaysRemaining(DateTime endDate, [DateTime? startDate]) {
    final start = startDate ?? DateTime.now();
    final difference = endDate.difference(start);
    return difference.inDays;
  }

  /// Calculate duration between two dates in days
  static int getDuration(DateTime startDate, DateTime endDate) {
    final difference = endDate.difference(startDate);
    return difference.inDays;
  }

  /// Calculate progress percentage
  static int calculateProgress(
    DateTime startDate,
    DateTime endDate, [
    DateTime? currentDate,
  ]) {
    final current = currentDate ?? DateTime.now();

    final totalDuration = endDate.difference(startDate).inMilliseconds;
    final elapsed = current.difference(startDate).inMilliseconds;

    if (totalDuration == 0) return 0;

    final progress = (elapsed / totalDuration * 100).round();
    return progress.clamp(0, 100);
  }

  /// Check if date is in the past
  static bool isPastDate(DateTime date) {
    return date.isBefore(DateTime.now());
  }

  /// Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Get relative time string (e.g., "2 days ago", "in 5 days")
  static String getRelativeTime(DateTime date) {
    final diffDays = getDaysRemaining(date);

    if (diffDays == 0) return 'Hari ini';
    if (diffDays == 1) return 'Besok';
    if (diffDays == -1) return 'Kemarin';
    if (diffDays > 0) return '$diffDays hari lagi';
    return '${diffDays.abs()} hari yang lalu';
  }

  /// Generate unique ID
  static String generateId() {
    return '${DateTime.now().millisecondsSinceEpoch}-${_generateRandomString(9)}';
  }

  static String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    return List.generate(
        length, (index) => chars[(random + index) % chars.length]).join();
  }

  /// Validate email format
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return emailRegex.hasMatch(email);
  }

  /// Validate phone number format (Indonesian)
  static bool isValidPhone(String phone) {
    final phoneRegex = RegExp(r'^(\+62|62|0)[0-9]{9,12}$');
    return phoneRegex.hasMatch(phone.replaceAll(RegExp(r'\s'), ''));
  }

  /// Truncate text to specified length
  static String truncateText(String text, [int maxLength = 50]) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  /// Capitalize first letter of string
  static String capitalizeFirst(String str) {
    if (str.isEmpty) return '';
    return str[0].toUpperCase() + str.substring(1);
  }

  /// Sort list by date field
  static List<T> sortByDate<T>(
    List<T> list,
    DateTime Function(T) getDate, {
    bool ascending = false,
  }) {
    final sorted = List<T>.from(list);
    sorted.sort((a, b) {
      final comparison = getDate(a).compareTo(getDate(b));
      return ascending ? comparison : -comparison;
    });
    return sorted;
  }

  /// Group list by field
  static Map<K, List<T>> groupBy<T, K>(
    List<T> list,
    K Function(T) keyFunction,
  ) {
    final map = <K, List<T>>{};
    for (final item in list) {
      final key = keyFunction(item);
      map.putIfAbsent(key, () => []).add(item);
    }
    return map;
  }

  /// Parse date from string (YYYY-MM-DD format)
  static DateTime? parseDate(String dateString) {
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  /// Format date to string (YYYY-MM-DD format)
  static String dateToString(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }
}
