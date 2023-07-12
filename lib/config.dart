// ignore_for_file: constant_identifier_names, non_constant_identifier_names

// app metadata
const APP_NAME = 'Manhuagui';
const APP_VERSION = '1.3.0';
const APP_LEGALESE = 'Copyright © 2020-2023 AoiHosizora';
const APP_DESCRIPTION = //
    '第三方漫画柜 ($WEB_HOMEPAGE_URL) 安卓客户端，使用 Flutter 开发，当前版本为 $APP_VERSION。\n'
    '\n'
    '开发者: GitHub @Aoi-hosizora (青いほしぞら) <$AUTHOR_EMAIL>\n'
    '\n'
    '本应用仅供学习使用，客户端和服务端代码完全开源，仅供非商业用途。\n'
    '\n'
    '本应用与漫画柜内容提供方无任何关系，若有问题，请发邮件或 Issue 联系。';

// data and related
const ASSETS_PREFIX = 'lib/assets/';
const DB_NAME = 'db_manhuagui';
const DL_NTFC_ID = 'com.aoihosizora.manhuagui:download';
const DL_NTFC_NAME = '漫画下载通知';
const DL_NTFC_DESCRIPTION = '显示当前的漫画下载进度';
const LOG_CONSOLE_BUFFER = 200;

// network timeout
const CONNECT_TIMEOUT = 8000; // 8.0s (local -> my server)
const SEND_TIMEOUT = 8000; // 8.0s (local -> my server)
const RECEIVE_TIMEOUT = 10000; // 10.0s (my server -> manhuagui server -> my server -> local)
const DOWNLOAD_HEAD_TIMEOUT = 5000; // 5.0s (local -> manhuagui server -> local)
const DOWNLOAD_IMAGE_TIMEOUT = 12000; // 12.0s (local -> manhuagui server -> local)
const GALLERY_IMAGE_TIMEOUT = 15000; // 15.0s (local -> manhuagui server -> local)
// => LTIMEOUT
final CONNECT_LTIMEOUT = (CONNECT_TIMEOUT * 1.5).toInt();
final SEND_LTIMEOUT = (SEND_TIMEOUT * 1.5).toInt();
final RECEIVE_LTIMEOUT = (RECEIVE_TIMEOUT * 1.5).toInt();
final DOWNLOAD_HEAD_LTIMEOUT = (DOWNLOAD_HEAD_TIMEOUT * 1.5).toInt();
final DOWNLOAD_IMAGE_LTIMEOUT = (DOWNLOAD_IMAGE_TIMEOUT * 1.5).toInt();
final GALLERY_IMAGE_LTIMEOUT = (GALLERY_IMAGE_TIMEOUT * 1.5).toInt();
// => LLTIMEOUT
const CONNECT_LLTIMEOUT = CONNECT_TIMEOUT * 2;
const SEND_LLTIMEOUT = SEND_TIMEOUT * 2;
const RECEIVE_LLTIMEOUT = RECEIVE_TIMEOUT * 2;
const DOWNLOAD_HEAD_LLTIMEOUT = DOWNLOAD_HEAD_TIMEOUT * 2;
const DOWNLOAD_IMAGE_LLTIMEOUT = DOWNLOAD_IMAGE_TIMEOUT * 2;
const GALLERY_IMAGE_LLTIMEOUT = GALLERY_IMAGE_TIMEOUT * 2;

// api related
const BASE_API_URL = 'https://api-manhuagui.aoihosizora.top/v1/';
const BASE_API_PURE_URL = 'https://api-manhuagui.aoihosizora.top/';
const USER_AGENT = 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/87.0.4280.66 Safari/537.36';
const REFERER = 'https://www.manhuagui.com/';
const DEFAULT_USER_AVATAR_URL = 'https://cf.hamreus.com/images/default.png';
const DEFAULT_AUTHOR_COVER_URL = 'https://cf.hamreus.com/zpic/none.jpg';

// website urls
const AUTHOR_EMAIL = 'aoihosizora@hotmail.com';
const WEB_HOMEPAGE_URL = 'https://www.manhuagui.com/';
const USER_CENTER_URL = 'https://www.manhuagui.com/user/center/index';
const MESSAGE_URL = 'https://www.manhuagui.com/user/message/system';
const EDIT_PROFILE_URL = 'https://www.manhuagui.com/user/center/proinfo';
const REGISTER_URL = 'https://www.manhuagui.com/user/register';
const PROJECT_HOMEPAGE_URL = 'https://aoi-hosizora.github.io/manhuagui_flutter';
const FEEDBACK_URL = 'https://github.com/Aoi-hosizora/manhuagui_flutter/issues';
const RELEASE_URL = 'https://github.com/Aoi-hosizora/manhuagui_flutter/releases';
