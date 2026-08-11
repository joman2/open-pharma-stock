package dev.steenbakker.mobile_scanner

import android.graphics.ImageFormat
import android.graphics.Point
import android.graphics.Rect
import android.graphics.YuvImage
import android.media.Image
import java.io.ByteArrayOutputStream

fun Image.toByteArray(): ByteArray {
    val yBuffer = planes[0].buffer
    val vuBuffer = planes[2].buffer
    val ySize = yBuffer.remaining()
    val vuSize = vuBuffer.remaining()
    val nv21 = ByteArray(ySize + vuSize)

    yBuffer.get(nv21, 0, ySize)
    vuBuffer.get(nv21, ySize, vuSize)

    val yuvImage = YuvImage(nv21, ImageFormat.NV21, width, height, null)
    return ByteArrayOutputStream().use { output ->
        yuvImage.compressToJpeg(
            Rect(0, 0, yuvImage.width, yuvImage.height),
            50,
            output,
        )
        output.toByteArray()
    }
}

val FossBarcode.data: Map<String, Any?>
    get() = mapOf(
        "calendarEvent" to null,
        "contactInfo" to null,
        "corners" to cornerPoints?.map { corner -> corner.data },
        "displayValue" to displayValue,
        "driverLicense" to null,
        "email" to null,
        "format" to format,
        "geoPoint" to null,
        "phone" to null,
        "rawBytes" to rawBytes,
        "rawValue" to rawValue,
        "size" to boundingBox?.size,
        "sms" to null,
        "type" to FossBarcodeValues.TYPE_TEXT,
        "url" to null,
        "wifi" to null,
    )

fun FossBarcode.dataWithTracking(
    inScanWindow: Boolean,
    track: Map<String, Any?>? = null,
): Map<String, Any?> =
    data.toMutableMap().apply {
        this["inScanWindow"] = inScanWindow
        if (track != null) {
            this["track"] = track
        }
    }

val Point.data: Map<String, Double>
    get() = mapOf("x" to x.toDouble(), "y" to y.toDouble())

fun Rect.dataRect(): Map<String, Double> = mapOf(
    "left" to left.toDouble(),
    "top" to top.toDouble(),
    "right" to right.toDouble(),
    "bottom" to bottom.toDouble(),
)

private val Rect.size: Map<String, Any?>
    get() {
        if (left <= right && top <= bottom) {
            return mapOf(
                "width" to width().toDouble(),
                "height" to height().toDouble(),
            )
        }
        return emptyMap()
    }
