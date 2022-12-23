import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';

/// 用于多选列表的 Fab 容器，在 [HistorySubPage] 使用
class MultiSelectionFabContainer extends StatelessWidget {
  const MultiSelectionFabContainer({
    Key? key,
    required this.fabForNormal,
    required this.multiSelectableController,
    required this.fabForMultiSelection,
  }) : super(key: key);

  final Widget fabForNormal;
  final MultiSelectableController multiSelectableController;
  final List<Tuple2<Widget, VoidCallback>> fabForMultiSelection;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: AlignmentDirectional.bottomEnd,
      children: [
        // normal mode
        // ScrollAnimatedFab(
        //   // ...
        //   condition: !_msController.multiSelecting ? ScrollAnimatedCondition.direction : ScrollAnimatedCondition.custom,
        // )
        fabForNormal,

        // multi selection mode
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // multi selection actions
            for (var tup in fabForMultiSelection)
              Padding(
                padding: EdgeInsets.only(bottom: kMiniButtonOffsetAdjustment),
                child: AnimatedFab(
                  show: multiSelectableController.multiSelecting,
                  fab: FloatingActionButton(
                    child: tup.item1,
                    mini: true,
                    heroTag: null,
                    onPressed: tup.item2,
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
                  onPressed: () {},
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

class ValueObjectKey<T, U> extends LocalKey {
  const ValueObjectKey(this.value, this.object);

  final T value;

  final U object;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is ValueObjectKey<T, U> && other.value == value; // ignore object
  }

  @override
  int get hashCode => hashValues(runtimeType, value); // ignore object
}
