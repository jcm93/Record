/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An object that captures a stream of captured sample buffers containing screen and audio content.
*/

import Foundation
import AVFAudio
import ScreenCaptureKit
import OSLog
import Combine

/// A structure that contains the video data to render.
struct CapturedFrame {
    static let invalid = CapturedFrame(surface: nil, contentRect: .zero, contentScale: 0, scaleFactor: 0)
    
    let surface: IOSurface?
    let contentRect: CGRect
    let contentScale: CGFloat
    let scaleFactor: CGFloat
    var size: CGSize { contentRect.size }
}

/// An object that wraps an instance of `SCStream`, and returns its results as an `AsyncThrowingStream`.
class CaptureEngine: @unchecked Sendable {
    
    private let logger = Logger()
    
    private var stream: SCStream?
    private let videoSampleBufferQueue = DispatchQueue(label: "com.example.apple-samplecode.VideoSampleBufferQueue")
    private let audioSampleBufferQueue = DispatchQueue(label: "com.example.apple-samplecode.AudioSampleBufferQueue")
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
                try stream?.addStreamOutput(streamOutput, type: .screen, sampleHandlerQueue: videoSampleBufferQueue)
                try stream?.addStreamOutput(streamOutput, type: .audio, sampleHandlerQueue: audioSampleBufferQueue)
                stream?.startCapture()
            } catch {
                print(error)
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
    
    func startRecording(options: Options) async {
        //let options = Options(destMovieURL: "./poopy.mp4", destFileType: .mp4, destWidth: 3456, destHeight: 2234, destBitRate: 15000000, codec: kCMVideoCodecType_HEVC, pixelFormat: kCVPixelFormatType_32BGRA, maxKeyFrameIntervalDuration: 0.0, maxKeyFrameInterval: 2, cbr: false, verbose: true, iccProfile: nil, bitDepth: 8)
        self.streamOutput.encoder = await Encoder(options: options)
    }
    
    func stopRecording() async {
        try await self.streamOutput.encoder.stopEncoding()
        self.streamOutput.encoder = nil
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
    
    var encoder: Encoder!
    
    // Store the the startCapture continuation, so you can cancel it if an error occurs.
    private var continuation: AsyncThrowingStream<CapturedFrame, Error>.Continuation?
    
    init(continuation: AsyncThrowingStream<CapturedFrame, Error>.Continuation?) {
        self.continuation = continuation
    }
    
    /// - Tag: DidOutputSampleBuffer
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of outputType: SCStreamOutputType) {
        
        // Return early if the sample buffer is invalid.
        guard sampleBuffer.isValid else {
            print("invalid sample")
            return
        }
        
        // Determine which type of data the sample buffer contains.
        switch outputType {
        case .screen:
            // Create a CapturedFrame structure for a video sample buffer.
            guard let frame = createFrame(for: sampleBuffer) else { return }
            capturedFrameHandler?(frame)
        case .audio:
            // Create an AVAudioPCMBuffer from an audio sample buffer.
            self.encoder?.encodeAudioFrame(sampleBuffer)
            //guard let samples = createPCMBuffer(for: sampleBuffer) else { return }
            //pcmBufferHandler?(samples)
        @unknown default:
            fatalError("Encountered unknown stream output type: \(outputType)")
        }
    }
    
    /// Create a `CapturedFrame` for the video sample buffer.
    private func createFrame(for sampleBuffer: CMSampleBuffer) -> CapturedFrame? {
        
        // Retrieve the array of metadata attachments from the sample buffer.
        guard let attachmentsArray = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer,
                                                                             createIfNecessary: false) as? [[SCStreamFrameInfo: Any]],
              let attachments = attachmentsArray.first else { return nil }
        
        // Validate the status of the frame. If it isn't `.complete`, return nil.
        /*guard let statusRawValue = attachments[SCStreamFrameInfo.status] as? Int,
              let status = SCFrameStatus(rawValue: statusRawValue),
              status == .complete else { return nil }*/
        
        // Get the pixel buffer that contains the image data.
        guard let pixelBuffer = sampleBuffer.imageBuffer else { return nil }
        self.encoder?.encodeFrame(buffer: pixelBuffer, timeStamp: sampleBuffer.presentationTimeStamp, duration: .invalid, properties: nil, infoFlags: nil)
        
        // Get the backing IOSurface.
        guard let surfaceRef = CVPixelBufferGetIOSurface(pixelBuffer)?.takeUnretainedValue() else { return nil }
        let surface = unsafeBitCast(surfaceRef, to: IOSurface.self)
        
        // Retrieve the content rectangle, scale, and scale factor.
        guard let contentRectDict = attachments[.contentRect],
              let contentRect = CGRect(dictionaryRepresentation: contentRectDict as! CFDictionary),
              let contentScale = attachments[.contentScale] as? CGFloat,
              let scaleFactor = attachments[.scaleFactor] as? CGFloat else { return nil }
        
        // Create a new frame with the relevant data.
        let frame = CapturedFrame(surface: surface,
                                  contentRect: contentRect,
                                  contentScale: contentScale,
                                  scaleFactor: scaleFactor)
        return frame
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
