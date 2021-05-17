package io.juwei;

import android.util.Log;

/**
 * 调试日志打印工具类
 *
 * @author 张莹
 */
public class Logger {

    public static void info(String msg) {
        //部分国产机屏蔽了WARN级别以下的日志，故用w代替d/i/v
        Log.w(Constants.LOG_TAG, msg);
    }

    public static void error(String msg, Throwable t) {
        Log.e(Constants.LOG_TAG, msg, t);
    }

}
