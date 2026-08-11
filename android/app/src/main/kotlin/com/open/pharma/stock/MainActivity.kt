package com.open.pharma.stock

import android.content.BroadcastReceiver
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ApplicationInfo
import android.graphics.BitmapFactory
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.provider.MediaStore
import android.util.Log
import android.view.KeyEvent
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageProxy
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.core.content.ContextCompat
import com.google.zxing.BarcodeFormat
import com.google.zxing.BinaryBitmap
import com.google.zxing.DecodeHintType
import com.google.zxing.PlanarYUVLuminanceSource
import com.google.zxing.RGBLuminanceSource
import com.google.zxing.common.HybridBinarizer
import com.google.zxing.datamatrix.DataMatrixReader
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.util.EnumMap
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
  private val channelName = "datamatrix_fallback_decoder"
  private val cameraFallbackChannel = "camera_fallback_scans"
  private val appTourChannelName = "open_pharma_stock/app_tour"
  private val appQaChannelName = "open_pharma_stock/qa"
  private val appBackupChannelName = "open_pharma_stock/backup"
  private val decodeExecutor = Executors.newSingleThreadExecutor()
  private val analysisExecutor = Executors.newSingleThreadExecutor()
  private val mainHandler = Handler(Looper.getMainLooper())
  private var fallbackSink: EventChannel.EventSink? = null
  private var fallbackProvider: ProcessCameraProvider? = null
  private var fallbackAnalysis: ImageAnalysis? = null
  private var lastFallbackAttemptMs: Long = 0
  private var fallbackCooldownUntilMs: Long = 0
  private val fallbackThrottleMs: Long = 750
  private val fallbackSuccessCooldownMs: Long = 2500
  private var isDebug = false
  private var tutorialKeyCaptureEnabled = false
  private var appTourChannel: MethodChannel? = null
  private var appQaChannel: MethodChannel? = null
  private var appBackupChannel: MethodChannel? = null
  private var qaReceiver: BroadcastReceiver? = null

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    isDebug =
        (applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0
    appTourChannel = MethodChannel(
        flutterEngine.dartExecutor.binaryMessenger,
        appTourChannelName,
    ).also { channel ->
      channel.setMethodCallHandler { call, result ->
        if (call.method != "setCaptureEnabled") {
          result.notImplemented()
          return@setMethodCallHandler
        }
        tutorialKeyCaptureEnabled = call.argument<Boolean>("enabled") ?: false
        result.success(null)
      }
    }
    appQaChannel = MethodChannel(
        flutterEngine.dartExecutor.binaryMessenger,
        appQaChannelName,
    )
    appBackupChannel = MethodChannel(
        flutterEngine.dartExecutor.binaryMessenger,
        appBackupChannelName,
    ).also { channel ->
      channel.setMethodCallHandler { call, result ->
        if (call.method != "writeBackupToDownloads") {
          result.notImplemented()
          return@setMethodCallHandler
        }
        val fileName = call.argument<String>("fileName")
        val content = call.argument<String>("content")
        if (fileName.isNullOrBlank() || content == null) {
          result.error("invalid_args", "Missing backup payload.", null)
          return@setMethodCallHandler
        }
        try {
          val path = writeBackupToDownloads(fileName, content)
          result.success(path)
        } catch (error: Exception) {
          result.error("write_failed", error.message, null)
        }
      }
    }
    if (isDebug) {
      registerQaReceiver()
    }
    EventChannel(
        flutterEngine.dartExecutor.binaryMessenger,
        cameraFallbackChannel,
    ).setStreamHandler(
        object : EventChannel.StreamHandler {
          override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
            fallbackSink = events
            startCameraFallback()
          }

          override fun onCancel(arguments: Any?) {
            fallbackSink = null
            stopCameraFallback()
          }
        },
    )
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
      .setMethodCallHandler { call, result ->
        if (call.method != "decode") {
          result.notImplemented()
          return@setMethodCallHandler
        }
        val imageBytes = call.argument<ByteArray>("imageBytes")
        val variant = call.argument<Int>("variant") ?: -1
        if (imageBytes == null || imageBytes.isEmpty()) {
          result.success(null)
          return@setMethodCallHandler
        }
        decodeExecutor.execute {
          Log.i("OPS", "ZXING try variant=$variant bytes=${imageBytes.size}")
          val decoded = decodeDataMatrix(imageBytes)
          if (decoded != null && decoded.isNotEmpty()) {
            Log.i("OPS", "ZXING OK variant=$variant")
          } else {
            Log.d("OPS", "[FALLBACK_FAIL] variant=$variant")
          }
          mainHandler.post { result.success(decoded) }
        }
      }
  }

  private fun registerQaReceiver() {
    if (qaReceiver != null) {
      return
    }
    val action = "${packageName}.QA"
    qaReceiver =
        object : BroadcastReceiver() {
          override fun onReceive(context: Context?, intent: Intent?) {
            val safeIntent = intent ?: return
            val command =
                safeIntent.getStringExtra("command")
                    ?: safeIntent.getStringExtra("cmd")
                    ?: return
            val payload = HashMap<String, Any?>()
            val extras = safeIntent.extras
            payload["command"] = command
            extras?.keySet()?.forEach { key ->
              if (key == "command" || key == "cmd") {
                return@forEach
              }
              payload[key] = extras.get(key)
            }
            mainHandler.post {
              appQaChannel?.invokeMethod("runCommand", payload)
            }
          }
        }
    registerReceiver(qaReceiver, IntentFilter(action))
  }

  override fun dispatchKeyEvent(event: KeyEvent): Boolean {
    if (tutorialKeyCaptureEnabled && event.action == KeyEvent.ACTION_UP) {
      val forwardedMethod =
          when (event.keyCode) {
            KeyEvent.KEYCODE_ENTER,
            KeyEvent.KEYCODE_NUMPAD_ENTER,
            KeyEvent.KEYCODE_DPAD_CENTER,
            KeyEvent.KEYCODE_DPAD_RIGHT,
            KeyEvent.KEYCODE_SPACE -> "next"
            KeyEvent.KEYCODE_DPAD_LEFT -> "previous"
            KeyEvent.KEYCODE_BACK -> "skip"
            else -> null
          }
      if (forwardedMethod != null) {
        mainHandler.post { appTourChannel?.invokeMethod(forwardedMethod, null) }
        return true
      }
    }
    return super.dispatchKeyEvent(event)
  }

  private fun decodeDataMatrix(imageBytes: ByteArray): String? {
    return try {
      val decodedBitmap =
          BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)
              ?: return null
      val width = decodedBitmap.width
      val height = decodedBitmap.height
      if (width <= 0 || height <= 0) {
        return null
      }
      val intPixels = IntArray(width * height)
      decodedBitmap.getPixels(intPixels, 0, width, 0, 0, width, height)
      val source = RGBLuminanceSource(width, height, intPixels)
      attemptDecode(source)
    } catch (e: Exception) {
      if (isDebug) {
        Log.d("OPS", "ZXING decode error", e)
      }
      null
    }
  }

  private fun attemptDecode(source: com.google.zxing.LuminanceSource): String? {
      val reader = DataMatrixReader()
      val hints = EnumMap<DecodeHintType, Any>(DecodeHintType::class.java)
      hints[DecodeHintType.TRY_HARDER] = java.lang.Boolean.TRUE
      hints[DecodeHintType.POSSIBLE_FORMATS] = listOf(BarcodeFormat.DATA_MATRIX)

      try {
          val binaryBitmap = BinaryBitmap(HybridBinarizer(source))
          return reader.decode(binaryBitmap, hints).text
      } catch (e: Exception) {
      }

      try {
          val invertedSource = source.invert()
          val binaryBitmap = BinaryBitmap(HybridBinarizer(invertedSource))
          return reader.decode(binaryBitmap, hints).text
      } catch (e: Exception) {
          return null
      }
  }

  private fun startCameraFallback() {
    if (fallbackSink == null || fallbackAnalysis != null) {
      return
    }
    val providerFuture = ProcessCameraProvider.getInstance(this)
    providerFuture.addListener(
        {
          val provider = providerFuture.get()
          fallbackProvider = provider
          val analysis = ImageAnalysis.Builder()
              .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
              .build()
          analysis.setAnalyzer(analysisExecutor) { imageProxy ->
            analyzeFallbackFrame(imageProxy)
          }
          fallbackAnalysis = analysis
          try {
            provider.bindToLifecycle(
                this,
                CameraSelector.DEFAULT_BACK_CAMERA,
                analysis,
            )
          } catch (e: Exception) {
            if (isDebug) {
              Log.d("OPS", "CAMERA_FALLBACK bind failed", e)
            }
            stopCameraFallback()
          }
        },
        ContextCompat.getMainExecutor(this),
    )
  }

  private fun stopCameraFallback() {
    val provider = fallbackProvider
    val analysis = fallbackAnalysis
    if (provider != null && analysis != null) {
      provider.unbind(analysis)
    }
    fallbackAnalysis = null
  }

  private fun analyzeFallbackFrame(imageProxy: ImageProxy) {
    try {
      if (fallbackSink == null) {
        return
      }
      val now = SystemClock.elapsedRealtime()
      if (now < fallbackCooldownUntilMs) {
        return
      }
      if (now - lastFallbackAttemptMs < fallbackThrottleMs) {
        return
      }
      lastFallbackAttemptMs = now
      if (isDebug) {
        Log.d("OPS", "CAMERA_FALLBACK try")
      }
      val decoded = decodeFromImageProxy(imageProxy)
      if (decoded != null && decoded.isNotEmpty()) {
        Log.i("OPS", "CAMERA_FALLBACK OK len=${decoded.length}")
        fallbackCooldownUntilMs = now + fallbackSuccessCooldownMs
        mainHandler.post { fallbackSink?.success(decoded) }
      }
    } catch (e: Exception) {
      if (isDebug) {
        Log.d("OPS", "CAMERA_FALLBACK error", e)
      }
    } finally {
      imageProxy.close()
    }
  }

  private fun decodeFromImageProxy(imageProxy: ImageProxy): String? {
    val width = imageProxy.width
    val height = imageProxy.height
    if (width <= 0 || height <= 0) {
      return null
    }
    val plane = imageProxy.planes[0]
    val buffer = plane.buffer
    val rowStride = plane.rowStride
    val pixelStride = plane.pixelStride
    val yData = ByteArray(buffer.remaining())
    buffer.get(yData)
    val packed = ByteArray(width * height)
    var outIndex = 0
    for (row in 0 until height) {
      val rowIndex = row * rowStride
      var colIndex = rowIndex
      for (col in 0 until width) {
        packed[outIndex] = yData[colIndex]
        outIndex += 1
        colIndex += pixelStride
      }
    }
    val source = PlanarYUVLuminanceSource(
        packed,
        width,
        height,
        0,
        0,
        width,
        height,
        false,
    )
    return attemptDecode(source)
  }

  override fun onDestroy() {
    qaReceiver?.let { unregisterReceiver(it) }
    qaReceiver = null
    decodeExecutor.shutdown()
    analysisExecutor.shutdown()
    super.onDestroy()
  }

  private fun writeBackupToDownloads(fileName: String, content: String): String {
    val resolver = applicationContext.contentResolver
    val values = ContentValues().apply {
      put(MediaStore.Downloads.DISPLAY_NAME, fileName)
      put(MediaStore.Downloads.MIME_TYPE, "application/json")
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
        put(MediaStore.Downloads.RELATIVE_PATH, "Download")
        put(MediaStore.Downloads.IS_PENDING, 1)
      }
    }
    val collection =
        MediaStore.Downloads.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
    val uri =
        resolver.insert(collection, values)
            ?: throw IllegalStateException("Falha ao criar ficheiro no Downloads.")

    resolver.openOutputStream(uri)?.use { stream ->
      stream.write(content.toByteArray(Charsets.UTF_8))
      stream.flush()
    } ?: throw IllegalStateException("Falha ao escrever ficheiro de backup.")

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
      val completed = ContentValues().apply {
        put(MediaStore.Downloads.IS_PENDING, 0)
      }
      resolver.update(uri, completed, null, null)
    }

    return "/storage/emulated/0/Download/$fileName"
  }
}
