//
//  CVPixelBufferHelpers.swift
//  Record
//
//  Created by John Moody on 8/10/23.
//  Copyright © 2023 Apple. All rights reserved.
//

import Foundation
import VideoToolbox

//adapted from https://github.com/hollance/CoreMLHelpers/blob/master/CoreMLHelpers/CVPixelBuffer%2BCreate.swift

fileprivate func metalCompatiblityAttributes() -> [String: Any] {
  let attributes: [String: Any] = [
    String(kCVPixelBufferMetalCompatibilityKey): true,
    String(kCVPixelBufferOpenGLCompatibilityKey): true,
    String(kCVPixelBufferIOSurfacePropertiesKey): [
      String(kCVPixelBufferIOSurfaceCoreAnimationCompatibilityKey): true
    ]
  ]
  return attributes
}

func copyPixelBuffer(withNewDimensions x: Int, y: Int, srcPixelBuffer: CVImageBuffer) -> CVImageBuffer? {
    
    var combinedAttributes: [String: Any] = [:]
    
    if let attachments = CVBufferCopyAttachments(srcPixelBuffer, .shouldPropagate) as? [String: Any] {
        for (key, value) in attachments {
            combinedAttributes[key] = value
        }
    }
    
    combinedAttributes = combinedAttributes.merging(metalCompatiblityAttributes()) {$1}
    
    var maybePixelBuffer: CVPixelBuffer?
    let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                     x,
                                     y,
                                     CVPixelBufferGetPixelFormatType(srcPixelBuffer),
                                     combinedAttributes as CFDictionary,
                                     &maybePixelBuffer)
    
    
    guard status == kCVReturnSuccess, let dstPixelBuffer = maybePixelBuffer else {
        return nil
    }
    
    //return dstPixelBuffer
    
    /*let dstFlags = CVPixelBufferLockFlags(rawValue: 0)
    guard kCVReturnSuccess == CVPixelBufferLockBaseAddress(dstPixelBuffer, dstFlags) else {
        return nil
    }
    defer { CVPixelBufferUnlockBaseAddress(dstPixelBuffer, dstFlags) }
    
    for plane in 0...max(0, CVPixelBufferGetPlaneCount(srcPixelBuffer) - 1) {
        if let srcAddr = CVPixelBufferGetBaseAddressOfPlane(srcPixelBuffer, plane),
           let dstAddr = CVPixelBufferGetBaseAddressOfPlane(dstPixelBuffer, plane) {
            let srcBytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(srcPixelBuffer, plane)
            let dstBytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(dstPixelBuffer, plane)
            
            for h in 0..<CVPixelBufferGetHeightOfPlane(srcPixelBuffer, plane) {
                let srcPtr = srcAddr.advanced(by: h*srcBytesPerRow)
                let dstPtr = dstAddr.advanced(by: h*dstBytesPerRow)
                dstPtr.copyMemory(from: srcPtr, byteCount: srcBytesPerRow)
            }
        }
    }*/
        return dstPixelBuffer
}

public func createPixelBuffer(width: Int, height: Int, pixelFormat: OSType) -> CVPixelBuffer? {
  let attributes = metalCompatiblityAttributes() as CFDictionary
  var pixelBuffer: CVPixelBuffer?
  let status = CVPixelBufferCreate(nil, width, height, pixelFormat, attributes, &pixelBuffer)
  if status != kCVReturnSuccess {
    return nil
  }
  return pixelBuffer
}
