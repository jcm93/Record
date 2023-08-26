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
                        Spacer(minLength: 20)
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
        }
        .frame(width: 260)
        .padding(EdgeInsets(top: 15, leading: 15, bottom: 15, trailing: 15))
        .background(.quaternary)
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(Color(.quaternaryLabelColor), lineWidth: 1)
        )
        
        TabView {
            
            ColorTabItem(screenRecorder: self.screenRecorder)
            
            KeyframesTabItem(screenRecorder: self.screenRecorder)
            
            ReplayBufferTabItem(screenRecorder: self.screenRecorder)
            
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(width: 290)
        .controlSize(.small)
    }
}
