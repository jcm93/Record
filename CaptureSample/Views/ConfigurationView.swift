/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view that provides the UI to configure screen capture.
*/

import SwiftUI
import ScreenCaptureKit

/// The app's configuration user interface.
struct ConfigurationView: View {
    
    private let sectionSpacing: CGFloat = 20
    private let verticalLabelSpacing: CGFloat = 8
    
    private let alignmentOffset: CGFloat = 10
    
    @StateObject private var audioPlayer = AudioPlayer()
    @ObservedObject var screenRecorder: ScreenRecorder
    @Binding var userStopped: Bool
    
    @FocusState private var isTextFieldFocused: Bool
    
    private let scaleWidth: Int = 0
    private let scaleHeight: Int = 0
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack {
                    Form {
                        VStack(alignment: .leading) {
                            Spacer()
                                .frame(height: 10)
                            HeaderView("Video")
                                .padding(EdgeInsets(top: 0, leading: 0, bottom: 1, trailing: 0))
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
                                        if (self.screenRecorder.capturePixelFormat == .biplanarfull420f || self.screenRecorder.capturePixelFormat == .biplanarpartial420v) {
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
                                                .background(Color(red: 0.086, green: 0.086, blue: 0.086))
                                        }
                                        HStack {
                                            TextField("Height", value: $screenRecorder.captureHeight, formatter: NumberFormatter())
                                                .disabled(true)
                                                .fixedSize()
                                                .background(Color(red: 0.086, green: 0.086, blue: 0.086))
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
                                                .background(Color(red: 0.086, green: 0.086, blue: 0.086))
                                                .disabled(!screenRecorder.doesScale)
                                            }
                                            HStack {
                                                TextField("Height", value: $screenRecorder.scaleHeight, formatter: NumberFormatter(), onEditingChanged: { value in
                                                    if !value {
                                                        self.screenRecorder.dimensionsChanged(width: 0, height: screenRecorder.scaleHeight)
                                                    }
                                                })
                                                .fixedSize()
                                                .background(Color(red: 0.086, green: 0.086, blue: 0.086))
                                                .disabled(!screenRecorder.doesScale)
                                            }
                                        }
                                    }
                                    .controlSize(.small)
                                    .labelsHidden()
                                    Toggle("Scale Output", isOn: $screenRecorder.doesScale)
                                        .alignmentGuide(.imageTitleAlignmentGuide) { dimension in
                                            dimension[.leading]
                                        }
                                    
                                    Toggle("Exclude self from stream", isOn: $screenRecorder.isAppExcluded)
                                        .disabled(screenRecorder.captureType == .window)
                                        .onChange(of: screenRecorder.isAppExcluded) { _ in
                                            // Capturing app audio is only possible when the sample is included in the stream.
                                            // Ensure the audio stops playing if the user enables the "Exclude app from stream" checkbox.
                                            if screenRecorder.isAppExcluded {
                                                audioPlayer.stop()
                                            }
                                        }
                                        .controlSize(.small)
                                        .alignmentGuide(.imageTitleAlignmentGuide) { dimension in
                                            dimension[.leading]
                                        }
                                }
                                .padding(EdgeInsets(top: 4, leading: -2, bottom: 0, trailing: -2))
                            }
                            .frame(width: 260)
                            .padding(EdgeInsets(top: 15, leading: 15, bottom: 15, trailing: 15))
                            .controlSize(.small)
                            .background(Color(red: 0.149, green: 0.149, blue: 0.149))
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(Color(red: 0.224, green: 0.224, blue: 0.244), lineWidth: 1)
                            )
                            
                            
                            Spacer()
                                .frame(height: 8)
                            
                            HeaderView("Audio")
                            VStack(alignment: .trailing) {
                                Toggle("Capture audio", isOn: $screenRecorder.isAudioCaptureEnabled)
                                    .padding(EdgeInsets(top: 0, leading: 48, bottom: 0, trailing: 0))
                                    .controlSize(.small)
                            }
                            .frame(width: 260)
                            .padding(EdgeInsets(top: 15, leading: 15, bottom: 15, trailing: 15))
                            .background(Color(red: 0.149, green: 0.149, blue: 0.149))
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(Color(red: 0.224, green: 0.224, blue: 0.244), lineWidth: 1)
                            )
                            
                            //AudioLevelsView(audioLevelsProvider: screenRecorder.audioLevelsProvider)
                            //Spacer()
                            //.frame(height: 20)
                            
                            Spacer()
                                .frame(height: 8)
                            
                            HeaderView("Encoder")
                                .padding(EdgeInsets(top: 0, leading: 0, bottom: 1, trailing: 0))
                            
                            VStack(alignment: .imageTitleAlignmentGuide) {
                                Group {
                                    HStack {
                                        Text("Codec")
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
                                        Text("Container")
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
                                            Text("Rate Control")
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
                                                Text("Bitrate")
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
                                                Text("Quality")
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
                                            Text("ProRes Setting")
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
                                        Text("Frames per second")
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
                                                Text("Pixel Format")
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
                                                Text("Color Primaries")
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
                                                Text("YCbCr Matrix")
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
                                                Text("Transfer Function")
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
                                                Text("Gamma")
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
                                            Text("Bit Depth")
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
                                            Text("Dest. Color Space")
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
                                                Text("Interval")
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
                                                Text("Interval (secs)")
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
                            //.background(Color(red: 0.18, green: 0.18, blue: 0.18))
                        }
                        
                        Spacer()
                            .frame(height: 8)
                        
                        HeaderView("Output")
                        
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
                    
                    Spacer()
                        .frame(minHeight: 15)
                    
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
                    .frame(maxWidth: .infinity, minHeight: 60)
                }
                .frame(minHeight: geometry.size.height)
            }
            .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 6))
            .background(Color(red: 0.122, green: 0.122, blue: 0.122))
            .frame(width: geometry.size.width)
        }
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

/// A view that displays a styled header for the Video and Audio sections.
struct HeaderView: View {
    
    private let title: String
    private let alignmentOffset: CGFloat = 10.0
    
    init(_ title: String) {
        self.title = title
    }
    
    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundColor(.secondary)
            .padding(EdgeInsets(top: 0, leading: 6, bottom: 0, trailing: 0))
            //.alignmentGuide(.leading) { _ in alignmentOffset }
    }
}

extension HorizontalAlignment {
    /// A custom alignment for image titles.
    private struct ImageTitleAlignment: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            // Default to trailing
            context[HorizontalAlignment.trailing]
        }
    }


    /// A guide for aligning titles.
    static let imageTitleAlignmentGuide = HorizontalAlignment(
        ImageTitleAlignment.self
    )
}
