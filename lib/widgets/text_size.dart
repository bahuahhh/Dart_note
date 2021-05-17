import 'dart:ui';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

// final textHeight = 'text'.height(constrainedWidth: 200, context: context);
// final textSpanHeight = TextSpan(text: 'text').height(200);
// final textSpanListHeight = textSpanList.height(constrainedWidth: 200, context: context);

extension TextSize on String {
  Size size(final TextStyle style, final BuildContext context) {
    return (TextPainter(text: TextSpan(text: this, style: style), textScaleFactor: MediaQuery.of(context).textScaleFactor, textDirection: TextDirection.ltr)..layout()).size;
  }

  double height({final double constrainedWidth, final BuildContext context}) {
    return [TextSpan(text: this)].height(constrainedWidth: constrainedWidth, context: context);
  }
}

extension TextSpanSize on TextSpan {
  double height(final double constrainedWidth) {
    final constraints = BoxConstraints(maxWidth: constrainedWidth);
    RenderParagraph renderParagraph = RenderParagraph(this, textDirection: TextDirection.ltr);
    renderParagraph.layout(constraints);
    return renderParagraph.getMaxIntrinsicHeight(constrainedWidth);
  }
}

extension TextSpanListSize on Iterable<TextSpan> {
  double height({final double constrainedWidth, final BuildContext context}) {
    final constraints = BoxConstraints(maxWidth: constrainedWidth);
    final singleSpan = TextSpan(style: DefaultTextStyle.of(context).style, children: this.toList());
    RenderParagraph renderParagraph = RenderParagraph(singleSpan, textDirection: TextDirection.ltr);
    renderParagraph.layout(constraints);
    return renderParagraph.getMaxIntrinsicHeight(constrainedWidth);
  }
}
