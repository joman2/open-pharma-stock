package dev.steenbakker.mobile_scanner

import android.app.Activity
import android.content.Context
import android.content.pm.ApplicationInfo
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.graphics.Rect
import android.graphics.RectF
import android.hardware.display.DisplayManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.util.Log
import android.util.Size
import android.view.Surface
import android.view.WindowManager
import androidx.camera.core.Camera
import androidx.camera.core.CameraSelector
import androidx.camera.core.ExperimentalGetImage
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageProxy
import androidx.camera.core.Preview
import androidx.camera.core.TorchState
import androidx.camera.core.resolutionselector.ResolutionSelector
import androidx.camera.core.resolutionselector.ResolutionStrategy
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import com.google.zxing.BarcodeFormat
import com.google.zxing.BinaryBitmap
import com.google.zxing.DecodeHintType
import com.google.zxing.RGBLuminanceSource
import com.google.zxing.PlanarYUVLuminanceSource
import com.google.zxing.common.HybridBinarizer
import com.google.zxing.common.GlobalHistogramBinarizer
import com.google.zxing.common.BitMatrix
import com.google.zxing.datamatrix.DataMatrixReader
import com.google.zxing.datamatrix.decoder.Decoder
import dev.steenbakker.mobile_scanner.objects.DetectionSpeed
import dev.steenbakker.mobile_scanner.objects.MobileScannerStartParameters
import dev.steenbakker.mobile_scanner.utils.YuvToRgbConverter
import io.flutter.view.TextureRegistry
import java.io.ByteArrayOutputStream
import java.io.File
import java.util.EnumMap
import java.util.concurrent.Executors
import kotlin.math.abs
import kotlin.math.min
import kotlin.math.max
import kotlin.math.roundToInt
import kotlin.math.sqrt
import org.opencv.android.OpenCVLoader
import org.opencv.core.Core
import org.opencv.core.CvType
import org.opencv.core.Mat
import org.opencv.core.MatOfPoint
import org.opencv.core.MatOfPoint2f
import org.opencv.core.Point
import org.opencv.core.Scalar
import org.opencv.core.Size as CvSize
import org.opencv.imgcodecs.Imgcodecs
import org.opencv.imgproc.Imgproc

