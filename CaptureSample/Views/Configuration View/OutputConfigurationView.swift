//
//  OutputConfigurationView.swift
//  Record
//
//  Created by John Moody on 8/24/23.
//  Copyright © 2023 Apple. All rights reserved.
//

import SwiftUI
import OSLog

struct OutputConfigurationView: View {
    
    @State private var currentLog: TextDocument?
    @ObservedObject var screenRecorder: ScreenRecorder
    
    @State private var isExporting = false
    
    var logger = Logger.application
    
    var body: some View {
        VStack(alignment: .imageTitleAlignmentGuide) {
            HStack {
                Text("Output folder:")
                    .padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 0))
                HStack {
                    TextField("Path", text: $screenRecorder.filePath)
                        .disabled(true)
                        .alignmentGuide(.imageTitleAlignmentGuide) { dimension in
                            dimension[.leading]
                        }
                    Button {
                        Task { await self.selectFolder() }
                    } label: {
                        Image(systemName: "folder")
                    }
                }
            }
            Button("Save Current Log") {
                Task {
                    self.currentLog = await logger.generateLog()
                    if self.currentLog != nil {
                        isExporting = true
                    }
                }
            }
            .fileExporter(isPresented: $isExporting, document: self.currentLog, contentType: .plainText, onCompletion: {
                result in
                switch result {
                case .success:
                    logger.notice("Successfully output log to file")
                case .failure:
                    logger.notice("Did not output log to file")
                }
            })
        }
        .modifier(ConfigurationSubViewStyle())
        .labelsHidden()
    }
    
    func selectFolder() async {
        let folderChooserPoint = CGPoint(x: 0, y: 0)
        let folderChooserSize = CGSize(width: 500, height: 600)
        let folderChooserRectangle = CGRect(origin: folderChooserPoint, size: folderChooserSize)
        let folderPicker = NSOpenPanel(contentRect: folderChooserRectangle, styleMask: .utilityWindow, backing: .buffered, defer: true)
        
        folderPicker.canChooseDirectories = true
        folderPicker.canDownloadUbiquitousContents = true
        folderPicker.canResolveUbiquitousConflicts = true
        
        folderPicker.begin { response in
            
            if response == .OK {
                let pickedFolders = folderPicker.urls
                self.screenRecorder.outputFolder = pickedFolders[0]
                self.screenRecorder.filePath = pickedFolders[0].path()
            }
        }
    }
}
