//
//  OutputConfigurationView.swift
//  Record
//
//  Created by John Moody on 8/24/23.
//  Copyright © 2023 Apple. All rights reserved.
//

import SwiftUI

struct OutputConfigurationView: View {
    @ObservedObject var screenRecorder: ScreenRecorder
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
        }
        .frame(width: 260)
        .padding(EdgeInsets(top: 15, leading: 15, bottom: 15, trailing: 15))
        .background(Color(red: 0.149, green: 0.149, blue: 0.149))
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(Color(red: 0.224, green: 0.224, blue: 0.244), lineWidth: 1)
        )
        .controlSize(.small)
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
