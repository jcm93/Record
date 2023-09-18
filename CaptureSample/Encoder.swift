//
//  Encoder.swift
//  CaptureSample
//
//  Created by John Moody on 7/22/23.
//  Copyright © 2023 Apple. All rights reserved.
//

import Foundation
import VideoToolbox
import AVFAudio
import CoreGraphics
import AppKit
import OSLog

enum EncoderError: Error {
    case videoSinkAlreadyActive
    case initialFrameNotEncoded
    case replayBufferIsNil
}

class VTEncoder: NSObject {
    
    var session: VTCompressionSession!
    var videoSink: VideoSink!
    var pixelTransferSession: VTPixelTransferSession?
    var stoppingEncoding = false
    var pixelTransferBuffer: CVPixelBuffer!
    
    var destWidth: Int
    var destHeight: Int
    
    var criticalErrorEncountered = false
    var currentError: Error?
    
    var hasStarted = false
    var isStarting = false
    
    private let logger = Logger.encoder
    
    init?(options: Options) async throws {
        self.destWidth = options.destWidth
        self.destHeight = options.destHeight
        super.init()
        let sourceImageBufferAttributes = [kCVPixelBufferPixelFormatTypeKey: options.pixelFormat as CFNumber] as CFDictionary
        
        let err = VTCompressionSessionCreate(allocator: kCFAllocatorDefault,
                                             width: Int32(options.destWidth),
                                             height: Int32(options.destHeight),
                                             codecType: options.codec,
                                             encoderSpecification: nil,
                                             imageBufferAttributes: sourceImageBufferAttributes,
                                             compressedDataAllocator: nil,
                                             outputCallback: nil,
                                             refcon: nil,
                                             compressionSessionOut: &self.session)
        guard err == noErr, self.session != nil else {
            logger.critical("Failed to create encoding session: \(err, privacy: .public)")
            let error = NSError(domain: NSOSStatusErrorDomain, code: Int(err))
            throw error
        }
        await self.configureSession(options: options)
        self.videoSink = VideoSink(fileURL: options.destMovieURL,
                                       fileType: options.destFileType,
                                       codec: options.codec,
                                       width: options.destWidth,
                                       height: options.destHeight,
                                       isRealTime: true,
                                       usesReplayBuffer: options.usesReplayBuffer,
                                       replayBufferDuration: options.replayBufferDuration)
        if options.convertsColorSpace || options.scales {
            var err2 = VTPixelTransferSessionCreate(allocator: nil, pixelTransferSessionOut: &pixelTransferSession)
            if noErr != err2 {
                logger.fault("Error creating pixel transfer session: \(err2, privacy: .public)")
            }
            err2 = VTSessionSetProperty(self.pixelTransferSession!, key: kVTPixelTransferPropertyKey_DownsamplingMode, value: kVTDownsamplingMode_Average)
            if noErr != err2 {
                logger.fault("Error setting downsampling mode on pixel transfer: \(err2, privacy: .public)")
            }
            if options.convertsColorSpace {
                err2 = VTSessionSetProperty(self.pixelTransferSession!, key: kVTPixelTransferPropertyKey_DestinationColorPrimaries, value: options.targetColorSpace!)
                if noErr != err2 {
                    logger.fault("Error setting color primaries on pixel transfer: \(err2, privacy: .public)")
                }
            }
        }
    }
    
