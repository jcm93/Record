import AVFoundation
import OSLog

/// A type that receives compressed frames and creates a destination movie file.
public class VideoSink {
    private var assetWriter: AVAssetWriter!
    private var assetWriterInput: AVAssetWriterInput!
    private var assetWriterAudioInput: AVAssetWriterInput!
    private var sessionStarted = false
    private var hasInitAudio = false
    var replayBuffer: ReplayBuffer?
    var audioReplayBuffer: ReplayBuffer?
    var replayBufferQueue = DispatchQueue(label: "com.jcm.replayBufferQueue")
    var isStopping = false
    var audioFrameCount = 0
    var usingReplayBuffer = true
    var stupidTemporaryBuffer = [CMSampleBuffer]()
    var hasStarted = false
    
    private var bookmarkedURL: URL?
    
    private let logger = Logger.videoSink
    
    var fileURL: URL
    var fileType: AVFileType
    var codec: CMVideoCodecType
    var width: Int
    var height: Int
    var isRealTime: Bool
    var usesReplayBuffer: Bool
    var replayBufferDuration: Int
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
    public init(fileURL: URL, fileType: AVFileType, codec: CMVideoCodecType, width: Int, height: Int, isRealTime: Bool, usesReplayBuffer: Bool, replayBufferDuration: Int) {
        self.fileURL = fileURL
        self.fileType = fileType
        self.codec = codec
        self.width = width
        self.height = height
        self.isRealTime = isRealTime
        self.usesReplayBuffer = usesReplayBuffer
        self.replayBufferDuration = replayBufferDuration
        if usesReplayBuffer {
            self.replayBuffer = ReplayBuffer(buffer: [], maxLengthInSeconds: replayBufferDuration)
            self.audioReplayBuffer = ReplayBuffer(buffer: [], maxLengthInSeconds: replayBufferDuration)
        }
        self.isStopping = false
    }
    
    /// Appends a video frame to the destination movie file.
    /// - Parameter sbuf: A video frame in a `CMSampleBuffer`.
    public func sendSampleBuffer(_ sbuf: CMSampleBuffer) {
        if self.replayBuffer != nil && !self.isStopping {
            self.replayBufferQueue.schedule {
                self.replayBuffer!.addSampleBuffer(sbuf)
            }
        } else {
            if assetWriterInput.isReadyForMoreMediaData {
                assetWriterInput.append(sbuf)
            } else {
                let debugString = String(format: "Error: VideoSink dropped a frame [PTS: %.3f]", sbuf.presentationTimeStamp.seconds)
                self.logger.fault("\(debugString, privacy: .public)")
            }
        }
    }
    
    func startSession(_ sbuf: CMSampleBuffer) throws {
        if self.replayBuffer == nil {
            try initializeAssetWriters()
            self.assetWriter.startSession(atSourceTime: sbuf.presentationTimeStamp)
            self.sessionStarted = true
        }
        print("started at \(sbuf.presentationTimeStamp.seconds)")
        if sbuf.formatDescription?.mediaType == .audio {
            sendAudioBuffer(sbuf)
        } else {
            sendSampleBuffer(sbuf)
        }
        self.hasStarted = true
    }
    
