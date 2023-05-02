package com.example.manhuagui_flutter

import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
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
        private const val SHARE_FILES_METHOD = "shareFiles"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodResult) {
        when (call.method) {
            RESTART_APP_METHOD -> restartApp(call, result)
            INSERT_MEDIA_METHOD -> insertMedia(call, result)
            SHARE_TEXT_METHOD -> shareText(call, result)
            SHARE_FILE_METHOD -> shareFile(call, result)
            SHARE_FILES_METHOD -> shareFiles(call, result)
            else -> result.notImplemented()
        }
    }

    // TODO waifu2x bytearray

    private fun restartApp(@Suppress("UNUSED_PARAMETER") call: MethodCall, result: MethodResult) {
        // https://github.com/gabrimatic/restart_app/blob/master/android/src/main/kotlin/gabrimatic/info/restart/RestartPlugin.kt

        val component = (context.packageManager.getLaunchIntentForPackage(context.packageName))!!.component
        val intent = Intent.makeRestartActivityTask(component)
        context.startActivity(intent)
        Runtime.getRuntime().exit(0)
        result.success(true)
    }

    private fun insertMedia(call: MethodCall, result: MethodResult) {
        // https://github.com/CarnegieTechnologies/gallery_saver/blob/master/android/src/main/kotlin/carnegietechnologies/gallery_saver/FileUtils.kt
        // https://github.com/hui-z/image_gallery_saver/blob/master/android/src/main/kotlin/com/example/imagegallerysaver/ImageGallerySaverPlugin.kt
        // https://developer.android.com/training/camera/photobasics#TaskGallery
        val filepath = call.argument<Any>("filepath")?.toString() ?: ""

        @Suppress("DEPRECATION")
        val intent = Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE)
        intent.data = Uri.fromFile(File(filepath))
        sendBroadcast(intent)
        result.success(true)
    }

    private fun shareText(call: MethodCall, result: MethodResult) {
        // https://github.com/lubritto/flutter_share/blob/master/android/src/main/java/com/example/fluttershare/FlutterSharePlugin.java
        // https://github.com/fluttercommunity/plus_plugins/blob/main/packages/share_plus/share_plus/android/src/main/kotlin/dev/fluttercommunity/plus/share/Share.kt
        // https://developer.android.com/training/sharing/send
        // https://developer.android.com/reference/androidx/core/app/ShareCompat.IntentBuilder
        val shareText: String = call.argument<Any>("shareText")?.toString() ?: ""
        val shareTitle: String? = call.argument<Any>("shareTitle")?.toString() // nullable
        val chooserTitle: String? = call.argument<Any>("chooserTitle")?.toString() // nullable

        val intent = Intent(Intent.ACTION_SEND).apply {
            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_NEW_TASK)
            type = "text/plain"
            putExtra(Intent.EXTRA_TEXT, shareText)
            putExtra(Intent.EXTRA_TITLE, shareTitle)
        }
        val chooserIntent = Intent.createChooser(intent, chooserTitle)
        context.startActivity(chooserIntent)
        result.success(true)
    }

    private fun shareFile(call: MethodCall, result: MethodResult) {
        // https://github.com/lubritto/flutter_share/issues/9
        // https://developer.android.com/training/secure-file-sharing/share-file#GrantPermissions
        // https://www.cnblogs.com/BobGo/archive/2021/09/29/15321483.html
        // https://stackoverflow.com/questions/67327522/sharing-a-url-with-image-preview-data-sharesheet
        val filepath: String = call.argument<Any>("filepath")?.toString() ?: ""
        val fileType: String = call.argument<Any>("fileType")?.toString() ?: "*/*"
        val shareText: String? = call.argument<Any>("shareText")?.toString() // nullable
        val shareTitle: String? = call.argument<Any>("shareTitle")?.toString() // nullable
        val chooserTitle: String? = call.argument<Any>("chooserTitle")?.toString() // nullable

        val fileUri = FileProvider.getUriForFile(context, context.applicationContext.packageName + ".provider", File(filepath))
        val intent = Intent(Intent.ACTION_SEND).apply {
            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_NEW_TASK)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            setDataAndType(fileUri, fileType)
            putExtra(Intent.EXTRA_TEXT, shareText)
            putExtra(Intent.EXTRA_TITLE, shareTitle) // maybe useless
            putExtra(Intent.EXTRA_STREAM, fileUri)
        }
        val chooserIntent = Intent.createChooser(intent, chooserTitle)
        @Suppress("DEPRECATION")
        context.packageManager.queryIntentActivities(chooserIntent, PackageManager.MATCH_DEFAULT_ONLY).forEach { resolveInfo ->
            context.grantUriPermission(resolveInfo.activityInfo.packageName, fileUri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        context.startActivity(chooserIntent)
        result.success(true)
    }

    private fun shareFiles(call: MethodCall, result: MethodResult) {
        // https://github.com/fluttercommunity/plus_plugins/blob/main/packages/share_plus/share_plus/android/src/main/kotlin/dev/fluttercommunity/plus/share/Share.kt#L85
        val filepaths: List<String> = call.argument<List<String>>("filepaths") ?: listOf()
        val fileType: String = call.argument<Any>("fileType")?.toString() ?: "*/*"
        val shareText: String? = call.argument<Any>("shareText")?.toString() // nullable
        val shareTitle: String? = call.argument<Any>("shareTitle")?.toString() // nullable
        val chooserTitle: String? = call.argument<Any>("chooserTitle")?.toString() // nullable

        if (filepaths.isEmpty()) {
            result.success(true)
            return
        }
        val fileUris = arrayListOf<Uri>()
        filepaths.forEach { filepath ->
            fileUris.add(FileProvider.getUriForFile(context, context.applicationContext.packageName + ".provider", File(filepath)))
        }

        val intent = if (fileUris.size == 1) {
            Intent(Intent.ACTION_SEND).apply {
                addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_NEW_TASK)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                setDataAndType(fileUris.first(), fileType)
                putExtra(Intent.EXTRA_TEXT, shareText)
                putExtra(Intent.EXTRA_TITLE, shareTitle) // maybe useless
                putExtra(Intent.EXTRA_STREAM, fileUris.first())
            }
        } else {
            Intent(Intent.ACTION_SEND_MULTIPLE).apply {
                addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_NEW_TASK)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                type = fileType
                putExtra(Intent.EXTRA_TEXT, shareText)
                putExtra(Intent.EXTRA_TITLE, shareTitle) // maybe useless
                putParcelableArrayListExtra(Intent.EXTRA_STREAM, fileUris)
            }
        }
        val chooserIntent = Intent.createChooser(intent, chooserTitle)
        @Suppress("DEPRECATION")
        context.packageManager.queryIntentActivities(chooserIntent, PackageManager.MATCH_DEFAULT_ONLY).forEach { resolveInfo ->
            fileUris.forEach { fileUri -> context.grantUriPermission(resolveInfo.activityInfo.packageName, fileUri, Intent.FLAG_GRANT_READ_URI_PERMISSION) }
        }
        context.startActivity(chooserIntent)
        result.success(true)
    }
}
