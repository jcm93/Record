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

class Encoder: NSObject {
    
    var session: VTCompressionSession!
    var videoSink: VideoSink!
    
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
            self.videoSink = try VideoSink(filePath: options.destMoviePath,
                                           fileType: options.destFileType,
                                           codec: options.codec,
                                           width: options.destWidth,
                                           height: options.destHeight,
                                           isRealTime: true)
        } catch {
            fatalError("dong")
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
        
        if  options.cbr {
            err = VTSessionSetProperty(session, key: kVTCompressionPropertyKey_ConstantBitRate, value: options.destBitRate as CFNumber)
            if noErr != err {
                print("Warning: VTSessionSetProperty(kVTCompressionPropertyKey_ConstantBitRate) failed (\(err))")
            }
        } else {
            err = VTSessionSetProperty(session, key: kVTCompressionPropertyKey_AverageBitRate, value: options.destBitRate as CFNumber)
            if noErr != err {
                print("Warning: VTSessionSetProperty(kVTCompressionPropertyKey_AverageBitRate) failed (\(err))")
            }
            let byteLimit = (Double(options.destBitRate) / 8 * 1.5) as CFNumber
            let secLimit = Double(1.0) as CFNumber
            let limitsArray = [ byteLimit, secLimit ] as CFArray
            err = VTSessionSetProperty(session, key: kVTCompressionPropertyKey_DataRateLimits, value: limitsArray)
            if noErr != err {
                print("Warning: VTSessionSetProperty(kVTCompressionPropertyKey_DataRateLimits) failed (\(err))")
            }
        }
        err = VTSessionSetProperty(session, key: kVTCompressionPropertyKey_AllowTemporalCompression, value: kCFBooleanTrue)
        if noErr != err {
            print("Warning: VTSessionSetProperty(kVTCompressionPropertyKey_AllowTemporalCompression) failed (\(err))")
        }
        err = VTSessionSetProperty(session, key: kVTCompressionPropertyKey_AllowFrameReordering, value: kCFBooleanTrue)
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
        
        err = VTSessionSetProperty(session, key: kVTCompressionPropertyKey_ColorPrimaries, value: kCVImageBufferColorPrimaries_P3_D65)
        if noErr != err {
            print("setting color primaries failed")
        }
        /*err = VTSessionSetProperty(session, key: kVTCompressionPropertyKey_TransferFunction, value: kCVImageBufferTransferFunction_ITU_R_2100_HLG)
        if noErr != err {
            print("setting transfer function failed")
        }*/
        /*err = VTSessionSetProperty(session, key: kVTCompressionPropertyKey_ICCProfile, value: kIOSurfaceICCProfile)
        if noErr != err {
            print("setting icc profile failed")
        }*/
        err = VTSessionSetProperty(session, key: kVTCompressionPropertyKey_YCbCrMatrix, value: kCVImageBufferYCbCrMatrix_ITU_R_2020)
        if noErr != err {
            print("setting ycbcr matrix failed")
        }
    }
    
    func encodeFrame(buffer: CVImageBuffer, timeStamp: CMTime, duration: CMTime, properties: CFDictionary?, infoFlags: UnsafeMutablePointer<VTEncodeInfoFlags>?) {
        VTCompressionSessionEncodeFrame(self.session, imageBuffer: buffer, presentationTimeStamp: timeStamp, duration: .invalid, frameProperties: properties, infoFlagsOut: infoFlags) {
            (status: OSStatus, infoFlags: VTEncodeInfoFlags, sbuf: CMSampleBuffer?) -> Void in
            self.videoSink.sendSampleBuffer(sbuf!)
        }
    }
    
    func encodeAudioFrame(_ buffer: CMSampleBuffer) {
        self.videoSink.sendAudioBuffer(buffer)
    }
    
    func stopEncoding() async {
        VTCompressionSessionCompleteFrames(self.session, untilPresentationTimeStamp: .invalid)
        do {
            try await self.videoSink.close()
        } catch {
            print(error)
            fatalError("error")
        }
    }
    
}


