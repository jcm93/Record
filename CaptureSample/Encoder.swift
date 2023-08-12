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

class VTEncoder: NSObject {
    
    var session: VTCompressionSession!
    var videoSink: VideoSink!
    var pixelTransferSession: VTPixelTransferSession?
    var stoppingEncoding = false
    var testPixelBuffer: CVPixelBuffer!
    
    init(options: Options) async {
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
            fatalError("VTCompressionSession creation failed (\(err))!")
        }
        await self.configureSession(options: options)
        do {
            self.videoSink = try VideoSink(fileURL: options.destMovieURL,
                                           fileType: options.destFileType,
                                           codec: options.codec,
                                           width: options.destWidth,
                                           height: options.destHeight,
                                           isRealTime: true)
        } catch {
            fatalError("dong")
        }
        if options.convertsColorSpace {
            var err2 = VTPixelTransferSessionCreate(allocator: nil, pixelTransferSessionOut: &pixelTransferSession)
            if noErr != err2 {
                print("error creating pixel transfer session")
            }
            err2 = VTSessionSetProperty(self.pixelTransferSession!, key: kVTPixelTransferPropertyKey_DestinationColorPrimaries, value: options.targetColorSpace!)
            if noErr != err2 {
                print("error setting color primaries on pixel transfer")
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
            print("Warning: VTSessionSetProperty(kVTCompressionPropertyKey_ProfileLevel) failed (\(err))")
        }
        err = VTSessionSetProperty(session, key: kVTCompressionPropertyKey_RealTime, value: kCFBooleanTrue)
        if noErr != err {
            print("Warning: VTSessionSetProperty(kVTCompressionPropertyKey_RealTime) failed (\(err))")
        }
        
        switch options.rateControl {
        case .cbr:
            err = VTSessionSetProperty(session, key: kVTCompressionPropertyKey_ConstantBitRate, value: options.destBitRate as CFNumber)
            if noErr != err {
                print("Warning: VTSessionSetProperty(kVTCompressionPropertyKey_ConstantBitRate) failed (\(err))")
            }
        case .abr:
            err = VTSessionSetProperty(session, key: kVTCompressionPropertyKey_AverageBitRate, value: options.destBitRate as CFNumber)
            if noErr != err {
                print("Warning: VTSessionSetProperty(kVTCompressionPropertyKey_AverageBitRate) failed (\(err))")
            }
            /*let byteLimit = (Double(options.destBitRate) / 8 * 1.5) as CFNumber
            let secLimit = Double(1.0) as CFNumber
            let limitsArray = [ byteLimit, secLimit ] as CFArray
            err = VTSessionSetProperty(session, key: kVTCompressionPropertyKey_DataRateLimits, value: limitsArray)
            if noErr != err {
                print("Warning: VTSessionSetProperty(kVTCompressionPropertyKey_DataRateLimits) failed (\(err))")
            }*/
        case .crf:
            err = VTSessionSetProperty(session, key: kVTCompressionPropertyKey_Quality, value: options.crfValue)
            if noErr != err {
                print("Warning: VTSessionSetProperty(kVTCompressionPropertyKey_Quality) failed (\(err))")
            }
        }
        err = VTSessionSetProperty(session, key: kVTCompressionPropertyKey_AllowTemporalCompression, value: kCFBooleanTrue)
        if noErr != err {
            print("Warning: VTSessionSetProperty(kVTCompressionPropertyKey_AllowTemporalCompression) failed (\(err))")
        }
        err = VTSessionSetProperty(session, key: kVTCompressionPropertyKey_AllowFrameReordering, value: options.bFrames ? kCFBooleanTrue : kCFBooleanFalse)
        if noErr != err {
            print("Warning: VTSessionSetProperty(kVTCompressionPropertyKey_AllowFrameReordering) failed (\(err))")
        }
        err = VTSessionSetProperty(session, key: kVTCompressionPropertyKey_MaxKeyFrameInterval, value: options.maxKeyFrameInterval as CFNumber)
        if noErr != err {
            print("Warning: VTSessionSetProperty(kVTCompressionPropertyKey_MaxKeyFrameInterval) failed (\(err))")
        }
        err = VTSessionSetProperty(session, key: kVTCompressionPropertyKey_MaxKeyFrameIntervalDuration,
                                   value: options.maxKeyFrameIntervalDuration as CFNumber)
        if noErr != err {
            print("Warning: VTSessionSetProperty(kVTCompressionPropertyKey_MaxKeyFrameIntervalDuration) failed (\(err))")
        }
        err = VTSessionSetProperty(session, key: kVTCompressionPropertyKey_ColorPrimaries, value: options.colorPrimaries)
        if noErr != err {
            print("setting color primaries failed")
        }
        err = VTSessionSetProperty(session, key: kVTCompressionPropertyKey_OutputBitDepth, value: options.bitDepth as CFNumber)
        if noErr != err {
            print("setting output bit depth failed")
        }
        err = VTSessionSetProperty(session, key: kVTCompressionPropertyKey_YCbCrMatrix, value: options.yuvMatrix)
        if noErr != err {
            print("setting ycbcr matrix failed")
        }
        if options.usesICC {
            err = VTSessionSetProperty(session, key: kVTCompressionPropertyKey_ICCProfile, value: options.iccProfile)
            if noErr != err {
                print("setting icc profile failed")
            }
        }
        err = VTSessionSetProperty(session, key: kVTCompressionPropertyKey_TransferFunction, value: options.transferFunction)
        if noErr != err {
            print("setting transfer function failed")
        }
        print("set settings")
        if options.gammaValue != nil && options.transferFunction == TransferFunctionSetting.useGamma.stringValue() {
            err = VTSessionSetProperty(session, key: kVTCompressionPropertyKey_GammaLevel, value: options.gammaValue! as CFNumber)
            if noErr != err {
                print("setting gamma failed")
            }
        }
    }
    
    func encodeFrame(buffer: CVImageBuffer, timeStamp: CMTime, duration: CMTime, properties: CFDictionary?, infoFlags: UnsafeMutablePointer<VTEncodeInfoFlags>?) {
        /*if let pixelTransferSession = pixelTransferSession {
            if self.testPixelBuffer == nil {
                self.testPixelBuffer = copyPixelBuffer(withNewDimensions: 1728, y: 1116, srcPixelBuffer: buffer)
            }
            VTPixelTransferSessionTransferImage(pixelTransferSession, from: buffer, to: testPixelBuffer)
        }*/
        if self.stoppingEncoding != true {
            VTCompressionSessionEncodeFrame(self.session, imageBuffer: buffer, presentationTimeStamp: timeStamp, duration: duration, frameProperties: properties, infoFlagsOut: infoFlags) {
                (status: OSStatus, infoFlags: VTEncodeInfoFlags, sbuf: CMSampleBuffer?) -> Void in
                if sbuf != nil {
                    self.videoSink.sendSampleBuffer(sbuf!)
                }
            }
        }
    }
    
    func encodeAudioFrame(_ buffer: CMSampleBuffer) {
        self.videoSink.sendAudioBuffer(buffer)
    }
    
    func stopEncoding() async {
        self.stoppingEncoding = true
        VTCompressionSessionCompleteFrames(self.session, untilPresentationTimeStamp: .invalid)
        VTCompressionSessionInvalidate(self.session)
        if let pts = self.pixelTransferSession {
            VTPixelTransferSessionInvalidate(pts)
            self.pixelTransferSession = nil
        }
        //CFRelease(self.session)
        do {
            try await self.videoSink.close()
            self.stoppingEncoding = false
        } catch {
            print(error)
            fatalError("error")
        }
    }
    
}


