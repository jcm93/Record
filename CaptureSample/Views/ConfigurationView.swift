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
    
    var body: some View {
        ScrollView {
            VStack {
                Form {
                    VStack(alignment: .leading) {
                        HeaderView("Video")
                            .padding(EdgeInsets(top: 0, leading: 0, bottom: 1, trailing: 0))
                        
                        // A group that hides view labels.
                        Group {
                            VStack(alignment: .leading, spacing: verticalLabelSpacing) {
                                Text("Capture Type")
                                Picker("Capture", selection: $screenRecorder.captureType) {
                                    Text("Display")
                                        .tag(ScreenRecorder.CaptureType.display)
                                    Text("Window")
                                        .tag(ScreenRecorder.CaptureType.window)
                                }
                                .pickerStyle(.radioGroup)
                                .horizontalRadioGroupLayout()
                            }
                            .padding(EdgeInsets(top: 0, leading: 0, bottom: 5, trailing: 0))
                            
                            VStack(alignment: .leading, spacing: verticalLabelSpacing) {
                                Text("Screen Content")
                                switch screenRecorder.captureType {
                                case .display:
                                    Picker("Display", selection: $screenRecorder.selectedDisplay) {
                                        ForEach(screenRecorder.availableDisplays, id: \.self) { display in
                                            Text(display.displayName)
                                                .tag(SCDisplay?.some(display))
                                        }
                                    }
                                    
                                case .window:
                                    Picker("Window", selection: $screenRecorder.selectedWindow) {
                                        ForEach(screenRecorder.availableWindows, id: \.self) { window in
                                            Text(window.displayName)
                                                .tag(SCWindow?.some(window))
                                        }
                                    }
                                }
                            }
                        }
                        .labelsHidden()
                        
                        Toggle("Exclude self from stream", isOn: $screenRecorder.isAppExcluded)
                            .disabled(screenRecorder.captureType == .window)
                            .onChange(of: screenRecorder.isAppExcluded) { _ in
                                // Capturing app audio is only possible when the sample is included in the stream.
                                // Ensure the audio stops playing if the user enables the "Exclude app from stream" checkbox.
                                if screenRecorder.isAppExcluded {
                                    audioPlayer.stop()
                                }
                            }
                            .padding(EdgeInsets(top: 0, leading: 0, bottom: 4, trailing: 0))
                        Group {
                            Text("Pixel Format")
                            Picker("Pixel Format", selection: $screenRecorder.capturePixelFormat) {
                                ForEach(ScreenRecorder.CapturePixelFormat.allCases, id: \.self) { format in
                                    Text(format.stringValue())
                                        .tag(format)
                                }
                            }
                            .padding(EdgeInsets(top: 0, leading: 0, bottom: 4, trailing: 0))
                            if (self.screenRecorder.capturePixelFormat == .biplanarfull420f || self.screenRecorder.capturePixelFormat == .biplanarpartial420v) {
                                Text("Transfer Function")
                                Picker("Transfer Function", selection: $screenRecorder.captureYUVMatrix) {
                                    ForEach(ScreenRecorder.CaptureYUVMatrix.allCases, id: \.self) { format in
                                        Text(format.stringValue())
                                            .tag(format)
                                    }
                                }
                            }
                            Text("Color Space")
                            Picker("Color Space", selection: $screenRecorder.captureColorSpace) {
                                ForEach(CaptureColorSpace.allCases, id: \.self) { format in
                                    Text(String(format.cfString()))
                                        .tag(format)
                                }
                            }
                        }
                        .labelsHidden()
                        // Add some space between the Video and Audio sections.
                        Spacer()
                            .frame(height: 20)
                        
                        HeaderView("Audio")
                        
                        Toggle("Capture audio", isOn: $screenRecorder.isAudioCaptureEnabled)
                            .padding(EdgeInsets(top: 0, leading: 0, bottom: 4, trailing: 0))
                        AudioLevelsView(audioLevelsProvider: screenRecorder.audioLevelsProvider)
                        Spacer()
                            .frame(height: 20)
                        
                        HeaderView("Encoder")
                            .padding(EdgeInsets(top: 0, leading: 0, bottom: 1, trailing: 0))
                        
                        Group {
                            VStack(alignment: .leading) {
                                Text("Output folder")
                                HStack {
                                    TextField("Path", text: $screenRecorder.filePath)
                                        .disabled(true)
                                    Button {
                                        Task { await self.selectFolder() }
                                        
                                    } label: {
                                        Text("Browse")
                                    }
                                }
                            }
                        }
                        .labelsHidden()
                        
                        Group {
                            Text("Codec")
                            Picker("Codec", selection: $screenRecorder.encoderSetting) {
                                Text("H.264")
                                    .tag(ScreenRecorder.EncoderSetting.H264)
                                Text("HEVC")
                                    .tag(ScreenRecorder.EncoderSetting.H265)
                            }
                            .pickerStyle(.radioGroup)
                            .horizontalRadioGroupLayout()
                            .padding(EdgeInsets(top: 0, leading: 0, bottom: 4, trailing: 0))
                            
                        }
                        .labelsHidden()
                        
                        Group {
                            Text("Container")
                            Picker("Container", selection: $screenRecorder.containerSetting) {
                                Text(".mp4")
                                    .tag(ScreenRecorder.ContainerSetting.mp4)
                                Text(".mov")
                                    .tag(ScreenRecorder.ContainerSetting.mov)
                            }
                            .pickerStyle(.radioGroup)
                            .horizontalRadioGroupLayout()
                            .padding(EdgeInsets(top: 0, leading: 0, bottom: 4, trailing: 0))
                        }
                        .labelsHidden()
                        Group {
                            Text("Rate Control")
                            Picker("Rate Control", selection: $screenRecorder.rateControlSetting) {
                                Text("CBR")
                                    .tag(RateControlSetting.cbr)
                                Text("ABR")
                                    .tag(RateControlSetting.abr)
                                Text("CRF")
                                    .tag(RateControlSetting.crf)
                            }
                            .pickerStyle(.radioGroup)
                            .horizontalRadioGroupLayout()
                            .padding(EdgeInsets(top: 0, leading: 0, bottom: 4, trailing: 0))
                        }
                        .labelsHidden()
                        
                        
                        if (screenRecorder.rateControlSetting != .crf) {
                            Group {
                                Text("Bitrate")
                                HStack {
                                    TextField("", value: $screenRecorder.bitRate, format: .number)
                                        .frame(width: 100)
                                    Text("kbps")
                                }
                            }
                            .padding(EdgeInsets(top: 0, leading: 0, bottom: 4, trailing: 0))
                            .labelsHidden()
                        } else {
                            Group {
                                //Text("Quality")
                                Text("Quality")
                                Slider(
                                    value: $screenRecorder.crfValue,
                                    in: 0.0...1.00,
                                    step: 0.05
                                ) {
                                    Text("Values from 0 to 1.00")
                                } minimumValueLabel: {
                                    Text("Poor")
                                } maximumValueLabel: {
                                    Text("'Lossless'")
                                }
                                Text("CRF \(screenRecorder.crfValue)")
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                            .padding(EdgeInsets(top: 0, leading: 0, bottom: 4, trailing: 0))
                            .labelsHidden()
                        }
                        Group {
                            //Text("Quality")
                            Text("Frames per second")
                            TextField("Value", value: $screenRecorder.framesPerSecond, format: .number)
                        }
                        .labelsHidden()
                        
                        TabView {
                            VStack(alignment: .leading) {
                                Group {
                                    Text("Pixel Format")
                                    Picker("Pixel Format", selection: $screenRecorder.pixelFormatSetting) {
                                        ForEach(ScreenRecorder.CapturePixelFormat.allCases, id: \.self) { format in
                                            Text(format.stringValue())
                                                .tag(format)
                                        }
                                    }
                                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 4, trailing: 0))
                                }
                                .labelsHidden()
                                Group {
                                    Text("Color Primaries")
                                    Picker("Color Primaries", selection: $screenRecorder.colorPrimariesSetting) {
                                        ForEach(ScreenRecorder.ColorPrimariesSetting.allCases, id: \.self) { format in
                                            Text(format.stringValue() as String? ?? "Untagged")
                                                .tag(format)
                                        }
                                    }
                                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 4, trailing: 0))
                                }
                                .labelsHidden()
                                Group {
                                    Text("YCbCr Matrix")
                                    Picker("YCbCr Matrix", selection: $screenRecorder.yCbCrMatrixSetting) {
                                        ForEach(ScreenRecorder.YCbCrMatrixSetting.allCases, id: \.self) { format in
                                            Text(format.stringValue() as String? ?? "Untagged")
                                                .tag(format)
                                        }
                                    }
                                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 4, trailing: 0))
                                }
                                .labelsHidden()
                                Group {
                                    Text("Transfer Function")
                                    Picker("Transfer Function", selection: $screenRecorder.transferFunctionSetting) {
                                        ForEach(ScreenRecorder.TransferFunctionSetting.allCases, id: \.self) { format in
                                            Text(format.stringValue() as String? ?? "Untagged")
                                                .tag(format)
                                        }
                                    }
                                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 4, trailing: 0))
                                }
                                .labelsHidden()
                                Text("Bit Depth")
                                Picker("Bit depth", selection: $screenRecorder.bitDepthSetting) {
                                    Text("8")
                                        .tag(ScreenRecorder.BitDepthSetting.eight)
                                    Text("10")
                                        .tag(ScreenRecorder.BitDepthSetting.ten)
                                }
                                .pickerStyle(.radioGroup)
                                .horizontalRadioGroupLayout()
                                .padding(EdgeInsets(top: 0, leading: 0, bottom: 4, trailing: 0))
                                .labelsHidden()
                                Toggle("Use display ICC profile", isOn: $screenRecorder.usesICCProfile)
                                
                            }
                            .tabItem { Label("Color", systemImage: "house") }
                            
                            VStack(alignment: .leading) {
                                Group {
                                    Text("Max keyframe interval (frames)")
                                    HStack {
                                        Picker("Max keyframe interval", selection: $screenRecorder.keyframeSetting) {
                                            Text("Auto")
                                                .tag(ScreenRecorder.KeyframeSetting.auto)
                                                .frame(width: 30)
                                            Text("Custom")
                                                .tag(ScreenRecorder.KeyframeSetting.custom)
                                                .frame(width: 50)
                                        }
                                        .pickerStyle(.radioGroup)
                                        .horizontalRadioGroupLayout()
                                        .padding(EdgeInsets(top: 0, leading: 0, bottom: 4, trailing: 0))
                                        TextField("Value", value: $screenRecorder.maxKeyframeInterval, format: .number)
                                            .disabled(screenRecorder.keyframeSetting != .custom)
                                    }
                                }
                                .labelsHidden()
                                Group {
                                    Text("Max keyframe interval duration (secs)")
                                    HStack {
                                        Picker("Max keyframe interval duration (secs)", selection: $screenRecorder.keyframeIntervalSetting) {
                                            Text("Unlimited")
                                                .tag(ScreenRecorder.KeyframeDurationSetting.unlimited)
                                                .frame(width: 60)
                                            Text("Custom")
                                                .tag(ScreenRecorder.KeyframeDurationSetting.custom)
                                                .frame(width: 50)
                                        }
                                        .pickerStyle(.radioGroup)
                                        .horizontalRadioGroupLayout()
                                        .padding(EdgeInsets(top: 0, leading: 0, bottom: 4, trailing: 0))
                                        TextField("Value", value: $screenRecorder.maxKeyframeIntervalDuration, format: .number)
                                            .disabled(screenRecorder.keyframeIntervalSetting != .custom)
                                    }
                                    
                                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 4, trailing: 0))
                                }
                                .labelsHidden()
                                Group {
                                    Toggle("Allow frame reordering (B frames)", isOn: $screenRecorder.bFramesSetting)
                                        .padding(EdgeInsets(top: 0, leading: 0, bottom: 4, trailing: 0))
                                }
                            }
                            .tabItem { Label("Keyframes", systemImage: "house") }
                            
                            
                        }
                        Toggle("Allow broken combinations", isOn: $screenRecorder.enableBroken)
                        
                        
                        Spacer()
                    }
                    
                    
                }
                .padding()
                
                
                
                
                Spacer()
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
                    .disabled(!screenRecorder.isRunning)
                }
                HStack {
                    Button {
                        Task { await screenRecorder.record() }
                        
                    } label: {
                        Text("Start Recording")
                    }
                    .disabled(screenRecorder.isRecording || !screenRecorder.isRunning)
                    Button {
                        Task { await screenRecorder.stopRecord() }
                        
                    } label: {
                        Text("Stop Recording")
                    }
                    .disabled(!screenRecorder.isRecording || !screenRecorder.isRunning)
                }
                .frame(maxWidth: .infinity, minHeight: 60)
            }
        }
        .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 6))
        .background(MaterialView())
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
            .alignmentGuide(.leading) { _ in alignmentOffset }
    }
}
