import AVFoundation

/// A type that receives compressed frames and creates a destination movie file.
public class VideoSink {
    private let assetWriter: AVAssetWriter
    private let assetWriterInput: AVAssetWriterInput
    private var sessionStarted = false
    
    /// Creates a video sink or throws an error if it fails.
    /// - Parameters:
    ///   - filePath: The destination movie file path.
    ///   - fileType: The destination movie file type.
    ///   - codec: The codec type that the system uses to compress the video frames.
    ///   - width: The video width.
    ///   - height: The video height.
    ///   - isRealTime: A Boolean value that indicates whether the video sink tailors its processing for real-time sources.
    ///                 Set to `true` if video source operates in real-time like a live camera.
    ///                 Set to `false` for offline transcoding, which may be faster or slower than real-time.
    public init(filePath: String, fileType: AVFileType, codec: CMVideoCodecType, width: Int, height: Int, isRealTime: Bool) throws {
        let sinkURL = URL(fileURLWithPath: filePath)

        assetWriter = try AVAssetWriter(outputURL: sinkURL, fileType: fileType)

        let videoFormatDesc = try CMFormatDescription(videoCodecType: CMFormatDescription.MediaSubType(rawValue: codec), width: width, height: height)

        assetWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: nil, sourceFormatHint: videoFormatDesc)
        if isRealTime {
            assetWriterInput.expectsMediaDataInRealTime = true
        }
        assetWriter.add(assetWriterInput)

        guard assetWriter.startWriting() else {
            throw assetWriter.error!
        }
    }
    
    /// Appends a video frame to the destination movie file.
    /// - Parameter sbuf: A video frame in a `CMSampleBuffer`.
    public func sendSampleBuffer(_ sbuf: CMSampleBuffer) {
        if !sessionStarted {
            assetWriter.startSession(atSourceTime: sbuf.presentationTimeStamp)
            sessionStarted = true
        }
        if assetWriterInput.isReadyForMoreMediaData {
            assetWriterInput.append(sbuf)
        } else {
            print(String(format: "Error: VideoSink dropped a frame [PTS: %.3f]", sbuf.presentationTimeStamp.seconds))
        }
    }
    
    /// Closes the destination movie file.
    public func close() async throws {
        assetWriterInput.markAsFinished()
        await assetWriter.finishWriting()

        if assetWriter.status == .failed {
            throw assetWriter.error!
        }
    }
}
