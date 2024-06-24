import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/model/author.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/page/author.dart';
import 'package:manhuagui_flutter/page/author_detail.dart';
import 'package:manhuagui_flutter/page/favorite_author.dart';
import 'package:manhuagui_flutter/page/view/custom_icons.dart';
import 'package:manhuagui_flutter/service/db/favorite.dart';
import 'package:manhuagui_flutter/service/evb/auth_manager.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';
import 'package:manhuagui_flutter/service/native/browser.dart';
import 'package:manhuagui_flutter/service/native/clipboard.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

/// [_DialogHelper] 帮助类
part 'author_dialog_helper.dart';

/// 作者列表页-作者弹出菜单 [showPopupMenuForAuthorList]
part 'author_dialog_list.dart';

/// 作者页-作者收藏对话框 [showPopupMenuForAuthorFavoriting]
part 'author_dialog_fav.dart';

/// 作者收藏页-修改备注对话框 [showUpdateFavoriteAuthorRemarkDialog]
/// 作者列表页/作者收藏页-寻找ID对话框 [showFindAuthorByIdDialog]
/// 作者页-作者名对话框 [showPopupMenuForAuthorName]
part 'author_dialog_misc.dart';

// ===

// updated callbacks
typedef FavoriteUpdatedCallback = void Function(FavoriteAuthor? favorite);
