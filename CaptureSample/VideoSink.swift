import AVFoundation

/// A type that receives compressed frames and creates a destination movie file.
public class VideoSink {
    private let assetWriter: AVAssetWriter
    private let assetWriterInput: AVAssetWriterInput
    private var assetWriterAudioInput: AVAssetWriterInput
    private var sessionStarted = false
    private var hasInitAudio = false
    
    private var bookmarkedURL: URL?
    
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
    public init(fileURL: URL, fileType: AVFileType, codec: CMVideoCodecType, width: Int, height: Int, isRealTime: Bool) throws {
        //very ugly
        let bookmarkedData = UserDefaults.standard.data(forKey: "mostRecentSinkURL")
        var isStale = false
        if bookmarkedData != nil {
            self.bookmarkedURL = try URL(resolvingBookmarkData: bookmarkedData!, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
        }
        if bookmarkedURL?.path() == fileURL.deletingLastPathComponent().path() {
            bookmarkedURL?.startAccessingSecurityScopedResource()
        }
        let sinkURL = fileURL
        let bookmarkData = try sinkURL.deletingLastPathComponent().bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
        UserDefaults.standard.setValue(bookmarkData, forKey: "mostRecentSinkURL")
        assetWriter = try AVAssetWriter(outputURL: sinkURL, fileType: fileType)

        let videoFormatDesc = try CMFormatDescription(videoCodecType: CMFormatDescription.MediaSubType(rawValue: codec), width: width, height: height)

        assetWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: nil, sourceFormatHint: videoFormatDesc)
        let audioFormatDescription = AudioStreamBasicDescription(mSampleRate: 48000.0, mFormatID: kAudioFormatLinearPCM, mFormatFlags: 0x29, mBytesPerPacket: 4, mFramesPerPacket: 1, mBytesPerFrame: 4, mChannelsPerFrame: 2, mBitsPerChannel: 32, mReserved: 0)
        let outputSettings = [
                AVFormatIDKey: UInt(kAudioFormatLinearPCM),
                AVSampleRateKey: 48000,
                AVNumberOfChannelsKey: 2,
                //AVChannelLayoutKey: NSData(bytes:&channelLayout, length:MemoryLayout<AudioChannelLayout>.size),
                AVLinearPCMBitDepthKey: 16,
                AVLinearPCMIsNonInterleaved: false,
                AVLinearPCMIsFloatKey: false,
                AVLinearPCMIsBigEndianKey: false
            ] as [String : Any]
        let cmFormat = try CMFormatDescription(audioStreamBasicDescription: audioFormatDescription)
        assetWriterAudioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: outputSettings, sourceFormatHint: cmFormat)
        
        if isRealTime {
            assetWriterInput.expectsMediaDataInRealTime = true
            assetWriterAudioInput.expectsMediaDataInRealTime = true
        }
        assetWriter.add(assetWriterInput)
        assetWriter.add(assetWriterAudioInput)
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
    
    public func sendAudioBuffer(_ buffer: CMSampleBuffer) {
        guard sessionStarted else { return }
        if assetWriterAudioInput.isReadyForMoreMediaData {
            assetWriterAudioInput.append(buffer)
        }
    }
    
    /// Closes the destination movie file.
    public func close() async throws {
        assetWriterInput.markAsFinished()
        assetWriterAudioInput.markAsFinished()
        await assetWriter.finishWriting()

        if assetWriter.status == .failed {
            throw assetWriter.error!
        }
        bookmarkedURL!.stopAccessingSecurityScopedResource()
    }
}
