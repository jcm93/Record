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
                    
                    // Add some space between the Video and Audio sections.
                    Spacer()
                        .frame(height: 20)
                    
                    HeaderView("Audio")
                    
                    Toggle("Capture audio", isOn: $screenRecorder.isAudioCaptureEnabled)
                    Toggle("Exclude app audio", isOn: $screenRecorder.isAppAudioExcluded)
                        .disabled(screenRecorder.isAppExcluded)
                    AudioLevelsView(audioLevelsProvider: screenRecorder.audioLevelsProvider)
                    Button {
                        if !audioPlayer.isPlaying {
                            audioPlayer.play()
                        } else {
                            audioPlayer.stop()
                        }
                    } label: {
                        Text("\(!audioPlayer.isPlaying ? "Play" : "Stop") App Audio")
                    }
                    .disabled(screenRecorder.isAppExcluded)
                    Spacer()
                        .frame(height: 20)
                    HeaderView("Encoder")
                        .padding(EdgeInsets(top: 0, leading: 0, bottom: 1, trailing: 0))
                    
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
                                .tag(ScreenRecorder.RateControlSetting.cbr)
                            Text("ABR")
                                .tag(ScreenRecorder.RateControlSetting.abr)
                            Text("CRF")
                                .tag(ScreenRecorder.RateControlSetting.crf)
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
                        .labelsHidden()
                    }
                    
                    Group {
                        Text("Pixel Format")
                        Picker("Pixel Format", selection: $screenRecorder.pixelFormat) {
                            Text("BGRA")
                                .tag(ScreenRecorder.PixelFormat.bgra)
                            Text("v420")
                                .tag(ScreenRecorder.PixelFormat.v420)
                        }
                        .padding(EdgeInsets(top: 0, leading: 0, bottom: 4, trailing: 0))
                    }
                    .labelsHidden()
                    Group {
                        Text("Color Primaries")
                        Picker("Color Primaries", selection: $screenRecorder.colorPrimaries) {
                            Text("P3 D65")
                                .tag(ScreenRecorder.ColorPrimaries.P3_D65)
                            Text("DCI P3")
                                .tag(ScreenRecorder.ColorPrimaries.DCI_P3)
                        }
                        .padding(EdgeInsets(top: 0, leading: 0, bottom: 4, trailing: 0))
                    }
                    .labelsHidden()
                    Group {
                        Text("YCbCr Matrix")
                        Picker("YCbCr Matrix", selection: $screenRecorder.yCbCrMatrix) {
                            Text("ITU_R_2020")
                                .tag(ScreenRecorder.YCbCrMatrix.ITU_R_2020)
                            Text("ITU_R_709_2")
                                .tag(ScreenRecorder.YCbCrMatrix.ITU_R_709_2)
                        }
                        .padding(EdgeInsets(top: 0, leading: 0, bottom: 4, trailing: 0))
                    }
                    .labelsHidden()
                    Group {
                        Text("Transfer Function")
                        Picker("Transfer Function", selection: $screenRecorder.transferFunction) {
                            Text("Untagged")
                                .tag(ScreenRecorder.TransferFunction.untagged)
                        }
                        .padding(EdgeInsets(top: 0, leading: 0, bottom: 4, trailing: 0))
                    }
                    .labelsHidden()
                    
                    
                    
                    
                    
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
        .background(MaterialView())
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
