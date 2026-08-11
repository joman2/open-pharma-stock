package dev.steenbakker.mobile_scanner

import android.graphics.Bitmap
import android.graphics.Point
import android.graphics.Rect
import androidx.camera.core.ImageProxy
import com.google.zxing.BarcodeFormat
import com.google.zxing.BinaryBitmap
import com.google.zxing.DecodeHintType
import com.google.zxing.LuminanceSource
import com.google.zxing.MultiFormatReader
import com.google.zxing.RGBLuminanceSource
import com.google.zxing.Result
import com.google.zxing.ResultPoint
import com.google.zxing.common.HybridBinarizer
import com.google.zxing.multi.GenericMultipleBarcodeReader
import java.util.EnumMap
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt

/**
 * Minimal barcode representation used by the FLOSS Android scanner.
 *
 * The integer values intentionally match mobile_scanner's public Dart protocol,
 * which historically mirrored ML Kit. No Google barcode runtime is required.
 */
data class FossBarcode(
    val rawValue: String?,
    val displayValue: String?,
    val format: Int,
    val boundingBox: Rect?,
    val cornerPoints: Array<Point>?,
    val rawBytes: ByteArray?,
)

object FossBarcodeValues {
    const val FORMAT_UNKNOWN = -1
    const val FORMAT_ALL = 0
    const val FORMAT_CODE_128 = 1
    const val FORMAT_CODE_39 = 2
    const val FORMAT_CODE_93 = 4
    const val FORMAT_CODABAR = 8
    const val FORMAT_DATA_MATRIX = 16
    const val FORMAT_EAN_13 = 32
    const val FORMAT_EAN_8 = 64
    const val FORMAT_ITF = 128
    const val FORMAT_QR_CODE = 256
    const val FORMAT_UPC_A = 512
    const val FORMAT_UPC_E = 1024
    const val FORMAT_PDF_417 = 2048
    const val FORMAT_AZTEC = 4096

    // mobile_scanner's Dart enum uses the historical ML Kit value for text.
    const val TYPE_TEXT = 7

    fun toZxingFormat(value: Int): BarcodeFormat? = when (value) {
        FORMAT_CODE_128 -> BarcodeFormat.CODE_128
        FORMAT_CODE_39 -> BarcodeFormat.CODE_39
        FORMAT_CODE_93 -> BarcodeFormat.CODE_93
        FORMAT_CODABAR -> BarcodeFormat.CODABAR
        FORMAT_DATA_MATRIX -> BarcodeFormat.DATA_MATRIX
        FORMAT_EAN_13 -> BarcodeFormat.EAN_13
        FORMAT_EAN_8 -> BarcodeFormat.EAN_8
        FORMAT_ITF -> BarcodeFormat.ITF
        FORMAT_QR_CODE -> BarcodeFormat.QR_CODE
        FORMAT_UPC_A -> BarcodeFormat.UPC_A
        FORMAT_UPC_E -> BarcodeFormat.UPC_E
        FORMAT_PDF_417 -> BarcodeFormat.PDF_417
        FORMAT_AZTEC -> BarcodeFormat.AZTEC
        else -> null
    }

    fun fromZxingFormat(value: BarcodeFormat): Int = when (value) {
        BarcodeFormat.CODE_128 -> FORMAT_CODE_128
        BarcodeFormat.CODE_39 -> FORMAT_CODE_39
        BarcodeFormat.CODE_93 -> FORMAT_CODE_93
        BarcodeFormat.CODABAR -> FORMAT_CODABAR
        BarcodeFormat.DATA_MATRIX -> FORMAT_DATA_MATRIX
        BarcodeFormat.EAN_13 -> FORMAT_EAN_13
        BarcodeFormat.EAN_8 -> FORMAT_EAN_8
        BarcodeFormat.ITF -> FORMAT_ITF
        BarcodeFormat.QR_CODE -> FORMAT_QR_CODE
        BarcodeFormat.UPC_A -> FORMAT_UPC_A
        BarcodeFormat.UPC_E -> FORMAT_UPC_E
        BarcodeFormat.PDF_417 -> FORMAT_PDF_417
        BarcodeFormat.AZTEC -> FORMAT_AZTEC
        else -> FORMAT_UNKNOWN
    }
}

class FossBarcodeDecoder {
    fun decode(
        imageProxy: ImageProxy,
        formats: Set<BarcodeFormat>?,
    ): List<FossBarcode> {
        val original = copyLuminancePlane(imageProxy)
        val rotation = normalizeRotation(imageProxy.imageInfo.rotationDegrees)
        val rotated = rotateLuminance(
            original,
            imageProxy.width,
            imageProxy.height,
            rotation,
        )
        val width = if (rotation == 90 || rotation == 270) imageProxy.height else imageProxy.width
        val height = if (rotation == 90 || rotation == 270) imageProxy.width else imageProxy.height
        val source = com.google.zxing.PlanarYUVLuminanceSource(
            rotated,
            width,
            height,
            0,
            0,
            width,
            height,
            false,
        )
        return decodeSource(source, formats)
    }

