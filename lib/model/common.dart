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
  text = text.replaceAll('-', '/');
  var now = DateTime.now();
  var ymd = DateFormat('yyyy/MM/dd');

  int? minutes, hours, days, dayDiff;
  String? duration, datetime;
  if (text.contains('分钟前')) {
    minutes = int.tryParse(text.substring(0, text.length - 3));
    if (minutes != null) {
      duration = minutes == 0 ? '不到1分钟前' : '$minutes分钟前';
      dayDiff = 0;
    }
  } else if (text.contains('小时前')) {
    hours = int.tryParse(text.substring(0, text.length - 3));
    if (hours != null) {
      duration = '$hours小时前';
      var now = DateTime.now();
      dayDiff = hours <= now.hour ? 0 : 1;
    }
  } else if (text.contains('天前')) {
    days = int.tryParse(text.substring(0, text.length - 2));
    if (days != null && days <= 7) {
      duration = days == 0 ? '今天' : '$days天前';
      dayDiff = days;
    }
  } else {
    try {
      var parsed = ymd.parse(text);
      var du = now.difference(parsed);
      if (du.inDays <= 7) {
        days = du.inDays;
        duration = days == 0 ? '今天' : '$days天前';
        dayDiff = days;
        datetime = text;
      }
    } catch (_) {}
  }

  if (duration == null) {
    return ParseResult(date: text, duration: null, dayDiff: null); // "2023/02/02"
  }
  if (datetime == null) {
    var old = now.subtract(Duration(minutes: minutes ?? 0, hours: hours ?? 0, days: days ?? 0));
    datetime = ymd.format(old);
  }
  return ParseResult(date: datetime, duration: duration, dayDiff: dayDiff); // "2023/02/02", "今天" or "xxx天前"
}

// =====================================
// datetime & pattern => datetime string
// =====================================

enum FormatPattern {
  dateNoYear, // "02/02"
  date, // "2023/02/02"
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
      return md.format(datetime); // "2023/02/02"
    case FormatPattern.date:
      return ymd.format(datetime); // "2023/02/02"
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
