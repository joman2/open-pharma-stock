package dev.steenbakker.mobile_scanner.objects

import dev.steenbakker.mobile_scanner.FossBarcodeValues

enum class BarcodeFormats(val intValue: Int) {
    UNKNOWN(FossBarcodeValues.FORMAT_UNKNOWN),
    ALL_FORMATS(FossBarcodeValues.FORMAT_ALL),
    CODE_128(FossBarcodeValues.FORMAT_CODE_128),
    CODE_39(FossBarcodeValues.FORMAT_CODE_39),
    CODE_93(FossBarcodeValues.FORMAT_CODE_93),
    CODABAR(FossBarcodeValues.FORMAT_CODABAR),
    DATA_MATRIX(FossBarcodeValues.FORMAT_DATA_MATRIX),
    EAN_13(FossBarcodeValues.FORMAT_EAN_13),
    EAN_8(FossBarcodeValues.FORMAT_EAN_8),
    ITF(FossBarcodeValues.FORMAT_ITF),
    QR_CODE(FossBarcodeValues.FORMAT_QR_CODE),
    UPC_A(FossBarcodeValues.FORMAT_UPC_A),
    UPC_E(FossBarcodeValues.FORMAT_UPC_E),
    PDF417(FossBarcodeValues.FORMAT_PDF_417),
    AZTEC(FossBarcodeValues.FORMAT_AZTEC);

    companion object {
        fun fromRawValue(rawValue: Int): BarcodeFormats {
            return when(rawValue) {
                -1 -> UNKNOWN
                0 -> ALL_FORMATS
                1 -> CODE_128
                2 -> CODE_39
                4 -> CODE_93
                8 -> CODABAR
                16 -> DATA_MATRIX
                32 -> EAN_13
                64 -> EAN_8
                128 -> ITF
                256 -> QR_CODE
                512 -> UPC_A
                1024 -> UPC_E
                2048 -> PDF417
                4096 -> AZTEC
                else -> UNKNOWN
            }
        }
    }
}
