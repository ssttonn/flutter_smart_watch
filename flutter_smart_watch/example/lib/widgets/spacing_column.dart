import 'package:flutter/material.dart';
import 'package:flutter_smart_watch_example/extensions.dart';

class SpacingColumn extends Column {
  SpacingColumn(
      {super.key,
      super.mainAxisAlignment,
      super.mainAxisSize,
      super.crossAxisAlignment,
      super.textDirection,
      super.verticalDirection,
      super.textBaseline,
      required List<Widget> children,
      double spacing = 0})
      : super(
            children: spacing > 0
                ? children.addBetweenItems(SizedBox(height: spacing))
                : children);
}
