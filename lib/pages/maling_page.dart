import 'package:estore_app/blocs/maling_bloc.dart';
import 'package:estore_app/constants.dart';
import 'package:estore_app/global.dart';
import 'package:estore_app/order/order_utils.dart';
import 'package:estore_app/widgets/space.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MalingPage extends StatefulWidget {
  @override
  _MalingPageState createState() => _MalingPageState();
}

class _MalingPageState extends State<MalingPage> with SingleTickerProviderStateMixin {
  //抹零业务逻辑处理
  MalingBloc _malingBloc;

  //GridView布局和实际数字之间差
  int offset = 1;

  @override
  void initState() {
    super.initState();

    _malingBloc = BlocProvider.of<MalingBloc>(context);
    assert(this._malingBloc != null);

    _malingBloc.add(LoadDataEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomPadding: false, //输入框抵住键盘
      backgroundColor: Constants.hexStringToColor("#656472"),
      body: BlocListener<MalingBloc, MalingState>(
        cubit: this._malingBloc,
        listener: (context, state) {},
        child: BlocBuilder<MalingBloc, MalingState>(
          cubit: this._malingBloc,
          buildWhen: (previousState, currentState) {
            return true;
          },
          builder: (context, state) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Container(
                    padding: Constants.paddingAll(20),
                    height: double.infinity,
                    width: double.infinity,
                    color: Constants.hexStringToColor("#F0F0F0"),
                    child: GridView.builder(
                      itemCount: 16,
                      shrinkWrap: true,
                      physics: AlwaysScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: Constants.getAdapterWidth(10),
                        crossAxisSpacing: Constants.getAdapterHeight(10),
                        childAspectRatio: Constants.getAdapterWidth(400) / Constants.getAdapterHeight(200),
                      ),
                      itemBuilder: (context, index) {
                        var selected = index == ((state.malingRule == null || state.malingRule == 0) ? 0 : state.malingRule + offset);

                        Widget widget;

                        switch (index) {
                          case 0:
                            widget = _buildMaling(index, "不抹零", "系统实款实收", selected);
                            break;
                          case 2:
                            widget = _buildMaling(index, "四舍五入到元", "例：18.10→18.00", selected);
                            break;
                          case 3:
                            widget = _buildMaling(index, "向下抹零到元", "例：18.80→18.00", selected);
                            break;
                          case 4:
                            widget = _buildMaling(index, "向上抹零到元", "例：18.10→19.00", selected);
                            break;
                          case 5:
                            widget = _buildMaling(index, "四舍五入到角", "例：18.18→18.20", selected);
                            break;
                          case 6:
                            widget = _buildMaling(index, "向下抹零到角", "例：18.12→18.10", selected);
                            break;
                          case 7:
                            widget = _buildMaling(index, "向上抹零到角", "例：18.12→18.20", selected);
                            break;
                          case 8:
                            widget = _buildMaling(index, "向下抹零到5角", "例：18.80→18.50", selected);
                            break;
                          case 9:
                            widget = _buildMaling(index, "向上抹零到5角", "例：18.80→19.00", selected);
                            break;
                          case 10:
                            widget = _buildMaling(index, "向下抹零到5元", "例：18.80→15.00", selected);
                            break;
                          case 11:
                            widget = _buildMaling(index, "向下抹零到10元", "例：18.80→10.00", selected);
                            break;
                          case 12:
                            widget = _buildMaling(index, "向下抹零到100元", "例：118.80→100.00", selected);
                            break;
                          default:
                            widget = Container();
                            break;
                        }
                        return widget;
                      },
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  height: Constants.getAdapterHeight(100),
                  padding: Constants.paddingAll(10),
                  color: Constants.hexStringToColor("#FFFFFF"),
                  child: FlatButton(
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
                      this._malingBloc.add(SaveMalingConfig(state.malingRule));
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  ///构建抹零可选项
  Widget _buildMaling(int index, String title, String subTitle, bool selected) {
    var backgroundColor = selected ? Constants.hexStringToColor("#F8F7FF") : Constants.hexStringToColor("#FFFFFF");
    var borderColor = selected ? Constants.hexStringToColor("#7A73C7") : Constants.hexStringToColor("#D0D0D0");
    var titleColor = selected ? Constants.hexStringToColor("#7A73C7") : Constants.hexStringToColor("#333333");
    var subTitleColor = selected ? Constants.hexStringToColor("#7A73C7") : Constants.hexStringToColor("#999999");
    return InkWell(
      onTap: () {
        int malingRule = index > 0 ? index - offset : 0;

        ///选择抹零方式
        this._malingBloc.add(SelectMalingConfig(malingRule));

        OrderUtils.instance.calculateMaling(18.49);
        OrderUtils.instance.calculateMaling(18.59);
      },
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: borderColor, width: 1.0),
          borderRadius: BorderRadius.all(Radius.circular(4.0)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              "$title",
              style: TextStyles.getTextStyle(fontSize: 28, color: titleColor),
            ),
            Space(height: Constants.getAdapterHeight(12)),
            Text(
              "$subTitle",
              style: TextStyles.getTextStyle(fontSize: 20, color: subTitleColor),
            ),
          ],
        ),
      ),
    );
  }
}
