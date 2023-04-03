#!/bin/bash

mkdir -p deps

# Process sqflite dependency
if [ -d deps/sqflite ]; then
  echo "Ignore existed \"deps/sqflite/\""
else
  git clone --depth 1 --branch v2.2.5-0 https://github.com/tekartik/sqflite deps/sqflite
  sed -i "s/sdk: '>=2.18.0 <3.0.0'/sdk: '>=2.16.2 <3.0.0' # sdk: '>=2.18.0 <3.0.0'/" deps/sqflite/sqflite/pubspec.yaml
  sed -i 's/flutter: ">=3.3.0"/# flutter: ">=3.3.0"/' deps/sqflite/sqflite/pubspec.yaml
  sed -i "s/sqflite_common: '>=2.4.2+2 <4.0.0'/sqflite_common:\n    path: ..\/sqflite_common/" deps/sqflite/sqflite/pubspec.yaml
  sed -i "s/sdk: '>=2.18.0 <3.0.0'/sdk: '>=2.16.2 <3.0.0' # sdk: '>=2.18.0 <3.0.0'/" deps/sqflite/sqflite/example/pubspec.yaml
  sed -i "s/sdk: '>=2.18.0 <3.0.0'/sdk: '>=2.16.2 <3.0.0' # sdk: '>=2.18.0 <3.0.0'/" deps/sqflite/sqflite_common/pubspec.yaml
  sed -i "s/SqfliteBatchOperation(super.type, this.method, super.sql, super.arguments);/SqfliteBatchOperation(dynamic type, this.method, dynamic sql, dynamic arguments) : super(type, sql, arguments);/" deps/sqflite/sqflite_common/lib/src/batch.dart
fi

# Process photo_view dependency
if [ -d deps/photo_view ]; then
  echo "Ignore existed \"deps/photo_view/\""
else
  git clone --depth 1 --branch 0.14.0 https://github.com/bluefireteam/photo_view deps/photo_view
  sed -i "0,/required this.enablePanAlways,/s//required this.enablePanAlways,\n    this.customBuilder,/" deps/photo_view/lib/src/photo_view_wrappers.dart
  sed -i "0,/final bool? enablePanAlways;/s//final bool? enablePanAlways;\n  final Widget Function(BuildContext, Widget)? customBuilder;/" deps/photo_view/lib/src/photo_view_wrappers.dart
  sed -i "s/return PhotoViewCore(/var view = PhotoViewCore(/" deps/photo_view/lib/src/photo_view_wrappers.dart
  sed -z -i "s/widget.enablePanAlways ?? false,\n    );/widget.enablePanAlways ?? false,\n    );\n    return widget.customBuilder?.call(context, view) ?? view;/" deps/photo_view/lib/src/photo_view_wrappers.dart
  sed -i "0,/this.enablePanAlways,/s//this.enablePanAlways,\n    this.customBuilder,/" deps/photo_view/lib/photo_view.dart
  sed -i "s/loadingBuilder = null,/loadingBuilder = null,\n        customBuilder = null,/" deps/photo_view/lib/photo_view.dart
  sed -i "s/final bool? enablePanAlways;/final bool? enablePanAlways;\n\n  final Widget Function(BuildContext, Widget)? customBuilder;/" deps/photo_view/lib/photo_view.dart
  sed -z -i "s/enablePanAlways: widget.enablePanAlways,\n              );/enablePanAlways: widget.enablePanAlways,\n                customBuilder: widget.customBuilder,\n              );/" deps/photo_view/lib/photo_view.dart
fi

# Process flutter_ahlib reloadable_photo_view.dart
if [ -f deps/photo_view/lib/reloadable_photo_view.dart ]; then
  echo "Ignore existed \"deps/photo_view/lib/reloadable_photo_view.dart\""
else
  curl -o deps/photo_view/lib/reloadable_photo_view.dart https://raw.githubusercontent.com/Aoi-hosizora/flutter_ahlib/dev.v1.3.0/lib/src/image/reloadable_photo_view.dart
  sed -i "0,/this.errorBuilder,/s//this.errorBuilder,\n    this.customBuilder,/" deps/photo_view/lib/reloadable_photo_view.dart
  sed -i "0,/final ErrorPlaceholderBuilder? errorBuilder;/s//final ErrorPlaceholderBuilder? errorBuilder;\n\n  final Widget Function(BuildContext, Widget)? customBuilder;/" deps/photo_view/lib/reloadable_photo_view.dart
  sed -i "s/errorBuilder: widget.errorBuilder,/errorBuilder: widget.errorBuilder,\n        customBuilder: widget.customBuilder,/" deps/photo_view/lib/reloadable_photo_view.dart
fi
