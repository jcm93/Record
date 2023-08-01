//
//  PixelTransfer.swift
//  Record
//
//  Created by John Moody on 7/29/23.
//  Copyright © 2023 Apple. All rights reserved.
//

import Foundation
import VideoToolbox

class ColorConverter {
    
    private var pixelTransferSession: VTPixelTransferSession!
    
    init(outputColorSpace: CFString) {
        let err = VTPixelTransferSessionCreate(allocator: nil, pixelTransferSessionOut: &pixelTransferSession)
        VTSessionSetProperty(self.pixelTransferSession, key: kVTPixelTransferPropertyKey_DestinationColorPrimaries, value: outputColorSpace)
        
    }
}
