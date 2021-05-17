import 'package:estore_app/blocs/download_bloc.dart';
import 'package:estore_app/constants.dart';
import 'package:estore_app/global.dart';
import 'package:estore_app/i18n/i18n.dart';
import 'package:estore_app/routers/navigator_utils.dart';
import 'package:estore_app/routers/router_manager.dart';
import 'package:estore_app/utils/device_utils.dart';
import 'package:estore_app/utils/image_utils.dart';
import 'package:estore_app/widgets/load_image.dart';
import 'package:estore_app/widgets/space.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DownloadPage extends StatefulWidget {
  @override
  _DownloadPageState createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  //程序版本
  String appVersion = "1.0.0";

  //下载逻辑处理
  DownloadBloc _downloadBloc;

  @override
  void initState() {
    super.initState();

    initPlatformState();

    _downloadBloc = BlocProvider.of<DownloadBloc>(context);
    assert(_downloadBloc != null);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _downloadBloc.add(Ready());
    });
  }

  /// Initialize platform state.
  Future<void> initPlatformState() async {
    if (!mounted) return;

    appVersion = await DeviceUtils.instance.getAppVersion();
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context);
    assert(local != null);

    return Scaffold(
      resizeToAvoidBottomPadding: false,
      body: BlocListener<DownloadBloc, DownloadState>(
        cubit: this._downloadBloc,
        listener: (context, state) {
          if (state.status == DownloadStatus.Finished) {
            NavigatorUtils.instance.push(context, RouterManager.HOME_PAGE, replace: true);
          }
        },
        child: BlocBuilder<DownloadBloc, DownloadState>(
          cubit: this._downloadBloc,
          buildWhen: (previousState, currentState) {
            return true;
          },
          builder: (context, state) {
            return Container(
              padding: Constants.paddingAll(0),
              decoration: BoxDecoration(
                color: Constants.hexStringToColor("#FFFFFF"),
                image: DecorationImage(image: AssetImage(ImageUtils.getImgPath("download/background", format: "jpg")), fit: BoxFit.cover),
              ),
              child: Center(
                child: Container(
                  padding: Constants.paddingLTRB(25, 25, 25, 0),
                  width: Constants.getAdapterWidth(700),
                  height: Constants.getAdapterHeight(400),
                  decoration: ShapeDecoration(
                    color: Constants.hexStringToColor("#FFFFFF"),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(6.0),
                      ),
                    ),
                  ),
                  child: Column(
                    children: <Widget>[
                      Center(
                        child: LoadAssetImage("brand_logo", format: "png", height: Constants.getAdapterHeight(58), width: Constants.getAdapterWidth(200), fit: BoxFit.fill),
                      ),
                      Space(height: Constants.getAdapterHeight(16)),
                      Center(
                        child: Text(
                          "V$appVersion",
                          style: TextStyles.getTextStyle(fontSize: 32, color: Constants.hexStringToColor("#3385FF")),
                        ),
                      ),
                      Space(height: Constants.getAdapterHeight(29)),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          "${(state.processValue * 100).toStringAsFixed(2)}%",
                          style: TextStyles.getTextStyle(fontSize: 28, color: Constants.hexStringToColor("#333333")),
                        ),
                      ),
                      Space(height: Constants.getAdapterHeight(14)),
                      SizedBox(
                        height: Constants.getAdapterHeight(32),
                        child: ClipRRect(
                          borderRadius: BorderRadius.all(Radius.circular(16.0)),
                          child: LinearProgressIndicator(
                            value: state.processValue,
                            backgroundColor: Constants.hexStringToColor("#F0F0F0"),
                            valueColor: AlwaysStoppedAnimation<Color>(Constants.hexStringToColor("#3385FF")),
                          ),
                        ),
                      ),
                      Space(height: Constants.getAdapterHeight(29)),
                      Row(
                        children: <Widget>[
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "${state.message}",
                              style: TextStyles.getTextStyle(fontSize: 28, color: Constants.hexStringToColor("#333333")),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
