import 'package:flutter/material.dart';

// Positioned.directional(
// top: Constants.getAdapterHeight(-4),
// end: Constants.getAdapterWidth(2),
// width: Constants.getAdapterWidth(200),
// height: Constants.getAdapterHeight(200),
// textDirection: TextDirection.ltr,
// child: CustomPaint(
// painter: VerticalText(
// text: "空桌台",
// textStyle: TextStyles.getTextStyle(
// color: Constants.hexStringToColor("#999999"),
// fontSize: 20,
// ),
// width: Constants.getAdapterWidth(200),
// height: Constants.getAdapterHeight(200),
// ),
// ),
// ),

// 垂直布局的文字. 从右上开始排序到左下角.
class VerticalText extends CustomPainter {
  String text;
  double width;
  double height;
  TextStyle textStyle;

  VerticalText({@required this.text, @required this.textStyle, @required this.width, @required this.height});

  @override
  void paint(Canvas canvas, Size size) {
    var paint = new Paint();
    paint.color = textStyle.color;
    double offsetX = width;
    double offsetY = 0;
    bool newLine = true;
    double maxWidth = 0;

    maxWidth = findMaxWidth(text, textStyle);

    text.runes.forEach((rune) {
      String str = new String.fromCharCode(rune);
      TextSpan span = new TextSpan(style: textStyle, text: str);
      TextPainter tp = new TextPainter(text: span, textAlign: TextAlign.center, textDirection: TextDirection.ltr);
      tp.layout();

      if (offsetY + tp.height > height) {
        newLine = true;
        offsetY = 0;
      }

      if (newLine) {
        offsetX -= maxWidth;
        newLine = false;
      }

      if (offsetX < -maxWidth) {
        return;
      }

      tp.paint(canvas, new Offset(offsetX, offsetY));
      offsetY += tp.height;
    });
  }

  double findMaxWidth(String text, TextStyle style) {
    double maxWidth = 0;

    text.runes.forEach((rune) {
      String str = new String.fromCharCode(rune);
      TextSpan span = new TextSpan(style: style, text: str);
      TextPainter tp = new TextPainter(text: span, textAlign: TextAlign.center, textDirection: TextDirection.ltr);
      tp.layout();
      maxWidth = max(maxWidth, tp.width);
    });

    return maxWidth;
  }

  @override
  bool shouldRepaint(VerticalText oldDelegate) {
    return oldDelegate.text != text || oldDelegate.textStyle != textStyle || oldDelegate.width != width || oldDelegate.height != height;
  }

  double max(double a, double b) {
    if (a > b) {
      return a;
    } else {
      return b;
    }
  }
}
