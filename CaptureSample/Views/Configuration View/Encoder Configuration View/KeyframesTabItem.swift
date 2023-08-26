//
//  EncoderConfigurationKeyframesTabItem.swift
//  Record
//
//  Created by John Moody on 8/24/23.
//  Copyright © 2023 Apple. All rights reserved.
//

import SwiftUI

struct KeyframesTabItem: View {
    @ObservedObject var screenRecorder: ScreenRecorder
    var body: some View {
        VStack(alignment: .imageTitleAlignmentGuide) {
            Group {
                HStack {
                    HStack {
                        Text("Interval:")
                        Picker("Max keyframe interval", selection: $screenRecorder.keyframeSetting) {
                            Text("Auto")
                                .tag(KeyframeSetting.auto)
                            //.frame(width: 25)
                            Text("Custom")
                                .tag(KeyframeSetting.custom)
                            //.frame(width: 45)
                        }
                        .alignmentGuide(.imageTitleAlignmentGuide) { dimension in
                            dimension[.leading]
                        }
                        //.pickerStyle(.radioGroup)
                        .frame(width: 92)
                        .horizontalRadioGroupLayout()
                        .padding(EdgeInsets(top: 0, leading: 0, bottom: 4, trailing: 0))
                        TextField("Value", value: $screenRecorder.maxKeyframeInterval, format: .number)
                            .disabled(screenRecorder.keyframeSetting != .custom)
                            .frame(width: 30)
                    }
                }
            }
            .labelsHidden()
            Group {
                HStack {
                    HStack {
                        Text("Interval (secs):")
                        Picker("Max keyframe interval duration (secs)", selection: $screenRecorder.keyframeIntervalSetting) {
                            Text("Unlimited")
                                .tag(KeyframeDurationSetting.unlimited)
                                .frame(width: 60)
                            Text("Custom")
                                .tag(KeyframeDurationSetting.custom)
                                .frame(width: 50)
                        }
                        .alignmentGuide(.imageTitleAlignmentGuide) { dimension in
                            dimension[.leading]
                        }
                        //.pickerStyle(.radioGroup)
                        .frame(width: 92)
                        .horizontalRadioGroupLayout()
                        .padding(EdgeInsets(top: 0, leading: 0, bottom: 4, trailing: 0))
                        TextField("Value", value: $screenRecorder.maxKeyframeIntervalDuration, format: .number)
                            .disabled(screenRecorder.keyframeIntervalSetting != .custom)
                            .frame(width: 30)
                    }
                }
                
                .padding(EdgeInsets(top: 0, leading: 0, bottom: 4, trailing: 0))
            }
            .labelsHidden()
            Group {
                Toggle("Enable B frames", isOn: $screenRecorder.bFramesSetting)
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 4, trailing: 0))
                    .alignmentGuide(.imageTitleAlignmentGuide) { dimension in
                        dimension[.leading]
                    }
            }
        }
        .padding(EdgeInsets(top: 6, leading: 4, bottom: 6, trailing: 4))
    }
}

