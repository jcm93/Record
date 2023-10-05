//
//  EventTap.swift
//  Record
//
//  Created by John Moody on 9/18/23.
//  Copyright © 2023 Apple. All rights reserved.
//

import Cocoa

enum EventTapError: Error {
    case failedToCreateTap
}

class RecordEventTap {
    
    private var screenRecorder: ScreenRecorder! = nil
    var callback: (() -> Void)? = nil
    
    init() throws {
        
        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue)
        
        let eventTap = CGEvent.tapCreate(tap: CGEventTapLocation.cghidEventTap,
                                         place: CGEventTapPlacement.headInsertEventTap,
                                         options: CGEventTapOptions.listenOnly,
                                         eventsOfInterest: mask,
                                         ///adapted from https://github.com/mickael-menu/ShadowVim/blob/a4fbea4c9322eb9c0db904808c0c54466605c133/Sources/Toolkit/Input/EventTap.swift#L51 (github code search)
                                         callback: { proxy, type, event, refcon in
                                                Unmanaged<RecordEventTap>.fromOpaque(refcon!)
                                                    .takeUnretainedValue()
                                                    .eventTapCallback(proxy: proxy, type: type, event: event)
                                                    .map { Unmanaged.passUnretained($0) }
                                                    },
                                         userInfo: Unmanaged.passUnretained(self).toOpaque()
        )
        
        guard let eventTap = eventTap else {
            throw EventTapError.failedToCreateTap
        }
        
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
    }
    
    func eventTapCallback(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> CGEvent? {
        //per documentation, if we are only a passive listener, we can return nil without affecting the event stream
        
        guard let keyCode = NSEvent(cgEvent: event)?.keyCode else {
            return nil
        }
        
        if keyCode == 0x6F {
            callback!()
        }
        return nil
    }
}
