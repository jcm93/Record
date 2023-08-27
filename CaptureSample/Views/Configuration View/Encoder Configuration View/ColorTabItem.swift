//
//  EncoderConfigurationColorTabView.swift
//  Record
//
//  Created by John Moody on 8/24/23.
//  Copyright © 2023 Apple. All rights reserved.
//

import SwiftUI

struct ColorTabItem: View {
    @ObservedObject var screenRecorder: ScreenRecorder
    var body: some View {
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
        .padding(EdgeInsets(top: 8, leading: 15, bottom: 0, trailing: 15))
    }
}
