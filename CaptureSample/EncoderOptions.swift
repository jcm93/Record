import AVFoundation
import VideoToolbox
import OSLog

public struct OptionsStorable: Encodable, Decodable, Hashable {
    
    public let fileType: ContainerSetting
    public let bitrate: Int
    public let pixelFormat: CapturePixelFormat
    public let primaries: ColorPrimariesSetting
    public let transfer: TransferFunctionSetting
    public let yuv: YCbCrMatrixSetting
    public let bitDepth: Int
    public let usesICC: Bool
    public let maxKeyFrameDuration: Double
    public let maxKeyFrameInterval: Int
    public let rateControl: RateControlSetting
    public let bFrames: Bool
    public let crfValue: Double
    public let gammaValue: Double
    public let convertsColorSpace: Bool
    public let targetColorSpace: CaptureColorSpace
    public let encoderSetting: EncoderSetting
    public let proResSetting: ProResSetting
    public let encoderPixelFormat: CapturePixelFormat
    public let presetName: String
    public let scales: Bool
    public let usesReplayBuffer: Bool
    public let replayBufferDuration: Int
    
    init(fileType: ContainerSetting, bitrate: Int, pixelFormat: CapturePixelFormat, primaries: ColorPrimariesSetting, transfer: TransferFunctionSetting, yuv: YCbCrMatrixSetting, bitDepth: Int, usesICC: Bool, maxKeyFrameDuration: Double, maxKeyFrameInterval: Int, rateControl: RateControlSetting, bFrames: Bool, crfValue: Double, gammaValue: Double, convertsColorSpace: Bool, targetColorSpace: CaptureColorSpace, encoderSetting: EncoderSetting, proResSetting: ProResSetting, encoderPixelFormat: CapturePixelFormat, presetName: String, scales: Bool, usesReplayBuffer: Bool, replayBufferDuration: Int) {
        self.fileType = fileType
        self.bitrate = bitrate
        self.pixelFormat = pixelFormat
        self.primaries = primaries
        self.transfer = transfer
        self.yuv = yuv
        self.bitDepth = bitDepth
        self.usesICC = usesICC
        self.maxKeyFrameDuration = maxKeyFrameDuration
        self.maxKeyFrameInterval = maxKeyFrameInterval
        self.rateControl = rateControl
        self.bFrames = bFrames
        self.crfValue = crfValue
        self.gammaValue = gammaValue
        self.convertsColorSpace = convertsColorSpace
        self.targetColorSpace = targetColorSpace
        self.encoderSetting = encoderSetting
        self.proResSetting = proResSetting
        self.encoderPixelFormat = encoderPixelFormat
        self.presetName = presetName
        self.scales = scales
        self.usesReplayBuffer = usesReplayBuffer
        self.replayBufferDuration = replayBufferDuration
    }
}

public struct Options: @unchecked Sendable {

    /// The destination movie file to write output video frames to.
    public let outputFolder: URL

    /// The destination movie file type.
    public let destFileType: AVFileType

    /// The destination movie width.
    public let destWidth: Int
    
    public let bitDepth: Int

    /// The destination movie height.
    public let destHeight: Int

    /// The destination movie target bit rate in bits per second.
    public let destBitRate: Int

    /// The codec type to encode with.
    public let codec: CMVideoCodecType

    /// The pixel format to encode with.
    public let pixelFormat: OSType
    
    /// The max key frame interval in seconds
    public let maxKeyFrameIntervalDuration: Double

    /// The max key frame interval in number of frames.
    public let maxKeyFrameInterval: Int

    /// Print noisy status if `true`.
    public let verbose: Bool

    /// Replace the destination movie file if it already exists, if `true`.
    public let replace = true
    
    public let iccProfile: CFData?
    
    public let rateControl: RateControlSetting
    
    public let colorPrimaries: CFString?
    
    public let transferFunction: CFString?
    
    public let yuvMatrix: CFString?
    
    public let bFrames: Bool
    
    public let crfValue: CFNumber?
    
    public let gammaValue: Double?
    
    public let convertsColorSpace: Bool
    
    public let targetColorSpace: CFString?
    
    public let usesICC: Bool
    
    public let scales: Bool
    
    public let usesReplayBuffer: Bool
    
    public let replayBufferDuration: Int

