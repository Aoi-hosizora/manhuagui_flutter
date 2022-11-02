import 'package:flutter/material.dart';

/// 下载列表页-下载设置

class DlSetting {
  DlSetting({
    required this.defaultToDeleteFiles,
    required this.downloadPagesTogether,
    required this.invertDownloadOrder,
  });

  final bool defaultToDeleteFiles; // 默认删除已下载的文件
  final int downloadPagesTogether; // 同时下载的页面数量
  final bool invertDownloadOrder; // 漫画章节下载顺序

  DlSetting.defaultSetting()
      : this(
          defaultToDeleteFiles: false,
          downloadPagesTogether: 4,
          invertDownloadOrder: false,
        );

  DlSetting copyWith({
    bool? defaultToDeleteFiles,
    int? downloadPagesTogether,
    bool? invertDownloadOrder,
  }) {
    return DlSetting(
      defaultToDeleteFiles: defaultToDeleteFiles ?? this.defaultToDeleteFiles,
      downloadPagesTogether: downloadPagesTogether ?? this.downloadPagesTogether,
      invertDownloadOrder: invertDownloadOrder ?? this.invertDownloadOrder,
    );
  }
}

class DlSettingSubPage extends StatefulWidget {
  const DlSettingSubPage({
    Key? key,
    required this.setting,
    required this.onSettingChanged,
  }) : super(key: key);

  final DlSetting setting;
  final void Function(DlSetting) onSettingChanged;

  @override
  State<DlSettingSubPage> createState() => _DlSettingSubPageState();
}

class _DlSettingSubPageState extends State<DlSettingSubPage> {
  late var _defaultToDeleteFiles = widget.setting.defaultToDeleteFiles;
  late var _downloadPagesTogether = widget.setting.downloadPagesTogether;
  late var _invertDownloadOrder = widget.setting.invertDownloadOrder;

  DlSetting get _newestSetting => DlSetting(
        defaultToDeleteFiles: _defaultToDeleteFiles,
        downloadPagesTogether: _downloadPagesTogether,
        invertDownloadOrder: _invertDownloadOrder,
      );

  Widget _buildComboBox<T>({
    required String title,
    double width = 120,
    required T value,
    required List<T> values,
    required Widget Function(T) builder,
    required void Function(T) onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodyText1,
        ),
        SizedBox(
          height: 38,
          width: width,
          child: DropdownButton<T>(
            value: value,
            items: values.map((s) => DropdownMenuItem<T>(child: builder(s), value: s)).toList(),
            underline: Container(color: Colors.white),
            isExpanded: true,
            onChanged: (v) {
              if (v != null) {
                onChanged.call(v);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSwitcher({
    required String title,
    required bool value,
    required void Function(bool) onChanged,
    bool enable = true,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodyText1,
        ),
        SizedBox(
          height: 38,
          child: Switch(
            value: value,
            onChanged: enable ? onChanged : null,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSwitcher(
          title: '默认删除已下载的文件　　　　　　',
          value: _defaultToDeleteFiles,
          onChanged: (b) {
            _defaultToDeleteFiles = b;
            widget.onSettingChanged.call(_newestSetting);
            if (mounted) setState(() {});
          },
        ),
        _buildComboBox<int>(
          title: '同时下载的页面数量',
          width: 75,
          value: _downloadPagesTogether.clamp(1, 8),
          values: List.generate(8, (i) => i + 1),
          builder: (s) => Text(
            '$s页',
            style: Theme.of(context).textTheme.bodyText2,
          ),
          onChanged: (c) {
            _downloadPagesTogether = c.clamp(1, 8);
            widget.onSettingChanged.call(_newestSetting);
            if (mounted) setState(() {});
          },
        ),
        _buildComboBox<bool>(
          title: '漫画章节下载顺序',
          value: _invertDownloadOrder,
          values: [false, true],
          builder: (s) => Text(
            !s ? '正序 (旧到新)' : '逆序 (新到旧)',
            style: Theme.of(context).textTheme.bodyText2,
          ),
          onChanged: (c) {
            _invertDownloadOrder = c;
            widget.onSettingChanged.call(_newestSetting);
            if (mounted) setState(() {});
          },
        ),
      ],
    );
  }
}