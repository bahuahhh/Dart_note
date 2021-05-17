import 'dart:ui';

import 'package:estore_app/global.dart';
import 'package:flutter/material.dart';

///CheckBox组件
///zhangy 2019-10-01 add
class CheckBox extends StatefulWidget {
  final bool checked;
  final bool enabled;
  final ValueChanged<bool> onChanged;
  final String text;
  final Size size;
  final Color activeColor;
  final Color disabledColor;
  final Color textColor;
  final double fontSize;
  final FontWeight fontWeight;
  final dynamic value;

  CheckBox({
    this.checked = false,
    this.onChanged,
    this.text,
    this.enabled = true,
    this.activeColor = Colors.blue,
    this.textColor = Colors.black,
    this.disabledColor = Colors.grey,
    this.fontSize = 22,
    this.fontWeight = FontWeight.normal,
    this.size = const Size(24, 24),
    this.value,
  });

  @override
  _CheckboxState createState() => _CheckboxState();
}

class _CheckboxState extends State<CheckBox> {
  void setValue() {
    if (!isDisabled) {
      widget.onChanged(!widget.checked);
    }
  }

  ///是否禁用状态
  bool get isDisabled => (widget.enabled != null && !widget.enabled);

  @override
  Widget build(BuildContext context) {
    ///CheckBox框样式
    Widget res = _CheckBoxContainer(
      color: (isDisabled ? widget.disabledColor : widget.activeColor),
      checked: widget.checked,
      size: widget.size,
    );

    //如果定义文本内容
    if (widget.text != null) {
      res = Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          res,
          Padding(
            padding: EdgeInsets.only(left: 8),
            child: Text(
              widget.text,
              style: TextStyles.getTextStyle(
                color: (isDisabled ? widget.disabledColor : widget.textColor),
                fontSize: widget.fontSize,
                fontWeight: widget.fontWeight,
              ),
            ),
          )
        ],
      );
    }

    return GestureDetector(
      onTapUp: (_) => setValue(),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: res,
      ),
    );
  }
}

class _CheckBoxContainer extends StatelessWidget {
  final bool checked;
  final Color color;
  final Size size;

  _CheckBoxContainer({this.checked, this.color, this.size});

  @override
  Widget build(BuildContext context) {
    if (checked != null && checked) {
      return Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
        child: AspectRatio(
          aspectRatio: 1,
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: CustomPaint(
              foregroundPainter: _DashPainter(Colors.white),
            ),
          ),
        ),
      );
    }
    return Container(
      width: size.width,
      height: size.height,
      decoration: BoxDecoration(
        border: Border.all(
          color: color,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  final Color color;

  _DashPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    Paint line = new Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width / 7;
    double cX = size.width / 2;
    double cY = size.height / 2;
    Path dashPath = Path()
      ..moveTo(cX * 0.5, cY * 0.95)
      ..lineTo(cX * 0.85, cY * 1.3)
      ..lineTo(cX * 1.5, cY * 0.7);
    canvas.drawPath(dashPath, line);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