    /// A read only property that shows the configuration values user provides.
    public var description: String {
        return """
        Encoder session started with options:
            bitrate           : \(destBitRate) bps
            cbr               : \(rateControl)
            codec             : \(codec.description)
            dimensions        : \(destWidth) x \(destHeight)
            keyframe-duration : \(maxKeyFrameIntervalDuration) sec
            keyframe-interval : \(maxKeyFrameInterval) frames
            out               : \(outputFolder)
            pixel-format      : \(pixelFormat)
            rate-control      : \(rateControl)
            icc-profile       : \(iccProfile.debugDescription)
            bit-depth         : \(bitDepth)
            color-primaries   : \(colorPrimaries)
            transfer-function : \(transferFunction)
            yuv-matrix        : \(yuvMatrix)
            b-frames          : \(bFrames)
            crf-value         : \(crfValue)
            gamma-value       : \(gammaValue)
            converts-color    : \(convertsColorSpace)
            target-space      : \(targetColorSpace)
            uses-ICC          : \(usesICC)
            scales-output     : \(scales)
            uses-buffer       : \(usesReplayBuffer)
            replay-duration   : \(replayBufferDuration)
        """
    }

    /// Create an instance of `Options`.
    /// - Parameters:
    ///   - sourceMoviePath: The file path of the source movie file.
    ///   - destMoviePath: The file path of the destination movie file.
    ///   - destFileType: The destination movie file type.
    ///   - frameCount: The max number of frames to encode.
    ///   - destWidth: The destination movie width.
    ///   - destHeight: The destination movie height.
    ///   - destBitRate: The destination movie bit rate in bits per second.
    ///   - codec: The codec type to encode the movie with.
    ///   - pixelFormat: The pixel format of the uncompressed image to encode.
    ///   - maxKeyFrameIntervalDuration: The max key frame interval in seconds.
    ///   - maxKeyFrameInterval: The max key frame interval in number of frames.
    ///   - cbr: A Boolean value that specifies whether to pad the encoded frame for constant bit rate.
    ///   - verbose: A Boolean value that specifies whether to print frame info.
    public init(outputFolder: URL, destFileType: AVFileType, destWidth: Int, destHeight: Int, destBitRate: Int,
                codec: CMVideoCodecType, pixelFormat: OSType, maxKeyFrameIntervalDuration: Double,
                maxKeyFrameInterval: Int, rateControl: RateControlSetting, crfValue: CFNumber, verbose: Bool, iccProfile: CFData?, bitDepth: Int, colorPrimaries: CFString?, transferFunction: CFString?, yuvMatrix: CFString?, bFrames: Bool, gammaValue: Double?, convertsColorSpace: Bool, targetColorSpace: CFString?, usesICC: Bool, scales: Bool, usesReplayBuffer: Bool, replayBufferDuration: Int) {
        self.outputFolder = outputFolder
        self.destFileType = destFileType
        self.destWidth = destWidth
        self.destHeight = destHeight
        self.destBitRate = destBitRate
        self.codec = codec
        self.pixelFormat = pixelFormat
        self.maxKeyFrameIntervalDuration = maxKeyFrameIntervalDuration
        self.maxKeyFrameInterval = maxKeyFrameInterval
        self.rateControl = rateControl
        self.verbose = verbose
        self.iccProfile = iccProfile
        self.bitDepth = bitDepth
        self.colorPrimaries = colorPrimaries
        self.transferFunction = transferFunction
        self.yuvMatrix = yuvMatrix
        self.bFrames = bFrames
        self.crfValue = crfValue
        self.gammaValue = gammaValue
        self.convertsColorSpace = convertsColorSpace
        self.targetColorSpace = targetColorSpace
        self.usesICC = usesICC
        self.scales = scales
        self.usesReplayBuffer = usesReplayBuffer
        self.replayBufferDuration = replayBufferDuration
    }
    
    func logStart(_ logger: Logger) {
        logger.notice("""
        Encoder session started with options:
            bitrate           : \(destBitRate * 1000, format: .bitrate)
            cbr               : \(rateControl == .cbr)
            codec             : \(codec)
            dimensions        : \(destWidth) x \(destHeight)
            keyframe-duration : \(maxKeyFrameIntervalDuration) seconds
            keyframe-interval : \(maxKeyFrameInterval) frames
            out               : \(outputFolder, privacy: .private(mask: .hash))
            pixel-format      : \(pixelFormat)
            rate-control      : \(rateControl.rawValue)
            icc-profile       : \(iccProfile.debugDescription)
            bit-depth         : \(bitDepth)
            color-primaries   : \(colorPrimaries ?? "untagged" as CFString)
            transfer-function : \(transferFunction ?? "untagged" as CFString)
            yuv-matrix        : \(yuvMatrix)
            b-frames          : \(bFrames)
            crf-value         : \(crfValue)
            gamma-value       : \(gammaValue ?? 0.0, format: .hybrid)
            converts-color    : \(convertsColorSpace)
            target-space      : \(targetColorSpace ?? "nil" as CFString)
            uses-ICC          : \(usesICC)
            scales-output     : \(scales)
            uses-buffer       : \(usesReplayBuffer)
            replay-duration   : \(replayBufferDuration)
        """)
    }
}
