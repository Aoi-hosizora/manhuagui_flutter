import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:logger/logger.dart';

// TODO https://github.com/FMotalleb/logger
// TODO https://github.com/fmotalleb/logger_flutter

class LogConsolePage extends StatefulWidget {
  const LogConsolePage({
    Key? key,
    this.dark = false,
    this.showCloseButton = false,
    this.showClearButton = true,
    this.onExport,
  }) : super(key: key);

  final bool dark;
  final bool showCloseButton;
  final bool showClearButton;
  final void Function(String content)? onExport;

  @override
  State<LogConsolePage> createState() => _LogConsolePageState();

  static final _outputEventBuffer = ListQueue<OutputEvent>();
  static int _bufferSize = 20;
  static var _initialized = false;

  static void initialize({int bufferSize = 20}) {
    if (_initialized) {
      return;
    }

    _bufferSize = bufferSize;
    _initialized = true;

    globalLogger.addOutputListener((event) {
      if (_outputEventBuffer.length == bufferSize) {
        _outputEventBuffer.removeFirst();
      }
      _outputEventBuffer.add(event);
    });
  }
}

class _RenderedEvent {
  final int id;
  final Level level;
  final TextSpan span;
  final String lowerCaseText;

  _RenderedEvent(this.id, this.level, this.span, this.lowerCaseText);
}

class _LogConsolePageState extends State<LogConsolePage> {
  late OutputEventCallback _callback;

  final ListQueue<_RenderedEvent> _renderedBuffer = ListQueue();
  List<_RenderedEvent> _filteredBuffer = [];

  final _scrollController = ScrollController();
  final _filterController = TextEditingController();

  Level _filterLevel = Level.verbose;
  double _logFontSize = 14;

  var _currentId = 0;
  bool _scrollListenerEnabled = true;
  bool _followBottom = true;

  @override
  void initState() {
    super.initState();

    _callback = (e) {
      if (_renderedBuffer.length == LogConsolePage._bufferSize) {
        _renderedBuffer.removeFirst();
      }
      _renderedBuffer.add(_renderEvent(e));
      _refreshFilter();
    };

    globalLogger.addOutputListener(_callback);

    _scrollController.addListener(() {
      if (!_scrollListenerEnabled) return;
      var scrolledToBottom = _scrollController.offset >= _scrollController.position.maxScrollExtent;
      setState(() {
        _followBottom = scrolledToBottom;
      });
    });
  }

  @override
  void dispose() {
    globalLogger.removeOutputListener(_callback);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _renderedBuffer.clear();
    for (var event in LogConsolePage._outputEventBuffer) {
      _renderedBuffer.add(_renderEvent(event));
    }
    _refreshFilter();
  }

  void _refreshFilter() {
    var newFilteredBuffer = _renderedBuffer.where((it) {
      var logLevelMatches = it.level.index >= _filterLevel.index;
      if (!logLevelMatches) {
        return false;
      } else if (_filterController.text.isNotEmpty) {
        var filterText = _filterController.text.toLowerCase();
        return it.lowerCaseText.contains(filterText);
      } else {
        return true;
      }
    }).toList();
    setState(() {
      _filteredBuffer = newFilteredBuffer;
    });

    if (_followBottom) {
      Future.delayed(Duration.zero, _scrollToBottom);
    }
  }

  void _scrollToBottom() async {
    _scrollListenerEnabled = false;

    setState(() {
      _followBottom = true;
    });

    var scrollPosition = _scrollController.position;
    await _scrollController.animateTo(
      scrollPosition.maxScrollExtent,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );

    _scrollListenerEnabled = true;
  }

  _RenderedEvent _renderEvent(OutputEvent event) {
    var parser = _AnsiParser(widget.dark);
    var text = event.lines.join('\n');
    parser.parse(text);
    return _RenderedEvent(
      _currentId++,
      event.level,
      TextSpan(children: parser.spans),
      text.toLowerCase(),
    );
  }