class MobileScanner(
    private val activity: Activity,
    private val textureRegistry: TextureRegistry,
    private val mobileScannerCallback: MobileScannerCallback,
    private val mobileScannerErrorCallback: MobileScannerErrorCallback,
) {

    /// Internal variables
    private var cameraProvider: ProcessCameraProvider? = null
    private var camera: Camera? = null
    private var preview: Preview? = null
    private var textureEntry: TextureRegistry.SurfaceTextureEntry? = null
    private var lastScanned: List<String?>? = null
    private var scannerTimeout = false
    private var displayListener: DisplayManager.DisplayListener? = null

    /// Configurable variables
    var scanWindow: List<Float>? = null
    private var detectionSpeed: DetectionSpeed = DetectionSpeed.NO_DUPLICATES
    private var detectionTimeout: Long = 250
    private var returnImage = false
    private var enableFallbackDecoder = false
    private var debugDpmFrames = false
    private var debugDpmSoft = false
    private val isDebug =
        (activity.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0
    private val openCvReady = OpenCVLoader.initDebug()
    private val fossBarcodeDecoder = FossBarcodeDecoder()
    private var barcodeFormats: Set<BarcodeFormat>? = null
    private val zxingFallbackAnalyzer = ZXingFallbackAnalyzer()
    private var primaryTrack: NativeTrackedBarcode? = null
    private val analysisExecutor = Executors.newSingleThreadExecutor()

    private data class NativeBarcodeCandidate(
        val barcode: FossBarcode,
        val rect: Rect,
        val inScanWindow: Boolean,
        val roiOverlap: Float,
        val identity: String,
    )

    private data class NativeTrackedBarcode(
        val identity: String,
        val rect: RectF,
        val stableFrames: Int,
        val missedFrames: Int,
        val lastSeenAtMs: Long,
        val roiOverlap: Float,
        val confidence: Float,
        val locked: Boolean,
    )

    /**
     * callback for the camera. Every frame is passed through this function.
     */
    @ExperimentalGetImage
    val captureOutput = ImageAnalysis.Analyzer { imageProxy -> // YUV_420_888 format
        if (detectionSpeed == DetectionSpeed.NORMAL && scannerTimeout) {
            imageProxy.close()
            return@Analyzer
        } else if (detectionSpeed == DetectionSpeed.NORMAL) {
            scannerTimeout = true
        }

        try {
            val barcodes = fossBarcodeDecoder.decode(imageProxy, barcodeFormats)
            val now = SystemClock.elapsedRealtime()
            if (detectionSpeed == DetectionSpeed.NO_DUPLICATES) {
                val newScannedBarcodes = barcodes
                    .mapNotNull { barcode -> barcode.rawValue }
                    .sorted()
                if (newScannedBarcodes == lastScanned) {
                    return@Analyzer
                }
                if (newScannedBarcodes.isNotEmpty()) {
                    lastScanned = newScannedBarcodes
                }
            }

            val scanRect = scaledScanWindowRect(scanWindow, imageProxy)
            val candidates = barcodes.mapNotNull { barcode ->
                buildNativeCandidate(barcode, scanRect)
            }
            val trackedCandidate = selectPrimaryTrackedCandidate(candidates, scanRect)
            val trackedBarcode = updatePrimaryTrack(trackedCandidate, now)
            val barcodeMap = candidates.map { candidate ->
                val trackPayload = if (
                    trackedBarcode != null &&
                    candidate.identity == trackedBarcode.identity
                ) {
                    nativeTrackPayload(trackedBarcode)
                } else {
                    null
                }
                candidate.barcode.dataWithTracking(
                    inScanWindow = candidate.inScanWindow,
                    track = trackPayload,
                )
            }

            val hasDecodedDataMatrix = barcodes.any {
                it.format == FossBarcodeValues.FORMAT_DATA_MATRIX &&
                    !it.rawValue.isNullOrEmpty()
            }
            if (barcodeMap.isEmpty()) {
                zxingFallbackAnalyzer.arm(now, "roi_no_decode")
                zxingFallbackAnalyzer.analyze(imageProxy)
                return@Analyzer
            }
            if (hasDecodedDataMatrix && candidates.any { it.inScanWindow }) {
                zxingFallbackAnalyzer.disarm()
            }

            if (!returnImage) {
                mobileScannerCallback(barcodeMap, null, null, null)
                return@Analyzer
            }

            val mediaImage = imageProxy.image
            if (mediaImage == null) {
                mobileScannerCallback(barcodeMap, null, null, null)
                return@Analyzer
            }
            val bitmap = Bitmap.createBitmap(
                mediaImage.width,
                mediaImage.height,
                Bitmap.Config.ARGB_8888,
            )
            YuvToRgbConverter(activity.applicationContext).yuvToRgb(mediaImage, bitmap)
            val rotated = rotateBitmap(
                bitmap,
                imageProxy.imageInfo.rotationDegrees.toFloat(),
            )
            val stream = ByteArrayOutputStream()
            rotated.compress(Bitmap.CompressFormat.PNG, 100, stream)
            mobileScannerCallback(
                barcodeMap,
                stream.toByteArray(),
                rotated.width,
                rotated.height,
            )
            if (rotated !== bitmap) {
                bitmap.recycle()
            }
            rotated.recycle()
        } catch (error: Exception) {
            Log.e("OpenPharmaStock", "Barcode analysis failed", error)
            mobileScannerErrorCallback(error.localizedMessage ?: error.toString())
        } finally {
            imageProxy.close()
            if (detectionSpeed == DetectionSpeed.NORMAL) {
                Handler(Looper.getMainLooper()).postDelayed({
                    scannerTimeout = false
                }, detectionTimeout)
            }
        }
    }

    private fun emitFallbackBarcode(text: String) {
        val barcodeData: Map<String, Any?> = mapOf(
            "rawValue" to text,
            "displayValue" to text,
            "format" to FossBarcodeValues.FORMAT_DATA_MATRIX,
            "type" to FossBarcodeValues.TYPE_TEXT,
            "inScanWindow" to true,
        )
        mobileScannerCallback(listOf(barcodeData), null, null, null)
    }

    private data class NormalizedResult(
        val binary: Mat,
        val gray: Mat,
        val modules: Int,
        val quietZone: Int,
    )

    private data class AmbiguousCell(
        val index: Int,
        val confidence: Double,
    )

    private data class ModuleGrid(
        val base: BooleanArray,
        val ambiguous: List<AmbiguousCell>,
    )

    private data class SoftDecodeResult(
        val text: String?,
        val lastError: String?,
    )

    private inner class ZXingFallbackAnalyzer : ImageAnalysis.Analyzer {
        private val roiScale = 1.0 // Use full image to avoid cutting off code
        private val thresholdOffset = 5
        private val dpmRoiScale = 0.8
        private val dpmClipLimit = 3.0
        private val dpmTileGrid = 8
        private val dpmAdaptiveBlockSize = 31
        private val dpmAdaptiveC = 5.0
        private val dpmMinBlobs = 50
        private val dpmMinSize = 256
        private val dpmMaxSize = 640
        private val dpmModulePixels = 6.0
        private val dpmQuietZoneRatio = 0.1
        private val dpmSoftBlackThreshold = 0.62
        private val dpmSoftWhiteThreshold = 0.38
        private val dpmSoftInsetRatio = 0.15
        private val dpmSoftTopK = 12
        private val dpmSoftPairK = 8
        private val stackMaxFrames = 10
        private val stackMinFrames = 6
        private val stackHistorySize = 8
        private val stackStableRequired = 6
        private val stackStableTolerance = 1
        private val stackVariantUpscale = 2
        private val stackFrames = ArrayDeque<ByteArray>(stackMaxFrames)
        private val stackModulesHistory = ArrayDeque<Int>(stackHistorySize)
        private var stackWidth = 0
        private var stackHeight = 0
        private val stackScratchValues = IntArray(stackMaxFrames)
        private val stackBlurEnabled = false
        private val throttleMs = 750L
        private val successCooldownMs = 2500L
        private val armWindowMs = 1200L
        private var lastAttemptMs: Long = 0
        private var cooldownUntilMs: Long = 0
        private var armedUntilMs: Long = 0
        private var lastArmReason: String = "idle"
        private val hints =
            EnumMap<DecodeHintType, Any>(DecodeHintType::class.java).apply {
                this[DecodeHintType.TRY_HARDER] = java.lang.Boolean.TRUE
                this[DecodeHintType.POSSIBLE_FORMATS] =
                    listOf(BarcodeFormat.DATA_MATRIX)
            }

        fun arm(now: Long, reason: String) {
            armedUntilMs = now + armWindowMs
            lastArmReason = reason
        }

        fun disarm() {
            armedUntilMs = 0L
            lastArmReason = "idle"
        }

        override fun analyze(imageProxy: ImageProxy) {
            if (!enableFallbackDecoder) {
                return
            }
            val now = SystemClock.elapsedRealtime()
            if (now > armedUntilMs) {
                return
            }
            if (now < cooldownUntilMs) {
                return
            }
            if (now - lastAttemptMs < throttleMs) {
                return
            }
            lastAttemptMs = now
            val decoded = decode(imageProxy)
            if (decoded.isNullOrEmpty()) {
                return
            }
            if (isDebug) {
                Log.i(
                    "OPS",
                    "OPS: ZXING_FALLBACK OK len=${decoded.length} reason=$lastArmReason",
                )
            }
            cooldownUntilMs = now + successCooldownMs
            disarm()
            emitFallbackBarcode(decoded)
        }

        private fun decode(imageProxy: ImageProxy): String? {
            val width = imageProxy.width
            val height = imageProxy.height
            if (width <= 0 || height <= 0) {
                return null
            }
            val plane = imageProxy.planes[0]
            val buffer = plane.buffer
            if (!buffer.hasRemaining()) {
                return null
            }
            val rowStride = plane.rowStride
            val pixelStride = plane.pixelStride
            val yData = ByteArray(buffer.remaining())
            buffer.get(yData)
            buffer.rewind()
            if (openCvReady) {
                val dpmDecoded = decodeDpm(
                    yData,
                    rowStride,
                    pixelStride,
                    width,
                    height,
                )
                if (!dpmDecoded.isNullOrEmpty()) {
                    return dpmDecoded
                }
            } else if (isDebug) {
                Log.d("OPS", "OPS: DPM fail reason=opencv_not_ready")
            }
            val roiSize = (minOf(width, height) * roiScale).toInt().coerceAtLeast(1)
            val left = ((width - roiSize) / 2).coerceAtLeast(0)
            val top = ((height - roiSize) / 2).coerceAtLeast(0)

            val decodedNormal = decodeVariant(
                yData,
                rowStride,
                pixelStride,
                left,
                top,
                roiSize,
                roiSize,
                invert = false,
                variant = "A",
            )
            if (!decodedNormal.isNullOrEmpty()) {
                return decodedNormal
            }

            return decodeVariant(
                yData,
                rowStride,
                pixelStride,
                left,
                top,
                roiSize,
                roiSize,
                invert = true,
                variant = "B",
            )
        }

        private fun decodeVariant(
            yData: ByteArray,
            rowStride: Int,
            pixelStride: Int,
            left: Int,
            top: Int,
            width: Int,
            height: Int,
            invert: Boolean,
            variant: String,
        ): String? {
            if (isDebug) {
                Log.d("OPS", "OPS: ZXING_FALLBACK try variant=$variant")
            }
            
            val source = if (pixelStride == 1) {
                 PlanarYUVLuminanceSource(
                    yData,
                    rowStride,
                    yData.size / rowStride, // estimated height from buffer size/stride
                    left,
                    top,
                    width,
                    height,
                    false
                )
            } else {
                 // Fallback for non-standard stride (rare)
                 val pixelCount = width * height
                 val pixels = IntArray(pixelCount)
                 var outIndex = 0
                 for (row in 0 until height) {
                     var inputIndex = (top + row) * rowStride + left * pixelStride
                     for (col in 0 until width) {
                         val y = yData[inputIndex].toInt() and 0xFF
                         val value = y
                         pixels[outIndex] = (0xFF shl 24) or (value shl 16) or (value shl 8) or value
                         outIndex += 1
                         inputIndex += pixelStride
                     }
                 }
                 RGBLuminanceSource(width, height, pixels)
            }

            val finalSource = if (invert) source.invert() else source
            
            // For inverted codes (white on black), GlobalHistogramBinarizer is often better 
            // as they are usually high contrast synthetic labels.
            // For normal codes, HybridBinarizer handles shadows/gradients better.
            val primaryBinarizer = if (invert && variant == "B") {
                 GlobalHistogramBinarizer(finalSource)
            } else {
                 HybridBinarizer(finalSource)
            }

            return try {
                val binaryBitmap = BinaryBitmap(primaryBinarizer)
                val result = DataMatrixReader().decode(binaryBitmap, hints).text
                if (!result.isNullOrEmpty() && isDebug) {
                    val method = if (primaryBinarizer is GlobalHistogramBinarizer) "GHB" else "HYBRID"
                    Log.i("OPS", "OPS: ZXING_FALLBACK OK variant=$variant method=$method len=${result.length}")
                }
                result
            } catch (e: Exception) {
                // Try the other binarizer as fallback
                try {
                     val fallbackBinarizer = if (primaryBinarizer is GlobalHistogramBinarizer) {
                         HybridBinarizer(finalSource)
                     } else {
                         GlobalHistogramBinarizer(finalSource)
                     }
                     val binaryBitmap = BinaryBitmap(fallbackBinarizer)
                     val result = DataMatrixReader().decode(binaryBitmap, hints).text
                     if (!result.isNullOrEmpty() && isDebug) {
                        val method = if (fallbackBinarizer is GlobalHistogramBinarizer) "GHB" else "HYBRID"
                        Log.i("OPS", "OPS: ZXING_FALLBACK OK (fallback) variant=$variant method=$method len=${result.length}")
                     }
                     result
                } catch (e2: Exception) {
                    if (isDebug) {
                         Log.d("OPS", "OPS: ZXING_FALLBACK try 1 error: ${e::class.simpleName}")
                         Log.d("OPS", "OPS: ZXING_FALLBACK try 2 error: ${e2::class.simpleName}")
                    }
                    null
                }
            }
        }



        private fun decodeDpm(
            yData: ByteArray,
            rowStride: Int,
            pixelStride: Int,
            width: Int,
            height: Int,
        ): String? {
            if (isDebug) {
                Log.d("OPS", "OPS: DPM start")
            }
            val roiSize = (minOf(width, height) * dpmRoiScale).toInt().coerceAtLeast(1)
            val left = ((width - roiSize) / 2).coerceAtLeast(0)
            val top = ((height - roiSize) / 2).coerceAtLeast(0)
            val roiMat = buildRoiMat(yData, rowStride, pixelStride, left, top, roiSize, roiSize)
                ?: run {
                    if (isDebug) {
                        Log.d("OPS", "OPS: DPM fail reason=roi")
                    }
                    return null
                }
            val clahe = Imgproc.createCLAHE(
                dpmClipLimit,
                CvSize(dpmTileGrid.toDouble(), dpmTileGrid.toDouble()),
            )
            val contrast = Mat()
            clahe.apply(roiMat, contrast)
            roiMat.release()

            val decodedNormal = decodeDpmVariant(contrast, "V1", invert = false)
            if (!decodedNormal.isNullOrEmpty()) {
                contrast.release()
                return decodedNormal
            }

            val decodedInverted = decodeDpmVariant(contrast, "V2", invert = true)
            contrast.release()
            if (!decodedInverted.isNullOrEmpty()) {
                return decodedInverted
            }

            if (isDebug) {
                Log.d("OPS", "OPS: DPM fail reason=all_variants")
            }
            return null
        }

        private fun decodeDpmVariant(
            base: Mat,
            variant: String,
            invert: Boolean,
        ): String? {
            val working = Mat()
            if (invert) {
                Core.bitwise_not(base, working)
            } else {
                base.copyTo(working)
            }

            val morphKernel = Imgproc.getStructuringElement(
                Imgproc.MORPH_ELLIPSE,
                CvSize(5.0, 5.0),
            )
            val morph = Mat()
            val morphType = if (invert) Imgproc.MORPH_BLACKHAT else Imgproc.MORPH_TOPHAT
            Imgproc.morphologyEx(working, morph, morphType, morphKernel)
            morphKernel.release()

            val blurred = Mat()
            Imgproc.GaussianBlur(morph, blurred, CvSize(3.0, 3.0), 0.0)

            val thresholded = Mat()
            Imgproc.adaptiveThreshold(
                blurred,
                thresholded,
                255.0,
                Imgproc.ADAPTIVE_THRESH_GAUSSIAN_C,
                Imgproc.THRESH_BINARY,
                dpmAdaptiveBlockSize,
                dpmAdaptiveC,
            )

            val closeKernel = Imgproc.getStructuringElement(
                Imgproc.MORPH_RECT,
                CvSize(3.0, 3.0),
            )
            val closed = Mat()
            Imgproc.morphologyEx(thresholded, closed, Imgproc.MORPH_CLOSE, closeKernel)
            closeKernel.release()

            morph.release()
            blurred.release()
            thresholded.release()

            val keypoints = detectBlobs(closed)
            if (isDebug) {
                Log.d("OPS", "OPS: DPM variant=$variant blobs=${keypoints.size}")
            }
            if (keypoints.size < dpmMinBlobs) {
                if (isDebug) {
                    Log.d("OPS", "OPS: DPM fail reason=blobs count=${keypoints.size}")
                }
                closed.release()
                return null
            }

            val normalizedResult = normalizeFromKeypoints(closed, working, keypoints)
            working.release()
            if (normalizedResult == null) {
                if (isDebug) {
                    Log.d("OPS", "OPS: DPM fail reason=homography")
                }
                closed.release()
                return null
            }
            if (isDebug) {
                Log.d(
                    "OPS",
                    "OPS: DPM normalized size=${normalizedResult.binary.cols()}x${normalizedResult.binary.rows()}",
                )
            }
            if (debugDpmFrames && isDebug) {
                saveDebugMat(closed, "preprocessed_$variant")
                saveDebugMat(normalizedResult.binary, "normalized_$variant")
            }

            val dmtxDecoded = decodeDmtx(normalizedResult.gray)
            if (!dmtxDecoded.isNullOrEmpty()) {
                normalizedResult.binary.release()
                normalizedResult.gray.release()
                closed.release()
                return dmtxDecoded
            }

            val stackedDecoded = decodeDmtxStacked(
                normalizedResult.gray,
                normalizedResult.modules,
            )
            if (!stackedDecoded.isNullOrEmpty()) {
                normalizedResult.binary.release()
                normalizedResult.gray.release()
                closed.release()
                return stackedDecoded
            }

            val moduleBinarized = moduleBinarize(
                normalizedResult.binary,
                normalizedResult.modules,
                normalizedResult.quietZone,
            )
            if (isDebug) {
                Log.d(
                    "OPS",
                    "OPS: DPM module binarization applied N=${normalizedResult.modules}",
                )
            }
            if (debugDpmFrames && isDebug) {
                saveDebugMat(moduleBinarized, "modules_$variant")
            }

            val decoded = decodeBitMatrixFromModules(
                normalizedResult.gray,
                normalizedResult.modules,
                normalizedResult.quietZone,
                variant,
            ) ?: decodeZxingFromMat(
                moduleBinarized,
                variant,
                normalizedResult.modules,
            )

            moduleBinarized.release()
            normalizedResult.binary.release()
            normalizedResult.gray.release()
            closed.release()

            return decoded
        }

        private fun buildRoiMat(
            yData: ByteArray,
            rowStride: Int,
            pixelStride: Int,
            left: Int,
            top: Int,
            width: Int,
            height: Int,
        ): Mat? {
            if (width <= 0 || height <= 0) {
                return null
            }
            val roiBytes = ByteArray(width * height)
            var outIndex = 0
            for (row in 0 until height) {
                var inputIndex = (top + row) * rowStride + left * pixelStride
                for (col in 0 until width) {
                    roiBytes[outIndex] = yData[inputIndex]
                    outIndex += 1
                    inputIndex += pixelStride
                }
            }
            val mat = Mat(height, width, CvType.CV_8UC1)
            mat.put(0, 0, roiBytes)
            return mat
        }

        private fun detectBlobs(binary: Mat): List<Point> {
            val contours = ArrayList<MatOfPoint>()
            val hierarchy = Mat()
            Imgproc.findContours(
                binary,
                contours,
                hierarchy,
                Imgproc.RETR_LIST,
                Imgproc.CHAIN_APPROX_SIMPLE,
            )
            hierarchy.release()

            val minArea = 6.0
            val maxArea = 5000.0
            val minCircularity = 0.4

            val centroids = ArrayList<Point>()
            for (contour in contours) {
                val area = Imgproc.contourArea(contour)
                if (area < minArea || area > maxArea) {
                    contour.release()
                    continue
                }
                val contour2f = MatOfPoint2f(*contour.toArray())
                val perimeter = Imgproc.arcLength(contour2f, true)
                if (perimeter > 0.0) {
                    val circularity = (4.0 * Math.PI * area) / (perimeter * perimeter)
                    if (circularity >= minCircularity) {
                        val moments = Imgproc.moments(contour)
                        val m00 = moments.m00
                        if (m00 != 0.0) {
                            val cx = moments.m10 / m00
                            val cy = moments.m01 / m00
                            centroids.add(Point(cx, cy))
                        }
                    }
                }
                contour2f.release()
                contour.release()
            }
            return centroids
        }

        private fun normalizeFromKeypoints(
            binary: Mat,
            graySource: Mat,
            keypoints: List<Point>,
        ): NormalizedResult? {
            if (keypoints.isEmpty()) {
                return null
            }
            val points = keypoints.toTypedArray()
            val matPoints = MatOfPoint2f(*points)
            val rect = Imgproc.minAreaRect(matPoints)
            if (rect.size.width <= 0 || rect.size.height <= 0) {
                if (isDebug) {
                    Log.d("OPS", "OPS: DPM fail reason=rect")
                }
                matPoints.release()
                return null
            }
            val rectPoints = Array(4) { Point() }
            rect.points(rectPoints)
            val ordered = orderPoints(rectPoints)

            val moduleSize = estimateModuleSize(keypoints)
            if (moduleSize == null || moduleSize <= 0.0) {
                if (isDebug) {
                    Log.d("OPS", "OPS: DPM fail reason=module_size")
                }
                matPoints.release()
                return null
            }
            val side = max(rect.size.width, rect.size.height)
            val modulesGuess =
                (side / moduleSize).roundToInt().coerceIn(10, 200)
            if (isDebug) {
                Log.d("OPS", "OPS: DPM homography ok modulesGuess=$modulesGuess")
            }

            val normalizedSide =
                (modulesGuess * dpmModulePixels).roundToInt().coerceIn(dpmMinSize, dpmMaxSize)
            val quietZone = (normalizedSide * dpmQuietZoneRatio).roundToInt().coerceAtLeast(4)
            val targetSide = normalizedSide + quietZone * 2

            val src = MatOfPoint2f(
                ordered[0],
                ordered[1],
                ordered[2],
                ordered[3],
            )
            val dst = MatOfPoint2f(
                Point(0.0, 0.0),
                Point((normalizedSide - 1).toDouble(), 0.0),
                Point((normalizedSide - 1).toDouble(), (normalizedSide - 1).toDouble()),
                Point(0.0, (normalizedSide - 1).toDouble()),
            )

            val transform = Imgproc.getPerspectiveTransform(src, dst)
            val warpedBinary = Mat()
            Imgproc.warpPerspective(
                binary,
                warpedBinary,
                transform,
                CvSize(normalizedSide.toDouble(), normalizedSide.toDouble()),
                Imgproc.INTER_NEAREST,
            )
            Imgproc.threshold(
                warpedBinary,
                warpedBinary,
                0.0,
                255.0,
                Imgproc.THRESH_BINARY or Imgproc.THRESH_OTSU,
            )

            val warpedGray = Mat()
            Imgproc.warpPerspective(
                graySource,
                warpedGray,
                transform,
                CvSize(normalizedSide.toDouble(), normalizedSide.toDouble()),
                Imgproc.INTER_LINEAR,
            )

            val outputBinary = Mat(targetSide, targetSide, CvType.CV_8UC1, Scalar(255.0))
            val roiBinary = outputBinary.submat(
                quietZone,
                quietZone + normalizedSide,
                quietZone,
                quietZone + normalizedSide,
            )
            warpedBinary.copyTo(roiBinary)
            roiBinary.release()
            warpedBinary.release()

            val outputGray = Mat(targetSide, targetSide, CvType.CV_8UC1, Scalar(255.0))
            val roiGray = outputGray.submat(
                quietZone,
                quietZone + normalizedSide,
                quietZone,
                quietZone + normalizedSide,
            )
            warpedGray.copyTo(roiGray)
            roiGray.release()
            warpedGray.release()
            transform.release()
            src.release()
            dst.release()
            matPoints.release()
            return NormalizedResult(
                binary = outputBinary,
                gray = outputGray,
                modules = modulesGuess,
                quietZone = quietZone,
            )
        }

        private fun orderPoints(points: Array<Point>): Array<Point> {
            val ordered = Array(4) { Point() }
            val sums = points.map { it.x + it.y }
            val diffs = points.map { it.x - it.y }
            val minSum = sums.minOrNull() ?: return points
            val maxSum = sums.maxOrNull() ?: return points
            val minDiff = diffs.minOrNull() ?: return points
            val maxDiff = diffs.maxOrNull() ?: return points
            val minSumIndex = sums.indexOf(minSum)
            val maxSumIndex = sums.indexOf(maxSum)
            val minDiffIndex = diffs.indexOf(minDiff)
            val maxDiffIndex = diffs.indexOf(maxDiff)
            ordered[0] = points[minSumIndex]
            ordered[2] = points[maxSumIndex]
            ordered[1] = points[minDiffIndex]
            ordered[3] = points[maxDiffIndex]
            return ordered
        }

        private fun estimateModuleSize(points: List<Point>): Double? {
            if (points.size < 2) {
                return null
            }
            val distances = DoubleArray(points.size)
            for (i in points.indices) {
                var minDist = Double.MAX_VALUE
                for (j in points.indices) {
                    if (i == j) {
                        continue
                    }
                    val dx = points[i].x - points[j].x
                    val dy = points[i].y - points[j].y
                    val dist = sqrt(dx * dx + dy * dy)
                    if (dist < minDist) {
                        minDist = dist
                    }
                }
                distances[i] = minDist
            }
            distances.sort()
            val median = distances[distances.size / 2]
            if (!median.isFinite() || median <= 0.0) {
                return null
            }
            return median
        }

        private fun moduleBinarize(
            normalized: Mat,
            modules: Int,
            quietZone: Int,
        ): Mat {
            val totalSize = normalized.rows()
            val normalizedSide = totalSize - quietZone * 2
            if (modules <= 0 || normalizedSide <= 0 || normalizedSide != normalized.cols()) {
                return normalized.clone()
            }

            val dataRegion = normalized.submat(
                quietZone,
                quietZone + normalizedSide,
                quietZone,
                quietZone + normalizedSide,
            )
            val globalMean = Core.mean(dataRegion).`val`[0]
            val output = Mat(totalSize, totalSize, CvType.CV_8UC1, Scalar(255.0))

            val cellSize = normalizedSide.toDouble() / modules.toDouble()
            for (row in 0 until modules) {
                val y0 = (row * cellSize).toInt()
                val y1 = ((row + 1) * cellSize).toInt().coerceAtMost(normalizedSide)
                if (y1 <= y0) {
                    continue
                }
                for (col in 0 until modules) {
                    val x0 = (col * cellSize).toInt()
                    val x1 = ((col + 1) * cellSize).toInt().coerceAtMost(normalizedSide)
                    if (x1 <= x0) {
                        continue
                    }
                    val cell = dataRegion.submat(y0, y1, x0, x1)
                    val mean = Core.mean(cell).`val`[0]
                    cell.release()
                    val color = if (mean < globalMean) 0.0 else 255.0
                    Imgproc.rectangle(
                        output,
                        Point((quietZone + x0).toDouble(), (quietZone + y0).toDouble()),
                        Point((quietZone + x1 - 1).toDouble(), (quietZone + y1 - 1).toDouble()),
                        Scalar(color),
                        Imgproc.FILLED,
                    )
                }
            }

            dataRegion.release()
            return output
        }

        private fun decodeDmtx(normalizedGray: Mat): String? {
            val width = normalizedGray.cols()
            val height = normalizedGray.rows()
            if (width <= 0 || height <= 0) {
                return null
            }
            if (isDebug) {
                Log.d("OPS", "OPS: DPM DMTX try w=$width h=$height")
            }
            val decoded = DmtxNative.decodeNormalizedMat(normalizedGray)
            return if (!decoded.isNullOrEmpty()) {
                if (isDebug) {
                    Log.i("OPS", "OPS: DPM DMTX OK len=${decoded.length}")
                }
                decoded
            } else {
                if (isDebug) {
                    Log.d("OPS", "OPS: DPM DMTX FAIL no_result")
                }
                null
            }
        }

        private fun decodeDmtxStacked(
            normalizedGray: Mat,
            modules: Int,
        ): String? {
            val width = normalizedGray.cols()
            val height = normalizedGray.rows()
            if (width <= 0 || height <= 0) {
                return null
            }

            if (width != stackWidth || height != stackHeight) {
                stackFrames.clear()
                stackModulesHistory.clear()
                stackWidth = width
                stackHeight = height
            }

            val grayForStack = if (stackBlurEnabled) {
                val blurred = Mat()
                Imgproc.GaussianBlur(
                    normalizedGray,
                    blurred,
                    CvSize(3.0, 3.0),
                    0.0,
                )
                blurred
            } else {
                normalizedGray
            }

            val bytes = ByteArray(width * height)
            grayForStack.get(0, 0, bytes)
            if (stackBlurEnabled) {
                grayForStack.release()
            }

            updateModulesHistory(modules)
            val median = medianModules()
            val minN = median - stackStableTolerance
            val maxN = median + stackStableTolerance
            if (modules in minN..maxN) {
                stackFrames.addLast(bytes)
                while (stackFrames.size > stackMaxFrames) {
                    stackFrames.removeFirst()
                }
            }

            val stable = isModulesStable(median)
            if (!stable) {
                if (isDebug) {
                    Log.d(
                        "OPS",
                        "OPS: DPM STACK wait stable N hist=${stackModulesHistory.joinToString(",")}",
                    )
                }
                return null
            }

            if (stackFrames.size < stackMinFrames) {
                return null
            }

            val stacked = buildStackMedian(stackFrames.toList(), width, height)
            if (isDebug) {
                Log.d("OPS", "OPS: DPM STACK built frames=${stackFrames.size} w=$width h=$height")
            }

            val decoded = decodeDmtxStackVariants(stacked, width, height)
            if (!decoded.isNullOrEmpty()) {
                stackFrames.clear()
                return decoded
            }

            if (isDebug) {
                Log.d("OPS", "OPS: DPM DMTX_STACK FAIL_ALL")
            }
            return null
        }

        private fun decodeDmtxStackVariants(
            stacked: ByteArray,
            width: Int,
            height: Int,
        ): String? {
            val variants = ArrayList<Triple<Int, ByteArray, Pair<Int, Int>>>(4)
            variants.add(Triple(0, stacked, Pair(width, height)))
            val inverted = invertBytes(stacked)
            variants.add(Triple(1, inverted, Pair(width, height)))
            val upscaled = upscale2xBilinear(stacked, width, height)
            variants.add(Triple(2, upscaled, Pair(width * stackVariantUpscale, height * stackVariantUpscale)))
            val upscaledInverted = upscale2xBilinear(inverted, width, height)
            variants.add(Triple(3, upscaledInverted, Pair(width * stackVariantUpscale, height * stackVariantUpscale)))

            for (variant in variants) {
                val v = variant.first
                val bytes = variant.second
                val dims = variant.third
                if (isDebug) {
                    Log.d("OPS", "OPS: DPM DMTX_STACK try v=$v w=${dims.first} h=${dims.second}")
                }
                val decoded = DmtxNative.decodeGray(bytes, dims.first, dims.second)
                if (!decoded.isNullOrEmpty()) {
                    if (isDebug) {
                        Log.i("OPS", "OPS: DPM DMTX_STACK OK v=$v len=${decoded.length}")
                    }
                    return decoded
                }
            }
            return null
        }

        private fun invertBytes(input: ByteArray): ByteArray {
            val out = ByteArray(input.size)
            for (i in input.indices) {
                val value = input[i].toInt() and 0xFF
                out[i] = (255 - value).toByte()
            }
            return out
        }

        private fun upscale2xBilinear(
            input: ByteArray,
            width: Int,
            height: Int,
        ): ByteArray {
            val outW = width * stackVariantUpscale
            val outH = height * stackVariantUpscale
            val out = ByteArray(outW * outH)
            for (y in 0 until height) {
                val rowOffset = y * width
                val nextRowOffset = if (y + 1 < height) (y + 1) * width else rowOffset
                val outRow = (y * stackVariantUpscale) * outW
                val outRowNext = (y * stackVariantUpscale + 1) * outW
                for (x in 0 until width) {
                    val idx = rowOffset + x
                    val p00 = input[idx].toInt() and 0xFF
                    val p10 = if (x + 1 < width) input[idx + 1].toInt() and 0xFF else p00
                    val p01 = input[nextRowOffset + x].toInt() and 0xFF
                    val p11 = if (x + 1 < width) {
                        input[nextRowOffset + x + 1].toInt() and 0xFF
                    } else {
                        p01
                    }
                    val outIdx = outRow + x * 2
                    out[outIdx] = p00.toByte()
                    out[outIdx + 1] = ((p00 + p10) / 2).toByte()
                    val outIdxNext = outRowNext + x * 2
                    out[outIdxNext] = ((p00 + p01) / 2).toByte()
                    out[outIdxNext + 1] = ((p00 + p10 + p01 + p11) / 4).toByte()
                }
            }
            return out
        }

        private fun buildStackMedian(
            frames: List<ByteArray>,
            width: Int,
            height: Int,
        ): ByteArray {
            val count = frames.size
            val out = ByteArray(width * height)
            val total = width * height
            for (i in 0 until total) {
                for (f in 0 until count) {
                    stackScratchValues[f] = frames[f][i].toInt() and 0xFF
                }
                for (j in 1 until count) {
                    val key = stackScratchValues[j]
                    var k = j - 1
                    while (k >= 0 && stackScratchValues[k] > key) {
                        stackScratchValues[k + 1] = stackScratchValues[k]
                        k -= 1
                    }
                    stackScratchValues[k + 1] = key
                }
                out[i] = stackScratchValues[count / 2].toByte()
            }
            return out
        }

        private fun updateModulesHistory(modules: Int) {
            stackModulesHistory.addLast(modules)
            while (stackModulesHistory.size > stackHistorySize) {
                stackModulesHistory.removeFirst()
            }
        }

        private fun medianModules(): Int {
            if (stackModulesHistory.isEmpty()) {
                return 0
            }
            val values = stackModulesHistory.toIntArray()
            values.sort()
            return values[values.size / 2]
        }

        private fun isModulesStable(median: Int): Boolean {
            if (stackModulesHistory.size < stackHistorySize) {
                return false
            }
            var count = 0
            for (value in stackModulesHistory) {
                if (kotlin.math.abs(value - median) <= stackStableTolerance) {
                    count += 1
                }
            }
            return count >= stackStableRequired
        }

        private fun decodeZxingFromMat(
            mat: Mat,
            variant: String,
            modules: Int,
        ): String? {
            val width = mat.cols()
            val height = mat.rows()
            if (width <= 0 || height <= 0) {
                return null
            }
            if (isDebug) {
                Log.d("OPS", "OPS: DPM ZXing try variant=$variant N=$modules")
            }
            val bytes = ByteArray(width * height)
            mat.get(0, 0, bytes)
            val pixels = IntArray(bytes.size)
            for (i in bytes.indices) {
                val value = bytes[i].toInt() and 0xFF
                pixels[i] = (0xFF shl 24) or (value shl 16) or (value shl 8) or value
            }
            val source = RGBLuminanceSource(width, height, pixels)
            val binaryBitmap = BinaryBitmap(HybridBinarizer(source))
            return try {
                val decoded = DataMatrixReader().decode(binaryBitmap, hints).text
                if (!decoded.isNullOrEmpty() && isDebug) {
                    Log.i("OPS", "OPS: DPM ZXing OK len=${decoded.length}")
                }
                decoded
            } catch (e: Exception) {
                if (isDebug) {
                    Log.d("OPS", "OPS: DPM ZXing FAIL ${e.javaClass.simpleName}")
                }
                null
            }
        }

        private fun decodeBitMatrixFromModules(
            normalized: Mat,
            modules: Int,
            quietZone: Int,
            variant: String,
        ): String? {
            if (modules <= 0) {
                return null
            }
            val candidates = listOf(modules - 4, modules - 2, modules, modules + 2, modules + 4)
                .map { it.coerceAtLeast(10) }
                .distinct()
            var lastFail: String? = null
            for (n in candidates) {
                val grid = buildModuleGrid(normalized, n, quietZone) ?: continue
                val decoded = decodeSoftCandidates(grid, n, variant)
                if (!decoded.text.isNullOrEmpty()) {
                    return decoded.text
                }
                if (!decoded.lastError.isNullOrEmpty()) {
                    lastFail = decoded.lastError
                }
            }
            if (isDebug) {
                val message = lastFail ?: "unknown"
                Log.d("OPS", "OPS: DPM soft FAIL_ALL last=$message")
            }
            return null
        }

        private fun decodeSoftCandidates(
            grid: ModuleGrid,
            modules: Int,
            variant: String,
        ): SoftDecodeResult {
            val ambiguous = grid.ambiguous.sortedBy { it.confidence }
            if (isDebug) {
                Log.d("OPS", "OPS: DPM soft start N=$modules amb=${ambiguous.size}")
            }
            val k = minOf(dpmSoftTopK, ambiguous.size)
            val k2 = minOf(dpmSoftPairK, k)
            val topK = ambiguous.take(k).map { it.index }
            val topK2 = ambiguous.take(k2).map { it.index }

            val candidates = ArrayList<IntArray>()
            candidates.add(IntArray(0))
            for (index in topK) {
                candidates.add(intArrayOf(index))
            }
            for (i in 0 until topK2.size) {
                for (j in i + 1 until topK2.size) {
                    candidates.add(intArrayOf(topK2[i], topK2[j]))
                }
            }

            var lastError: String? = null
            val decoder = Decoder()
            val quietCandidates = listOf(2, 3)
            for (quiet in quietCandidates) {
                if (isDebug) {
                    Log.d(
                        "OPS",
                        "OPS: DPM soft candidates=${candidates.size} K=$k q=$quiet",
                    )
                }
                for ((idx, flips) in candidates.withIndex()) {
                    if (debugDpmSoft && isDebug) {
                        Log.d(
                            "OPS",
                            "OPS: DPM soft try idx=$idx flips=${flips.size} q=$quiet",
                        )
                    }
                    val size = modules + quiet * 2
                    val bitMatrix = BitMatrix(size, size)
                    for (row in 0 until modules) {
                        val rowOffset = row * modules
                        for (col in 0 until modules) {
                            val cellIndex = rowOffset + col
                            val shouldFlip = isIndexFlipped(cellIndex, flips)
                            val value = if (shouldFlip) !grid.base[cellIndex] else grid.base[cellIndex]
                            if (value) {
                                bitMatrix.set(col + quiet, row + quiet)
                            }
                        }
                    }
                    try {
                        val result = decoder.decode(bitMatrix)
                        val text = result.text
                        if (!text.isNullOrEmpty()) {
                            if (isDebug) {
                                Log.i(
                                    "OPS",
                                    "OPS: DPM soft OK idx=$idx flips=${flips.size} q=$quiet len=${text.length}",
                                )
                            }
                            return SoftDecodeResult(text, null)
                        }
                    } catch (e: Exception) {
                        lastError = e.javaClass.simpleName
                    }
                }
            }
            return SoftDecodeResult(null, lastError)
        }

        private fun isIndexFlipped(index: Int, flips: IntArray): Boolean {
            for (flip in flips) {
                if (flip == index) {
                    return true
                }
            }
            return false
        }

        private fun buildModuleGrid(
            normalized: Mat,
            modules: Int,
            quietZone: Int,
        ): ModuleGrid? {
            val totalSize = normalized.rows()
            val normalizedSide = totalSize - quietZone * 2
            if (modules <= 0 || normalizedSide <= 0 || normalizedSide != normalized.cols()) {
                return null
            }
            val dataRegion = normalized.submat(
                quietZone,
                quietZone + normalizedSide,
                quietZone,
                quietZone + normalizedSide,
            )
            val grid = BooleanArray(modules * modules)
            val ambiguous = ArrayList<AmbiguousCell>()
            val cellSize = normalizedSide.toDouble() / modules.toDouble()
            val inset = max(1, (cellSize * dpmSoftInsetRatio).toInt())
            for (row in 0 until modules) {
                val y0 = (row * cellSize).toInt()
                val y1 = ((row + 1) * cellSize).toInt().coerceAtMost(normalizedSide)
                if (y1 <= y0) {
                    continue
                }
                for (col in 0 until modules) {
                    val x0 = (col * cellSize).toInt()
                    val x1 = ((col + 1) * cellSize).toInt().coerceAtMost(normalizedSide)
                    if (x1 <= x0) {
                        continue
                    }
                    val ix0 = (x0 + inset).coerceAtMost(x1 - 1)
                    val iy0 = (y0 + inset).coerceAtMost(y1 - 1)
                    val ix1 = (x1 - inset).coerceAtLeast(ix0 + 1)
                    val iy1 = (y1 - inset).coerceAtLeast(iy0 + 1)
                    val cell = if (ix1 <= ix0 || iy1 <= iy0) {
                        dataRegion.submat(y0, y1, x0, x1)
                    } else {
                        dataRegion.submat(iy0, iy1, ix0, ix1)
                    }
                    val mean = Core.mean(cell).`val`[0]
                    cell.release()
                    val s = 1.0 - (mean / 255.0)
                    val confidence = abs(s - 0.5)
                    val index = row * modules + col
                    val black = s >= 0.5
                    grid[index] = black
                    if (s >= dpmSoftBlackThreshold) {
                        continue
                    }
                    if (s <= dpmSoftWhiteThreshold) {
                        continue
                    }
                    ambiguous.add(AmbiguousCell(index, confidence))
                }
            }
            dataRegion.release()
            return ModuleGrid(grid, ambiguous)
        }

        private fun saveDebugMat(mat: Mat, name: String) {
            val cacheDir = activity.cacheDir
            val file = File(
                cacheDir,
                "ops_dpm_${name}_${SystemClock.elapsedRealtime()}.png",
            )
            Imgcodecs.imwrite(file.absolutePath, mat)
        }
    }

    private fun rotateBitmap(bitmap: Bitmap, degrees: Float): Bitmap {
        val matrix = Matrix()
        matrix.postRotate(degrees)
        return Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true)
    }

    private fun scaledScanWindowRect(
        scanWindow: List<Float>?,
        inputImage: ImageProxy,
    ): Rect? {
        if (scanWindow == null) {
            return null
        }
        return try {
            val rotated = inputImage.imageInfo.rotationDegrees % 180 != 0
            val imageWidth = if (rotated) inputImage.height else inputImage.width
            val imageHeight = if (rotated) inputImage.width else inputImage.height

            val left = (scanWindow[0] * imageWidth).roundToInt()
            val top = (scanWindow[1] * imageHeight).roundToInt()
            val right = (scanWindow[2] * imageWidth).roundToInt()
            val bottom = (scanWindow[3] * imageHeight).roundToInt()

            Rect(left, top, right, bottom)
        } catch (exception: IllegalArgumentException) {
            null
        }
    }

    private fun geometryRect(barcode: FossBarcode): Rect? {
        val corners = barcode.cornerPoints
        val baseRect = if (!corners.isNullOrEmpty()) {
            val left = corners.minOf { it.x }
            val top = corners.minOf { it.y }
            val right = corners.maxOf { it.x }
            val bottom = corners.maxOf { it.y }
            if (right > left && bottom > top) {
                Rect(left, top, right, bottom)
            } else {
                null
            }
        } else {
            barcode.boundingBox
        }
        return baseRect
    }

    private fun overlapRatio(a: Rect, b: Rect): Float {
        val left = max(a.left, b.left)
        val top = max(a.top, b.top)
        val right = min(a.right, b.right)
        val bottom = min(a.bottom, b.bottom)
        if (right <= left || bottom <= top) {
            return 0f
        }
        val intersectionArea = (right - left) * (bottom - top)
        val area = a.width() * a.height()
        if (area <= 0) {
            return 0f
        }
        return intersectionArea.toFloat() / area.toFloat()
    }

    private fun buildNativeCandidate(
        barcode: FossBarcode,
        scanRect: Rect?,
    ): NativeBarcodeCandidate? {
        val rect = geometryRect(barcode) ?: return null
        val overlap = if (scanRect == null) 1f else overlapRatio(rect, scanRect)
        val centerInScanWindow = scanRect?.contains(rect.centerX(), rect.centerY()) ?: true
        val inScanWindow = centerInScanWindow || overlap >= 0.12f
        val identity = barcode.rawValue?.takeIf { it.isNotEmpty() }
            ?: "${barcode.format}:${rect.centerX()}:${rect.centerY()}"
        return NativeBarcodeCandidate(
            barcode = barcode,
            rect = rect,
            inScanWindow = inScanWindow,
            roiOverlap = overlap,
            identity = identity,
        )
    }

    private fun rectIou(a: RectF, b: RectF): Float {
        val left = max(a.left, b.left)
        val top = max(a.top, b.top)
        val right = min(a.right, b.right)
        val bottom = min(a.bottom, b.bottom)
        if (right <= left || bottom <= top) {
            return 0f
        }
        val intersection = (right - left) * (bottom - top)
        val union = (a.width() * a.height()) + (b.width() * b.height()) - intersection
        if (union <= 0f) {
            return 0f
        }
        return intersection / union
    }

    private fun smoothTrackRect(
        current: RectF?,
        next: RectF,
        stableFrames: Int,
    ): RectF {
        return RectF(next)
    }

    private fun acquisitionScore(
        candidate: NativeBarcodeCandidate,
        scanRect: Rect?,
    ): Float {
        val area = candidate.rect.width().toFloat() * candidate.rect.height().toFloat()
        val scanCenterX = scanRect?.exactCenterX() ?: candidate.rect.exactCenterX()
        val scanCenterY = scanRect?.exactCenterY() ?: candidate.rect.exactCenterY()
        val dx = candidate.rect.exactCenterX() - scanCenterX
        val dy = candidate.rect.exactCenterY() - scanCenterY
        val distance = sqrt((dx * dx) + (dy * dy))
        return (candidate.roiOverlap * 520f) + (area * 0.018f) - (distance * 1.1f)
    }

    private fun continuityScore(
        candidate: NativeBarcodeCandidate,
        track: NativeTrackedBarcode,
        scanRect: Rect?,
    ): Float {
        val rect = RectF(candidate.rect)
        val iou = rectIou(rect, track.rect)
        val dx = rect.centerX() - track.rect.centerX()
        val dy = rect.centerY() - track.rect.centerY()
        val distance = sqrt((dx * dx) + (dy * dy))
        val area = rect.width() * rect.height()
        val identityBonus = if (candidate.identity == track.identity) 220f else 0f
        val scanCenterX = scanRect?.exactCenterX() ?: rect.centerX()
        val scanCenterY = scanRect?.exactCenterY() ?: rect.centerY()
        val scanDistance = sqrt(
            ((rect.centerX() - scanCenterX) * (rect.centerX() - scanCenterX)) +
                ((rect.centerY() - scanCenterY) * (rect.centerY() - scanCenterY)),
        )
        return (iou * 900f) +
            (candidate.roiOverlap * 180f) +
            identityBonus +
            (area * 0.012f) -
            (distance * 1.35f) -
            (scanDistance * 0.3f)
    }

    private fun selectPrimaryTrackedCandidate(
        candidates: List<NativeBarcodeCandidate>,
        scanRect: Rect?,
    ): NativeBarcodeCandidate? {
        if (candidates.isEmpty()) {
            return null
        }
        val track = primaryTrack
        if (track != null) {
            var best: NativeBarcodeCandidate? = null
            var bestScore = Float.NEGATIVE_INFINITY
            for (candidate in candidates) {
                val score = continuityScore(candidate, track, scanRect)
                if (score > bestScore) {
                    bestScore = score
                    best = candidate
                }
            }
            if (best != null && bestScore > 120f) {
                return best
            }
        }
        var best: NativeBarcodeCandidate? = null
        var bestScore = Float.NEGATIVE_INFINITY
        for (candidate in candidates) {
            val score = acquisitionScore(candidate, scanRect)
            if (score > bestScore) {
                bestScore = score
                best = candidate
            }
        }
        return best
    }

    private fun updatePrimaryTrack(
        candidate: NativeBarcodeCandidate?,
        now: Long,
    ): NativeTrackedBarcode? {
        if (candidate == null) {
            val current = primaryTrack ?: return null
            val missedFrames = current.missedFrames + 1
            if (missedFrames >= 3 || now - current.lastSeenAtMs > 260L) {
                primaryTrack = null
                return null
            }
            val held = current.copy(missedFrames = missedFrames)
            primaryTrack = held
            return held
        }

        val current = primaryTrack
        val nextRect = RectF(candidate.rect)
        val continued = current != null &&
            (current.identity == candidate.identity || rectIou(current.rect, nextRect) > 0.38f)
        val stableFrames = if (continued && current != null) current.stableFrames + 1 else 1
        val smoothed = smoothTrackRect(current?.rect, nextRect, stableFrames)
        val confidence = min(
            1f,
            (candidate.roiOverlap * 0.55f) + (min(stableFrames, 8) * 0.08f),
        )
        val tracked = NativeTrackedBarcode(
            identity = candidate.identity,
            rect = smoothed,
            stableFrames = stableFrames,
            missedFrames = 0,
            lastSeenAtMs = now,
            roiOverlap = candidate.roiOverlap,
            confidence = confidence,
            locked = stableFrames >= 2,
        )
        primaryTrack = tracked
        return tracked
    }

    private fun nativeTrackPayload(track: NativeTrackedBarcode): Map<String, Any?> {
        val rect = Rect(
            track.rect.left.roundToInt(),
            track.rect.top.roundToInt(),
            track.rect.right.roundToInt(),
            track.rect.bottom.roundToInt(),
        )
        val corners = listOf(
            android.graphics.Point(rect.left, rect.top).data,
            android.graphics.Point(rect.right, rect.top).data,
            android.graphics.Point(rect.right, rect.bottom).data,
            android.graphics.Point(rect.left, rect.bottom).data,
        )
        return mapOf(
            "id" to track.identity,
            "rect" to rect.dataRect(),
            "corners" to corners,
            "confidence" to track.confidence.toDouble(),
            "locked" to track.locked,
            "stableFrames" to track.stableFrames,
            "ageMs" to max(0L, SystemClock.elapsedRealtime() - track.lastSeenAtMs).toInt(),
        )
    }

    // Return the best resolution for the actual device orientation.
    //
    // By default the resolution is 480x640, which is too low for ML Kit.
    // If the given resolution is not supported by the display,
    // the closest available resolution is used.
    //
    // The resolution should be adjusted for the display rotation, to preserve the aspect ratio.
    @Suppress("deprecation")
    private fun getResolution(cameraResolution: Size): Size {
        val rotation = if (Build.VERSION.SDK_INT >= 30) {
            activity.display!!.rotation
        } else {
            val windowManager = activity.applicationContext.getSystemService(Context.WINDOW_SERVICE) as WindowManager

            windowManager.defaultDisplay.rotation
        }

        val widthMaxRes = cameraResolution.width
        val heightMaxRes = cameraResolution.height

        val targetResolution = if (rotation == Surface.ROTATION_0 || rotation == Surface.ROTATION_180) {
            Size(widthMaxRes, heightMaxRes) // Portrait mode
        } else {
            Size(heightMaxRes, widthMaxRes) // Landscape mode
        }
        return targetResolution
    }

    /**
     * Start barcode scanning by initializing the camera and FLOSS decoder.
     */
    @ExperimentalGetImage
    fun start(
        barcodeFormats: Set<BarcodeFormat>?,
        returnImage: Boolean,
        enableFallbackDecoder: Boolean,
        debugDpmFrames: Boolean,
        cameraPosition: CameraSelector,
        torch: Boolean,
        detectionSpeed: DetectionSpeed,
        torchStateCallback: TorchStateCallback,
        zoomScaleStateCallback: ZoomScaleStateCallback,
        mobileScannerStartedCallback: MobileScannerStartedCallback,
        mobileScannerErrorCallback: (exception: Exception) -> Unit,
        detectionTimeout: Long,
        cameraResolution: Size?,
        newCameraResolutionSelector: Boolean
    ) {
        this.detectionSpeed = detectionSpeed
        this.detectionTimeout = detectionTimeout
        this.returnImage = returnImage
        this.enableFallbackDecoder = enableFallbackDecoder
        this.debugDpmFrames = debugDpmFrames
        this.debugDpmSoft = debugDpmFrames
        this.barcodeFormats = barcodeFormats

        if (camera?.cameraInfo != null && preview != null && textureEntry != null) {
            mobileScannerErrorCallback(AlreadyStarted())

            return
        }

        lastScanned = null

        val cameraProviderFuture = ProcessCameraProvider.getInstance(activity)
        val executor = ContextCompat.getMainExecutor(activity)

        cameraProviderFuture.addListener({
            cameraProvider = cameraProviderFuture.get()
            val numberOfCameras = cameraProvider?.availableCameraInfos?.size

            if (cameraProvider == null) {
                mobileScannerErrorCallback(CameraError())

                return@addListener
            }

            cameraProvider?.unbindAll()
            textureEntry = textureRegistry.createSurfaceTexture()

            // Preview
            val surfaceProvider = Preview.SurfaceProvider { request ->
                if (isStopped()) {
                    return@SurfaceProvider
                }

                val texture = textureEntry!!.surfaceTexture()
                texture.setDefaultBufferSize(
                    request.resolution.width,
                    request.resolution.height
                )

                val surface = Surface(texture)
                request.provideSurface(surface, executor) { }
            }

            // Build the preview to be shown on the Flutter texture
            val previewBuilder = Preview.Builder()
            preview = previewBuilder.build().apply { setSurfaceProvider(surfaceProvider) }

            // Build the analyzer used by ZXing and the libdmtx fallback.
            val analysisBuilder = ImageAnalysis.Builder()
                .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
            val displayManager = activity.applicationContext.getSystemService(Context.DISPLAY_SERVICE) as DisplayManager

            if (cameraResolution != null) {
                if (newCameraResolutionSelector) {
                    val selectorBuilder = ResolutionSelector.Builder()
                    selectorBuilder.setResolutionStrategy(
                        ResolutionStrategy(
                            cameraResolution,
                            ResolutionStrategy.FALLBACK_RULE_CLOSEST_HIGHER_THEN_LOWER
                        )
                    )
                    analysisBuilder.setResolutionSelector(selectorBuilder.build()).build()
                } else {
                    @Suppress("DEPRECATION")
                    analysisBuilder.setTargetResolution(getResolution(cameraResolution))
                }

                if (displayListener == null) {
                    displayListener = object : DisplayManager.DisplayListener {
                        override fun onDisplayAdded(displayId: Int) {}

                        override fun onDisplayRemoved(displayId: Int) {}

                        override fun onDisplayChanged(displayId: Int) {
                            if (newCameraResolutionSelector) {
                                val selectorBuilder = ResolutionSelector.Builder()
                                selectorBuilder.setResolutionStrategy(
                                    ResolutionStrategy(
                                        cameraResolution,
                                        ResolutionStrategy.FALLBACK_RULE_CLOSEST_HIGHER_THEN_LOWER
                                    )
                                )
                                analysisBuilder.setResolutionSelector(selectorBuilder.build()).build()
                            } else {
                                @Suppress("DEPRECATION")
                                analysisBuilder.setTargetResolution(getResolution(cameraResolution))
                            }
                        }
                    }

                    displayManager.registerDisplayListener(
                        displayListener, null,
                    )
                }
            }

            val analysis = analysisBuilder.build().apply {
                setAnalyzer(analysisExecutor, captureOutput)
            }

            try {
                camera = cameraProvider?.bindToLifecycle(
                    activity as LifecycleOwner,
                    cameraPosition,
                    preview,
                    analysis
                )
            } catch(exception: Exception) {
                mobileScannerErrorCallback(NoCamera())

                return@addListener
            }

            camera?.let {
                // Register the torch listener
                it.cameraInfo.torchState.observe(activity as LifecycleOwner) { state ->
                    // TorchState.OFF = 0; TorchState.ON = 1
                    torchStateCallback(state)
                }

                // Register the zoom scale listener
                it.cameraInfo.zoomState.observe(activity) { state ->
                    zoomScaleStateCallback(state.linearZoom.toDouble())
                }

                // Enable torch if provided
                if (it.cameraInfo.hasFlashUnit()) {
                    it.cameraControl.enableTorch(torch)
                }
            }

            val resolution = analysis.resolutionInfo!!.resolution
            val width = resolution.width.toDouble()
            val height = resolution.height.toDouble()
            val portrait = (camera?.cameraInfo?.sensorRotationDegrees ?: 0) % 180 == 0

            // Start with 'unavailable' torch state.
            var currentTorchState: Int = -1

            camera?.cameraInfo?.let {
                if (!it.hasFlashUnit()) {
                    return@let
                }

                currentTorchState = it.torchState.value ?: -1
            }

            mobileScannerStartedCallback(
                MobileScannerStartParameters(
                    if (portrait) width else height,
                    if (portrait) height else width,
                    currentTorchState,
                    textureEntry!!.id(),
                    numberOfCameras ?: 0
                )
            )
        }, executor)

    }
    /**
     * Stop barcode scanning.
     */
    fun stop() {
        if (isStopped()) {
            throw AlreadyStopped()
        }

        if (displayListener != null) {
            val displayManager = activity.applicationContext.getSystemService(Context.DISPLAY_SERVICE) as DisplayManager

            displayManager.unregisterDisplayListener(displayListener)
            displayListener = null
        }

        val owner = activity as LifecycleOwner
        // Release the camera observers first.
        camera?.cameraInfo?.let {
            it.torchState.removeObservers(owner)
            it.zoomState.removeObservers(owner)
            it.cameraState.removeObservers(owner)
        }
        // Unbind the camera use cases, the preview is a use case.
        // The camera will be closed when the last use case is unbound.
        cameraProvider?.unbindAll()
        cameraProvider = null
        camera = null
        preview = null

        // Release the texture for the preview.
        textureEntry?.release()
        textureEntry = null

        barcodeFormats = null
        lastScanned = null
        enableFallbackDecoder = false
        debugDpmFrames = false
        debugDpmSoft = false
    }

    private fun isStopped() = camera == null && preview == null

    /**
     * Toggles the flash light on or off.
     */
    fun toggleTorch() {
        camera?.let {
            if (!it.cameraInfo.hasFlashUnit()) {
                return@let
            }

            when(it.cameraInfo.torchState.value) {
                TorchState.OFF -> it.cameraControl.enableTorch(true)
                TorchState.ON -> it.cameraControl.enableTorch(false)
            }
        }
    }

    /**
     * Analyze a single image.
     */
    fun analyzeImage(
        image: Uri,
        onSuccess: AnalyzerSuccessCallback,
        onError: AnalyzerErrorCallback) {
        try {
            val bitmap = activity.contentResolver.openInputStream(image)?.use { input ->
                BitmapFactory.decodeStream(input)
            }
            if (bitmap == null) {
                onError("Unable to decode image.")
                return
            }
            val barcodeMap = fossBarcodeDecoder
                .decode(bitmap, barcodeFormats)
                .map { barcode -> barcode.data }
            bitmap.recycle()
            if (barcodeMap.isEmpty()) {
                onSuccess(null)
            } else {
                onSuccess(barcodeMap)
            }
        } catch (error: Exception) {
            onError(error.localizedMessage ?: error.toString())
        }
    }

    /**
     * Set the zoom rate of the camera.
     */
    fun setScale(scale: Double) {
        if (scale > 1.0 || scale < 0) throw ZoomNotInRange()
        if (camera == null) throw ZoomWhenStopped()
        camera?.cameraControl?.setLinearZoom(scale.toFloat())
    }

    /**
     * Reset the zoom rate of the camera.
     */
    fun resetScale() {
        if (camera == null) throw ZoomWhenStopped()
        camera?.cameraControl?.setZoomRatio(1f)
    }

    /**
     * Dispose of this scanner instance.
     */
    fun dispose() {
        if (isStopped()) {
            return
        }

        stop() // Defer to the stop method, which disposes all resources anyway.
    }
}
