package io.juwei.app;

import io.flutter.app.FlutterApplication;
import io.flutter.view.FlutterMain;
import io.juwei.Logger;
import io.juwei.utils.SafeAreaUtils;

public class MainApplication extends FlutterApplication {
    @Override
    public void onCreate() {
        super.onCreate();
        FlutterMain.startInitialization(this);

        Logger.info("Android Native Load Finished");
    }
}
