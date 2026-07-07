package com.awing.awing_ai_learning

import android.app.ActivityManager
import android.content.Context
import android.os.Bundle
import androidx.activity.enableEdgeToEdge
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

// Extends FlutterFragmentActivity (NOT FlutterActivity) so the activity
// inherits from androidx.fragment.app.FragmentActivity → ComponentActivity.
// This is required because the AndroidX `enableEdgeToEdge()` extension
// is only defined on ComponentActivity. FlutterActivity (the default)
// extends android.app.Activity directly, which would fail to resolve.
class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.awing.learning/asset_pack"
    private val DEVICE_CAPABILITY_CHANNEL = "com.awing.learning/device_capability"

    // Android 15 (SDK 35) requires apps to opt into edge-to-edge display.
    // enableEdgeToEdge() is the AndroidX-provided backwards-compatible API
    // that works on Android 5.0+ and silences the Play Console warning
    // "Edge-to-edge may not display for all users". It also handles the
    // deprecated APIs (setStatusBarColor / setNavigationBarColor) that
    // were flagged in the same warning bundle.
    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getAssetPath" -> {
                        // Returns a file:// path to the asset, copying to cache if needed.
                        // Install-time asset packs are merged into the app's AssetManager.
                        val assetPath = call.argument<String>("path") ?: ""
                        try {
                            val cachedFile = copyAssetToCache(assetPath)
                            result.success(cachedFile.absolutePath)
                        } catch (e: Exception) {
                            result.error("ASSET_NOT_FOUND", "Asset not found: $assetPath", e.message)
                        }
                    }
                    "getAssetBytes" -> {
                        // Returns raw bytes of the asset.
                        val assetPath = call.argument<String>("path") ?: ""
                        try {
                            val bytes = assets.open(assetPath).use { it.readBytes() }
                            result.success(bytes)
                        } catch (e: Exception) {
                            result.error("ASSET_NOT_FOUND", "Asset not found: $assetPath", e.message)
                        }
                    }
                    "assetExists" -> {
                        val assetPath = call.argument<String>("path") ?: ""
                        try {
                            assets.open(assetPath).close()
                            result.success(true)
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        // === Device capability channel — Phase C RAM gate ===
        // Returns total + available RAM in MB so the Dart side can decide
        // whether to enable on-device Gemma 3 1B (needs ~1.2 GB free +
        // ~3 GB total device). Kids' phones in Cameroon often have 2-4 GB
        // and we refuse to download the model if the device can't run it.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DEVICE_CAPABILITY_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getMemoryInfo" -> {
                        try {
                            val am = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
                            val info = ActivityManager.MemoryInfo()
                            am.getMemoryInfo(info)
                            val totalMb = info.totalMem / (1024 * 1024)
                            val availMb = info.availMem / (1024 * 1024)
                            val lowMemory = info.lowMemory
                            result.success(mapOf(
                                "totalRamMb" to totalMb,
                                "availableRamMb" to availMb,
                                "lowMemory" to lowMemory,
                                "platform" to "android"
                            ))
                        } catch (e: Exception) {
                            result.error("MEM_INFO_FAILED", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Copy an asset from the AssetManager to the app's cache directory.
     * Returns the cached File. Skips copy if already cached.
     */
    private fun copyAssetToCache(assetPath: String): File {
        val cacheDir = File(cacheDir, "asset_pack_cache")
        val cachedFile = File(cacheDir, assetPath)

        if (cachedFile.exists()) {
            return cachedFile
        }

        cachedFile.parentFile?.mkdirs()

        assets.open(assetPath).use { input ->
            FileOutputStream(cachedFile).use { output ->
                input.copyTo(output)
            }
        }

        return cachedFile
    }
}