    fun decode(
        bitmap: Bitmap,
        formats: Set<BarcodeFormat>?,
    ): List<FossBarcode> {
        val pixels = IntArray(bitmap.width * bitmap.height)
        bitmap.getPixels(
            pixels,
            0,
            bitmap.width,
            0,
            0,
            bitmap.width,
            bitmap.height,
        )
        return decodeSource(
            RGBLuminanceSource(bitmap.width, bitmap.height, pixels),
            formats,
        )
    }

    private fun decodeSource(
        source: LuminanceSource,
        formats: Set<BarcodeFormat>?,
    ): List<FossBarcode> {
        val results = linkedMapOf<String, FossBarcode>()
        decodePass(source, formats).forEach { result ->
            results[resultKey(result)] = result.toFossBarcode()
        }
        decodePass(source.invert(), formats).forEach { result ->
            results.putIfAbsent(resultKey(result), result.toFossBarcode())
        }
        return results.values.toList()
    }

    private fun decodePass(
        source: LuminanceSource,
        formats: Set<BarcodeFormat>?,
    ): List<Result> {
        val hints = EnumMap<DecodeHintType, Any>(DecodeHintType::class.java).apply {
            this[DecodeHintType.TRY_HARDER] = java.lang.Boolean.TRUE
            if (!formats.isNullOrEmpty()) {
                this[DecodeHintType.POSSIBLE_FORMATS] = formats.toList()
            }
        }
        val reader = MultiFormatReader().apply { setHints(hints) }
        val bitmap = BinaryBitmap(HybridBinarizer(source))
        return try {
            GenericMultipleBarcodeReader(reader).decodeMultiple(bitmap, hints).toList()
        } catch (_: Exception) {
            try {
                listOf(reader.decodeWithState(bitmap))
            } catch (_: Exception) {
                emptyList()
            } finally {
                reader.reset()
            }
        }
    }

    private fun resultKey(result: Result): String =
        "${result.barcodeFormat}:${result.text}"

    private fun Result.toFossBarcode(): FossBarcode {
        val points = resultPoints?.filterNotNull().orEmpty()
        val rect = points.toBoundingRect()
        val corners = rect?.let {
            arrayOf(
                Point(it.left, it.top),
                Point(it.right, it.top),
                Point(it.right, it.bottom),
                Point(it.left, it.bottom),
            )
        }
        return FossBarcode(
            rawValue = text,
            displayValue = text,
            format = FossBarcodeValues.fromZxingFormat(barcodeFormat),
            boundingBox = rect,
            cornerPoints = corners,
            rawBytes = rawBytes,
        )
    }

    private fun List<ResultPoint>.toBoundingRect(): Rect? {
        if (isEmpty()) {
            return null
        }
        val minX = minOf { it.x }.roundToInt()
        val maxX = maxOf { it.x }.roundToInt()
        val minY = minOf { it.y }.roundToInt()
        val maxY = maxOf { it.y }.roundToInt()
        val padding = 12
        return Rect(
            max(0, minX - padding),
            max(0, minY - padding),
            max(minX + 1, maxX + padding),
            max(minY + 1, maxY + padding),
        )
    }

    private fun copyLuminancePlane(imageProxy: ImageProxy): ByteArray {
        val plane = imageProxy.planes[0]
        val buffer = plane.buffer.duplicate()
        buffer.rewind()
        val bytes = ByteArray(buffer.remaining())
        buffer.get(bytes)

        val output = ByteArray(imageProxy.width * imageProxy.height)
        var outputIndex = 0
        for (y in 0 until imageProxy.height) {
            val rowOffset = y * plane.rowStride
            for (x in 0 until imageProxy.width) {
                val inputIndex = rowOffset + (x * plane.pixelStride)
                output[outputIndex++] = bytes[inputIndex]
            }
        }
        return output
    }

    private fun normalizeRotation(rotation: Int): Int =
        ((rotation % 360) + 360) % 360

    private fun rotateLuminance(
        input: ByteArray,
        width: Int,
        height: Int,
        rotation: Int,
    ): ByteArray {
        if (rotation == 0) {
            return input
        }
        val output = ByteArray(input.size)
        when (rotation) {
            90 -> {
                for (y in 0 until height) {
                    for (x in 0 until width) {
                        output[x * height + (height - y - 1)] = input[y * width + x]
                    }
                }
            }
            180 -> {
                for (index in input.indices) {
                    output[input.lastIndex - index] = input[index]
                }
            }
            270 -> {
                for (y in 0 until height) {
                    for (x in 0 until width) {
                        output[(width - x - 1) * height + y] = input[y * width + x]
                    }
                }
            }
            else -> return input
        }
        return output
    }
}
