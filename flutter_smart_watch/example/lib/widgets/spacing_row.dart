import 'package:flutter/material.dart';

import '../extensions.dart';

class SpacingRow extends Row {
  SpacingRow(
      {super.key,
      super.mainAxisAlignment,
      super.mainAxisSize,
      super.crossAxisAlignment,
      super.textDirection,
      super.verticalDirection,
      super.textBaseline, // NO DEFAULT: we don't know what the text's baseline should be
      required List<Widget> children,
      double spacing = 0})
      : super(
            children: spacing > 0
                ? children.addBetweenItems(SizedBox(width: spacing))
                : children);
}
