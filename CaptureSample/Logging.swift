//
//  Logging.swift
//  Record
//
//  Created by John Moody on 10/10/23.
//  Copyright © 2023 jcm. All rights reserved.
//

import Foundation
import SwiftUI
import OSLog
import UniformTypeIdentifiers

extension Logger {
    private static var subsystem = Bundle.main.bundleIdentifier!

    static let encoder = Logger(subsystem: subsystem, category: "encoder")

    static let videoSink = Logger(subsystem: subsystem, category: "videoSink")
    
    static let capture = Logger(subsystem: subsystem, category: "capture")
    
    static let application = Logger(subsystem: subsystem, category: "application")
    
    func generateLog() async -> TextDocument? {
        do {
            let logStore = try OSLogStore(scope: .currentProcessIdentifier)
            let timeIntervalToFetch = Date().timeIntervalSince(startupTime)
            let predicate = NSPredicate(format: "subsystem CONTAINS[c] 'com.jcm.record'")
            let entries = try logStore.getEntries(at: logStore.position(timeIntervalSinceEnd: timeIntervalToFetch), matching: predicate)
            var logString = ""
            for entry in entries {
                logString.append("\(entry.date): \(entry.composedMessage)\n")
            }
            let document = TextDocument(text: logString)
            return document
        } catch {
            self.notice("Failed to retrieve log entries for self")
            return nil
        }
    }
}


struct TextDocument: FileDocument {
    //taken from https://swiftwithmajid.com/2023/05/10/file-importing-and-exporting-in-swiftui/
    static var readableContentTypes: [UTType] {
        [.plainText]
    }
    
    var text = ""
    
    init(text: String) {
        self.text = text
    }
    
    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            text = String(decoding: data, as: UTF8.self)
        } else {
            text = ""
        }
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(text.utf8))
    }
}
