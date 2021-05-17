import 'dart:async';

import 'package:flutter/material.dart';

/// Spinner Input like HTML5 spinners
class SpinnerButtonStyle {
  Color color;

  Color textColor;
  Widget child;
  double width;
  double height;
  BorderRadius borderRadius;
  double highlightElevation;
  Color highlightColor;
  double elevation;

  SpinnerButtonStyle({this.color, this.textColor, this.child, this.width, this.height, this.borderRadius, this.highlightElevation, this.highlightColor, this.elevation});
}

class SpinnerInput extends StatefulWidget {
  final double spinnerValue;
  final double middleNumberWidth;
  final EdgeInsets middleNumberPadding;
  final TextStyle middleNumberStyle;
  final Color middleNumberBackground;
  final double minValue;
  final double maxValue;
  final double step;
  final int fractionDigits;
  final Duration longPressSpeed;
  final Function(double newValue) onChange;
  final bool disabledLongPress;
  final SpinnerButtonStyle plusButton;
  final SpinnerButtonStyle minusButton;
  final SpinnerButtonStyle popupButton;
  final TextStyle popupTextStyle;
  final TextDirection direction;

  SpinnerInput({
    @required this.spinnerValue,
    this.middleNumberWidth,
    this.middleNumberBackground,
    this.middleNumberPadding = const EdgeInsets.all(5),
    this.middleNumberStyle = const TextStyle(fontSize: 20),
    this.maxValue: 100,
    this.minValue: 0,
    this.step: 1,
    this.fractionDigits: 0,
    this.longPressSpeed: const Duration(milliseconds: 50),
    this.disabledLongPress = false,
    this.onChange,
    this.plusButton,
    this.minusButton,
    this.popupButton,
    this.direction = TextDirection.ltr,
    this.popupTextStyle = const TextStyle(fontSize: 18, color: Colors.black87, height: 1.15),
  });

  @override
  _SpinnerInputState createState() => _SpinnerInputState();
}

class _SpinnerInputState extends State<SpinnerInput> with TickerProviderStateMixin {
  TextEditingController textEditingController;
  final _focusNode = FocusNode();

  Timer timer;
  double _spinnerValue;

  SpinnerButtonStyle _plusSpinnerStyle;
  SpinnerButtonStyle _minusSpinnerStyle;
  SpinnerButtonStyle _popupButtonStyle;

