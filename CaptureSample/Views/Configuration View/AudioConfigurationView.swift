//
//  AudioConfigurationView.swift
//  Record
//
//  Created by John Moody on 8/24/23.
//  Copyright © 2023 Apple. All rights reserved.
//

import SwiftUI

struct AudioConfigurationView: View {
    @ObservedObject var screenRecorder: ScreenRecorder
    var body: some View {
        VStack(alignment: .trailing) {
            Toggle("Capture audio", isOn: $screenRecorder.isAudioCaptureEnabled)
                .padding(EdgeInsets(top: 0, leading: 48, bottom: 0, trailing: 0))
                .controlSize(.small)
        }
        .frame(width: 260)
        .padding(EdgeInsets(top: 15, leading: 15, bottom: 15, trailing: 15))
        .background(.quaternary)
        //.background(Color(red: 0.149, green: 0.149, blue: 0.149))
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(Color(.quaternaryLabelColor), lineWidth: 1)
        )
    }
}
