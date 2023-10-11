/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An object that captures a stream of captured sample buffers containing screen and audio content.
*/

import Foundation
import AVFAudio
import ScreenCaptureKit
import OSLog
import VideoToolbox

/// A structure that contains the video data to render.
struct CapturedFrame {
    static let invalid = CapturedFrame(surface: nil, contentRect: .zero, contentScale: 0, scaleFactor: 0, encodedSurface: nil, encodedContentRect: nil)
    
    let surface: IOSurface?
    let contentRect: CGRect
    let contentScale: CGFloat
    let scaleFactor: CGFloat
    var size: CGSize { contentRect.size }
    
    let encodedSurface: IOSurface?
    let encodedContentRect: CGRect?
    var encodedSize: CGSize? { encodedContentRect?.size }
}

/// An object that wraps an instance of `SCStream`, and returns its results as an `AsyncThrowingStream`.
class CaptureEngine: @unchecked Sendable {
    
    private let logger = Logger()
    
    private var stream: SCStream?
    private let videoSampleBufferQueue = DispatchQueue(label: "com.jcm.Record.VideoSampleBufferQueue")
    private let audioSampleBufferQueue = DispatchQueue(label: "com.jcm.Record.AudioSampleBufferQueue")
    var streamOutput: CaptureEngineStreamOutput!
    
    // Performs average and peak power calculations on the audio samples.
    private let powerMeter = PowerMeter()
    var audioLevels: AudioLevels { powerMeter.levels }
    
    // Store the the startCapture continuation, so that you can cancel it when you call stopCapture().
    private var continuation: AsyncThrowingStream<CapturedFrame, Error>.Continuation?
    
    /// - Tag: StartCapture
    func startCapture(configuration: SCStreamConfiguration, filter: SCContentFilter) -> AsyncThrowingStream<CapturedFrame, Error> {
        AsyncThrowingStream<CapturedFrame, Error> { continuation in
            // The stream output object.
            self.streamOutput = CaptureEngineStreamOutput(continuation: continuation)
            streamOutput.capturedFrameHandler = { continuation.yield($0) }
            streamOutput.pcmBufferHandler = { self.powerMeter.process(buffer: $0) }
            
            
            do {
                stream = SCStream(filter: filter, configuration: configuration, delegate: streamOutput)
                
                // Add a stream output to capture screen content.
                try stream?.addStreamOutput(streamOutput, type: .screen, sampleHandlerQueue: nil)
                try stream?.addStreamOutput(streamOutput, type: .audio, sampleHandlerQueue: nil)
                stream?.startCapture()
            } catch {
                logger.critical("Could not initialize ScreenCaptureKit stream with error: \(error, privacy: .public)")
                continuation.finish(throwing: error)
            }
        }
    }
    
    func stopCapture() async {
        do {
            try await stream?.stopCapture()
            continuation?.finish()
        } catch {
            continuation?.finish(throwing: error)
        }
        powerMeter.processSilence()
    }
    
    func startRecording(options: Options) async throws {
        self.streamOutput.encoder = try await VTEncoder(options: options)
    }
    
    func stopRecording() async throws {
        try await self.streamOutput.stopReplayBuffer()
        try await self.streamOutput.encoder.stopEncoding()
        self.streamOutput.encoder = nil
    }
    
    func saveReplayBuffer() throws {
        try self.streamOutput.saveReplayBuffer()
    }
    
    /// - Tag: UpdateStreamConfiguration
    func update(configuration: SCStreamConfiguration, filter: SCContentFilter) async {
        do {
            try await stream?.updateConfiguration(configuration)
            try await stream?.updateContentFilter(filter)
        } catch {
            logger.error("Failed to update the stream session: \(String(describing: error))")
        }
    }
}

/// A class that handles output from an SCStream, and handles stream errors.
class CaptureEngineStreamOutput: NSObject, SCStreamOutput, SCStreamDelegate {
    
    var pcmBufferHandler: ((AVAudioPCMBuffer) -> Void)?
    var capturedFrameHandler: ((CapturedFrame) -> Void)?
    
    var encoder: VTEncoder!
    var destinationPixelBuffer: CVPixelBuffer?
    var srcData: UnsafeMutableRawPointer!
    var dstData: UnsafeMutableRawPointer!
    private let frameHandlerQueue = DispatchQueue(label: "com.jcm.Record.FrameHandlerQueue")
    
    var framesWritten = 0
    
    private let logger = Logger.capture
    
    // Store the the startCapture continuation, so you can cancel it if an error occurs.
    private var continuation: AsyncThrowingStream<CapturedFrame, Error>.Continuation?
    
    var errorHandler: ((Error) -> Void)?
    
    init(continuation: AsyncThrowingStream<CapturedFrame, Error>.Continuation?) {
        self.continuation = continuation
    }
    
