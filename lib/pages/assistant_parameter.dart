import 'package:estore_app/constants.dart';
import 'package:estore_app/global.dart';
import 'package:estore_app/utils/toast_utils.dart';
import 'package:estore_app/widgets/space.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AssistantParameter extends StatefulWidget {
  @override
  _AssistantParameterState createState() => _AssistantParameterState();
}

class _AssistantParameterState extends State<AssistantParameter> with SingleTickerProviderStateMixin {
  //输入框
  final FocusNode _focus = FocusNode();
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((callback) {
      final text = Global.instance.globalConfigStringValue(ConfigConstant.ASSISTANT_PARAMETER);
      _controller.value = _controller.value.copyWith(
        text: text,
        //selection: TextSelection(baseOffset: 0, extentOffset: text.length),
        //composing: TextRange.empty,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomPadding: false, //输入框抵住键盘
      backgroundColor: Constants.hexStringToColor("#F0F0F0"),
      body: Container(
        padding: Constants.paddingSymmetric(vertical: 20, horizontal: 40),
        color: Constants.hexStringToColor("#F0F0F0"),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "设置收银主机的IP和端口",
                style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#444444"), fontSize: 32, fontWeight: FontWeight.bold),
              ),
            ),
            Space(
              height: Constants.getAdapterHeight(30),
            ),
            _buildInputBox(),
            Space(
              height: Constants.getAdapterHeight(30),
            ),
            FlatButton(
              child: Container(
                alignment: Alignment.center,
                child: Text("保存", style: TextStyles.getTextStyle(fontSize: 28, color: Constants.hexStringToColor("#FFFFFF"))),
              ),
              color: Constants.hexStringToColor("#7A73C7"),
              disabledColor: Colors.grey,
              shape: RoundedRectangleBorder(
                side: BorderSide.none,
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
              onPressed: () async {
                var inputValue = _controller.text;
                var regexp = new RegExp(r'^((25[0-5]|2[0-4]\d|((1\d{2})|([1-9]?\d)))\.){3}(25[0-5]|2[0-4]\d|((1\d{2})|([1-9]?\d)))$');
                if (regexp.hasMatch(inputValue)) {
                  var saveResult = await Global.instance.saveConfig(ConfigConstant.ASSISTANT_GROUP, ConfigConstant.ASSISTANT_PARAMETER, inputValue);
                  if (saveResult) {
                    ToastUtils.show("保存成功");
                  } else {
                    ToastUtils.show("保存失败");
                  }
                } else {
                  ToastUtils.show("非法的IP地址");
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  ///构建参数输入框
  Widget _buildInputBox() {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: Constants.getAdapterHeight(70),
      ),
      child: TextFormField(
        enabled: true,
        autofocus: false,
        controller: _controller,
        focusNode: _focus,
        // controller: TextEditingController.fromValue(
        //   TextEditingValue(
        //     text: "${state.currentPrinter.ipAddress}",
        //     selection: TextSelection.fromPosition(TextPosition(affinity: TextAffinity.downstream, offset: '${state.currentPrinter.ipAddress}'.length)),
        //   ),
        // ),
        textAlign: TextAlign.start,
        style: TextStyles.getTextStyle(fontSize: 28),
        decoration: InputDecoration(
          contentPadding: Constants.paddingSymmetric(horizontal: 15),
          hintText: "请输入参数或者点击搜索",
          hintStyle: TextStyles.getTextStyle(color: Constants.hexStringToColor("#999999"), fontSize: 28),
          filled: true,
          fillColor: Constants.hexStringToColor("#FFFFFF"),
          disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(0)), borderSide: BorderSide(color: Colors.transparent, width: 0.0)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(0)), borderSide: BorderSide(color: Colors.transparent, width: 0.0)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(0)), borderSide: BorderSide(color: Colors.transparent, width: 0.0)),
        ),
        inputFormatters: <TextInputFormatter>[
          LengthLimitingTextInputFormatter(24) //限制长度
        ],
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        textInputAction: TextInputAction.done,
        maxLines: 1,
        enableInteractiveSelection: false, //长按复制 剪切
        autocorrect: false,
        onChanged: (value) {
          //this._printerBloc.add(PrinterParameter(ipAddress: value));
        },
      ),
    );
  }
}
