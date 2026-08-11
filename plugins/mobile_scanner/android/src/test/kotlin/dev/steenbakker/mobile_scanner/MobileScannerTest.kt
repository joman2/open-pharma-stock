package dev.steenbakker.mobile_scanner

import com.google.zxing.BarcodeFormat
import kotlin.test.Test
import kotlin.test.assertEquals

internal class MobileScannerTest {
    @Test
    fun publicFormatValuesRoundTripThroughZxing() {
        val expected = mapOf(
            FossBarcodeValues.FORMAT_CODE_128 to BarcodeFormat.CODE_128,
            FossBarcodeValues.FORMAT_CODE_39 to BarcodeFormat.CODE_39,
            FossBarcodeValues.FORMAT_CODE_93 to BarcodeFormat.CODE_93,
            FossBarcodeValues.FORMAT_CODABAR to BarcodeFormat.CODABAR,
            FossBarcodeValues.FORMAT_DATA_MATRIX to BarcodeFormat.DATA_MATRIX,
            FossBarcodeValues.FORMAT_EAN_13 to BarcodeFormat.EAN_13,
            FossBarcodeValues.FORMAT_EAN_8 to BarcodeFormat.EAN_8,
            FossBarcodeValues.FORMAT_ITF to BarcodeFormat.ITF,
            FossBarcodeValues.FORMAT_QR_CODE to BarcodeFormat.QR_CODE,
            FossBarcodeValues.FORMAT_UPC_A to BarcodeFormat.UPC_A,
            FossBarcodeValues.FORMAT_UPC_E to BarcodeFormat.UPC_E,
            FossBarcodeValues.FORMAT_PDF_417 to BarcodeFormat.PDF_417,
            FossBarcodeValues.FORMAT_AZTEC to BarcodeFormat.AZTEC,
        )

        expected.forEach { (publicValue, zxingValue) ->
            assertEquals(zxingValue, FossBarcodeValues.toZxingFormat(publicValue))
            assertEquals(publicValue, FossBarcodeValues.fromZxingFormat(zxingValue))
        }
    }
}
