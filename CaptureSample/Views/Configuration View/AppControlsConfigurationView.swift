//
//  AppControlsConfigurationView.swift
//  Record
//
//  Created by John Moody on 8/24/23.
//  Copyright © 2023 Apple. All rights reserved.
//

import SwiftUI

struct AppControlsConfigurationView: View {
    
    @ObservedObject var screenRecorder: ScreenRecorder
    @Binding var userStopped: Bool
    
    var body: some View {
        HStack {
            Button {
                Task { await screenRecorder.start() }
                // Fades the paused screen out.
                withAnimation(Animation.easeOut(duration: 0.25)) {
                    userStopped = false
                }
            } label: {
                Text("Start Capture")
            }
            .controlSize(.large)
            .disabled(screenRecorder.isRunning)
            Button {
                Task { await screenRecorder.stop() }
                // Fades the paused screen in.
                withAnimation(Animation.easeOut(duration: 0.25)) {
                    userStopped = true
                }
                
            } label: {
                Text("Stop Capture")
            }
            .controlSize(.large)
            .disabled(!screenRecorder.isRunning)
        }
        Spacer(minLength: 10)
        HStack {
            if screenRecorder.isRecording || !screenRecorder.isRunning {
                Button {
                    Task { await screenRecorder.record() }
                    
                } label: {
                    Text("Start Recording")
                }
                .controlSize(.large)
                .buttonStyle(.bordered)
                .disabled(screenRecorder.isRecording || !screenRecorder.isRunning)
            } else {
                Button {
                    Task { await screenRecorder.record() }
                    
                } label: {
                    Text("Start Recording")
                }
                .controlSize(.large)
                .buttonStyle(.borderedProminent)
                .disabled(screenRecorder.isRecording || !screenRecorder.isRunning)
            }
            if screenRecorder.isRecording {
                Button {
                    Task { await screenRecorder.stopRecord() }
                    
                } label: {
                    Text("Stop Recording")
                }
                .controlSize(.large)
                .buttonStyle(.borderedProminent)
                .disabled(!screenRecorder.isRecording || !screenRecorder.isRunning)
            } else {
                Button {
                    Task { await screenRecorder.stopRecord() }
                    
                } label: {
                    Text("Stop Recording")
                }
                .controlSize(.large)
                .buttonStyle(.bordered)
                .disabled(!screenRecorder.isRecording || !screenRecorder.isRunning)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(EdgeInsets(top: 0, leading: 0, bottom: 15, trailing: 0))
    }
}
