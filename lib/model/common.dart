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

  String get durationDate {
    if (duration == null) {
      return date; // 2023/02/02
    }
    return '$duration ($date)'; // xxx前 (2023/02/02)
  }
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

String parseDatetimeStringAndTrimSecond(String text) {
  text = text.replaceAll('-', '/').trim();
  var ymdhms = DateFormat('yyyy/MM/dd HH:mm:ss');
  var ymdhm = DateFormat('yyyy/MM/dd HH:mm');
  try {
    var datetime = ymdhms.parse(text);
    return ymdhm.format(datetime); // 2023/02/02 17:53
  } catch (_) /* unexpected text format */ {
    return text;
  }
}

// =====================================
// datetime & pattern => datetime string
// =====================================

enum FormatPattern {
  //
  dateNoYr, // "02/02" <<< 特殊: 用于推荐页受众排行榜
  date, // "2023/02/02" <<< 特殊: 用于推荐页每日排行榜、受众排行榜页栏、签到提醒、稍后阅读时间检索栏
  barredDate, // "2023-02-02"
  //
  datetimeNoYrNoSec, // "02/02 17:53"
  datetimeNoSec, // "2023/02/02 17:53" <<< **用于正常显示时间** (漫画阅读历史弹出菜单、书架缓存记录行、漫画稍后阅读栏、应用信息行和对话框、漫画收藏管理行、漫画收藏分组管理行、漫画评论行)
  datetime, // "2023/02/02 17:53:15" <<< 特殊: 用于我的页、新发布的评论
  //
  duration, // "xxx前"
  durationOnlyDate, // "今天" or "xxx天前" <<< 特殊: 用于我的页
  //
  dateDuration, // "2023/02/02 (xxx前)"
  datetimeNoYrNoSecDuration, // "02/02 17:53 (xxx前)"
  datetimeNoSecDuration, // "2023/02/02 17:53 (xxx前)" <<< **用于详细显示时间** (漫画阅读历史栏、漫画稍后阅读弹出菜单、章节下载数据栏的时间)
  datetimeDuration, // "2023/02/02 17:53:15 (xxx前)"
  //
  durationDate, // "xxx前 (2023/02/02)"
  durationDatetimeNoYrNoSec, // "xxx前 (02/02 17:53)"
  durationDatetimeNoSec, // "xxx前 (2023/02/02 17:53)"
  durationDatetime, // "xxx前 (2023/02/02 17:53:15)"
  //
  durationOrDate, // "xxx前" or "2023/02/02" <<< **用于简短显示日期** (其他行的漫画阅读历史的日期)
  durationOrDatetimeNoYrNoSec, // "xxx前" or "02/02 17:53"
  durationOrDatetimeNoSec, // "xxx前" or "2023/02/02 17:53"
  durationOrDatetime, // "xxx前" or "2023/02/02 17:53:15"
  //
  durationOneDayOrDate, // "xxx小时前" or "xxx分钟前" or "2023/02/02"
  durationOneDayOrDatetimeNoYrNoSec, // "xxx小时前" or "xxx分钟前" or "02/02 17:53" <<< **用于简短显示时间** (漫画历史页的章节阅读历史的时间)
  durationOneDayOrDatetimeNoSec, // "xxx小时前" or "xxx分钟前" or "2023/02/02 17:53"
  durationOneDayOrDatetime, // "xxx小时前" or "xxx分钟前" or "2023/02/02 17:53:15"
  //
  durationDatetimeOrDateTimeNoSec, // "xxx前 (17:53)" or "xxx前 (02/02 17:53)" or "2023/02/02 17:53" <<< 用于显示列表时间 (历史行、收藏行、下载行、稍后阅读行)
  durationDatetimeOrDateTime, // "xxx前 (17:53:15)" or "xxx前 (02/02 17:53:15)" or "2023/02/02 17:53:15"
}

