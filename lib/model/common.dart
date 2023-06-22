import 'package:intl/intl.dart';

// ====================================================
// duration / date string => new date & duration string
// ====================================================

class ParseResult {
  const ParseResult({
    required this.date,
    required this.duration,
    required this.dayDiff,
  });

  final String date;
  final String? duration;
  final int? dayDiff;
}

ParseResult parseDurationOrDateString(String text) {
  text = text.replaceAll('-', '/').trim();
  var now = DateTime.now();
  var ymd = DateFormat('yyyy/MM/dd');

  int? minutes, hours, days, dayDiff;
  String? duration; // duration text or null
  if (text.contains('分钟前')) /* X分钟前 */ {
    minutes = int.tryParse(text.substring(0, text.length - 3)) ?? 0;
    dayDiff = 0;
    duration = minutes == 0 ? '不到1分钟前' : '$minutes分钟前';
  } else if (text.contains('小时前')) /* X小时前 */ {
    hours = int.tryParse(text.substring(0, text.length - 3)) ?? 0;
    dayDiff = hours <= now.hour ? 0 : 1;
    duration = '$hours小时前';
  } else if (text.contains('天前')) /* X天前 */ {
    days = int.tryParse(text.substring(0, text.length - 2)) ?? 0;
    dayDiff = days;
    duration = days == 0 ? '今天' : (days <= 7 ? '$days天前' : null);
  } else /* 2023/02/02 */ {
    try {
      days = now.difference(ymd.parse(text)).inDays;
      dayDiff = days;
      duration = days == 0 ? '今天' : (days <= 7 ? '$days天前' : null);
    } catch (_) /* unexpected text format */ {
      days = null;
      dayDiff = null; // null dayDiff => error
      duration = null;
    }
  }

  if (dayDiff == null) {
    return ParseResult(date: text, duration: null, dayDiff: null); // error, keep original text
  }
  var dateObj = now.subtract(Duration(minutes: minutes ?? 0, hours: hours ?? 0, days: days ?? 0));
  return ParseResult(
    date: ymd.format(dateObj), // "2023/02/02"
    duration: duration, // "x分钟前" or "x小时前" or "今天" or "x天前" or null
    dayDiff: dayDiff, // day difference from today, must be not null here
  );
}

// =====================================
// datetime & pattern => datetime string
// =====================================

enum FormatPattern {
  dateNoYear, // "02/02"
  date, // "2023/02/02"
  barredDate, // "2023-02-02"
  datetimeNoSec, // "2023/02/02 17:53"
  datetime, // "2023/02/02 17:53:15"
  duration, // "xxx前"
  durationOnlyDate, // "今天" or "xxx天前"
  dateDuration, // "2023/02/02 (xxx前)"
  datetimeDuration, // "2023/02/02 17:53:15 (xxx前)"
  durationDate, // "xxx前 (2023/02/02)"
  durationDatetime, // "xxx前 (2023/02/02 17:53:15)"
  durationOrDate, // "xxx前" or "2023/02/02"
  durationOrDatetime, // "xxx前" or "2023/02/02 17:53:15"
  durationDatetimeOrDateTime, // "xxx前 (17:53:15)" or "xxx前 (02/02 17:53:15)" or "2023/02/02 17:53:15"
}

String formatDatetimeAndDuration(DateTime datetime, FormatPattern pattern) {
  var md = DateFormat('MM/dd');
  var ymd = DateFormat('yyyy/MM/dd');
  var ymd2 = DateFormat('yyyy-MM-dd');
  var hms = DateFormat('HH:mm:ss');
  var mdhms = DateFormat('MM/dd HH:mm:ss');
  var ymdhm = DateFormat('yyyy/MM/dd HH:mm');
  var ymdhms = DateFormat('yyyy/MM/dd HH:mm:ss');

  String formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}天前';
    }
    if (duration.inHours > 0) {
      return '${duration.inHours}小时前';
    }
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes}分钟前';
    }
    return '不到1分钟前';
  }

  switch (pattern) {
    case FormatPattern.dateNoYear:
      return md.format(datetime); // "02/02"
    case FormatPattern.date:
      return ymd.format(datetime); // "2023/02/02"
    case FormatPattern.barredDate:
      return ymd2.format(datetime); // "2023-02-02"
    case FormatPattern.datetimeNoSec:
      return ymdhm.format(datetime); // "2023/02/02 17:53"
    case FormatPattern.datetime:
      return ymdhms.format(datetime); // "2023/02/02 17:53:15"

    case FormatPattern.duration:
      var duration = DateTime.now().difference(datetime);
      return formatDuration(duration); // "xxx前"
    case FormatPattern.durationOnlyDate:
      var now = DateTime.now();
      now = DateTime(now.year, now.month, now.day);
      var old = DateTime(datetime.year, datetime.month, datetime.day);
      var duration = now.difference(old);
      return duration.inDays == 0 ? '今天' : '${duration.inDays}天前'; // "今天" or "xxx天前"

    case FormatPattern.dateDuration:
      var duration = DateTime.now().difference(datetime);
      return '${ymd.format(datetime)} (${formatDuration(duration)})'; // "2023/02/02 (xxx前)"
    case FormatPattern.datetimeDuration:
      var duration = DateTime.now().difference(datetime);
      return '${ymdhms.format(datetime)} (${formatDuration(duration)})'; // "2023/02/02 17:53:15 (xxx前)"

    case FormatPattern.durationDate:
      var duration = DateTime.now().difference(datetime);
      return '${formatDuration(duration)} ${ymd.format(datetime)}'; // "xxx前 (2023/02/02)"
    case FormatPattern.durationDatetime:
      var duration = DateTime.now().difference(datetime);
      return '${formatDuration(duration)} ${ymdhms.format(datetime)}'; // "xxx前 (2023/02/02 17:53:15)"

    case FormatPattern.durationOrDate:
      var duration = DateTime.now().difference(datetime);
      return duration.inDays <= 7 ? formatDuration(duration) : ymd.format(datetime); // "xxx前" or "2023/02/02"
    case FormatPattern.durationOrDatetime:
      var duration = DateTime.now().difference(datetime);
      return duration.inDays <= 7 ? formatDuration(duration) : ymdhms.format(datetime); // "xxx前" or "2023/02/02 17:53:15"

    case FormatPattern.durationDatetimeOrDateTime:
      var now = DateTime.now();
      var duration = now.difference(datetime);
      if (duration.inDays > 7) {
        return ymdhms.format(datetime); // "2023/02/02 17:53:15"
      }
      if (now.day != datetime.day) {
        return '${formatDuration(duration)} (${mdhms.format(datetime)})'; // "xxx前 (02/02 17:53:15)"
      }
      return '${formatDuration(duration)} (${hms.format(datetime)})'; // "xxx前 (17:53:15)"
  }
}

// ===========
// other utils
// ===========

extension StringExtension on String {
  bool checkEqualityConsideringLastSlash(String o) {
    var a = this;
    if (a.endsWith('/')) {
      a = a.substring(0, a.length - 1);
    }
    if (o.endsWith('/')) {
      o = o.substring(0, o.length - 1);
    }
    return a == o;
  }
}
