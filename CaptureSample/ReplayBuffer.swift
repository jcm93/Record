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
    
    fileprivate var startIndex = 0
    
    var buffer: [CMSampleBuffer]
    
    var maxLengthInSeconds: Int
    
    init(buffer: [CMSampleBuffer], maxLengthInSeconds: Int) {
        self.buffer = buffer
        self.maxLengthInSeconds = maxLengthInSeconds
    }
    
    func popFirst() -> CMSampleBuffer? {
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
    
    public func write(_ element: CMSampleBuffer) {
        guard self.buffer.count != 0 else {
            self.buffer = [element]
            return
        }
        var purged = false
        var inserted = false
        var readIndex = startIndex
        while !inserted && !purged {
            let logicalReadIndex = readIndex % self.buffer.count
            let difference = (element.presentationTimeStamp.seconds) -
                             (self.buffer[logicalReadIndex].presentationTimeStamp.seconds)
            if difference > Double(self.maxLengthInSeconds) {
                if !inserted {
                    self.buffer[logicalReadIndex] = element
                    inserted = true
                    self.startIndex = (self.startIndex + 1) % self.buffer.count
                    readIndex += 1
                } else {
                    self.buffer.remove(at: readIndex)
                }
            } else {
                purged = true
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
