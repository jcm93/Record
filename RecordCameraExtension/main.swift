//
//  main.swift
//  RecordCameraExtension
//
//  Created by John Moody on 12/21/23.
//  Copyright © 2023 jcm. All rights reserved.
//

import Foundation
import CoreMediaIO

let providerSource = RecordCameraExtensionProviderSource(clientQueue: nil)
CMIOExtensionProvider.startService(provider: providerSource.provider)

CFRunLoopRun()
