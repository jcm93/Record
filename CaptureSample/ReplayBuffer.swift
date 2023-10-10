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
    var isSaving = false
    
    var framesWritten = 0
    
    var buffer: [CMSampleBuffer]
    
    var queuedBuffers = [CMSampleBuffer]()
    
    var maxLengthInSeconds: Double
    
    init(buffer: [CMSampleBuffer], maxLengthInSeconds: Double) {
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
    
    func sampleAtIndex(index: Int) -> CMSampleBuffer {
        let realIndex = (self.startIndex + index) % self.buffer.count
        return self.buffer[realIndex]
    }
    
    public func addSampleBuffer(_ sbuf: CMSampleBuffer) {
        //clear out the queue
        for queuedBuffer in queuedBuffers {
            self.write(queuedBuffer)
        }
        queuedBuffers = [CMSampleBuffer]()
        self.write(sbuf)
    }
    
    public func write(_ element: CMSampleBuffer) {
        var bufferTrimmed = false
        while !bufferTrimmed {
            guard buffer.count != 0 else {
                buffer = [element]
                self.startIndex = 0
                return
            }
            let first = buffer[startIndex]
            let seconds = element.secondsAfter(otherBuffer: first)
            guard seconds > self.maxLengthInSeconds else {
                bufferTrimmed = true
                continue
            }
            buffer.remove(at: startIndex)
            if self.startIndex == buffer.count {
                self.startIndex = 0
            }
        }
        buffer.insert(element, at: self.startIndex)
        self.startIndex = (self.startIndex + 1) % buffer.count
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
    
    func isBefore(otherBuffer: CMSampleBuffer) -> Bool {
        let result = CMTimeCompare(self.presentationTimeStamp, otherBuffer.presentationTimeStamp)
        return result < 0 ? true : false
    }
    
    func secondsAfter(otherBuffer: CMSampleBuffer) -> Double {
        return CMTimeSubtract(self.presentationTimeStamp, otherBuffer.presentationTimeStamp).seconds
    }
    
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
                        return nil
                    }
                guard CMBlockBufferReplaceDataBytes(
                    with: buffer.baseAddress!,
                    blockBuffer: blockBuffer!,
                    offsetIntoDestination: 0,
                    dataLength: length) == noErr else {
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
