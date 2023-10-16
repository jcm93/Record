import AVFoundation
import OSLog

/// A type that receives compressed frames and creates a destination movie file.
public class VideoSink {
    private var assetWriter: AVAssetWriter!
    private var assetWriterInput: AVAssetWriterInput!
    private var assetWriterAudioInput: AVAssetWriterInput!
    private var sessionStarted = false
    private var hasInitAudio = false
    var videoReplayBuffer: ReplayBuffer?
    var audioReplayBuffer: ReplayBuffer?
    var replayBufferQueue = DispatchQueue(label: "com.jcm.replayBufferQueue")
    var isStopping = false
    var audioFrameCount = 0
    var usingReplayBuffer = true
    var stupidTemporaryBuffer = [CMSampleBuffer]()
    var hasStarted = false
    
    var mostRecentImageBuffer: CVImageBuffer?
    var mostRecentSampleBuffer: CMSampleBuffer?
    
    private var bookmarkedURL: URL?
    
    private let logger = Logger.videoSink
    
    private let outputFolder: URL
    private let fileType: AVFileType
    private let codec: CMVideoCodecType
    private let width: Int
    private let height: Int
    private let isRealTime: Bool
    private let usesReplayBuffer: Bool
    private let replayBufferDuration: Int
    
    var accessingBookmarkURL = false
    
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
    public init(outputFolder: URL, fileType: AVFileType, codec: CMVideoCodecType, width: Int, height: Int, isRealTime: Bool, usesReplayBuffer: Bool, replayBufferDuration: Int) {
        self.outputFolder = outputFolder
        self.fileType = fileType
        self.codec = codec
        self.width = width
        self.height = height
        self.isRealTime = isRealTime
        self.usesReplayBuffer = usesReplayBuffer
        self.replayBufferDuration = replayBufferDuration
        if usesReplayBuffer {
            self.videoReplayBuffer = ReplayBuffer(buffer: [], maxLengthInSeconds: Double(replayBufferDuration))
            self.audioReplayBuffer = ReplayBuffer(buffer: [], maxLengthInSeconds: Double(replayBufferDuration))
        }
        self.isStopping = false
    }
    
    /// Appends a video frame to the destination movie file.
    /// - Parameter sbuf: A video frame in a `CMSampleBuffer`.
    public func sendSampleBuffer(_ sbuf: CMSampleBuffer) {
        if self.videoReplayBuffer != nil && !self.isStopping {
            self.replayBufferQueue.schedule {
                //nil check again; by the time this reaches the replay queue it might be nil
                if self.videoReplayBuffer != nil && !self.isStopping {
                    self.videoReplayBuffer!.addSampleBuffer(sbuf)
                }
            }
        } else {
            if assetWriterInput != nil && assetWriterInput.isReadyForMoreMediaData {
                assetWriterInput.append(sbuf)
            } else {
                let debugString = String(format: "Error: VideoSink dropped a frame [PTS: %.3f]", sbuf.presentationTimeStamp.seconds)
                self.logger.fault("\(debugString, privacy: .public)")
            }
        }
    }
    
    func startSession(_ sbuf: CMSampleBuffer) throws {
        if self.videoReplayBuffer == nil {
            try initializeAssetWriters()
            self.assetWriter.startSession(atSourceTime: sbuf.presentationTimeStamp)
            self.sessionStarted = true
        }
        logger.notice("Recording session started. Initial timestamp: \(sbuf.presentationTimeStamp.seconds, privacy: .public)")
        if sbuf.formatDescription?.mediaType == .audio {
            sendAudioBuffer(sbuf)
        } else {
            sendSampleBuffer(sbuf)
        }
        self.hasStarted = true
    }
    