    func configureSession(options: Options) async {
        var err: OSStatus = noErr
        if options.codec == kCMVideoCodecType_H264 {
            err = VTSessionSetProperty(session, key: kVTCompressionPropertyKey_ProfileLevel, value: kVTProfileLevel_H264_Main_AutoLevel)
        } else if options.codec == kCMVideoCodecType_HEVC {
            err = VTSessionSetProperty(session, key: kVTCompressionPropertyKey_ProfileLevel, value: kVTProfileLevel_HEVC_Main_AutoLevel)
        }
        if noErr != err {
            logger.fault("Failed to set profile level: \(err, privacy: .public)")
        }
        err = VTSessionSetProperty(session, key: kVTCompressionPropertyKey_RealTime, value: kCFBooleanFalse)
        if noErr != err {
            logger.fault("Failed to set realtime status: \(err, privacy: .public)")
        }
        
        switch options.rateControl {
        case .crf:
            err = VTSessionSetProperty(session, key: kVTCompressionPropertyKey_Quality, value: options.crfValue)
            if noErr != err {
                logger.fault("Failed to set CRF value: \(err, privacy: .public)")
            }
        case .cbr:
            err = VTSessionSetProperty(session, key: kVTCompressionPropertyKey_AverageBitRate, value: (options.destBitRate * 1000) as CFNumber)
            if noErr != err {
                logger.fault("Failed to set target average bitrate: \(err, privacy: .public)")
            }
            err = VTSessionSetProperty(session, key: kVTCompressionPropertyKey_ConstantBitRate, value: kCFBooleanTrue)
            if noErr != err {
                logger.fault("Failed to enable CBR: \(err, privacy: .public)")
            }
        default:
            err = VTSessionSetProperty(session, key: kVTCompressionPropertyKey_AverageBitRate, value: (options.destBitRate * 1000) as CFNumber)
            if noErr != err {
                logger.fault("Failed to set target average bitrate: \(err, privacy: .public)")
            }
            let byteLimit = (Double(options.destBitRate * 1000) * 1.5) as CFNumber
            let secLimit = Double(1.0) as CFNumber
            let limitsArray = [ byteLimit, secLimit ] as CFArray
            err = VTSessionSetProperty(session, key: kVTCompressionPropertyKey_DataRateLimits, value: limitsArray)
            if noErr != err {
                logger.fault("Failed to set advanced bitrate limits: \(err, privacy: .public)")
            }
        }
        err = VTSessionSetProperty(session, key: kVTCompressionPropertyKey_AllowTemporalCompression, value: kCFBooleanTrue)
        if noErr != err {
            logger.fault("Failed to enable temporal compression: \(err, privacy: .public)")
        }
        err = VTSessionSetProperty(session, key: kVTCompressionPropertyKey_AllowFrameReordering, value: options.bFrames ? kCFBooleanTrue : kCFBooleanFalse)
        if noErr != err {
            logger.fault("Failed to set b-frames status: \(err, privacy: .public)")
        }
        err = VTSessionSetProperty(session, key: kVTCompressionPropertyKey_MaxKeyFrameInterval, value: options.maxKeyFrameInterval as CFNumber)
        if noErr != err {
            logger.fault("Failed to set max keyframe interval: \(err, privacy: .public)")
        }
        err = VTSessionSetProperty(session, key: kVTCompressionPropertyKey_MaxKeyFrameIntervalDuration,
                                   value: options.maxKeyFrameIntervalDuration as CFNumber)
        if noErr != err {
            logger.fault("Failed to set max keyframe interval duration: \(err, privacy: .public)")
        }
        err = VTSessionSetProperty(session, key: kVTCompressionPropertyKey_ColorPrimaries, value: options.colorPrimaries)
        if noErr != err {
            logger.fault("Failed to set color primaries: \(err, privacy: .public)")
        }
        err = VTSessionSetProperty(session, key: kVTCompressionPropertyKey_OutputBitDepth, value: options.bitDepth as CFNumber)
        if noErr != err {
            logger.fault("Failed to set bit depth: \(err, privacy: .public)")
        }
        err = VTSessionSetProperty(session, key: kVTCompressionPropertyKey_YCbCrMatrix, value: options.yuvMatrix)
        if noErr != err {
            logger.fault("Failed to set YCbCr matrix: \(err, privacy: .public)")
        }
        if options.usesICC {
            err = VTSessionSetProperty(session, key: kVTCompressionPropertyKey_ICCProfile, value: options.iccProfile)
            if noErr != err {
                logger.fault("Failed to set ICC profile: \(err, privacy: .public)")
            }
        }
        err = VTSessionSetProperty(session, key: kVTCompressionPropertyKey_TransferFunction, value: options.transferFunction)
        if noErr != err {
            logger.fault("Failed to set transfer function: \(err, privacy: .public)")
        }
        print("set settings")
        if options.gammaValue != nil && options.transferFunction == TransferFunctionSetting.useGamma.stringValue() {
            err = VTSessionSetProperty(session, key: kVTCompressionPropertyKey_GammaLevel, value: options.gammaValue! as CFNumber)
            if noErr != err {
                logger.fault("Failed to set gamma value: \(err, privacy: .public)")
            }
        }
    }
    
