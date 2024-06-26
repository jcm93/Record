//
//  VideoCaptureConfigurationView.swift
//  Record
//
//  Created by John Moody on 8/24/23.
//  Copyright © 2023 Apple. All rights reserved.
//

import SwiftUI
import ScreenCaptureKit

struct VideoCaptureConfigurationView: View {
    @ObservedObject var screenRecorder: ScreenRecorder
    var body: some View {
        GroupBox {
            VStack(alignment: .imageTitleAlignmentGuide) {
                Group {
                    HStack {
                        Text("Capture Type:")
                        Picker("Capture", selection: $screenRecorder.captureType) {
                            Text("Display")
                                .tag(CaptureType.display)
                            Text("Window")
                                .tag(CaptureType.window)
                        }
                        .pickerStyle(.radioGroup)
                        .horizontalRadioGroupLayout()
                        .alignmentGuide(.imageTitleAlignmentGuide) { dimension in
                            dimension[.leading]
                        }                                //.padding([.trailing])
                    }
                    .labelsHidden()
                    HStack {
                        Text("Screen Content:")
                        switch screenRecorder.captureType {
                        case .display:
                            VStack {
                                Picker("Display", selection: $screenRecorder.selectedDisplay) {
                                    ForEach(screenRecorder.availableDisplays, id: \.self) { display in
                                        Text(display.displayName)
                                            .tag(SCDisplay?.some(display))
                                    }
                                }
                                .onHover(perform: { hovering in
                                    Task {
                                        await self.screenRecorder.refreshAvailableContent()
                                    }
                                })
                                .alignmentGuide(.imageTitleAlignmentGuide) { dimension in
                                    dimension[.leading]
                                }
                                .frame(width: 150)
                            }
                            
                        case .window:
                            Picker("Window", selection: $screenRecorder.selectedWindow) {
                                ForEach(screenRecorder.availableWindows, id: \.self) { window in
                                    Text(window.displayName)
                                        .tag(SCWindow?.some(window))
                                }
                            }
                            .onHover(perform: { hovering in
                                Task {
                                    await self.screenRecorder.refreshAvailableContent()
                                }
                            })
                            .alignmentGuide(.imageTitleAlignmentGuide) { dimension in
                                dimension[.leading]
                            }
                            .frame(width: 150)
                        }
                    }
                    .labelsHidden()
                    Group {
                        HStack {
                            Text("Capture HDR Status:")
                            Picker("Capture", selection: $screenRecorder.captureHDRStatus) {
                                Text("SDR")
                                    .tag(CaptureHDRStatus.SDR)
                                Text("Local HDR")
                                    .tag(CaptureHDRStatus.localHDR)
                                Text("Canonical HDR")
                                    .tag(CaptureHDRStatus.canonicalHDR)
                            }
                            .pickerStyle(.radioGroup)
                            .horizontalRadioGroupLayout()
                            .alignmentGuide(.imageTitleAlignmentGuide) { dimension in
                                dimension[.leading]
                            }
                        }
                        HStack {
                            Text("Pixel Format:")
                            Picker("Pixel Format", selection: $screenRecorder.capturePixelFormat) {
                                ForEach(CapturePixelFormat.allCases, id: \.self) { format in
                                    Text(format.stringValue())
                                        .tag(format)
                                }
                            }
                            .alignmentGuide(.imageTitleAlignmentGuide) { dimension in
                                dimension[.leading]
                            }
                            .frame(width: 150)
                        }
                        HStack {
                            Text("Transfer Function:")
                            Picker("Transfer Function", selection: $screenRecorder.captureYUVMatrix) {
                                ForEach(CaptureYUVMatrix.allCases, id: \.self) { format in
                                    Text(format.stringValue())
                                        .tag(format)
                                }
                            }
                            .alignmentGuide(.imageTitleAlignmentGuide) { dimension in
                                dimension[.leading]
                            }
                            .frame(width: 150)
                        }
                        HStack {
                            Text("Color Space:")
                            Picker("Color Space", selection: $screenRecorder.captureColorSpace) {
                                ForEach(CaptureColorSpace.allCases, id: \.self) { format in
                                    Text(String(format.cfString()))
                                        .tag(format)
                                }
                            }
                            .alignmentGuide(.imageTitleAlignmentGuide) { dimension in
                                dimension[.leading]
                            }
                            .frame(width: 150)
                        }
                    }
                    .labelsHidden()
                    .controlSize(.small)
                    HStack {
                        Text("Dimensions:")
                        HStack {
                            TextField("Width", value: $screenRecorder.captureWidth, formatter: NumberFormatter())
                                .disabled(true)
                                .alignmentGuide(.imageTitleAlignmentGuide) { dimension in
                                    dimension[.leading]
                                }
                                .fixedSize()
                            //.background(Color(red: 0.086, green: 0.086, blue: 0.086))
                        }
                        HStack {
                            TextField("Height", value: $screenRecorder.captureHeight, formatter: NumberFormatter())
                                .disabled(true)
                                .fixedSize()
                            //.background(Color(red: 0.086, green: 0.086, blue: 0.086))
                        }
                    }
                    .controlSize(.small)
                    .labelsHidden()
                    Group {
                        HStack {
                            Text("Scaled Dimensions:")
                            HStack {
                                TextField("Width", value: $screenRecorder.scaleWidth, formatter: NumberFormatter(), onEditingChanged: { value in
                                    if !value {
                                        self.screenRecorder.dimensionsChanged(width: screenRecorder.scaleWidth, height: 0)
                                    }
                                })
                                .alignmentGuide(.imageTitleAlignmentGuide) { dimension in
                                    dimension[.leading]
                                }
                                .fixedSize()
                                //.background(Color(red: 0.086, green: 0.086, blue: 0.086))
                                .disabled(!screenRecorder.doesScale)
                            }
                            HStack {
                                TextField("Height", value: $screenRecorder.scaleHeight, formatter: NumberFormatter(), onEditingChanged: { value in
                                    if !value {
                                        self.screenRecorder.dimensionsChanged(width: 0, height: screenRecorder.scaleHeight)
                                    }
                                })
                                .fixedSize()
                                //.background(Color(red: 0.086, green: 0.086, blue: 0.086))
                                .disabled(!screenRecorder.doesScale)
                            }
                        }
                    }
                    .controlSize(.small)
                    .labelsHidden()
                    Group {
                        //Text("Quality")
                        HStack {
                            Text("Target frame rate:")
                            TextField("Value", value: $screenRecorder.framesPerSecond, format: .number)
                                .alignmentGuide(.imageTitleAlignmentGuide) { dimension in
                                    dimension[.leading]
                                }
                        }
                    }
                    .controlSize(.small)
                    .labelsHidden()
                    .disabled(!screenRecorder.usesTargetFPS)
                    .help("Establishes a target frame rate for ScreenCaptureKit. Even with a target frame rate, frame times and rates are variable with the screen content refresh interval. Encoded FPS may be lower if the screen content contains many idle (duplicated) frames.")
                    
                    Toggle("Use target frame rate", isOn: $screenRecorder.usesTargetFPS)
                        .alignmentGuide(.imageTitleAlignmentGuide) { dimension in
                            dimension[.leading]
                        }
                        .help("If not targeting a frame rate, the system will make as many frames available as it can, up to the maximum supported frame rate.")
                    
                    Toggle("Scale Output", isOn: $screenRecorder.doesScale)
                        .alignmentGuide(.imageTitleAlignmentGuide) { dimension in
                            dimension[.leading]
                        }
                    
                    Toggle("Exclude self from stream", isOn: $screenRecorder.isAppExcluded)
                        .disabled(screenRecorder.captureType == .window)
                        .onChange(of: screenRecorder.isAppExcluded) { _ in
                            // Capturing app audio is only possible when the sample is included in the stream.
                            // Ensure the audio stops playing if the user enables the "Exclude app from stream" checkbox.
                        }
                        .controlSize(.small)
                        .alignmentGuide(.imageTitleAlignmentGuide) { dimension in
                            dimension[.leading]
                        }
                    Toggle("Live encode preview", isOn: $screenRecorder.showsEncodePreview)
                        .alignmentGuide(.imageTitleAlignmentGuide) { dimension in
                            dimension[.leading]
                        }
                }
                .padding(EdgeInsets(top: 4, leading: -2, bottom: 0, trailing: -2))
            }
            .modifier(ConfigurationSubViewStyle())
        }
    }
}
