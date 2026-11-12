import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Safe Indonesian Date Formatter that will never crash with LocaleDataException
class AppDateFormatter {
  static bool _initialized = false;

  static Future<void> ensureInitialized() async {
    if (_initialized) return;
    try {
      await initializeDateFormatting('id_ID', null);
      await initializeDateFormatting('id', null);
      _initialized = true;
    } catch (_) {
      // Fallback
    }
  }

  /// Convert a DateTime to local time zone if it is in UTC.
  static DateTime _toLocal(DateTime date) {
    return date.isUtc ? date.toLocal() : date;
  }

  /// Get Indonesian timezone abbreviation (WIB, WITA, WIT), defaulting to WIB.
  static String get localTimeZoneLabel {
    final offsetHours = DateTime.now().timeZoneOffset.inHours;
    if (offsetHours == 7) return 'WIB';
    if (offsetHours == 8) return 'WITA';
    if (offsetHours == 9) return 'WIT';
    return 'WIB';
  }

  /// Safely parse date strings from API (ISO UTC) or SQLite (UTC without Z)
  /// and convert to local device time.
  static DateTime parseDateTime(dynamic raw, {DateTime? fallback}) {
    if (raw == null) return fallback ?? DateTime.now();
    if (raw is DateTime) return raw.isUtc ? raw.toLocal() : raw;
    final str = raw.toString().trim();
    if (str.isEmpty) return fallback ?? DateTime.now();

    try {
      // If it's a date-only string like YYYY-MM-DD (e.g. incident_date)
      if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(str)) {
        return DateTime.tryParse(str) ?? (fallback ?? DateTime.now());
      }

      // Check if timezone indicator is already present (Z, z, or +/-HH:mm)
      final hasTimezone = str.endsWith('Z') ||
          str.endsWith('z') ||
          RegExp(r'[+-]\d{2}(:\d{2})?$').hasMatch(str);

      if (hasTimezone) {
        final dt = DateTime.tryParse(str);
        return dt != null ? dt.toLocal() : (fallback ?? DateTime.now());
      }

      // SQLite UTC timestamp without 'Z' (e.g. "2026-10-06 08:37:43" or "2026-10-06T08:37:43")
      // SQLite stores UTC by default. Append 'Z' to parse as UTC, then convert toLocal()
      final normalized = '${str.replaceAll(' ', 'T')}Z';
      final dtUtc = DateTime.tryParse(normalized);
      if (dtUtc != null) {
        return dtUtc.toLocal();
      }

      final dt = DateTime.tryParse(str);
      return dt != null ? dt.toLocal() : (fallback ?? DateTime.now());
    } catch (_) {
      return fallback ?? DateTime.now();
    }
  }

  /// Nullable version of parseDateTime
  static DateTime? tryParseDateTime(dynamic raw) {
    if (raw == null) return null;
    final str = raw.toString().trim();
    if (str.isEmpty) return null;
    return parseDateTime(raw);
  }

  /// Check if two dates fall on the exact same local calendar day
  static bool isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    final la = _toLocal(a);
    final lb = _toLocal(b);
    return la.year == lb.year && la.month == lb.month && la.day == lb.day;
  }

  /// Date divider pill label for chat (e.g. 'Hari Ini', 'Kemarin', '6 Oktober 2026')
  static String formatDatePill(DateTime? date) {
    if (date == null) return '';
    final d = _toLocal(date);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(d.year, d.month, d.day);
    final diffDays = today.difference(messageDate).inDays;

    if (diffDays == 0) return 'Hari Ini';
    if (diffDays == 1) return 'Kemarin';
    return format(d, pattern: 'd MMMM yyyy');
  }

  /// Chat list row timestamp (e.g. '15:37', 'Kemarin', 'Senin', '6 Okt 2026')
  static String formatChatListTime(DateTime? date) {
    if (date == null) return '--:--';
    final d = _toLocal(date);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(d.year, d.month, d.day);
    final diffDays = today.difference(messageDate).inDays;

    if (diffDays == 0) {
      return formatTime(d);
    } else if (diffDays == 1) {
      return 'Kemarin';
    } else if (diffDays < 7 && diffDays > 0) {
      const dayNames = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
      return dayNames[d.weekday - 1];
    } else {
      return formatShort(d);
    }
  }

  static String format(DateTime? date, {String pattern = 'dd MMM yyyy'}) {
    if (date == null) return '-';
    final d = _toLocal(date);
    try {
      return DateFormat(pattern, 'id_ID').format(d);
    } catch (_) {
      try {
        return DateFormat(pattern).format(d);
      } catch (_) {
        return '${d.day.toString().padLeft(2, '0')} ${_monthName(d.month)} ${d.year}';
      }
    }
  }

  static String formatShort(DateTime? date) {
    if (date == null) return '-';
    final d = _toLocal(date);
    try {
      return DateFormat('dd MMM yyyy', 'id_ID').format(d);
    } catch (_) {
      return '${d.day.toString().padLeft(2, '0')} ${_monthShort(d.month)} ${d.year}';
    }
  }

  static String formatDateTime(DateTime? date) {
    if (date == null) return '-';
    final d = _toLocal(date);
    try {
      return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(d);
    } catch (_) {
      return '${d.day.toString().padLeft(2, '0')} ${_monthShort(d.month)} ${d.year}, ${formatTime(d)}';
    }
  }

  static String formatTime(DateTime? date) {
    if (date == null) return '--:--';
    final d = _toLocal(date);
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static String formatDateTimeWib(DateTime? date) {
    if (date == null) return '-';
    final d = _toLocal(date);
    final dateStr = format(d, pattern: 'dd MMMM yyyy');
    final timeStr = formatTime(d);
    return '$dateStr\n$timeStr $localTimeZoneLabel';
  }

  static String formatDateTimeWibSingleLine(DateTime? date) {
    if (date == null) return '-';
    final d = _toLocal(date);
    final dateStr = format(d, pattern: 'dd MMMM yyyy');
    final timeStr = formatTime(d);
    return '$dateStr, $timeStr $localTimeZoneLabel';
  }

  static String formatRelative(DateTime? date) {
    if (date == null) return '-';
    final d = _toLocal(date);
    final diff = DateTime.now().difference(d);
    if (diff.isNegative) return 'Baru saja';
    if (diff.inSeconds < 60) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays == 1) return 'Kemarin';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return formatShort(d);
  }

  static String _monthName(int month) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    if (month >= 1 && month <= 12) return months[month - 1];
    return '';
  }

  static String _monthShort(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    if (month >= 1 && month <= 12) return months[month - 1];
    return '';
  }
}
