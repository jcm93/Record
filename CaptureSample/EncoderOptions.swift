import AVFoundation
import VideoToolbox

public struct Options: @unchecked Sendable {

    /// The destination movie file to write output video frames to.
    public let destMovieURL: URL

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

    /// A read only property that shows the configuration values user provides.
    public var description: String {
        return """
            bitrate           : \(destBitRate) bps
            cbr               : \(rateControl)
            codec             : \(codec)
            dimensions        : \(destWidth) x \(destHeight)
            keyframe-duration : \(maxKeyFrameIntervalDuration) sec
            keyframe-interval : \(maxKeyFrameInterval) frames
            out               : \(destMovieURL)
            pixel-format      : \(pixelFormat)
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
    public init(destMovieURL: URL, destFileType: AVFileType, destWidth: Int, destHeight: Int, destBitRate: Int,
                codec: CMVideoCodecType, pixelFormat: OSType, maxKeyFrameIntervalDuration: Double,
                maxKeyFrameInterval: Int, rateControl: RateControlSetting, crfValue: CFNumber, verbose: Bool, iccProfile: CFData?, bitDepth: Int, colorPrimaries: CFString?, transferFunction: CFString?, yuvMatrix: CFString?, bFrames: Bool) {
        self.destMovieURL = destMovieURL
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
    }
}
