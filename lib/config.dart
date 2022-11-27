// ignore_for_file: constant_identifier_names

const APP_NAME = 'Manhuagui';
const APP_VERSION = '1.2.1';
const APP_LEGALESE = 'Copyright © 2020-2022 AoiHosizora';
const APP_DESCRIPTION = //
    '第三方漫画柜 ($WEB_HOMEPAGE_URL) 安卓客户端，使用 Flutter 开发。\n'
    '作者：GitHub @Aoi-hosizora (青いほしぞら) <aoihosizora@hotmail.com>\n'
    '\n'
    '该客户端仅供学习使用，仅供非商业用途。\n'
    '\n'
    '本应用与漫画柜内容提供方无任何关系，若有问题，请发邮件或 Issue 联系。';

const ASSETS_PREFIX = 'lib/assets/';
const DB_NAME = 'db_manhuagui';
const DL_NTFC_ID = 'com.aoihosizora.manhuagui:download';
const DL_NTFC_NAME = '漫画下载通知';
const DL_NTFC_DESCRIPTION = '显示当前的漫画下载进度';
const LOG_CONSOLE_BUFFER = 200;

const DEBUG_ERROR = true;
const CONNECT_TIMEOUT = 5000; // 5.0s (local -> my server)
const SEND_TIMEOUT = 5000; // 5.0s (local -> my server)
const RECEIVE_TIMEOUT = 8000; // 8.0s (my server -> manhuagui server -> my server -> local)
const DOWNLOAD_HEAD_TIMEOUT = 4000; // 4.0s (local -> manhuagui server -> local)
const DOWNLOAD_IMAGE_TIMEOUT = 12000; // 12.0s (local -> manhuagui server -> local)
const CONNECT_LTIMEOUT = CONNECT_TIMEOUT * 2;
const SEND_LTIMEOUT = SEND_TIMEOUT * 2;
const RECEIVE_LTIMEOUT = RECEIVE_TIMEOUT * 2;
const DOWNLOAD_HEAD_LTIMEOUT = DOWNLOAD_HEAD_TIMEOUT * 2;
const DOWNLOAD_IMAGE_LTIMEOUT = DOWNLOAD_IMAGE_TIMEOUT * 2;

const BASE_API_URL = 'https://api-manhuagui.aoihosizora.top/v1/';
const USER_AGENT = 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/87.0.4280.66 Safari/537.36';
const REFERER = 'https://www.manhuagui.com/';

const WEB_HOMEPAGE_URL = 'https://www.manhuagui.com/';
const USER_CENTER_URL = 'https://www.manhuagui.com/user/center/index';
const MESSAGE_URL = 'https://www.manhuagui.com/user/message/system';
const EDIT_PROFILE_URL = 'https://www.manhuagui.com/user/center/proinfo';
const REGISTER_URL = 'https://www.manhuagui.com/user/register';
const SOURCE_CODE_URL = 'https://github.com/Aoi-hosizora/manhuagui_flutter';
const FEEDBACK_URL = 'https://github.com/Aoi-hosizora/manhuagui_flutter/issues/new';
const RELEASE_URL = 'https://github.com/Aoi-hosizora/manhuagui_flutter/releases';