  @override
  void initState() {
    /// initializing variables
    _spinnerValue = widget.spinnerValue;

    /// popup textfield
    textEditingController = TextEditingController(text: widget.spinnerValue.toStringAsFixed(widget.fractionDigits));
    textEditingController.addListener(() {});

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        textEditingController.selection = TextSelection(baseOffset: 0, extentOffset: textEditingController.value.text.length);
      }
    });

    // initialize buttons
    _plusSpinnerStyle = widget.plusButton ?? SpinnerButtonStyle();
    _plusSpinnerStyle.child ??= Icon(Icons.add);
    _plusSpinnerStyle.color ??= Color(0xff9EA8F0);
    _plusSpinnerStyle.textColor ??= Colors.white;
    _plusSpinnerStyle.borderRadius ??= BorderRadius.circular(50);
    _plusSpinnerStyle.width ??= 35;
    _plusSpinnerStyle.height ??= 35;
    _plusSpinnerStyle.elevation ??= null;
    _plusSpinnerStyle.highlightColor ??= null;
    _plusSpinnerStyle.highlightElevation ??= null;

    _minusSpinnerStyle = widget.minusButton ?? SpinnerButtonStyle();
    _minusSpinnerStyle.child ??= Icon(Icons.remove);
    _minusSpinnerStyle.color ??= Color(0xff9EA8F0);
    _minusSpinnerStyle.textColor ??= Colors.white;
    _minusSpinnerStyle.borderRadius ??= BorderRadius.circular(50);
    _minusSpinnerStyle.width ??= 35;
    _minusSpinnerStyle.height ??= 35;
    _minusSpinnerStyle.elevation ??= null;
    _minusSpinnerStyle.highlightColor ??= null;
    _minusSpinnerStyle.highlightElevation ??= null;

    _popupButtonStyle = widget.popupButton ?? SpinnerButtonStyle();
    _popupButtonStyle.child ??= Icon(Icons.check);
    _popupButtonStyle.color ??= Colors.lightGreen;
    _popupButtonStyle.textColor ??= Colors.white;
    _popupButtonStyle.borderRadius ??= BorderRadius.circular(5);
    _popupButtonStyle.width ??= 35;
    _popupButtonStyle.height ??= 35;
    _popupButtonStyle.elevation ??= null;
    _popupButtonStyle.highlightColor ??= null;
    _popupButtonStyle.highlightElevation ??= null;

    super.initState();
  }

  @override
  void dispose() {
    // Clean up the controller when the Widget is removed from the Widget tree
    textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ///zhangy 2020-01-10 直接修改数量后，重新赋值
    _spinnerValue = widget.spinnerValue;

    return Directionality(
      textDirection: widget.direction,
      child: Stack(
        children: <Widget>[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: _minusSpinnerStyle.width,
                height: _minusSpinnerStyle.height,
                child: GestureDetector(
                  child: RaisedButton(
                    padding: EdgeInsets.all(0),
                    color: _minusSpinnerStyle.color,
                    textColor: _minusSpinnerStyle.textColor,
                    elevation: _minusSpinnerStyle.elevation,
                    highlightColor: _minusSpinnerStyle.highlightColor,
                    highlightElevation: _minusSpinnerStyle.highlightElevation,
                    shape: new RoundedRectangleBorder(borderRadius: _minusSpinnerStyle.borderRadius),
                    onPressed: () {
                      decrease();
                    },
                    child: _minusSpinnerStyle.child,
                  ),
                  onLongPress: () {
                    if (widget.disabledLongPress == false) {
                      timer = Timer.periodic(widget.longPressSpeed, (timer) {
                        decrease();
                      });
                    }
                  },
                  onLongPressUp: () {
                    if (timer != null) timer.cancel();
                  },
                ),
              ),
              Container(
                width: widget.middleNumberWidth,
                padding: widget.middleNumberPadding,
                color: widget.middleNumberBackground,
                child: Text(
                  widget.spinnerValue.toStringAsFixed(widget.fractionDigits),
                  textAlign: TextAlign.center,
                  style: widget.middleNumberStyle,
                ),
              ),
              Container(
                width: _plusSpinnerStyle.width,
                height: _plusSpinnerStyle.height,
                child: GestureDetector(
                  child: RaisedButton(
                    elevation: _plusSpinnerStyle.elevation,
                    highlightColor: _plusSpinnerStyle.highlightColor,
                    highlightElevation: _plusSpinnerStyle.highlightElevation,
                    padding: EdgeInsets.all(0),
                    color: _plusSpinnerStyle.color,
                    textColor: _plusSpinnerStyle.textColor,
                    shape: new RoundedRectangleBorder(borderRadius: _plusSpinnerStyle.borderRadius),
                    onPressed: () {
                      increase();
                    },
                    child: _plusSpinnerStyle.child,
                  ),
                  onLongPress: () {
                    if (widget.disabledLongPress == false) {
                      timer = Timer.periodic(widget.longPressSpeed, (timer) {
                        increase();
                      });
                    }
                  },
                  onLongPressUp: () {
                    if (timer != null) timer.cancel();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void increase() {
    double value = _spinnerValue;
    value += widget.step;
    if (value <= widget.maxValue) {
      textEditingController.text = value.toStringAsFixed(widget.fractionDigits);
      _spinnerValue = value;
      setState(() {
        widget.onChange(value);
      });
    }
  }

  void decrease() {
    double value = _spinnerValue;
    value -= widget.step;
    if (value >= widget.minValue) {
      textEditingController.text = value.toStringAsFixed(widget.fractionDigits);
      _spinnerValue = value;
      setState(() {
        widget.onChange(value);
      });
    }
  }
}