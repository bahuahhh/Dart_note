package io.juwei.printer.sunmi;

import android.content.Context;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import org.json.JSONObject;
import android.util.Base64;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.Executors;

import io.flutter.plugin.common.BasicMessageChannel;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.JSONMessageCodec;
import io.juwei.Logger;


public class SunmiPrinterPlugin implements BasicMessageChannel.MessageHandler<Object>, BasicMessageChannel.Reply<Object>{

    public static final String CHANNEL_NAME = "io.juwei.app/sunmi_printer_plugin";

    private Context context;
    private BasicMessageChannel<Object> messageChannel;

    //打印机是否已经初始化
    public static boolean inited = false;

    public static SunmiPrinterPlugin registerWith(Context outerContext, BinaryMessenger binaryMessenger) {
        return new SunmiPrinterPlugin(outerContext,binaryMessenger);
    }

    private SunmiPrinterPlugin(Context outerContext,BinaryMessenger binaryMessenger) {
        this.context = outerContext;
        this.messageChannel = new BasicMessageChannel<>(binaryMessenger, CHANNEL_NAME, JSONMessageCodec.INSTANCE);
        //如果想要接收来自dart的消息，调用 setMessageHandler 来设置一个消息处理器
        this.messageChannel.setMessageHandler(this);

    }

    @Override
    public void onMessage(@Nullable Object message, @NonNull BasicMessageChannel.Reply<Object> reply) {

        Map<String, Object> response = new HashMap<>();

        try{
            if(message instanceof JSONObject){
                //Dart传递过来的对象
                JSONObject obj = (JSONObject) message;
                String action = obj.getString("action");
                Logger.info(action);
                switch (action){
                    case "init":{
                        //初始化打印机
                        if(!inited){
                            inited = init();
                        }

                        response.put("code", "00");
                        response.put("message", "成功");
                        response.put("data", new HashMap<String, Object>());

                        Logger.info("打印机初始化" + (inited ? "成功":"失败"));
                    }
                    break;
                    case "reinit":{
                        //初始化打印机
                        inited = reinit();

                        response.put("code", "00");
                        response.put("message", "成功");
                        response.put("data", new HashMap<String, Object>());

                        Logger.info("打印机初始化" + (inited ? "成功":"失败"));
                    }
                    break;
                    case "printRawData":{

                        JSONObject args = obj.getJSONObject("args");
                        String rawData = args.getString("data");

                        Executors.newSingleThreadExecutor().execute(new Runnable() {
                            @Override
                            public void run() {
                                try {
                                    byte [] bytes = Base64.decode(rawData, Base64.DEFAULT);

                                    SunmiPrintHelper.getInstance().sendRawData(bytes);

                                } catch (Exception e) {
                                    e.printStackTrace();
                                }
                            }
                        });

                    }
                    break;
                }
            }else{
                response.put("code", "999");
                response.put("message", "无法识别的数据类型");
                response.put("data", new HashMap<String, Object>());
                reply.reply(response);
            }
        }catch (Exception ex){
            ex.printStackTrace();
        }
    }

    private boolean init(){
        boolean result = false;
        try{
            SunmiPrintHelper.getInstance().initSunmiPrinterService(context);
            result = true;
        }catch (Exception ex){
            ex.printStackTrace();
            result = false;
        }
        return result;
    }


    private boolean reinit(){
        boolean result = false;
        try{
            SunmiPrintHelper.getInstance().deInitSunmiPrinterService(context);
            result = true;
        }catch (Exception ex){
            ex.printStackTrace();
            result = false;
        }
        return result;
    }

    @Override
    public void reply(@Nullable Object reply) {

    }
}
