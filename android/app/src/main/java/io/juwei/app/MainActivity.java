package io.juwei.app;

import android.app.Activity;
import android.content.Context;
import android.content.res.Resources;
import android.graphics.Color;
import android.graphics.drawable.Drawable;
import android.os.Build;
import android.os.Bundle;
import android.os.PersistableBundle;
import android.view.View;
import android.view.ViewGroup;
import android.view.ViewTreeObserver;
import android.view.Window;
import android.view.WindowManager;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.RequiresApi;
import androidx.core.content.ContextCompat;

import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.List;

import io.flutter.embedding.android.DrawableSplashScreen;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.android.FlutterView;
import io.flutter.embedding.android.SplashScreen;
import io.flutter.plugins.GeneratedPluginRegistrant;
import io.juwei.Logger;
import io.juwei.plugins.CommonPlugin;
import io.juwei.printer.sunmi.SunmiPrinterPlugin;

public class MainActivity extends FlutterActivity {


    @Override
    public void onCreate(@Nullable Bundle savedInstanceState, @Nullable PersistableBundle persistentState) {
        super.onCreate(savedInstanceState, persistentState);


//        setStatusBarTransparent();
//        View flutterView = findViewByType(FlutterView.class);
//        this.hideBottomUI(flutterView);


    }

    @Override
    protected void onStart() {
        super.onStart();

    }


    @Override
    protected void onResume() {
        super.onResume();

//        setStatusBarTransparent();
//        View flutterView = findViewByType(FlutterView.class);
//        this.hideBottomUI(flutterView);

//        setAutoHideBottomBar(this,1000);
    }


    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine);

        //注册系统依赖插件
        flutterEngine.getPlugins().add(new CommonPlugin());

        //注册商米打印插件
        SunmiPrinterPlugin.registerWith(this,this.getFlutterEngine().getDartExecutor());
    }

    @Override
    public SplashScreen provideSplashScreen() {
        Drawable splash = ContextCompat.getDrawable(this.getContext(),R.drawable.launch_background);
        return new DrawableSplashScreen(splash);
    }

//    private View findViewByType(Class<? extends View> viewType) {
//        View selectedView = getWindow().getDecorView().getRootView();//findViewById(0x01020002);
//        List<View> viewQueue = new ArrayList<>();
//
//        while (selectedView != null && !selectedView.getClass().equals(viewType)) {
//            if (selectedView instanceof ViewGroup) {
//                ViewGroup selectedViewGroup = (ViewGroup) selectedView;
//                for (int i = 0; i < selectedViewGroup.getChildCount(); ++i) {
//                    viewQueue.add(selectedViewGroup.getChildAt(i));
//                }
//            }
//
//            if (!viewQueue.isEmpty()) {
//                selectedView = viewQueue.remove(0);
//            } else {
//                selectedView = null;
//            }
//        }
//
//        return selectedView;
//    }

//    public void hideBottomUI(View view) {
//        int uiFlags = View.SYSTEM_UI_FLAG_LAYOUT_STABLE
//                | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
//                | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
//                | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION // hide nav bar
//                | View.SYSTEM_UI_FLAG_FULLSCREEN; // hide status bar
//
//        if( android.os.Build.VERSION.SDK_INT >= 19 ){
//            uiFlags |= View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY;    //View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY: hide navigation bars - compatibility: building API level is lower thatn 19, use magic number directly for higher API target level
//        } else {
//            uiFlags |= View.SYSTEM_UI_FLAG_LOW_PROFILE;
//        }
//        view.setSystemUiVisibility(uiFlags);
//    }
//
//    /**
//     * 设置透明状态栏
//     */
//    private void setStatusBarTransparent() {
//        Window window = getWindow();
//        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
//            window.clearFlags(WindowManager.LayoutParams.FLAG_TRANSLUCENT_STATUS);
//            window.getDecorView().setSystemUiVisibility(View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
//                    | View.SYSTEM_UI_FLAG_LAYOUT_STABLE);
//            window.addFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS);
//            window.setStatusBarColor(Color.TRANSPARENT);
//        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
//            window.addFlags(WindowManager.LayoutParams.FLAG_TRANSLUCENT_STATUS);
//        }
//    }

    @RequiresApi(api = Build.VERSION_CODES.CUPCAKE)
    public void setAutoHideBottomBar(final Activity activity, final long time){
        try {
            if (Build.VERSION.SDK_INT >= 19) {
                //透明导航栏
                activity.getWindow().addFlags(WindowManager.LayoutParams.FLAG_TRANSLUCENT_NAVIGATION);//透明导航栏，就是下面三个虚拟按钮
                //透明状态栏
                activity.getWindow().addFlags(WindowManager.LayoutParams.FLAG_TRANSLUCENT_STATUS);
            }
            if(checkDeviceHasNavigationBar(activity)){
                hideBottomUIMenu(activity);
            }

            final View view = activity.getWindow().getDecorView();
            view.getViewTreeObserver().addOnGlobalLayoutListener(new ViewTreeObserver.OnGlobalLayoutListener() {
                @Override
                public void onGlobalLayout() {
                    try {
                        if(checkDeviceHasNavigationBar(activity))
                            view.postDelayed(new Runnable() {
                                @Override
                                public void run() {
                                    hideBottomUIMenu(activity);
                                }
                            }, time);
                    }catch (Exception e){
                        e.printStackTrace();
                    }catch (Error e){
                        e.printStackTrace();
                    }
                }
            });
        }catch (Exception e){
            e.printStackTrace();
        }catch (Error e){
            e.printStackTrace();
        }
    }
    @RequiresApi(api = Build.VERSION_CODES.CUPCAKE)
    public boolean checkDeviceHasNavigationBar(Context context) {
        try {
            boolean hasNavigationBar = false;
            Resources rs = context.getResources();
            int id = rs.getIdentifier("config_showNavigationBar", "bool", "android");
            if (id > 0) {
                hasNavigationBar = rs.getBoolean(id);
            }
            try {
                Class systemPropertiesClass = Class.forName("android.os.SystemProperties");
                Method m = systemPropertiesClass.getMethod("get", String.class);
                String navBarOverride = (String) m.invoke(systemPropertiesClass, "qemu.hw.mainkeys");
                if ("1".equals(navBarOverride)) {
                    hasNavigationBar = false;
                } else if ("0".equals(navBarOverride)) {
                    hasNavigationBar = true;
                }
            } catch (Exception e) {

            }
            return hasNavigationBar;

        }catch (Exception e){
            e.printStackTrace();
        }catch (Error e){
            e.printStackTrace();
        }
        return false;
    }
    public void hideBottomUIMenu(Activity activity) {
        try {
            //隐藏虚拟按键，并且全屏
            if (Build.VERSION.SDK_INT > 11 && Build.VERSION.SDK_INT < 19) { // lower api
                View v = activity.getWindow().getDecorView();
                v.setSystemUiVisibility(View.GONE);
            } else if (Build.VERSION.SDK_INT >= 19) {
                //for new api versions.
                View decorView = activity.getWindow().getDecorView();
                int uiOptions = 0x00000002
                        | 0x00001000 | 0x00000004;
                decorView.setSystemUiVisibility(uiOptions);
            }
        }catch (Exception e){
            e.printStackTrace();
        }catch (Error e){
            e.printStackTrace();
        }
    }
}
