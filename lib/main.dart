import 'dart:io';
import 'dart:ui';

import 'package:estore_app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ));
    SystemChrome.setEnabledSystemUIOverlays([]);
  }

  runApp(MyApp(
    route: window.defaultRouteName,
  ));
}
