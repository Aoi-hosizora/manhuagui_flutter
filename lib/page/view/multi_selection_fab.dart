import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class MultiSelectionFabOption {
  const MultiSelectionFabOption({
    required this.child,
    this.tooltip,
    this.show = true,
    required this.onPressed,
  });

  final Widget child;
  final String? tooltip;
  final bool show;
  final VoidCallback onPressed;
}

/// 用于多选列表的 Fab 容器，在 [HistorySubPage]、[DownloadPage]、[DlFinishedSubPage]、[DlUnfinishedSubPage] 使用
class MultiSelectionFabContainer extends StatelessWidget {
  const MultiSelectionFabContainer({
    Key? key,
    required this.fabForNormal,
    required this.multiSelectableController,
    this.counterTooltip = '当前选中的内容',
    this.onCounterPressed,
    required this.fabForMultiSelection,
  }) : super(key: key);

  final Widget fabForNormal;
  final MultiSelectableController<ValueKey<int>> multiSelectableController;
  final String? counterTooltip;
  final VoidCallback? onCounterPressed;
  final List<MultiSelectionFabOption> fabForMultiSelection;

  static void showCounterDialog(
    BuildContext context, {
    required MultiSelectableController<ValueKey<int>> controller,
    required List<String> selected,
    required Iterable<ValueKey<int>> allKeys,
  }) {
    showDialog(
      context: context,
      builder: (c) => SimpleDialog(
        title: Text('已选中 ${selected.length} 项'),
        children: [
          IconTextDialogOption(
            icon: Icon(Icons.select_all),
            text: Text('全选'),
            onPressed: () {
              Navigator.of(c).pop();
              controller.select(allKeys);
            },
          ),
          if (selected.isNotEmpty)
            IconTextDialogOption(
              icon: Icon(MdiIcons.selectSearch),
              text: Text('查看已选择项'),
              onPressed: () {
                Navigator.of(c).pop();
                showDialog(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: Text('已选中 ${selected.length} 项'),
                    scrollable: true,
                    content: Text([for (int i = 0; i < selected.length; i++) '${i + 1}. ${selected[i]}'].join('\n')),
                    actions: [TextButton(child: Text('确定'), onPressed: () => Navigator.of(c).pop())],
                  ),
                );
              },
            ),
          if (selected.isNotEmpty)
            IconTextDialogOption(
              icon: Icon(MdiIcons.selectOff),
              text: Text('取消选择'),
              onPressed: () {
                Navigator.of(c).pop();
                controller.exitMultiSelectionMode();
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget wrapTooltipTheme({required Widget child}) => TooltipTheme(
          data: Theme.of(context).tooltipTheme.copyWith(
                verticalOffset: -16,
                margin: EdgeInsets.only(right: 68),
              ),
          child: child,
        );

    return Stack(
      alignment: AlignmentDirectional.bottomEnd,
      children: [
        // normal mode
        // => hide normal fab when multiSelecting with animation
        // ScrollAnimatedFab.condition: !_msController.multiSelecting ? ScrollAnimatedCondition.direction : ScrollAnimatedCondition.custom
        // ScrollAnimatedFab.customBehavior: (_) => false
        fabForNormal,

        // multi selection mode
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // multi selection actions
            for (var opt in fabForMultiSelection)
              Padding(
                padding: EdgeInsets.only(bottom: kMiniButtonOffsetAdjustment),
                child: AnimatedFab(
                  show: multiSelectableController.multiSelecting && opt.show,
                  fab: wrapTooltipTheme(
                    child: FloatingActionButton(
                      child: opt.child,
                      mini: true,
                      heroTag: null,
                      tooltip: opt.tooltip,
                      onPressed: opt.onPressed,
                    ),
                  ),
                ),
              ),

            // multi selection counter
            Padding(
              padding: EdgeInsets.only(bottom: kFloatingActionButtonMargin),
              child: AnimatedFab(
                show: multiSelectableController.multiSelecting,
                fab: wrapTooltipTheme(
                  child: FloatingActionButton(
                    child: Text(multiSelectableController.selectedItems.length.toString()),
                    mini: true,
                    heroTag: null,
                    tooltip: counterTooltip,
                    onPressed: () => onCounterPressed?.call(),
                  ),
                ),
              ),
            ),

            // exit multi selection mode
            AnimatedFab(
              show: multiSelectableController.multiSelecting,
              fab: FloatingActionButton(
                child: Icon(Icons.close),
                heroTag: null,
                onPressed: () => multiSelectableController.exitMultiSelectionMode(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class CheckboxForSelectableItem extends StatelessWidget {
  const CheckboxForSelectableItem({
    Key? key,
    required this.tip,
    required this.backgroundColor,
    this.scale,
    this.scaleAlignment = Alignment.bottomRight,
  }) : super(key: key);

  final SelectableItemTip tip;
  final Color backgroundColor;
  final double? scale;
  final AlignmentGeometry scaleAlignment;

  @override
  Widget build(BuildContext context) {
    var checkbox = Container(
      color: backgroundColor,
      child: Checkbox(
        value: tip.isSelected,
        onChanged: (v) => tip.toToggle?.call(),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
      ),
    );

    if (scale == null) {
      return checkbox;
    }
    return Transform.scale(
      scale: scale!,
      alignment: scaleAlignment,
      child: checkbox,
    );
  }
}
