package io.bednar.qrencoder

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.os.Bundle
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Two things the framework cannot do by itself:
 *
 * - The macOS build writes the PNG straight onto NSPasteboard. Android's
 *   clipboard only carries a URI to a file an app may read, so the same channel
 *   caches the image behind a FileProvider and puts that URI on the clipboard.
 * - Share sheets deliver text as an Intent, so the app registers for text/plain
 *   and hands whatever arrives to the editor, at launch or while running.
 */
class MainActivity : FlutterActivity() {
    private var pendingText: String? = null
    private var shareChannel: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        pendingText = sharedText(intent)
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "qrencoder/clipboard")
            .setMethodCallHandler { call, result ->
                if (call.method != "setPng") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val bytes = call.arguments as? ByteArray
                if (bytes == null) {
                    result.error("bad-image", "expected PNG bytes", null)
                    return@setMethodCallHandler
                }
                try {
                    val dir = File(cacheDir, "clipboard").apply { mkdirs() }
                    val file = File(dir, "qrencoder.png")
                    file.writeBytes(bytes)
                    val uri = FileProvider.getUriForFile(
                        this,
                        "$packageName.clipboard",
                        file,
                    )
                    val clip = ClipData.newUri(contentResolver, "QREncoder symbol", uri)
                    val manager =
                        getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                    manager.setPrimaryClip(clip)
                    result.success(null)
                } catch (error: Exception) {
                    result.error("clipboard", error.message, null)
                }
            }

        val shares = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "qrencoder/share")
        shares.setMethodCallHandler { call, result ->
            if (call.method != "consume") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            result.success(pendingText)
            pendingText = null
        }
        shareChannel = shares
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val text = sharedText(intent) ?: return
        val channel = shareChannel
        if (channel == null) {
            pendingText = text
        } else {
            channel.invokeMethod("onText", text)
        }
    }

    /** The text of a share, or null for a normal launch. */
    private fun sharedText(intent: Intent?): String? {
        if (intent == null || intent.action != Intent.ACTION_SEND) return null
        if (!intent.type.orEmpty().startsWith("text/")) return null
        return intent.getStringExtra(Intent.EXTRA_TEXT)
            ?.trim()
            ?.takeIf { it.isNotEmpty() }
    }
}
