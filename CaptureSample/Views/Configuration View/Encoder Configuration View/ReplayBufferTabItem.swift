//
//  EncoderConfigurationReplayBufferTabItem.swift
//  Record
//
//  Created by John Moody on 8/24/23.
//  Copyright © 2023 Apple. All rights reserved.
//

import SwiftUI

struct ReplayBufferTabItem: View {
    @ObservedObject var screenRecorder: ScreenRecorder
    var body: some View {
        VStack(alignment: .imageTitleAlignmentGuide) {
            Group {
                Toggle("Enable replay buffer", isOn: $screenRecorder.usesReplayBuffer)
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 6, trailing: 0))
                    .alignmentGuide(.imageTitleAlignmentGuide) { dimension in
                        dimension[.leading]
                    }
            }
            HStack {
                Text("Duration:")
                    .padding(EdgeInsets(top: 0, leading: 30, bottom: 0, trailing: 0))
                PickerView(seconds: $screenRecorder.replayBufferDuration)
                    .alignmentGuide(.imageTitleAlignmentGuide) { dimension in
                        dimension[.leading]
                    }
                    .disabled(!self.screenRecorder.usesReplayBuffer)
            }
            .labelsHidden()
        }
        .padding(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
        .tabItem { Label("Replay", systemImage: "house") }
    }
}
