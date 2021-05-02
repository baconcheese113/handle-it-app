package com.handle_it

import android.content.Intent
import android.os.Bundle
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant

private val TAG = MainActivity::class.java.name
private const val CHANNEL_NAME = "samples.flutter.dev/battery"
class MainActivity: FlutterActivity() {
    private var isAlert = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.i(TAG, "onCreate called with intent.action: ${intent.action} & intent.type ${intent.type}")
        if(intent.action == Intent.ACTION_SEND && intent.type != null) {
            if(intent.type == "text/plain") {
                isAlert = intent.getBooleanExtra("isAlert", false)
            }
        }
        val flutterEngine = FlutterEngine(this)
//        GeneratedPluginRegistrant.registerWith(flutterEngine)
        flutterEngine.dartExecutor.executeDartEntrypoint(DartExecutor.DartEntrypoint.createDefault())

        FlutterEngineCache.getInstance().put("1", flutterEngine)

        val channel = MethodChannel(flutterEngine.dartExecutor, CHANNEL_NAME)
        channel.setMethodCallHandler { call, result ->
            result.success(1)
        }
        Log.i(TAG,"onCreate finished")
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        Log.i(TAG, "inside configureFlutterEngine")
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME).setMethodCallHandler { call, result ->
            // Note: this method is invoked on the main thread
            Log.i(TAG, "in callMethod looking for: ${call.method}");
            if (call.method == "getBatteryLevel") {
//                val batteryLevel = getBatteryLevel()
//
//                if (batteryLevel != -1) {
//                } else {
//                    result.error("UNAVAILABLE", "Battery level not available.", null)
//                }
            } else if (call.method == "isAlert") {
                result.success(isAlert)
            } else {
                result.notImplemented()
            }
        }
    }

//    private fun getBatteryLevel(): Int {
//        Log.i(">>BLOOP", "inside getBatteryLevel")
//        val batteryLevel: Int
//        if (VERSION.SDK_INT >= VERSION_CODES.LOLLIPOP) {
//            val batteryManager = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
//            batteryLevel = batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
//        } else {
//            val intent = ContextWrapper(applicationContext).registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
//            batteryLevel = intent!!.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)  * 100 / intent.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
//        }
//
//        return batteryLevel
//    }
}
