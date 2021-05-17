import 'package:community_material_icon/community_material_icon.dart';
import 'package:estore_app/blocs/download_bloc.dart';
import 'package:estore_app/callbacks.dart';
import 'package:estore_app/constants.dart';
import 'package:estore_app/global.dart';
import 'package:estore_app/utils/device_utils.dart';
import 'package:estore_app/widgets/load_image.dart';
import 'package:estore_app/widgets/space.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FastDownloadPage extends StatefulWidget {
  final OnAcceptCallback onAccept;
  final OnCloseCallback onClose;

  FastDownloadPage({this.onAccept, this.onClose});

  @override
  _FastDownloadPageState createState() => _FastDownloadPageState();
}

class _FastDownloadPageState extends State<FastDownloadPage> with SingleTickerProviderStateMixin {
  //下载逻辑处理
  DownloadBloc _downloadBloc;

  @override
  void initState() {
    super.initState();

    initPlatformState();

    _downloadBloc = BlocProvider.of<DownloadBloc>(context);
    assert(_downloadBloc != null);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _downloadBloc.add(Initial());
    });
  }

  /// Initialize platform state.
  Future<void> initPlatformState() async {
    if (!mounted) return;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DownloadBloc, DownloadState>(
      cubit: this._downloadBloc,
      listener: (context, state) {
        if (state.status == DownloadStatus.Finished) {
          if (widget.onAccept != null) {
            var args = FastDownloadArgs();
            widget.onAccept(args);
          }
        }
      },
      child: BlocBuilder<DownloadBloc, DownloadState>(
        cubit: this._downloadBloc,
        buildWhen: (previousState, currentState) {
          return true;
        },
        builder: (context, state) {
          return Material(
            color: Colors.transparent,
            child: Container(
              padding: Constants.paddingAll(0),
              child: Center(
                child: Container(
                  padding: Constants.paddingLTRB(5, 5, 5, 5),
                  width: Constants.getAdapterWidth(700),
                  height: Constants.getAdapterHeight(500),
                  decoration: ShapeDecoration(
                    color: Constants.hexStringToColor("#FFFFFF"),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(6.0))),
                  ),
                  child: Column(
                    children: <Widget>[
                      ///顶部标题
                      //_buildHeader(),

                      ///中部操作区
                      _buildContent(state),

                      ///底部操作区
                      _buildFooter(),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  ///构建内容区域
  Widget _buildContent(DownloadState state) {
    return Expanded(
      child: Container(
        padding: Constants.paddingLTRB(25, 25, 25, 28),
        height: Constants.getAdapterHeight(510),
        width: double.infinity,
        color: Constants.hexStringToColor("#FFFFFF"),
        child: Column(
          children: <Widget>[
            Center(
              child: LoadAssetImage("brand_logo", format: "png", height: Constants.getAdapterHeight(58), width: Constants.getAdapterWidth(200), fit: BoxFit.fill),
            ),
            Space(height: Constants.getAdapterHeight(10)),
            Center(
              child: Text(
                "v${Global.instance.appVersion}",
                style: TextStyles.getTextStyle(fontSize: 32, color: Constants.hexStringToColor("#3385FF")),
              ),
            ),
            Space(height: Constants.getAdapterHeight(25)),
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
    );
  }

  ///构建底部工具栏
  Widget _buildFooter() {
    return Container(
      height: Constants.getAdapterHeight(100),
      padding: Constants.paddingLTRB(0, 14, 0, 16),
      decoration: BoxDecoration(
        color: Constants.hexStringToColor("#FFFFFF"),
        border: Border(top: BorderSide(width: 0, color: Constants.hexStringToColor("#999999"))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          FlatButton(
            child: Container(
              width: Constants.getAdapterWidth(120),
              height: Constants.getAdapterHeight(50),
              alignment: Alignment.center,
              child: Text("全部下载", style: TextStyles.getTextStyle(fontSize: 28, color: Color(0xFFFFFFFF))),
            ),
            color: Color(0xFF7A73C7),
            disabledColor: Colors.grey,
            shape: RoundedRectangleBorder(
              side: BorderSide.none,
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
            onPressed: () {
              _downloadBloc.add(Ready(fullDownload: true));
            },
          ),
          Space(
            width: Constants.getAdapterWidth(30),
          ),
          FlatButton(
            child: Container(
              width: Constants.getAdapterWidth(120),
              height: Constants.getAdapterHeight(50),
              alignment: Alignment.center,
              child: Text("增量下载", style: TextStyles.getTextStyle(fontSize: 28, color: Color(0xFFFFFFFF))),
            ),
            color: Color(0xFF7A73C7),
            disabledColor: Colors.grey,
            shape: RoundedRectangleBorder(
              side: BorderSide.none,
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
            onPressed: () {
              _downloadBloc.add(Ready(fullDownload: false));
            },
          ),
          Space(
            width: Constants.getAdapterWidth(30),
          ),
          FlatButton(
            child: Container(
              width: Constants.getAdapterWidth(120),
              height: Constants.getAdapterHeight(50),
              alignment: Alignment.center,
              child: Text("退出", style: TextStyles.getTextStyle(fontSize: 28, color: Color(0xFF333333))),
            ),
            color: Color(0xFFD0D0D0),
            disabledColor: Colors.grey,
            shape: RoundedRectangleBorder(
              side: BorderSide.none,
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
            onPressed: () {
              if (widget.onClose != null) {
                widget.onClose();
              }
            },
          ),
        ],
      ),
    );
  }
}