  Widget _buildLogContent() {
    return Container(
      color: widget.dark ? Colors.black : Colors.grey[150],
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 1600,
          child: ListView.builder(
            shrinkWrap: true,
            controller: _scrollController,
            itemBuilder: (context, index) {
              var logEntry = _filteredBuffer[index];
              return Text.rich(
                logEntry.span,
                key: Key(logEntry.id.toString()),
                style: TextStyle(fontSize: _logFontSize),
              );
            },
            itemCount: _filteredBuffer.length,
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return _LogBar(
      dark: widget.dark,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          const Text(
            'Log Console',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          if (widget.showClearButton)
            IconButton(
              icon: const Icon(
                Icons.delete,
                color: Color.fromARGB(255, 254, 20, 3),
              ),
              onPressed: () {
                _renderedBuffer.clear();
                LogConsolePage._outputEventBuffer.clear();
                _refreshFilter();
                setState(() {});
              },
            ),
          IconButton(
            icon: const Icon(Icons.import_export),
            onPressed: () {
              var content = _renderedBuffer.map((e) => e.lowerCaseText).join();
              if (widget.onExport != null) {
                widget.onExport?.call(content);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              setState(() {
                _logFontSize++;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: () {
              setState(() {
                _logFontSize--;
              });
            },
          ),
          if (widget.showCloseButton)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return _LogBar(
      dark: widget.dark,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Expanded(
            child: TextField(
              style: const TextStyle(fontSize: 20),
              controller: _filterController,
              onChanged: (s) => _refreshFilter(),
              decoration: const InputDecoration(
                labelText: 'Filter log output',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 20),
          DropdownButton<Level>(
            value: _filterLevel,
            items: const [
              DropdownMenuItem(
                child: Text('VERBOSE'),
                value: Level.verbose,
              ),
              DropdownMenuItem(
                child: Text('DEBUG'),
                value: Level.debug,
              ),
              DropdownMenuItem(
                child: Text('INFO'),
                value: Level.info,
              ),
              DropdownMenuItem(
                child: Text('WARNING'),
                value: Level.warning,
              ),
              DropdownMenuItem(
                child: Text('ERROR'),
                value: Level.error,
              ),
              DropdownMenuItem(
                child: Text('WTF'),
                value: Level.wtf,
              )
            ],
            onChanged: (value) {
              _filterLevel = value ?? Level.info;
              _refreshFilter();
            },
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: widget.dark
          ? ThemeData(
              brightness: Brightness.dark,
              colorScheme: ColorScheme.fromSwatch().copyWith(secondary: Colors.blueGrey),
            )
          : ThemeData(
              brightness: Brightness.light,
              colorScheme: ColorScheme.fromSwatch().copyWith(secondary: Colors.lightBlueAccent),
            ),
      home: Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildTopBar(),
              Expanded(
                child: _buildLogContent(),
              ),
              _buildBottomBar(),
            ],
          ),
        ),
        floatingActionButton: AnimatedOpacity(
          opacity: _followBottom ? 0 : 1,
          duration: const Duration(milliseconds: 150),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 60),
            child: FloatingActionButton(
              mini: true,
              clipBehavior: Clip.antiAlias,
              child: Icon(
                Icons.arrow_downward,
                color: widget.dark ? Colors.white : Colors.lightBlue[900],
              ),
              onPressed: _scrollToBottom,
            ),
          ),
        ),
      ),
    );
  }
}

class _LogBar extends StatelessWidget {
  final bool dark;
  final Widget child;

  const _LogBar({Key? key, required this.dark, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            if (!dark)
              BoxShadow(
                color: Colors.grey[400] ?? Colors.grey,
                blurRadius: 3,
              ),
          ],
        ),
        child: Material(
          color: dark ? Colors.blueGrey[900] : Colors.white,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(15, 8, 15, 8),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _AnsiParser {
  // ignore: constant_identifier_names
  static const TEXT = 0, BRACKET = 1, CODE = 2;

  final bool dark;

  _AnsiParser(this.dark);

  Color? foreground;
  Color? background;
  List<TextSpan> spans = [];

  void parse(String s) {
    spans = [];
    var state = TEXT;
    StringBuffer buffer = StringBuffer();
    var text = StringBuffer();
    var code = 0;
    List<int> codes = [];

    for (var i = 0, n = s.length; i < n; i++) {
      var c = s[i];

      switch (state) {
        case TEXT:
          if (c == '\u001b') {
            state = BRACKET;
            buffer = StringBuffer(c);
            code = 0;
            codes = [];
          } else {
            text.write(c);
          }
          break;

        case BRACKET:
          buffer.write(c);
          if (c == '[') {
            state = CODE;
          } else {
            state = TEXT;
            text.write(buffer);
          }
          break;

        case CODE:
          buffer.write(c);
          var codeUnit = c.codeUnitAt(0);
          if (codeUnit >= 48 && codeUnit <= 57) {
            code = code * 10 + codeUnit - 48;
            continue;
          } else if (c == ';') {
            codes.add(code);
            code = 0;
            continue;
          } else {
            if (text.isNotEmpty) {
              spans.add(createSpan(text.toString()));
              text.clear();
            }
            state = TEXT;
            if (c == 'm') {
              codes.add(code);
              handleCodes(codes);
            } else {
              text.write(buffer);
            }
          }

          break;
      }
    }

    spans.add(createSpan(text.toString()));
  }

  void handleCodes(List<int> codes) {
    if (codes.isEmpty) {
      codes.add(0);
    }

    switch (codes[0]) {
      case 0:
        foreground = getColor(0, true);
        background = getColor(0, false);
        break;
      case 38:
        foreground = getColor(codes[2], true);
        break;
      case 39:
        foreground = getColor(0, true);
        break;
      case 48:
        background = getColor(codes[2], false);
        break;
      case 49:
        background = getColor(0, false);
    }
  }

  Color? getColor(int colorCode, bool foreground) {
    switch (colorCode) {
      case 0:
        return foreground ? Colors.black : Colors.transparent;
      case 12:
        return dark ? Colors.lightBlue[300] : Colors.indigo[700];
      case 208:
        return dark ? Colors.orange[300] : Colors.orange[700];
      case 196:
        return dark ? Colors.red[300] : Colors.red[700];
      case 199:
        return dark ? Colors.pink[300] : Colors.pink[700];
      //TODO: check default color
      default:
        return foreground ? Colors.black : Colors.transparent;
    }
  }

  TextSpan createSpan(String text) {
    return TextSpan(
      text: text,
      style: TextStyle(
        color: foreground,
        backgroundColor: background,
      ),
    );
  }
}