String formatDatetimeAndDuration(DateTime datetime, FormatPattern pattern) {
  var md = DateFormat('MM/dd');
  var ymd = DateFormat('yyyy/MM/dd');
  var ymd2 = DateFormat('yyyy-MM-dd');
  var hm = DateFormat('HH:mm');
  var hms = DateFormat('HH:mm:ss');
  var mdhm = DateFormat('MM/dd HH:mm');
  var mdhms = DateFormat('MM/dd HH:mm:ss');
  var ymdhm = DateFormat('yyyy/MM/dd HH:mm');
  var ymdhms = DateFormat('yyyy/MM/dd HH:mm:ss');

  var now = DateTime.now();
  var duration = now.difference(datetime);

  var md2 = datetime.year == now.year ? md : ymd;
  var mdhm2 = datetime.year == now.year ? mdhm : ymdhm;

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
    case FormatPattern.dateNoYr:
      return md2.format(datetime); // "02/02"
    case FormatPattern.date:
      return ymd.format(datetime); // "2023/02/02"
    case FormatPattern.barredDate:
      return ymd2.format(datetime); // "2023-02-02"

    case FormatPattern.datetimeNoYrNoSec:
      return mdhm2.format(datetime); // "02/02 17:53"
    case FormatPattern.datetimeNoSec:
      return ymdhm.format(datetime); // "2023/02/02 17:53"
    case FormatPattern.datetime:
      return ymdhms.format(datetime); // "2023/02/02 17:53:15"

    case FormatPattern.duration:
      return formatDuration(duration); // "xxx前"
    case FormatPattern.durationOnlyDate:
      var given = DateTime(datetime.year, datetime.month, datetime.day);
      var duration = DateTime(now.year, now.month, now.day).difference(given);
      return duration.inDays == 0 ? '今天' : '${duration.inDays}天前'; // "今天" or "xxx天前"

    case FormatPattern.dateDuration:
      return '${ymd.format(datetime)} (${formatDuration(duration)})'; // "2023/02/02 (xxx前)"
    case FormatPattern.datetimeNoYrNoSecDuration:
      return '${mdhm2.format(datetime)} (${formatDuration(duration)})'; // "02/02 17:53 (xxx前)"
    case FormatPattern.datetimeNoSecDuration:
      return '${ymdhm.format(datetime)} (${formatDuration(duration)})'; // "2023/02/02 17:53 (xxx前)"
    case FormatPattern.datetimeDuration:
      return '${ymdhms.format(datetime)} (${formatDuration(duration)})'; // "2023/02/02 17:53:15 (xxx前)"

    case FormatPattern.durationDate:
      return '${formatDuration(duration)} ${ymd.format(datetime)}'; // "xxx前 (2023/02/02)"
    case FormatPattern.durationDatetimeNoYrNoSec:
      return '${formatDuration(duration)} ${mdhm2.format(datetime)}'; // "xxx前 (02/02 17:53)"
    case FormatPattern.durationDatetimeNoSec:
      return '${formatDuration(duration)} ${ymdhm.format(datetime)}'; // "xxx前 (2023/02/02 17:53)"
    case FormatPattern.durationDatetime:
      return '${formatDuration(duration)} ${ymdhms.format(datetime)}'; // "xxx前 (2023/02/02 17:53:15)"

    case FormatPattern.durationOrDate:
      return duration.inDays <= 7 ? formatDuration(duration) : ymd.format(datetime); // "xxx前" or "2023/02/02"
    case FormatPattern.durationOrDatetimeNoYrNoSec:
      return duration.inDays <= 7 ? formatDuration(duration) : mdhm2.format(datetime); // "xxx前" or "02/02 17:53"
    case FormatPattern.durationOrDatetimeNoSec:
      return duration.inDays <= 7 ? formatDuration(duration) : ymdhm.format(datetime); // "xxx前" or "2023/02/02 17:53"
    case FormatPattern.durationOrDatetime:
      return duration.inDays <= 7 ? formatDuration(duration) : ymdhms.format(datetime); // "xxx前" or "2023/02/02 17:53:15"

    case FormatPattern.durationOneDayOrDate:
      return duration.inDays == 0 ? formatDuration(duration) : ymd.format(datetime); // "xxx小时前" or "xxx分钟前" or "2023/02/02"
    case FormatPattern.durationOneDayOrDatetimeNoYrNoSec:
      return duration.inDays == 0 ? formatDuration(duration) : mdhm2.format(datetime); // "xxx小时前" or "xxx分钟前" or "02/02 17:53"
    case FormatPattern.durationOneDayOrDatetimeNoSec:
      return duration.inDays == 0 ? formatDuration(duration) : ymdhm.format(datetime); // "xxx小时前" or "xxx分钟前" or "2023/02/02 17:53"
    case FormatPattern.durationOneDayOrDatetime:
      return duration.inDays == 0 ? formatDuration(duration) : ymdhms.format(datetime); // "xxx小时前" or "xxx分钟前" or "2023/02/02 17:53:15"

    case FormatPattern.durationDatetimeOrDateTimeNoSec:
    case FormatPattern.durationDatetimeOrDateTime:
      var noSec = pattern == FormatPattern.durationDatetimeOrDateTimeNoSec;
      if (duration.inDays > 7) {
        return (noSec ? ymdhm : ymdhms).format(datetime); // "2023/02/02 17:53" or "2023/02/02 17:53:15"
      }
      if (now.day != datetime.day) {
        return '${formatDuration(duration)} (${(noSec ? mdhm : mdhms).format(datetime)})'; // "xxx前 (02/02 17:53)" or "xxx前 (02/02 17:53:15)"
      }
      return '${formatDuration(duration)} (${(noSec ? hm : hms).format(datetime)})'; // "xxx前 (17:53)" or "xxx前 (17:53:15)"
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