    /// - Tag: DidOutputSampleBuffer
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of outputType: SCStreamOutputType) {
        /// This is either called from VideoSampleBufferQueue, or AudioSampleBufferQueue.
        /// We assume that we don't want to perform lots of work on these queues, so they
        /// can be maximally available to handle new frames as they're delivered by SCK.
        /// Therefore, immediately dispatch to the frame handler queue.

        self.frameHandlerQueue.schedule {
            guard sampleBuffer.isValid else {
                self.logger.notice("ScreenCaptureKit emitted an invalid frame; skipping it. Timestamp: \(sampleBuffer.presentationTimeStamp.seconds, privacy: .public)")
                return
            }
            switch outputType {
            case .screen:
                if let frame = self.createFrame(for: sampleBuffer) {
                    self.capturedFrameHandler?(frame)
                }
            case .audio:
                if let copy = self.createAudioFrame(for: sampleBuffer) {
                    self.encoder?.encodeAudioFrame(copy)
                }
            @unknown default:
                self.errorHandler!(EncoderError.unknownFrameType)
            }
        }
    }
    
    func handleEncoderInitializationError(_ error: Error) {
        self.errorHandler!(error)
        // video sink should have already shut itself down if it throws an error, so we can just nil out the encoder.
        self.encoder = nil
    }
    
    func saveReplayBuffer() {
        self.frameHandlerQueue.schedule {
            do {
                try self.encoder.saveReplayBuffer()
            } catch {
                self.errorHandler!(error)
            }
        }
    }
    
    func stopReplayBuffer() {
        do {
            try self.encoder.videoSink.stopReplayBuffer()
        } catch {
            self.errorHandler!(error)
        }
    }
    /// Create a `CapturedFrame` for the video sample buffer.
    private func createFrame(for sampleBuffer: CMSampleBuffer) -> CapturedFrame? {
        
        guard let attachmentsArray = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer,
                                                                             createIfNecessary: false) as? [[SCStreamFrameInfo: Any]],
              let attachments = attachmentsArray.first else {
            logger.notice("ScreenCaptureKit emitted a frame with no attachment array. Skipping. Timestamp: \(sampleBuffer.presentationTimeStamp.seconds, privacy: .public)")
            return nil
        }
        
        
        /// Discard frames that are either blank or identical to the previous one (`.idle`).
        let statusRawValue = attachments[SCStreamFrameInfo.status] as! Int
        let status = SCFrameStatus(rawValue: statusRawValue)
        if status != SCFrameStatus.complete {
            return nil
        }
        
        guard let pixelBuffer = sampleBuffer.imageBuffer else { return nil }
        
        if let encoder = self.encoder {
            /// `VTCompressionSessionEncodeFrame` itself does not throw errors, it just comes back with `nil` if
            /// a problem is encountered. Rather, this is a way to propagate errors on the video sink, in case
            /// there is a problem identified while writing to the file that the user will want to be made aware
            /// of. It is only possible to throw an error here while starting a session with AssetWriter, so
            /// maybe this should be revised to be handled differently and not throw, with the first frame of
            /// the session handled separately. TODO
            
            if self.encoder.hasStarted {
                encoder.encodeFrame(buffer: pixelBuffer, timeStamp: sampleBuffer.presentationTimeStamp, duration: sampleBuffer.duration, properties: nil, infoFlags: nil)
            } else {
                do {
                    try encoder.startSession(buffer: pixelBuffer, timeStamp: sampleBuffer.presentationTimeStamp, duration: sampleBuffer.duration, properties: nil, infoFlags: nil)
                } catch {
                    self.handleEncoderInitializationError(error)
                }
            }
        }
        
        // Get the backing IOSurface.
        guard let surfaceRef = CVPixelBufferGetIOSurface(pixelBuffer)?.takeUnretainedValue() else { return nil }
        let surface = unsafeBitCast(surfaceRef, to: IOSurface.self)
        
        // Retrieve the content rectangle, scale, and scale factor.
        guard let contentRectDict = attachments[.contentRect],
              let contentRect = CGRect(dictionaryRepresentation: contentRectDict as! CFDictionary),
              let contentScale = attachments[.contentScale] as? CGFloat,
              let scaleFactor = attachments[.scaleFactor] as? CGFloat else { return nil }
        
        var encoderSurface: IOSurface?
        if let decoderPreview = self.encoder?.videoSink?.mostRecentImageBuffer {
            let ref = CVPixelBufferGetIOSurface(decoderPreview)?.takeUnretainedValue()
            encoderSurface = unsafeBitCast(ref, to: IOSurface.self)
        }
        
        // Create a new frame with the relevant data.
        let frame = CapturedFrame(surface: surface,
                                  contentRect: contentRect,
                                  contentScale: contentScale,
                                  scaleFactor: scaleFactor,
                                  encodedSurface: encoderSurface,
                                  encodedContentRect: contentRect)
        return frame
    }
    
    private func createAudioFrame(for sampleBuffer: CMSampleBuffer) -> CMSampleBuffer? {
        /// If we are using the replay buffer, we want to store some number of frames
        /// for later. We can't store the frames provided by SCK directly, though,
        /// because SCK repurposes the underlying buffers. If we incidentally hold
        /// references to them, SCK gives up and dies and stops providing audio.
        /// Instead, create a deep copy of the sample buffer and use that. This copy
        /// procedure is unnecessary if we are not using the replay buffer, but the
        /// penalty for copying is small enough that we just do it anyway.

        let copy = sampleBuffer.deepCopy()
        return copy
    }
        
    
    // Creates an AVAudioPCMBuffer instance on which to perform an average and peak audio level calculation.
    private func createPCMBuffer(for sampleBuffer: CMSampleBuffer) -> AVAudioPCMBuffer? {
        var ablPointer: UnsafePointer<AudioBufferList>?
        try? sampleBuffer.withAudioBufferList { audioBufferList, blockBuffer in
            ablPointer = audioBufferList.unsafePointer
        }
        guard let audioBufferList = ablPointer,
              let absd = sampleBuffer.formatDescription?.audioStreamBasicDescription,
              let format = AVAudioFormat(standardFormatWithSampleRate: absd.mSampleRate, channels: absd.mChannelsPerFrame) else { return nil }
        let buffer = AVAudioPCMBuffer(pcmFormat: format, bufferListNoCopy: audioBufferList)
        return buffer
    }
    
    func stream(_ stream: SCStream, didStopWithError error: Error) {
        continuation?.finish(throwing: error)
    }
}
