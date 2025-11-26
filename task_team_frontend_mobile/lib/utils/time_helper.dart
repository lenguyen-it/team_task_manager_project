import 'package:intl/intl.dart';

class TimeUtils {
  /// Chuyển DateTime sang giờ Việt Nam (UTC+7) an toàn
  static DateTime toVietnamTime(DateTime? dateTime) {
    if (dateTime == null) return DateTime.now();
    return dateTime.isUtc ? dateTime.toLocal() : dateTime;
  }

  /// Format giờ tin nhắn: 'HH:mm'
  static String formatMessageTime(DateTime? dateTime) {
    final dt = toVietnamTime(dateTime);
    return DateFormat('HH:mm', 'vi_VN').format(dt);
  }

  /// Format cho DateDivider: "Hôm nay", "Hôm qua", "Thứ Hai", "dd/MM/yyyy"
  static String formatDateDivider(DateTime? dateTime) {
    final dt = toVietnamTime(dateTime);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final inputDate = DateTime(dt.year, dt.month, dt.day);

    if (inputDate == today) return 'Hôm nay';
    if (inputDate == yesterday) return 'Hôm qua';
    if (now.difference(dt).inDays < 7) {
      return DateFormat('EEEE', 'vi_VN').format(dt); // Thứ Hai, Thứ Ba...
    }
    return DateFormat('dd/MM/yyyy', 'vi_VN').format(dt);
  }
}
