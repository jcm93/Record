import Foundation
import VideoToolbox

public enum CaptureType: Int, Codable, CaseIterable {
    case display
    case window
}

public enum EncoderSetting: Int, Codable, CaseIterable {
    case H264
    case H265
    case ProRes
    func stringValue() -> String {
        switch self {
        case .H264:
            return "H.264"
        case .H265:
            return "HEVC"
        case .ProRes:
            return "ProRes"
        }
    }
}

public enum ProResSetting: Int, Codable, CaseIterable {
    case ProRes422
    case ProRes4444
    case ProResRAW
    case ProRes422HQ
    case ProRes422LT
    case ProResRAWHQ
    case ProRes4444XQ
    case ProRes422Proxy
    func codecValue() -> CMVideoCodecType {
        switch self {
        case .ProRes422:
            return kCMVideoCodecType_AppleProRes422
        case .ProRes4444:
            return kCMVideoCodecType_AppleProRes4444
        case .ProResRAW:
            return kCMVideoCodecType_AppleProResRAW
        case .ProRes422HQ:
            return kCMVideoCodecType_AppleProRes422HQ
        case .ProRes422LT:
            return kCMVideoCodecType_AppleProRes422LT
        case .ProResRAWHQ:
            return kCMVideoCodecType_AppleProResRAWHQ
        case .ProRes4444XQ:
            return kCMVideoCodecType_AppleProRes4444XQ
        case .ProRes422Proxy:
            return kCMVideoCodecType_AppleProRes422Proxy
        }
    }
    func stringValue() -> String {
        switch self {
        case .ProRes422:
            return "ProRes 422"
        case .ProRes4444:
            return "ProRes 4444"
        case .ProResRAW:
            return "ProRes RAW"
        case .ProRes422HQ:
            return "ProRes 422 HQ"
        case .ProRes422LT:
            return "ProRes 422 LT"
        case .ProResRAWHQ:
            return "ProRes RAW HQ"
        case .ProRes4444XQ:
            return "ProRes 4444 XQ"
        case .ProRes422Proxy:
            return "ProRes 422 Proxy"
        }
    }
}

public enum ContainerSetting: Int, Codable, CaseIterable {
    case mov
    case mp4
}

public enum YCbCrMatrixSetting: Int, Codable, CaseIterable {
    case ITU_R_2020
    case ITU_R_709_2
    case ITU_R_601_2
    case SMPTE_240M_1995
    case untagged
    func stringValue() -> CFString? {
        switch self {
        case .ITU_R_2020:
            return kCVImageBufferYCbCrMatrix_ITU_R_2020
        case .ITU_R_709_2:
            return kCVImageBufferYCbCrMatrix_ITU_R_709_2
        case .untagged:
            return nil
        case .ITU_R_601_2:
            return kCVImageBufferYCbCrMatrix_ITU_R_601_4
        case .SMPTE_240M_1995:
            return kCVImageBufferYCbCrMatrix_SMPTE_240M_1995
        }
    }
}

public enum ColorPrimariesSetting: Int, Codable, CaseIterable {
    case P3_D65
    case DCI_P3
    case ITU_R_709_2
    case EBU_3213
    case SMPTE_C
    case ITU_R_2020
    case P22
    case untagged
    func stringValue() -> CFString? {
        switch self {
        case .DCI_P3:
            return kCVImageBufferColorPrimaries_DCI_P3
        case .P3_D65:
            return kCVImageBufferColorPrimaries_P3_D65
        case .untagged:
            return nil
        case .ITU_R_709_2:
            return kCVImageBufferColorPrimaries_ITU_R_709_2
        case .EBU_3213:
            return kCVImageBufferColorPrimaries_EBU_3213
        case .SMPTE_C:
            return kCVImageBufferColorPrimaries_SMPTE_C
        case .ITU_R_2020:
            return kCVImageBufferColorPrimaries_ITU_R_2020
        case .P22:
            return kCVImageBufferColorPrimaries_P22
        }
    }
}

public enum TransferFunctionSetting: Int, Codable, CaseIterable {
    case ITU_R_709_2
    case SMPTE_240M_1995
    case useGamma
    case sRGB
    case ITU_R_2020
    case SMPTE_ST_428_1
    case ITU_R_2100_HLG
    case SMPTE_ST_2084_PQ
    case untagged
    func stringValue() -> CFString? {
        switch self {
        case .ITU_R_709_2:
            return kCVImageBufferTransferFunction_ITU_R_709_2
        case .SMPTE_240M_1995:
            return kCVImageBufferTransferFunction_SMPTE_240M_1995
        case .useGamma:
            return kCVImageBufferTransferFunction_UseGamma
        case .sRGB:
            return kCVImageBufferTransferFunction_sRGB
        case .ITU_R_2020:
            return kCVImageBufferTransferFunction_ITU_R_2020
        case .SMPTE_ST_428_1:
            return kCVImageBufferTransferFunction_SMPTE_ST_428_1
        case .ITU_R_2100_HLG:
            return kCVImageBufferTransferFunction_ITU_R_2100_HLG
        case .SMPTE_ST_2084_PQ:
            return kCVImageBufferTransferFunction_SMPTE_ST_2084_PQ
        case .untagged:
            return nil
        }
    }
}

