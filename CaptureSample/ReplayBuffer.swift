//
//  ReplayBuffer.swift
//  Record
//
//  Created by John Moody on 8/21/23.
//  Copyright © 2023 Apple. All rights reserved.
//

import Foundation
import VideoToolbox


class ReplayBuffer {
    
    var startIndex = 0
    var isStopping = false
    
    var buffer: [CMSampleBuffer]
    
    var maxLengthInSeconds: Int
    
    init(buffer: [CMSampleBuffer], maxLengthInSeconds: Int) {
        self.buffer = buffer
        self.maxLengthInSeconds = maxLengthInSeconds
    }
    
    func removeFirst() -> CMSampleBuffer? {
        if self.startIndex < self.buffer.count {
            return self.buffer.remove(at: self.startIndex)
        } else {
            if self.buffer.count > 0 {
                return self.buffer.removeFirst()
            } else {
                return nil
            }
        }
    }
    
    func first() -> CMSampleBuffer? {
        if self.startIndex < self.buffer.count {
            return self.buffer[self.startIndex]
        } else {
            return self.buffer.first
        }
    }
    
    public func write(_ element: CMSampleBuffer) {
        guard self.buffer.count != 0 else {
            self.buffer = [element]
            return
        }
        var bufferTrimmed = false
        var inserted = false
        var readIndex = startIndex
        let newIsKeyframe = element.isKeyframe()
        while !(inserted && bufferTrimmed) {
            guard !self.isStopping else { return }
            let logicalReadIndex = readIndex % self.buffer.count
            let bufferHere = self.buffer[logicalReadIndex]
            let difference = (element.presentationTimeStamp.seconds) - (bufferHere.presentationTimeStamp.seconds)
            let existingIsKeyframe = bufferHere.isKeyframe()
            if difference > Double(self.maxLengthInSeconds) {
                if !inserted {
                    self.buffer.insert(element, at: logicalReadIndex)
                    self.startIndex = (self.startIndex + 1) % self.buffer.count
                    readIndex += 1
                    inserted = true
                } else {
                    if !existingIsKeyframe || newIsKeyframe {
                        self.buffer.remove(at: logicalReadIndex)
                    } else {
                        readIndex += 1
                    }
                }
            } else {
                bufferTrimmed = true
                if inserted != true {
                    if startIndex == 0 {
                        self.buffer.append(element)
                    } else {
                        self.buffer.insert(element, at: startIndex)
                        self.startIndex = (self.startIndex + 1) % self.buffer.count
                    }
                    inserted = true
                }
            }
        }
    }
    
    func firstNonKeyframe() -> CMSampleBuffer? {
        var tempReadIndex = self.startIndex
        while true {
            if tempReadIndex > self.startIndex + self.buffer.count {
                return nil
            }
            var logicalReadIndex = tempReadIndex % self.buffer.count
            let frame = self.buffer[logicalReadIndex]
            if !frame.isKeyframe() {
                return frame
            } else {
                tempReadIndex += 1
            }
        }
    }
}


extension CMSampleBuffer {
    func isKeyframe() -> Bool {
        if self.formatDescription?.mediaType == .audio {
            return true
        }
        if let attachmentArray = CMSampleBufferGetSampleAttachmentsArray(self, createIfNecessary: false) as? NSArray {
            let attachment = attachmentArray[0] as! NSDictionary
            // print("attach on frame \(frame): \(attachment)")
            if let notSync = attachment[kCMSampleAttachmentKey_NotSync] as? NSNumber {
                if !notSync.boolValue {
                    return true
                } else {
                    return false
                }
            } else {
                return false
            }
        } else {
            return false
        }
    }
    
    func deepCopy() -> CMSampleBuffer? {
            guard let formatDesc = CMSampleBufferGetFormatDescription(self),
                  let data = try? self.dataBuffer?.dataBytes() else {
                      return nil
                  }
            let nFrames = CMSampleBufferGetNumSamples(self)
            let pts = CMSampleBufferGetPresentationTimeStamp(self)
            let dataBuffer = data.withUnsafeBytes { (buffer) -> CMBlockBuffer? in
                var blockBuffer: CMBlockBuffer?
                let length: Int = data.count
                guard CMBlockBufferCreateWithMemoryBlock(
                    allocator: kCFAllocatorDefault,
                    memoryBlock: nil,
                    blockLength: length,
                    blockAllocator: nil,
                    customBlockSource: nil,
                    offsetToData: 0,
                    dataLength: length,
                    flags: 0,
                    blockBufferOut: &blockBuffer) == noErr else {
                        print("Failed to create block")
                        return nil
                    }
                guard CMBlockBufferReplaceDataBytes(
                    with: buffer.baseAddress!,
                    blockBuffer: blockBuffer!,
                    offsetIntoDestination: 0,
                    dataLength: length) == noErr else {
                        print("Failed to move bytes for block")
                        return nil
                    }
                return blockBuffer
            }
            guard let dataBuffer = dataBuffer else {
                return nil
            }
            var newSampleBuffer: CMSampleBuffer?
            CMAudioSampleBufferCreateReadyWithPacketDescriptions(
                allocator: kCFAllocatorDefault,
                dataBuffer: dataBuffer,
                formatDescription: formatDesc,
                sampleCount: nFrames,
                presentationTimeStamp: pts,
                packetDescriptions: nil,
                sampleBufferOut: &newSampleBuffer
            )
            return newSampleBuffer
        }
}
