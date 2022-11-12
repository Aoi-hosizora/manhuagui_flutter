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
  var _enableScrollListener = true;
  var _followBottom = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      _scrollController.addListener(_onScrolled);
      _updateFilteredBuffer();
      LogConsolePage._logger.addOutputListener(_callback);
    });
  }

  @override
  void dispose() {
    LogConsolePage._logger.removeOutputListener(_callback);
    _scrollController.dispose();
    _filterController.dispose();
    super.dispose();
  }

  void _callback(OutputEvent ev) {
    _updateFilteredBuffer();
  }

  void _updateFilteredBuffer() {
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

    if (_followBottom) {
      _scrollToBottom();
    }
  }

  void _onScrolled() {
    if (_enableScrollListener) {
      _followBottom = _scrollController.offset >= _scrollController.position.maxScrollExtent;
      if (mounted) setState(() {});
    }
  }

  void _scrollToBottom() async {
    _enableScrollListener = false;
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      await _scrollController.scrollToBottom();
      _enableScrollListener = true;
      _onScrolled();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('调试日志'),
        leading: AppBarActionButton.leading(context: context),
        actions: [
          AppBarActionButton(
            icon: const Icon(Icons.delete),
            tooltip: '清空日志',
            onPressed: () {
              _filteredBuffer.clear();
              LogConsolePage._eventBuffer.clear();
              if (mounted) setState(() {});
            },
          ),
          AppBarActionButton(
            icon: const Icon(Icons.ios_share),
            tooltip: '复制日志',
            onPressed: () => showDialog(
              context: context,
              builder: (c) => SimpleDialog(
                title: const Text('复制日志'),
                children: [
                  TextDialogOption(
                    text: const Text('复制所有日志'),
                    onPressed: () async {
                      Navigator.of(c).pop();
                      var logs = LogConsolePage._eventBuffer.map((e) => e.plainText).join('\n');
                      await copyText(logs, showToast: false);
                      Fluttertoast.showToast(msg: '调试日志已复制');
                    },
                  ),
                  TextDialogOption(
                    text: const Text('仅复制过滤后的日志'),
                    onPressed: () async {
                      Navigator.of(c).pop();
                      var logs = _filteredBuffer.map((e) => e.plainText).join('\n');
                      await copyText(logs, showToast: false);
                      Fluttertoast.showToast(msg: '调试日志已复制');
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Scrollbar(
              controller: _scrollController,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: 2000,
                    child: SelectableText(
                      _filteredBuffer.map((el) => el.plainText).join('\n'),
                      style: Theme.of(context).textTheme.bodyText2?.copyWith(fontFamily: 'monospace'),
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
      floatingActionButton: AnimatedOpacity(
        opacity: _followBottom ? 0 : 1,
        duration: const Duration(milliseconds: 150),
        child: Padding(
          padding: EdgeInsets.only(bottom: kToolbarHeight),
          child: FloatingActionButton(
            child: const Icon(Icons.arrow_downward),
            heroTag: null,
            mini: true,
            onPressed: _scrollToBottom,
          ),
        ),
      ),
    );
  }
}