    func initializeAssetWriters() throws {
        //pretty ugly still
        logger.notice("Initializing file asset writers.")
        do {
            let bookmarkedData = UserDefaults.standard.data(forKey: "mostRecentSinkURL")
            var isStale = false
            if bookmarkedData != nil {
                self.bookmarkedURL = try URL(resolvingBookmarkData: bookmarkedData!, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
            }
            if bookmarkedURL?.path() == outputFolder.path() {
                self.accessingBookmarkURL = true
                bookmarkedURL?.startAccessingSecurityScopedResource()
            }
            let fileExtension = self.fileType == .mov ? "mov" : "mp4"
            let sinkURL = outputFolder.appendingRecordFilename(fileExtension: fileExtension)
            let bookmarkData = try outputFolder.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
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
            
            
            assetWriterInput.expectsMediaDataInRealTime = true
            assetWriterAudioInput.expectsMediaDataInRealTime = true
            
            assetWriter.add(assetWriterInput)
            assetWriter.add(assetWriterAudioInput)
            guard assetWriter.startWriting() else {
                throw assetWriter.error!
            }
        } catch {
            logger.fault("Critical error initializing asset writers: \(error, privacy: .public)")
            if self.accessingBookmarkURL {
                self.bookmarkedURL?.stopAccessingSecurityScopedResource()
                self.accessingBookmarkURL = false
            }
            self.assetWriter?.cancelWriting()
            //this should be all the cleanup we need. everything else with `try`
            //shouldn't have any side effects, unlike AVAssetWriter and security-scoped bookmark
        }
    }
    
    public func sendAudioBuffer(_ buffer: CMSampleBuffer) {
        if self.audioReplayBuffer != nil && !self.isStopping {
            self.replayBufferQueue.schedule {
                self.audioReplayBuffer!.addSampleBuffer(buffer)
            }
        } else {
            guard sessionStarted else { return }
            if assetWriterAudioInput.isReadyForMoreMediaData {
                assetWriterAudioInput.append(buffer)
            }
        }
    }
    
    func saveReplayBuffer() throws {
        guard let videoReplayBuffer = self.videoReplayBuffer, let audioReplayBuffer = self.audioReplayBuffer else { throw EncoderError.replayBufferIsNil }
        try self.initializeAssetWriters()
        let firstNonKeyframe = self.videoReplayBuffer!.firstNonKeyframe()
        if !self.sessionStarted { self.assetWriter.startSession(atSourceTime: firstNonKeyframe!.presentationTimeStamp) }
        defer {
            Task {
                self.assetWriterAudioInput.markAsFinished()
                self.assetWriterInput.markAsFinished()
                await assetWriter.finishWriting()
            }
        }
        var finished = false
        var previousVideoFrame: CMSampleBuffer?
        var previousAudioFrame: CMSampleBuffer?
        var videoReadIndex = 0, audioReadIndex = 0, retryCount = 0
        while !finished {
            guard retryCount < 15 else {
                finished = true
                self.assetWriterAudioInput.markAsFinished()
                self.assetWriterInput.markAsFinished()
                Task {
                    await assetWriter.finishWriting()
                }
                throw EncoderError.replayBufferRetryLimitExceeded
            }
            if videoReadIndex >= videoReplayBuffer.buffer.count && audioReadIndex >= audioReplayBuffer.buffer.count {
                self.assetWriterAudioInput.markAsFinished()
                self.assetWriterInput.markAsFinished()
                finished = true
                logger.notice("Wrote all samples in replay buffer; finishing up.")
                continue
            }
            let videoFrame = videoReplayBuffer.sampleAtIndex(index: videoReadIndex)
            let audioFrame = audioReplayBuffer.sampleAtIndex(index: audioReadIndex)
            let frame = videoFrame.isBefore(otherBuffer: audioFrame) ? videoFrame : audioFrame
            switch frame.formatDescription!.mediaType {
            case .audio:
                if let pFrame = previousAudioFrame {
                    guard CMTimeCompare(frame.presentationTimeStamp, pFrame.presentationTimeStamp) > 0 else {
                        logger.fault("trying to encode an audio frame ordered before the previous frame encoded; this is a fault. exiting replay buffer save early")
                        finished = true
                        continue
                    }
                }
                if self.assetWriterAudioInput.isReadyForMoreMediaData {
                    let result = self.assetWriterAudioInput.append(frame)
                    if !result {
                        logger.notice("Audio asset writer failed to write a frame. Retrying; retry count is \(retryCount, privacy: .public) out of 15.")
                    }
                    previousAudioFrame = frame
                    audioReadIndex += 1
                    retryCount = 0
                } else {
                    retryCount += 1
                    Thread.sleep(forTimeInterval: 0.1)
                }
            case .video:
                if let pFrame = previousVideoFrame {
                    guard CMTimeCompare(frame.presentationTimeStamp, pFrame.presentationTimeStamp) > 0 else {
                        logger.fault("trying to encode a video frame ordered before the previous frame encoded; this is a fault. exiting replay buffer save early")
                        finished = true
                        continue
                    }
                }
                if self.assetWriterInput.isReadyForMoreMediaData {
                    let result = self.assetWriterInput.append(frame)
                    if !result {
                        logger.notice("Video asset writer failed to write a frame. Retrying; retry count is \(retryCount, privacy: .public) out of 15.")
                    }
                    previousVideoFrame = frame
                    videoReadIndex += 1
                    retryCount = 0
                } else {
                    retryCount += 1
                    Thread.sleep(forTimeInterval: 0.1)
                }
            default:
                logger.notice("Encountered unknown media type in replay buffer; skipping")
            }
        }
        logger.notice("""
                        Replay buffer wrote:
                        \(videoReadIndex, privacy: .public) out of \(String(self.videoReplayBuffer?.buffer.count ?? 0), privacy: .public) video frames,
                        \(audioReadIndex) out of \(String(self.audioReplayBuffer?.buffer.count ?? 0), privacy: .public) audio frames.
                        """)
    }
    
    func stopReplayBuffer() throws {
        self.videoReplayBuffer = nil
        self.audioReplayBuffer = nil
    }
    
    /// Closes the destination movie file.
    public func close() async throws {
        self.isStopping = true
        self.videoReplayBuffer?.isStopping = true
        self.audioReplayBuffer?.isStopping = true
        assetWriterInput?.markAsFinished()
        assetWriterAudioInput?.markAsFinished()
        if assetWriter != nil && assetWriter.status == .writing {
            await assetWriter?.finishWriting()
        }

        if assetWriter?.status == .failed {
            throw assetWriter.error!
        }
        bookmarkedURL?.stopAccessingSecurityScopedResource()
    }
}

private extension URL {
    func appendingRecordFilename(fileExtension: String) -> URL {
        let date = Date()
        let filename = (date.formatted(date: .omitted, time: .complete) + ", " + date.formatted(date: .abbreviated, time: .omitted)).replacingOccurrences(of: ":", with: "-")
        let newURL = self.appending(component: filename).appendingPathExtension(fileExtension)
        return newURL
    }
}
