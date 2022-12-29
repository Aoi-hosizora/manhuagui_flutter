import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';

class MultiSelectionFabOption {
  const MultiSelectionFabOption({
    required this.child,
    required this.onPressed,
  });

  final Widget child;
  final VoidCallback onPressed;
}

/// 用于多选列表的 Fab 容器，在 [HistorySubPage]、[DownloadPage]、[DlFinishedSubPage]、[DlUnfinishedSubPage] 使用
class MultiSelectionFabContainer extends StatelessWidget {
  const MultiSelectionFabContainer({
    Key? key,
    required this.fabForNormal,
    required this.multiSelectableController,
    this.onCounterPressed,
    required this.fabForMultiSelection,
  }) : super(key: key);

  final Widget fabForNormal;
  final MultiSelectableController multiSelectableController;
  final VoidCallback? onCounterPressed;
  final List<MultiSelectionFabOption> fabForMultiSelection;

  static void showSelectedItemsDialogForCounter(BuildContext context, List<String> items) {
    if (items.isEmpty) {
      return;
    }
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('已选中 ${items.length} 项'),
        content: Text([for (int i = 0; i < items.length; i++) '${i + 1}. ${items[i]}'].join('\n')),
        actions: [TextButton(child: Text('确定'), onPressed: () => Navigator.of(c).pop())],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  show: multiSelectableController.multiSelecting,
                  fab: FloatingActionButton(
                    child: opt.child,
                    mini: true,
                    heroTag: null,
                    onPressed: opt.onPressed,
                  ),
                ),
              ),

            // multi selection counter
            Padding(
              padding: EdgeInsets.only(bottom: kFloatingActionButtonMargin),
              child: AnimatedFab(
                show: multiSelectableController.multiSelecting,
                fab: FloatingActionButton(
                  child: Text(multiSelectableController.selectedItems.length.toString()),
                  mini: true,
                  heroTag: null,
                  onPressed: () => onCounterPressed?.call(),
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
