import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/config.dart';
import 'package:manhuagui_flutter/page/view/common_widgets.dart';
import 'package:manhuagui_flutter/page/view/detail_table.dart';
import 'package:manhuagui_flutter/service/dio/dio_manager.dart';
import 'package:manhuagui_flutter/service/dio/retrofit.dart';
import 'package:manhuagui_flutter/service/dio/wrap_error.dart';

/// 资源访问详情页，请求服务器并展示 RateLimit 信息
class ResourceDetailPage extends StatefulWidget {
  const ResourceDetailPage({
    Key? key,
  }) : super(key: key);

  @override
  _ResourceDetailPageState createState() => _ResourceDetailPageState();
}

class ResourceDetail {
  const ResourceDetail({
    required this.policy,
    required this.quantum,
    required this.window,
    required this.limit,
    required this.remaining,
    required this.reset,
    required this.requestID,
  });

  final String policy;
  final String quantum;
  final String window;
  final String limit;
  final String remaining;
  final String reset;
  final String requestID;

  static ResourceDetail fromHeader(Headers header) {
    // x-ratelimit-limit: 200
    // x-ratelimit-policy: 200;q=50;w=60
    // x-ratelimit-remaining: 191
    // x-ratelimit-reset: 23.444154961s
    var policy = header.value('x-ratelimit-policy') ?? '';
    var parts = policy.split(';');
    var quantum = '';
    if (parts.length >= 2) {
      quantum = parts[1].replaceAll('q=', '');
    }
    var window = '';
    if (parts.length >= 3) {
      window = parts[2].replaceAll('w=', '');
    }
    return ResourceDetail(
      policy: policy,
      quantum: quantum,
      window: window,
      limit: header.value('x-ratelimit-limit') ?? '',
      remaining: header.value('x-ratelimit-remaining') ?? '',
      reset: header.value('x-ratelimit-reset') ?? '',
      requestID: header.value('x-request-id') ?? '',
    );
  }
}

class _ResourceDetailPageState extends State<ResourceDetailPage> {
  final _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  var _loading = true; // initialize to true
  ResourceDetail? _data;
  var _error = '';

  Future<void> _loadData() async {
    _loading = true;
    _error = '';
    if (mounted) setState(() {});

    final client = RestClient(DioManager.instance.dio, baseUrl: BASE_API_PURE_URL);
    try {
      var resp = await client.ping();
      _data = null;
      _error = '';
      if (mounted) setState(() {});
      await Future.delayed(kFlashListDuration);
      _data = ResourceDetail.fromHeader(resp.response.headers);
    } catch (e, s) {
      _error = wrapError(e, s).text;
      if (_data != null) {
        Fluttertoast.showToast(msg: _error);
      }
    } finally {
      _loading = false;
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('资源访问详情'),
        leading: AppBarActionButton.leading(context: context),
      ),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: () => _loadData(),
        child: PlaceholderText.from(
          isLoading: _loading,
          errorText: _error,
          isEmpty: _data == null,
          setting: PlaceholderSetting().copyWithChinese(),
          onRefresh: () => _loadData(),
          childBuilder: (c) => ExtendedScrollbar(
            controller: _controller,
            interactive: true,
            mainAxisMargin: 2,
            crossAxisMargin: 2,
            child: ListView(
              controller: _controller,
              padding: EdgeInsets.zero,
              physics: AlwaysScrollableScrollPhysics(),
              children: [
                WarningTextView(
                  text: '此处的 "资源" 指本第三方应用配套的后端服务器 (只用于数据请求)，因为服务器由个人维护，所以需要进行资源访问限流。',
                  isWarning: false,
                ),
                Padding(
                  padding: EdgeInsets.only(left: 20, right: 20, top: 5, bottom: 15),
                  child: DetailTableView(
                    rows: [
                      DetailRow('时间窗口大小', '${_data!.window}s'),
                      DetailRow('窗口内访问次数限制', _data!.limit),
                      DetailRow('窗口内剩余访问次数', _data!.remaining),
                      DetailRow('时间窗口重置时间', _data!.reset),
                      DetailRow('重置后新增访问次数', _data!.quantum),
                      DetailRow('资源访问限流策略', 'bucket: t=${_data!.policy}'),
                      DetailRow('本次请求ID', _data!.requestID),
                    ],
                    fractionColumnWidth: 0.4,
                    tableWidth: MediaQuery.of(context).size.width - MediaQuery.of(context).padding.horizontal - 40,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