public enum KeyframeSetting: Int, Codable, CaseIterable {
    case auto
    case custom
}

public enum KeyframeDurationSetting: Int, Codable, CaseIterable {
    case unlimited
    case custom
}

public enum BitDepthSetting: Int, Codable, CaseIterable {
    case eight
    case ten
}

public enum CapturePixelFormat: Int, Codable, CaseIterable {
    case bgra
    case l10r
    case biplanarpartial420v
    case biplanarfull420f
    func osTypeFormat() -> OSType {
        switch self {
        case .bgra:
            return kCVPixelFormatType_32BGRA
        case .l10r:
            return kCVPixelFormatType_ARGB2101010LEPacked
        case .biplanarpartial420v:
            return kCVPixelFormatType_420YpCbCr10BiPlanarVideoRange
        case .biplanarfull420f:
            return kCVPixelFormatType_420YpCbCr10BiPlanarFullRange
        }
    }
    func stringValue() -> String {
        switch self {
        case .bgra:
            return "BGRA"
        case .l10r:
            return "l10r"
        case .biplanarpartial420v:
            return "420v"
        case .biplanarfull420f:
            return "420f"
        }
    }
}

public enum CaptureYUVMatrix: Int, Codable, CaseIterable {
    case itu_r_709
    case itu_r_601
    case smpte_240m_1995
    func cfStringFormat() -> CFString {
        switch self {
        case .itu_r_709:
            return CGDisplayStream.yCbCrMatrix_ITU_R_709_2
        case .itu_r_601:
            return CGDisplayStream.yCbCrMatrix_ITU_R_601_4
        case .smpte_240m_1995:
            return CGDisplayStream.yCbCrMatrix_SMPTE_240M_1995
        }
    }
    func stringValue() -> String {
        switch self {
        case .itu_r_709:
            return "709"
        case .itu_r_601:
            return "601"
        case .smpte_240m_1995:
            return "SMPTE 240M 1995"
        }
    }
}

public enum RateControlSetting: Int, Codable, CaseIterable {
    case cbr
    case abr
    case crf
}

public enum CaptureColorSpace: Int, Codable, CaseIterable {
    case displayp3
    case displayp3hlg
    case displayp3pq
    case extendedlineardisplayp3
    case srgb
    case linearsrgb
    case extendedlinearsrgb
    case genericgraygamma22
    case lineargray
    case extendedgray
    case extendedlineargray
    case genericrgblinear
    case cmyk
    case xyz
    case genericlab
    case acescg
    case adobergb98
    case dcip3
    case itur709
    case rommrgb
    case itur2020
    case itur2020hlg
    case itur2020pq
    case extendedlinearitur2020
    
    func cfString() -> CFString {
        switch self {
        case .displayp3:
            return CGColorSpace.displayP3
        case .displayp3hlg:
            return CGColorSpace.displayP3_HLG
        case .displayp3pq:
            return CGColorSpace.displayP3_PQ
        case .extendedlineardisplayp3:
            return CGColorSpace.extendedLinearDisplayP3
        case .srgb:
            return CGColorSpace.sRGB
        case .linearsrgb:
            return CGColorSpace.linearSRGB
        case .extendedlinearsrgb:
            return CGColorSpace.extendedLinearSRGB
        case .genericgraygamma22:
            return CGColorSpace.genericGrayGamma2_2
        case .lineargray:
            return CGColorSpace.linearGray
        case .extendedgray:
            return CGColorSpace.extendedGray
        case .extendedlineargray:
            return CGColorSpace.extendedLinearGray
        case .genericrgblinear:
            return CGColorSpace.genericRGBLinear
        case .cmyk:
            return CGColorSpace.genericCMYK
        case .xyz:
            return CGColorSpace.genericXYZ
        case .genericlab:
            return CGColorSpace.genericLab
        case .acescg:
            return CGColorSpace.acescgLinear
        case .adobergb98:
            return CGColorSpace.adobeRGB1998
        case .dcip3:
            return CGColorSpace.dcip3
        case .itur709:
            return CGColorSpace.itur_709
        case .rommrgb:
            return CGColorSpace.rommrgb
        case .itur2020:
            return CGColorSpace.itur_2020
        case .itur2020hlg:
            return CGColorSpace.itur_2020_HLG
        case .itur2020pq:
            return CGColorSpace.itur_2020_PQ
        case .extendedlinearitur2020:
            return CGColorSpace.extendedLinearITUR_2020
        }
    }
}

public func getCodecType(_ storableOptions: OptionsStorable) -> CMVideoCodecType {
    switch storableOptions.encoderSetting {
    case .H264:
        return kCMVideoCodecType_H264
    case .H265:
        return kCMVideoCodecType_HEVC
    case .ProRes:
        return storableOptions.proResSetting.codecValue()
    }
}
