package dev.steenbakker.mobile_scanner

import org.opencv.core.CvType
import org.opencv.core.Mat

object DmtxNative {
    private var loaded = false

    init {
        try {
            System.loadLibrary("dmtx_jni")
            loaded = true
        } catch (e: UnsatisfiedLinkError) {
            loaded = false
        }
    }

    external fun decodeGray(gray: ByteArray, width: Int, height: Int): String?

    fun decodeNormalizedMat(normalizedGray: Mat): String? {
        if (!loaded) {
            return null
        }
        if (normalizedGray.type() != CvType.CV_8UC1) {
            return null
        }
        val width = normalizedGray.cols()
        val height = normalizedGray.rows()
        if (width <= 0 || height <= 0) {
            return null
        }
        val bytes = ByteArray(width * height)
        normalizedGray.get(0, 0, bytes)
        return decodeGray(bytes, width, height)
    }
}
