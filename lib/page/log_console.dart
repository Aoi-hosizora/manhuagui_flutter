import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:logger/logger.dart';
import 'package:manhuagui_flutter/service/native/clipboard.dart';

class _PlainOutputEvent {
  final OutputEvent origin;
  final String plainText;

  _PlainOutputEvent(this.origin, this.plainText);
}

/// 调试日志页，与 flutter_ahlib example 基本保持一致
class LogConsolePage extends StatefulWidget {
  const LogConsolePage({Key? key}) : super(key: key);

  @override
  State<LogConsolePage> createState() => _LogConsolePageState();

  static var initialized = false;
  static var _logger = globalLogger;
  static var _bufferSize = 20;
  static final _eventBuffer = ListQueue<_PlainOutputEvent>();

  static void initialize(ExtendedLogger logger, {int bufferSize = 20}) {
    if (!initialized) {
      initialized = true;
      _logger = logger;
      _bufferSize = bufferSize;
      _eventBuffer.clear();
      _logger.addOutputListener(_callback);

      globalLogger.i('initialize LogConsolePage');
    }
  }

  static void finalize() {
    if (initialized) {
      _logger.removeOutputListener(_callback);
      _eventBuffer.clear();
      initialized = false;
    }
  }

  static void _callback(OutputEvent ev) {
    if (_eventBuffer.length == _bufferSize) {
      _eventBuffer.removeFirst();
    }
    var text = ev.lines.join('\n');
    var plainText = ansiEscapeCodeToPlainText(text);
    _eventBuffer.add(_PlainOutputEvent(ev, plainText));
  }
}

class _LogConsolePageState extends State<LogConsolePage> {
  final _scrollController = ScrollController();
  final _filterController = TextEditingController();

  final _filteredBuffer = <_PlainOutputEvent>[];
  var _filterLevel = Level.verbose;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      _updateFilteredBuffer();
      LogConsolePage._logger.addOutputListener(_updateFilteredBuffer);
    });
  }

  @override
  void dispose() {
    LogConsolePage._logger.removeOutputListener(_updateFilteredBuffer);
    _scrollController.dispose();
    _filterController.dispose();
    super.dispose();
  }

  void _updateFilteredBuffer([dynamic _]) {
    var filtered = LogConsolePage._eventBuffer.where((ev) {
      if (ev.origin.level.index < _filterLevel.index) {
        return false; // match level
      }
      if (_filterController.text.isEmpty) {
        return true; // empty filter query text
      }
      return ev.plainText.toLowerCase().contains(_filterController.text.toLowerCase());
    });
    _filteredBuffer.clear();
    _filteredBuffer.addAll(filtered);
    if (mounted) setState(() {});

    if (_scrollController.hasClients && _scrollController.position.atBottomEdge()) {
      WidgetsBinding.instance?.addPostFrameCallback((_) {
        _scrollController.scrollToBottom();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('调试日志'),
        leading: AppBarActionButton.leading(context: context),
        actions: [
          AppBarActionButton(
            icon: const Icon(Icons.ios_share),
            tooltip: '导出日志',
            onPressed: () => showDialog(
              context: context,
              builder: (c) => SimpleDialog(
                title: const Text('导出日志'),
                children: [
                  IconTextDialogOption(
                    icon: const Icon(Icons.copy),
                    text: const Text('复制所有日志'),
                    onPressed: () async {
                      Navigator.of(c).pop();
                      var logs = LogConsolePage._eventBuffer.map((e) => e.plainText).join('\n');
                      await copyText(logs, showToast: false);
                      Fluttertoast.showToast(msg: '调试日志已复制');
                    },
                  ),
                  IconTextDialogOption(
                    icon: const Icon(Icons.copy),
                    text: const Text('仅复制过滤后的日志'),
                    onPressed: () async {
                      Navigator.of(c).pop();
                      var logs = _filteredBuffer.map((e) => e.plainText).join('\n').trim();
                      await copyText(logs, showToast: false);
                      Fluttertoast.showToast(msg: '调试日志已复制');
                    },
                  ),
                ],
              ),
            ),
          ),
          AppBarActionButton(
            icon: const Icon(Icons.delete),
            tooltip: '清空日志',
            onPressed: () {
              _filteredBuffer.clear();
              LogConsolePage._eventBuffer.clear();
              if (mounted) setState(() {});
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _filteredBuffer.isEmpty
                ? Center(
                    child: Text('当前日志为空'),
                  )
                : ExtendedScrollbar(
                    controller: _scrollController,
                    interactive: true,
                    isAlwaysShown: true,
                    mainAxisMargin: 2,
                    crossAxisMargin: 2,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: 2000,
                          child: SelectableText(
                            _filteredBuffer.map((el) => el.plainText).join('\n') + ('\n' * 10),
                            style: Theme.of(context).textTheme.bodyText2?.copyWith(fontSize: 12.5, fontFamily: 'monospace'),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
          BottomAppBar(
            color: Colors.white,
            child: Container(
              height: kToolbarHeight,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _filterController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: '过滤日志...',
                      ),
                      style: const TextStyle(fontSize: 20),
                      onChanged: (s) => _updateFilteredBuffer(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  DropdownButton<Level>(
                    value: _filterLevel,
                    items: const [
                      DropdownMenuItem(child: Text('verbose'), value: Level.verbose),
                      DropdownMenuItem(child: Text('debug'), value: Level.debug),
                      DropdownMenuItem(child: Text('info'), value: Level.info),
                      DropdownMenuItem(child: Text('warning'), value: Level.warning),
                      DropdownMenuItem(child: Text('error'), value: Level.error),
                      DropdownMenuItem(child: Text('wtf'), value: Level.wtf),
                    ],
                    underline: Container(color: Colors.transparent),
                    onChanged: (value) {
                      if (value != null) {
                        _filterLevel = value;
                        _updateFilteredBuffer();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _filteredBuffer.isEmpty
          ? null
          : Padding(
              padding: const EdgeInsets.only(bottom: kToolbarHeight),
              child: ScrollAnimatedFab(
                scrollController: _scrollController,
                condition: ScrollAnimatedCondition.reverseDirection,
                fab: FloatingActionButton(
                  child: const Icon(Icons.vertical_align_bottom),
                  heroTag: null,
                  onPressed: () => _scrollController.scrollToBottom(),
                ),
              ),
            ),
    );
  }
}
