package com.example.manhuagui_flutter

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result as MethodResult
import java.io.File

class MainActivity: FlutterActivity(), MethodCallHandler {
    companion object {
        private const val CHANNEL = "com.aoihosizora.manhuagui"
        private const val RESTART_APP_METHOD = "restartApp"
        private const val INSERT_MEDIA_METHOD = "insertMedia"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodResult) {
        when (call.method) {
            RESTART_APP_METHOD -> {
                // https://github.com/gabrimatic/restart_app/blob/master/android/src/main/kotlin/gabrimatic/info/restart/RestartPlugin.kt
                val component = (context.packageManager.getLaunchIntentForPackage(context.packageName))!!.component
                val intent = Intent.makeRestartActivityTask(component)
                context.startActivity(intent)
                Runtime.getRuntime().exit(0)
                result.success(true)
            }
            INSERT_MEDIA_METHOD -> {
                // https://github.com/CarnegieTechnologies/gallery_saver/blob/master/android/src/main/kotlin/carnegietechnologies/gallery_saver/FileUtils.kt
                // https://github.com/hui-z/image_gallery_saver/blob/master/android/src/main/kotlin/com/example/imagegallerysaver/ImageGallerySaverPlugin.kt
                // https://developer.android.com/training/camera/photobasics#TaskGallery
                val filepath = call.argument<Any>("filepath")?.toString() ?: ""
                val intent = Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE)
                val f = File(filepath)
                intent.data = Uri.fromFile(f)
                sendBroadcast(intent)
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }
}
