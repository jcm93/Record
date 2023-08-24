//
//  EncoderConfigurationView.swift
//  Record
//
//  Created by John Moody on 8/24/23.
//  Copyright © 2023 Apple. All rights reserved.
//

import SwiftUI

struct EncoderConfigurationView: View {
    @ObservedObject var screenRecorder: ScreenRecorder
    var body: some View {
        VStack(alignment: .imageTitleAlignmentGuide) {
            Group {
                HStack {
                    Text("Codec:")
                    Picker("Codec", selection: $screenRecorder.encoderSetting) {
                        ForEach(EncoderSetting.allCases, id: \.self) { format in
                            Text(format.stringValue())
                                .tag(format)
                        }
                    }
                    //.pickerStyle(.radioGroup)
                    .frame(width: 150)
                    .horizontalRadioGroupLayout()
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 4, trailing: 0))
                    .alignmentGuide(.imageTitleAlignmentGuide) { dimension in
                        dimension[.leading]
                    }
                }
                
            }
            .controlSize(.small)
            .labelsHidden()
            
            Group {
                HStack {
                    Text("Container:")
                    Picker("Container", selection: $screenRecorder.containerSetting) {
                        Text(".mp4")
                            .tag(ContainerSetting.mp4)
                        Text(".mov")
                            .tag(ContainerSetting.mov)
                    }
                    .frame(width: 150)
                    //.pickerStyle(.radioGroup)
                    .horizontalRadioGroupLayout()
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 4, trailing: 0))
                    .alignmentGuide(.imageTitleAlignmentGuide) { dimension in
                        dimension[.leading]
                    }
                }
            }
            .controlSize(.small)
            .labelsHidden()
            if (self.screenRecorder.encoderSetting == .H264 || self.screenRecorder.encoderSetting == .H265) {
                Group {
                    HStack {
                        Text("Rate Control:")
                        Picker("Rate Control", selection: $screenRecorder.rateControlSetting) {
                            Text("CBR")
                                .tag(RateControlSetting.cbr)
                            Text("ABR")
                                .tag(RateControlSetting.abr)
                            Text("CRF")
                                .tag(RateControlSetting.crf)
                        }
                        .frame(width: 150)
                        //.pickerStyle(.radioGroup)
                        .horizontalRadioGroupLayout()
                        .padding(EdgeInsets(top: 0, leading: 0, bottom: 4, trailing: 0))
                        .alignmentGuide(.imageTitleAlignmentGuide) { dimension in
                            dimension[.leading]
                        }
                    }
                }
                .controlSize(.small)
                .labelsHidden()
                
                
                if (screenRecorder.rateControlSetting != .crf) {
                    Group {
                        HStack {
                            Text("Bitrate:")
                            HStack {
                                TextField("", value: $screenRecorder.bitRate, format: .number)
                                    .frame(width: 100)
                                    .alignmentGuide(.imageTitleAlignmentGuide) { dimension in
                                        dimension[.leading]
                                    }
                                Text("kbps")
                                    .frame(width: 40)
                            }
                        }
                    }
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 4, trailing: 0))
                    .controlSize(.small)
                    .labelsHidden()
                } else {
                    Group {
                        //Text("Quality")
                        HStack {
                            Text("Quality:")
                            Slider(
                                value: $screenRecorder.crfValue,
                                in: 0.0...1.00
                            ) {
                                Text("Values from 0 to 1.00")
                            }
                            .frame(width: 150)/*minimumValueLabel: {
                                               Text("Poor")
                                               } maximumValueLabel: {
                                               Text("'Lossless'")
                                               }*/
                            .alignmentGuide(.imageTitleAlignmentGuide) { dimension in
                                dimension[.leading]
                            }
                        }
                        HStack {
                            Text("CRF:")
                            TextField("CRF", value: $screenRecorder.crfValue, format: .number)
                                .frame(width: 70)
                                .alignmentGuide(.imageTitleAlignmentGuide) { dimension in
                                    dimension[.leading]
                                }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 4, trailing: 0))
                    .controlSize(.small)
                    .labelsHidden()
                }
            } else {
                Group {
                    HStack {
                        Text("ProRes Setting:")
                        Picker("ProRes Setting", selection: $screenRecorder.proResSetting) {
                            ForEach(ProResSetting.allCases, id: \.self) { format in
                                Text(format.stringValue())
                                    .tag(format)
                            }
                        }
                        .frame(width: 150)
                        .alignmentGuide(.imageTitleAlignmentGuide) { dimension in
                            dimension[.leading]
                        }
                    }
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 4, trailing: 0))
                }
                .controlSize(.small)
                .labelsHidden()
            }
            Group {
                //Text("Quality")
                HStack {
                    Text("Frames per second:")
                    TextField("Value", value: $screenRecorder.framesPerSecond, format: .number)
                        .alignmentGuide(.imageTitleAlignmentGuide) { dimension in
                            dimension[.leading]
                        }
                }
            }
            .controlSize(.small)
            .labelsHidden()
        }
        .frame(width: 260)
        .padding(EdgeInsets(top: 15, leading: 15, bottom: 15, trailing: 15))
        .background(Color(red: 0.149, green: 0.149, blue: 0.149))
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(Color(red: 0.224, green: 0.224, blue: 0.244), lineWidth: 1)
        )
        
        TabView {
            VStack(alignment: .imageTitleAlignmentGuide) {
                Group {
                    Group {
                        HStack {
                            Text("Pixel Format:")
                            Picker("Pixel Format", selection: $screenRecorder.pixelFormatSetting) {
                                ForEach(CapturePixelFormat.allCases, id: \.self) { format in
                                    Text(format.stringValue())
                                        .tag(format)
                                }
                            }
                            .frame(width: 150)
                            .alignmentGuide(.imageTitleAlignmentGuide) { dimension in
                                dimension[.leading]
                            }
                        }
                        .padding(EdgeInsets(top: 0, leading: 0, bottom: 4, trailing: 0))
                    }
                    .labelsHidden()
                    Group {
                        HStack {
                            Text("Color Primaries:")
                            Picker("Color Primaries", selection: $screenRecorder.colorPrimariesSetting) {
                                ForEach(ColorPrimariesSetting.allCases, id: \.self) { format in
                                    Text(format.stringValue() as String? ?? "Untagged")
                                        .tag(format)
                                }
                            }
                            .frame(width: 150)
                            .alignmentGuide(.imageTitleAlignmentGuide) { dimension in
                                dimension[.leading]
                            }
                        }
                        .padding(EdgeInsets(top: 0, leading: 0, bottom: 4, trailing: 0))
                    }
                    .labelsHidden()
                    Group {
                        HStack {
                            Text("YCbCr Matrix:")
                            Picker("YCbCr Matrix", selection: $screenRecorder.yCbCrMatrixSetting) {
                                ForEach(YCbCrMatrixSetting.allCases, id: \.self) { format in
                                    Text(format.stringValue() as String? ?? "Untagged")
                                        .tag(format)
                                }
                            }
                            .frame(width: 150)
                            .alignmentGuide(.imageTitleAlignmentGuide) { dimension in
                                dimension[.leading]
                            }
                        }
                        .padding(EdgeInsets(top: 0, leading: 0, bottom: 4, trailing: 0))
                    }
                    .labelsHidden()
                    Group {
                        HStack {
                            Text("Transfer Function:")
                            Picker("Transfer Function", selection: $screenRecorder.transferFunctionSetting) {
                                ForEach(TransferFunctionSetting.allCases, id: \.self) { format in
                                    Text(format.stringValue() as String? ?? "Untagged")
                                        .tag(format)
                                }
                            }
                            .frame(width: 150)
                            .alignmentGuide(.imageTitleAlignmentGuide) { dimension in
                                dimension[.leading]
                            }
                        }
                        .padding(EdgeInsets(top: 0, leading: 0, bottom: 4, trailing: 0))
                        if self.screenRecorder.transferFunctionSetting == .useGamma {
                            Text("Gamma:")
                            Slider(
                                value: $screenRecorder.gammaValue,
                                in: 0.0...3.0
                            ) {
                                Text("Values from 0 to 3.00")
                            } minimumValueLabel: {
                                Text("0.0")
                            } maximumValueLabel: {
                                Text("3.0")
                            }
                            HStack {
                                Text("Gamma:")
                                TextField("Gamma", value: $screenRecorder.gammaValue, format: .number)
                                    .frame(width: 70)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                    .labelsHidden()
                    HStack {
                        Text("Bit Depth:")
                        Picker("Bit depth", selection: $screenRecorder.bitDepthSetting) {
                            Text("8")
                                .tag(BitDepthSetting.eight)
                            Text("10")
                                .tag(BitDepthSetting.ten)
                        }
                        .alignmentGuide(.imageTitleAlignmentGuide) { dimension in
                            dimension[.leading]
                        }
                        .pickerStyle(.radioGroup)
                        .horizontalRadioGroupLayout()
                    }
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 4, trailing: 0))
                    .labelsHidden()
                    HStack {
                        Text("Dest. Color Space:")
                        Group {
                            Picker("Color Space", selection: $screenRecorder.convertTargetColorSpace) {
                                ForEach(CaptureColorSpace.allCases, id: \.self) { format in
                                    Text(String(format.cfString()))
                                        .tag(format)
                                }
                            }
                            .frame(width: 150)
                            .alignmentGuide(.imageTitleAlignmentGuide) { dimension in
                                dimension[.leading]
                            }
                            .disabled(!screenRecorder.pixelTransferEnabled)
                        }
                    }
                    .labelsHidden()
                    HStack {
                        Toggle("Pre-convert color space", isOn: $screenRecorder.pixelTransferEnabled)
                            .alignmentGuide(.imageTitleAlignmentGuide) { dimension in
                                dimension[.leading]
                            }
                    }
                    Toggle("Use display ICC profile", isOn: $screenRecorder.usesICCProfile)
                        .alignmentGuide(.imageTitleAlignmentGuide) { dimension in
                            dimension[.leading]
                        }
                    
                }
                .padding(EdgeInsets(top: 0, leading: -2, bottom: 4, trailing: -2))
            }
            .frame(width: 260)
            .padding(EdgeInsets(top: 15, leading: 15, bottom: 15, trailing: 15))
            .tabItem { Label("Color", systemImage: "house") }
            
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
            .tabItem { Label("Keyframes", systemImage: "house") }
            
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
        .fixedSize(horizontal: false, vertical: true)
        .frame(width: 290)
        .controlSize(.small)
    }
}
