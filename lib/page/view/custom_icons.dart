import 'package:flutter/material.dart';
import 'package:path_icon/path_icon.dart';

// ignore_for_file: non_constant_identifier_names

class CustomIcons {
  // https://yqnn.github.io/svg-path-editor/
  // https://fonts.google.com/icons?icon.set=Material+Symbols

  // Import Contacts, Sharp, Fill: 0, Weight: 500, Grade: 0, Optical size: 40
  static final opened_empty_book = PathIconData.fromData(
    '''M10.5 27.542q2.167 0 4.188.479 2.02.479 3.979 1.479V12.167Q16.833 11 14.75 10.375q-2.083-.625-4.25-.625-1.542 0-3.063.354-1.52.354-2.979.938v17.583q1.334-.583 2.917-.833 1.583-.25 3.125-.25ZM21.458 29.5q2-1 3.938-1.479 1.937-.479 4.104-.479 1.542 0 3.146.25 1.604.25 2.896.666V11.042q-1.375-.667-2.938-.98-1.562-.312-3.104-.312-2.167 0-4.208.625-2.042.625-3.834 1.792Zm-1.375 4.458Q18 32.375 15.542 31.479q-2.459-.896-5.042-.896-2.25 0-4.833.959-2.584.958-4.25 2.125V9.083q1.833-1.125 4.271-1.75 2.437-.625 4.77-.625 2.584 0 5.021.688 2.438.687 4.563 2.104 2.125-1.417 4.541-2.104 2.417-.688 4.959-.688 2.333 0 4.791.625 2.459.625 4.25 1.75v24.584q-1.625-1.209-4.229-2.146-2.604-.938-4.854-.938-2.583 0-4.958.917t-4.459 2.458Zm-8.541-14.333Z''',
  );

  // Import Contacts + Insights, Sharp, Fill: 0, Weight: 500, Grade: 0, Optical size: 40
  static final opened_empty_star_book = PathIconData.fromData(
    '''M10.5 27.542q2.167 0 4.188.479 2.02.479 3.979 1.479V12.167Q16.833 11 14.75 10.375q-2.083-.625-4.25-.625-1.542 0-3.063.354-1.52.354-2.979.938v17.583q1.334-.583 2.917-.833 1.583-.25 3.125-.25ZM21.458 29.5q2-1 3.938-1.479 1.937-.479 4.104-.479 1.542 0 3.146.25 1.604.25 2.896.666V11.042q-1.375-.667-2.938-.98-1.562-.312-3.104-.312-2.167 0-4.208.625-2.042.625-3.834 1.792Zm-1.375 4.458Q18 32.375 15.542 31.479q-2.459-.896-5.042-.896-2.25 0-4.833.959-2.584.958-4.25 2.125V9.083q1.833-1.125 4.271-1.75 2.437-.625 4.77-.625 2.584 0 5.021.688 2.438.687 4.563 2.104 2.125-1.417 4.541-2.104 2.417-.688 4.959-.688 2.333 0 4.791.625 2.459.625 4.25 1.75v24.584q-1.625-1.209-4.229-2.146-2.604-.938-4.854-.938-2.583 0-4.958.917t-4.459 2.458Zm-8.541-14.333ZM28.8 25l-1.792-3.917-3.875-1.75 3.875-1.833 1.792-3.875 1.792 3.875 3.916 1.833-3.916 1.792Z''',
  );
}

class CustomIcon extends StatelessWidget {
  const CustomIcon(
    this.icon, {
    Key? key,
    this.size,
    this.color,
  }) : super(key: key);

  final dynamic icon; // TODO make the type more `type`
  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    if (icon == null) {
      return Icon(icon, size: size, color: color);
    }
    if (icon is IconData) {
      return Icon(icon as IconData, size: size, color: color);
    }
    if (icon is PathIconData) {
      return PathIcon(icon as PathIconData, size: size, color: color);
    }
    if (icon is Widget) {
      return icon;
    }
    return SizedBox.shrink();
  }
}
