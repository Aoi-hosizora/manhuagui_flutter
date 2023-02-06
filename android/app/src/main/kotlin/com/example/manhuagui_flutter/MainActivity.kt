package com.example.manhuagui_flutter

import android.content.Intent
import android.net.Uri
import androidx.core.app.ShareCompat
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import java.io.File
import io.flutter.plugin.common.MethodChannel.Result as MethodResult


class MainActivity : FlutterActivity(), MethodCallHandler {
    companion object {
        private const val CHANNEL = "com.aoihosizora.manhuagui"
        private const val RESTART_APP_METHOD = "restartApp"
        private const val INSERT_MEDIA_METHOD = "insertMedia"
        private const val SHARE_TEXT_METHOD = "shareText"
        private const val SHARE_FILE_METHOD = "shareFile"
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
                intent.data = Uri.fromFile(File(filepath))
                sendBroadcast(intent)
                result.success(true)
            }

            SHARE_TEXT_METHOD -> {
                // https://github.com/lubritto/flutter_share/blob/master/android/src/main/java/com/example/fluttershare/FlutterSharePlugin.java
                val shareSubject = call.argument<Any>("shareSubject")?.toString() ?: ""
                val shareText = call.argument<Any>("shareText")?.toString() ?: ""
                val chooserTitle = call.argument<Any>("chooserTitle")?.toString() ?: ""
                ShareCompat.IntentBuilder.from(this)
                        .setSubject(shareSubject)
                        .setText(shareText)
                        .setChooserTitle(chooserTitle)
                        .setType("text/plain")
                        .startChooser()
                result.success(true)
            }

            SHARE_FILE_METHOD -> {
                // https://github.com/lubritto/flutter_share/blob/master/android/src/main/java/com/example/fluttershare/FlutterSharePlugin.java
                // https://github.com/lubritto/flutter_share/issues/9
                // https://www.cnblogs.com/BobGo/archive/2021/09/29/15321483.html
                // https://stackoverflow.com/questions/63723656/share-content-permission-denial-when-using-intent-createchooser
                val shareSubject = call.argument<Any>("shareSubject")?.toString() ?: ""
                val shareText = call.argument<Any>("shareText")?.toString() ?: ""
                val chooserTitle = call.argument<Any>("chooserTitle")?.toString() ?: ""
                val filepath = call.argument<Any>("filepath")?.toString() ?: ""
                val fileType = call.argument<Any>("fileType")?.toString() ?: "*/*"
                val fileUri = FileProvider.getUriForFile(context, context.applicationContext.packageName + ".provider", File(filepath))
                ShareCompat.IntentBuilder.from(this)
                        .setSubject(shareSubject)
                        .setText(shareText)
                        .setChooserTitle(chooserTitle)
                        .setType(fileType)
                        .setStream(fileUri)
                        .startChooser()
                result.success(true)
            }

            else -> result.notImplemented()
        }
    }
}