    func startSession(buffer: CVImageBuffer, timeStamp: CMTime, duration: CMTime, properties: CFDictionary?, infoFlags: UnsafeMutablePointer<VTEncodeInfoFlags>?) throws {
        guard !self.isStarting else {
            return
        }
        self.isStarting = true
        guard !self.criticalErrorEncountered else {
            throw self.currentError!
        }
        guard !self.videoSink.hasStarted else {
            throw EncoderError.videoSinkAlreadyActive
        }
        let pixelBufferToEncodeFrom = self.pixelTransferBuffer != nil ? self.pixelTransferBuffer : buffer
        if let pixelTransferSession = pixelTransferSession {
            if self.pixelTransferBuffer == nil {
                self.pixelTransferBuffer = copyPixelBuffer(withNewDimensions: self.destWidth, y: self.destHeight, srcPixelBuffer: buffer)
            }
            VTPixelTransferSessionTransferImage(pixelTransferSession, from: buffer, to: pixelTransferBuffer)
        }
        VTCompressionSessionEncodeFrame(self.session, imageBuffer: pixelBufferToEncodeFrom!, presentationTimeStamp: timeStamp, duration: duration, frameProperties: properties, infoFlagsOut: infoFlags) {
            (status: OSStatus, infoFlags: VTEncodeInfoFlags, sbuf: CMSampleBuffer?) -> Void in
            if sbuf != nil {
                do {
                    try self.videoSink.startSession(sbuf!)
                    self.hasStarted = true
                    self.isStarting = false
                } catch {
                    self.currentError = error
                    self.criticalErrorEncountered = true
                    self.logger.critical("Failed to initialize video sink: \(error, privacy: .public)")
                    self.isStarting = false
                }
            } else {
                self.criticalErrorEncountered = true
                self.currentError = EncoderError.initialFrameNotEncoded
                self.logger.critical("Failed to encode initial frame of session.")
                self.isStarting = false
            }
        }
    }
    
    func encodeFrame(buffer: CVImageBuffer, timeStamp: CMTime, duration: CMTime, properties: CFDictionary?, infoFlags: UnsafeMutablePointer<VTEncodeInfoFlags>?) {
        if self.stoppingEncoding != true {
            let pixelBufferToEncodeFrom = self.pixelTransferSession != nil ? self.pixelTransferBuffer! : buffer
            if let pixelTransferSession = pixelTransferSession {
                if self.pixelTransferBuffer == nil {
                    self.pixelTransferBuffer = copyPixelBuffer(withNewDimensions: self.destWidth, y: self.destHeight, srcPixelBuffer: buffer)
                }
                VTPixelTransferSessionTransferImage(pixelTransferSession, from: buffer, to: pixelTransferBuffer)
            }
            VTCompressionSessionEncodeFrame(self.session, imageBuffer: pixelBufferToEncodeFrom, presentationTimeStamp: timeStamp, duration: duration, frameProperties: properties, infoFlagsOut: infoFlags) {
                (status: OSStatus, infoFlags: VTEncodeInfoFlags, sbuf: CMSampleBuffer?) -> Void in
                if sbuf != nil {
                    self.videoSink.sendSampleBuffer(sbuf!)
                }
            }
        } else {
            /// User stopped the recording session, so don't add any more frames to it.
            return
        }
    }
    
    func encodeAudioFrame(_ buffer: CMSampleBuffer) {
        //todo should also throw
        self.videoSink.sendAudioBuffer(buffer)
    }
    
    func saveReplayBuffer() async throws {
        try self.videoSink.saveReplayBuffer()
    }
    
    func stopEncoding() async throws {
        self.stoppingEncoding = true
        VTCompressionSessionCompleteFrames(self.session, untilPresentationTimeStamp: .invalid)
        VTCompressionSessionInvalidate(self.session)
        if let pts = self.pixelTransferSession {
            VTPixelTransferSessionInvalidate(pts)
            self.pixelTransferSession = nil
        }
        //CFRelease(self.session)
        try await self.videoSink.close()
        self.hasStarted = false
        self.stoppingEncoding = false
    }
    
}


