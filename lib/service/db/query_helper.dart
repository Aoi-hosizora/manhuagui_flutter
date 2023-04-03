import 'package:flutter_ahlib/flutter_ahlib.dart';

class QueryHelper {
  static Tuple2<String, List<String>>? buildLikeStatement(List<String> columns, String? keyword, {bool includeWHERE = false, bool includeAND = false}) {
    if (keyword == null) {
      return null;
    }
    keyword = keyword.trim();
    if (keyword.isEmpty) {
      return null;
    }

    var keywords = keyword.replaceAll('\\', '\\\\').replaceAll('%', '\\%').replaceAll('_', '\\_').split(' ').toSet().toList();
    if (keywords.isEmpty) {
      return null;
    }

    var statements = <String>[];
    var arguments = <String>[];
    for (var column in columns) {
      statements.addAll([for (var _ in keywords) '`$column` LIKE ? ESCAPE \'\\\'']);
      arguments.addAll([for (var keyword in keywords) '%$keyword%']);
    }
    var statement = statements.join(' OR ');
    statement = (includeWHERE ? ' WHERE ' : ' ') + (includeAND ? ' AND ' : ' ') + '($statement)';
    return Tuple2(statement, arguments);
  }

  static String? buildOrderByStatement(SortMethod sortMethod, {String? idColumn, String? nameColumn, String? timeColumn, String? orderColumn, bool includeORDERBY = false}) {
    var desc = sortMethod.isDesc();
    var column = sortMethod.toAsc().let((sort) => //
        sort == SortMethod.byIdAsc
            ? idColumn
            : sort == SortMethod.byNameAsc
                ? nameColumn
                : sort == SortMethod.byTimeAsc
                    ? timeColumn
                    : orderColumn);
    var byName = sortMethod == SortMethod.byNameAsc || sortMethod == SortMethod.byNameDesc;
    if (column == null) {
      return null;
    }

    var statement = '`$column`' + (byName ? ' COLLATE LOCALIZED' : '') + (!desc ? ' ASC' : ' DESC');
    statement = (includeORDERBY ? ' ORDER BY ' : '') + statement;
    return statement;
  }
}

enum SortMethod {
  byIdAsc,
  byIdDesc,
  byNameAsc,
  byNameDesc,
  byTimeAsc,
  byTimeDesc,
  byOrderAsc,
  byOrderDesc,
}

extension SortMethodExtension on SortMethod {
  bool isAsc() {
    return this == SortMethod.byIdAsc || this == SortMethod.byNameAsc || this == SortMethod.byTimeAsc || this == SortMethod.byOrderAsc;
  }

  bool isDesc() {
    return this == SortMethod.byIdDesc || this == SortMethod.byNameDesc || this == SortMethod.byTimeDesc || this == SortMethod.byOrderDesc;
  }

  SortMethod toAsc() {
    if (isAsc()) {
      return this;
    }
    return this == SortMethod.byIdDesc
        ? SortMethod.byIdAsc
        : this == SortMethod.byNameDesc
            ? SortMethod.byNameAsc
            : this == SortMethod.byTimeDesc
                ? SortMethod.byTimeAsc
                : SortMethod.byOrderAsc;
  }

  SortMethod toDesc() {
    if (isDesc()) {
      return this;
    }
    return this == SortMethod.byIdAsc
        ? SortMethod.byIdDesc
        : this == SortMethod.byNameAsc
            ? SortMethod.byNameDesc
            : this == SortMethod.byTimeAsc
                ? SortMethod.byTimeDesc
                : SortMethod.byOrderDesc;
  }
}
