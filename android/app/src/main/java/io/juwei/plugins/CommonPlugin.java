package io.juwei.plugins;

import android.content.Context;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.juwei.Logger;
import io.juwei.utils.DesUtils;
import io.juwei.utils.DesX;

///通用插件
public class CommonPlugin implements MethodChannel.MethodCallHandler, FlutterPlugin {

    public static final String CHANNEL_NAME = "io.juwei.app/common_plugin";

    private Context applicationContext;
    private MethodChannel methodChannel;

    public CommonPlugin() {}

    private void onAttachedToEngine(Context applicationContext, BinaryMessenger messenger) {
        this.applicationContext = applicationContext;
        methodChannel = new MethodChannel(messenger, CHANNEL_NAME);
        methodChannel.setMethodCallHandler(this);
    }

    @Override
    public void onAttachedToEngine(FlutterPluginBinding binding) {
        onAttachedToEngine(binding.getApplicationContext(), binding.getBinaryMessenger());
    }

    @Override
    public void onDetachedFromEngine(FlutterPluginBinding binding) {
        applicationContext = null;
        methodChannel.setMethodCallHandler(null);
        methodChannel = null;
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        try{
            switch (call.method) {
                case "getPlatformVersion":
                {
                    result.success("Android " + android.os.Build.VERSION.RELEASE);
                }
                break;
                case "getTransferEncryptString":
                {
                    String body = call.argument("data");
                    if (body != null && body.length() > 0) {
                        String encryptString = DesUtils.getInstance().EncryptString(body);
                        result.success(encryptString);
                    } else {
                        result.success("");
                    }
                }
                break;
                case "getTransferDecryptString":
                {
                    String body = call.argument("data");
                    if(body != null && body.length() > 0){
                        String decryptString = DesUtils.getInstance().DecryptString(body);
                        result.success(decryptString);
                    }else{
                        result.success("");
                    }
                }
                break;
                default:
                    result.notImplemented();
                    break;
            }
        }catch(Exception ex){
            Logger.error("CommonPlugin插件发生异常",ex);
        }

    }
}
