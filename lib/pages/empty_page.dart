import 'package:estore_app/constants.dart';
import 'package:estore_app/global.dart';
import 'package:estore_app/routers/navigator_utils.dart';
import 'package:estore_app/widgets/cashier_vertical_tabs.dart';
import 'package:flutter/material.dart';

class EmptyPage extends StatefulWidget {
  @override
  _EmptyPageState createState() => _EmptyPageState();
}

class _EmptyPageState extends State<EmptyPage> with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomPadding: false, //输入框抵住键盘
      backgroundColor: Constants.hexStringToColor("#656472"),
      body: Container(
        padding: Constants.paddingAll(0),
        decoration: BoxDecoration(
          color: Constants.hexStringToColor("#656472"),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: Constants.paddingAll(0),
              height: Constants.getAdapterHeight(90.0),
              decoration: BoxDecoration(
                color: Constants.hexStringToColor("#FFFFFF"),
                border: Border(bottom: BorderSide(color: Constants.hexStringToColor("#F2F2F2"), width: 1)),
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => NavigatorUtils.instance.goBack(context),
                    child: SizedBox(
                      width: Constants.getAdapterWidth(90),
                      height: double.infinity,
                      child: Icon(Icons.arrow_back_ios, size: Constants.getAdapterWidth(32), color: Constants.hexStringToColor("#2B2B2B")),
                    ),
                  ),
                  Text(
                    "当前门店",
                    style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#383838"), fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CashierVerticalTabs(
                initialIndex: 0,
                tabsWidth: Constants.getAdapterWidth(180),
                tabsHeight: Constants.getAdapterHeight(90),
                backgroundColor: Constants.hexStringToColor("#FFFFFF"),
                tabBackgroundColor: Constants.hexStringToColor("#484752"),
                selectedTabBackgroundColor: Constants.hexStringToColor("#7A73C7"),
                indicatorColor: Colors.green,
                disabledChangePageFromContentView: true,
                changePageDuration: const Duration(milliseconds: 5),
                tabTextStyle: TextStyles.getTextStyle(color: Constants.hexStringToColor("#91939C"), fontSize: 24),
                tabTextAlignment: TabTextAlignment.center,
                selectedTabTextStyle: TextStyles.getTextStyle(color: Constants.hexStringToColor("#FFFFFF"), fontSize: 24),
                //header: buildHeaderBar(),
                //expandTabs: ExpandTabs(tabsWidth: Constants.getAdapterWidth(70)),
                tabs: <TabItem>[
                  TabItem("收银1"),
                  TabItem("收银2"),
                  TabItem("收银3"),
                  TabItem("收银4"),
                ],
                contents: <Widget>[
                  Container(),
                  Container(),
                  Container(),
                  Container(),
                ],
              ),
            ),
            Container(
              height: Constants.getAdapterHeight(120.0),
              decoration: BoxDecoration(
                color: Constants.hexStringToColor("#FFFFFF"),
                border: Border(top: BorderSide(color: Constants.hexStringToColor("#F2F2F2"), width: 1)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