    func initializeAssetWriters() throws {
        //pretty ugly still
        do {
            let bookmarkedData = UserDefaults.standard.data(forKey: "mostRecentSinkURL")
            var isStale = false
            if bookmarkedData != nil {
                self.bookmarkedURL = try URL(resolvingBookmarkData: bookmarkedData!, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
            }
            if bookmarkedURL?.path() == fileURL.deletingLastPathComponent().path() {
                self.accessingBookmarkURL = true
                bookmarkedURL?.startAccessingSecurityScopedResource()
            }
            let sinkURL = fileURL.uniquing()
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
            
            
            assetWriterInput.expectsMediaDataInRealTime = true
            assetWriterAudioInput.expectsMediaDataInRealTime = true
            
            assetWriter.add(assetWriterInput)
            assetWriter.add(assetWriterAudioInput)
            self.isStopping = false
            guard assetWriter.startWriting() else {
                throw assetWriter.error!
            }
        } catch {
            print("critical error starting asset writers \(error)")
            if self.accessingBookmarkURL {
                self.bookmarkedURL?.stopAccessingSecurityScopedResource()
                self.accessingBookmarkURL = false
            }
            self.assetWriter?.cancelWriting()
            //this should be all the cleanup we need? everything else with `try`
            //shouldn't have any side effects, unlike AVAssetWriter and security-scoped bookmark
        }
    }
    
    public func sendAudioBuffer(_ buffer: CMSampleBuffer) {
        if self.replayBuffer != nil && !self.isStopping {
            self.replayBufferQueue.schedule {
                self.replayBuffer!.addSampleBuffer(buffer)
            }
        } else {
            guard sessionStarted else { return }
            if assetWriterAudioInput.isReadyForMoreMediaData {
                assetWriterAudioInput.append(buffer)
            }
        }
    }
    
    func saveReplayBuffer() throws {
        self.replayBuffer!.isSaving = true
        try self.initializeAssetWriters()
        let firstNonKeyframe = self.replayBuffer!.firstNonKeyframe()
        if !self.sessionStarted { self.assetWriter.startSession(atSourceTime: firstNonKeyframe!.presentationTimeStamp) }
        guard let replayBuffer = self.replayBuffer else { throw EncoderError.replayBufferIsNil }
        var frameIndex = replayBuffer.startIndex
        var finished = false
        var retryCount = 0
        var frameCount = 0
        while !finished {
            guard retryCount < 1000 else {
                fatalError("failed to save the replay buffer")
            }
            if frameCount >= replayBuffer.buffer.count {
                self.assetWriterAudioInput.markAsFinished()
                self.assetWriterInput.markAsFinished()
                finished = true
            }
            let frameIndex = replayBuffer.startIndex + frameCount
            let logicalFrameIndex = frameIndex % replayBuffer.buffer.count
            let frame = replayBuffer.buffer[logicalFrameIndex]
            switch frame.formatDescription!.mediaType {
            case .audio:
                if self.assetWriterAudioInput.isReadyForMoreMediaData {
                    self.assetWriterAudioInput.append(frame)
                    frameCount += 1
                    retryCount = 0
                } else {
                    retryCount += 1
                    Thread.sleep(forTimeInterval: 0.1)
                }
            case .video:
                if self.assetWriterInput.isReadyForMoreMediaData {
                    self.assetWriterInput.append(frame)
                    frameCount += 1
                    retryCount = 0
                } else {
                    retryCount += 1
                    Thread.sleep(forTimeInterval: 0.1)
                }
            default:
                fatalError("encountered unknown frame type")
            }
        }
        Task {
            await assetWriter.finishWriting()
        }
        replayBuffer.isSaving = false
    }
    
    /// Closes the destination movie file.
    public func close() async throws {
        self.isStopping = true
        self.replayBuffer?.isStopping = true
        assetWriterInput.markAsFinished()
        assetWriterAudioInput.markAsFinished()
        await assetWriter.finishWriting()

        if assetWriter.status == .failed {
            throw assetWriter.error!
        }
        bookmarkedURL?.stopAccessingSecurityScopedResource()
    }
}

extension URL {
    func uniquing() -> URL {
        let fileManager = FileManager.default
        var uniqueInt = Int.random(in: 0...100000)
        var newURL = self
        //while fileManager.fileExists(atPath: self.path()) {
        let ext = self.pathExtension
        newURL = self.deletingPathExtension()
        let newLastComponent = self.lastPathComponent.appending(" \(uniqueInt)")
        newURL = newURL.deletingLastPathComponent()
        newURL = newURL.appending(path: newLastComponent).appendingPathExtension(ext)
        //}
        return newURL
    }
}
