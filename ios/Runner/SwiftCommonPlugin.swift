//
//  SwiftCommonPlugin.swift
//  Runner
//
//  Created by 张莹 on 2020/11/14.
//

import Flutter
import UIKit

public class SwiftCommonPlugin: NSObject, FlutterPlugin {
    
    final var DEFAULT_DES_KEY = "$AZKOSS$";
    static var CHANNEL_NAME = "io.juwei.app/common_plugin";
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: CHANNEL_NAME, binaryMessenger: registrar.messenger())
        let instance = SwiftCommonPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
      }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method{
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)
            break
        case "getTransferEncryptString":
            print(call.arguments ?? "null")
            guard let args = call.arguments as? Dictionary<String, String> else {
                result("")
                return
            }
            let body = args["data"]!
            let encryptString = DesX.desStr(text:body, key_1:DEFAULT_DES_KEY,key_2:DEFAULT_DES_KEY,  key_3:DEFAULT_DES_KEY)
            
            result(encryptString)
            break
        case "getTransferDecryptString":
            print(call.arguments ?? "null")
            break
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
