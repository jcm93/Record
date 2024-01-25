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
        GroupBox {
            VStack(alignment: .imageTitleAlignmentGuide) {
                Toggle("Capture audio", isOn: $screenRecorder.isAudioCaptureEnabled)
                    .padding(EdgeInsets(top: 0, leading: 48, bottom: 0, trailing: 0))
                    .controlSize(.small)
            }
        }
        .modifier(ConfigurationSubViewStyle())
    }
}
