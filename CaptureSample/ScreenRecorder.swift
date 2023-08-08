/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A model object that provides the interface to capture screen content and system audio.
*/

import Foundation
import ScreenCaptureKit
import Combine
import OSLog
import SwiftUI
import AVFoundation

/// A provider of audio levels from the captured samples.
class AudioLevelsProvider: ObservableObject {
    @Published var audioLevels = AudioLevels.zero
}

@MainActor
class ScreenRecorder: ObservableObject {
    
    /// The supported capture types.
    
    func getCodecType(_ storableOptions: OptionsStorable) -> CMVideoCodecType {
        switch storableOptions.encoderSetting {
        case .H264:
            return kCMVideoCodecType_H264
        case .H265:
            return kCMVideoCodecType_HEVC
        case .ProRes:
            return storableOptions.proResSetting.codecValue()
        }
    }
    
    private let logger = Logger()
    
    func savePreset() {
        let options = self.getStoredOptions()
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(options)
            UserDefaults.standard.setValue(data, forKey: "testPreset")
        } catch {
            print(error)
        }
    }
    
    func loadPreset() {
        do {
            let data = UserDefaults.standard.value(forKey: "testPreset") as! Data
            let decoder = JSONDecoder()
            let storable = try decoder.decode(OptionsStorable.self, from: data)
            self.setOptionsFromStorable(storable)
        } catch {
            print(error)
        }
    }
    
    func setOptionsFromStorable(_ storedOptions: OptionsStorable) {
        self.containerSetting = storedOptions.fileType
        self.bitRate = storedOptions.bitrate
        self.capturePixelFormat = storedOptions.pixelFormat
        self.colorPrimariesSetting = storedOptions.primaries
        self.transferFunctionSetting = storedOptions.transfer
        self.yCbCrMatrixSetting = storedOptions.yuv
        self.bitDepth = storedOptions.bitDepth
        self.usesICCProfile = storedOptions.usesICC
        self.maxKeyframeIntervalDuration = storedOptions.maxKeyFrameDuration
        self.maxKeyframeInterval = storedOptions.maxKeyFrameInterval
        self.rateControlSetting = storedOptions.rateControl
        self.bFramesSetting = storedOptions.bFrames
        self.crfValue =  storedOptions.crfValue
        self.gammaValue = storedOptions.gammaValue
        self.pixelTransferEnabled = storedOptions.convertsColorSpace
        self.convertTargetColorSpace = storedOptions.targetColorSpace
        self.encoderSetting = storedOptions.encoderSetting
        self.proResSetting = storedOptions.proResSetting
        self.pixelFormatSetting = storedOptions.encoderPixelFormat
    }
    
    func getStoredOptions() -> OptionsStorable {
        let storableOptions = OptionsStorable(fileType: self.containerSetting, bitrate: self.bitRate, pixelFormat: self.capturePixelFormat, primaries: self.colorPrimariesSetting, transfer: self.transferFunctionSetting, yuv: self.yCbCrMatrixSetting, bitDepth: self.bitDepth, usesICC: self.usesICCProfile, maxKeyFrameDuration: self.maxKeyframeIntervalDuration, maxKeyFrameInterval: self.maxKeyframeInterval, rateControl: self.rateControlSetting, bFrames: self.bFramesSetting, crfValue: self.crfValue, gammaValue: self.gammaValue, convertsColorSpace: self.pixelTransferEnabled, targetColorSpace: self.convertTargetColorSpace, encoderSetting: self.encoderSetting, proResSetting: self.proResSetting, encoderPixelFormat: self.pixelFormatSetting)
        return storableOptions
    }
    
    var options: Options {
        //self.streamConfiguration.minimumFrameInterval = CMTime(value: 1, timescale: CMTimeScale(self.framesPerSecond))
        if self.usesICCProfile {
            self.iccProfile = NSScreen.main?.colorSpace?.cgColorSpace?.copyICCData()
        }
        
        let storableOptions = self.getStoredOptions()
        
        let options = self.optionsFromPreset(storableOptions: storableOptions)
        
        return options
    }
    
    func optionsFromPreset(storableOptions: OptionsStorable) -> Options {
        let outputExtension = storableOptions.fileType == .mov ? "mov" : "mp4"
        let fileName = "Record \(Date()).\(outputExtension)"
        let outputURL = self.outputFolder.appending(path: fileName)
        let fileType = storableOptions.fileType == .mov ? AVFileType.mov : AVFileType.mp4
        let width = Int(self.captureWidth)!
        let height = Int(self.captureHeight)!
        let codec = self.getCodecType(storableOptions)
        let options = Options(destMovieURL: outputURL, destFileType: fileType, destWidth: width, destHeight: height, destBitRate: storableOptions.bitrate, codec: self.getCodecType(storableOptions), pixelFormat: storableOptions.encoderPixelFormat.osTypeFormat(), maxKeyFrameIntervalDuration: storableOptions.maxKeyFrameDuration, maxKeyFrameInterval: storableOptions.maxKeyFrameInterval, rateControl: storableOptions.rateControl, crfValue: storableOptions.crfValue as CFNumber, verbose: false, iccProfile: self.iccProfile, bitDepth: storableOptions.bitDepth, colorPrimaries: storableOptions.primaries.stringValue(), transferFunction: storableOptions.transfer.stringValue(), yuvMatrix: storableOptions.yuv.stringValue(), bFrames: storableOptions.bFrames, gammaValue: storableOptions.gammaValue, convertsColorSpace: storableOptions.convertsColorSpace, targetColorSpace: storableOptions.targetColorSpace.cfString(), usesICC: storableOptions.usesICC)
        return options
    }
    
    @Published var isRunning = false
    @Published var isRecording = false
    
    @Published var captureWidth: String = ""
    @Published var captureHeight: String = ""
    
    @AppStorage("bitRate") var bitRate: Int = 10000 {
        didSet { updateEngine() }
    }
    
    @AppStorage("crfValue") var crfValue: Double = 0.70 {
        didSet { updateEngine() }
    }
    
    @AppStorage("enableBroken") var enableBroken: Bool = false
    
    @AppStorage("usesICC") var usesICCProfile: Bool = false {
        didSet { updateEngine() }
    }
    
    @AppStorage("containerSetting") var containerSetting: ContainerSetting = .mp4 {
        didSet { updateEngine() }
    }
    
    // MARK: - Video Properties
    @Published var captureType: CaptureType = .display {
        didSet { updateEngine() }
    }
    
    @Published var selectedDisplay: SCDisplay? {
        didSet { updateEngine() }
    }
    
    @Published var selectedWindow: SCWindow? {
        didSet { updateEngine() }
    }
    
    @AppStorage("excludeSelf") var isAppExcluded = true {
        didSet { updateEngine() }
    }
    
    @AppStorage("capturePixelFormat") var capturePixelFormat: CapturePixelFormat = .bgra {
        didSet { updateEngine() }
    }
    
    @AppStorage("captureYUVMatrix") var captureYUVMatrix: CaptureYUVMatrix = .itu_r_709 {
        didSet { updateEngine() }
    }
    
    @AppStorage("captureColorSpace") var captureColorSpace: CaptureColorSpace = .displayp3 {
        didSet { updateEngine() }
    }
    
    @AppStorage("pixelTransferEnabled") var pixelTransferEnabled: Bool = false {
        didSet { updateEngine() }
    }
    
    @AppStorage("convertTargetColorSpace") var convertTargetColorSpace: CaptureColorSpace = .displayp3 {
        didSet { updateEngine() }
    }
    
    @AppStorage("encoderSetting") var encoderSetting: EncoderSetting = .H265 {
        didSet { updateEngine() }
    }
    
    @AppStorage("rateControlSetting") var rateControlSetting: RateControlSetting = .crf {
        didSet { updateEngine() }
    }
    
    @AppStorage("pixelFormatSetting") var pixelFormatSetting: CapturePixelFormat = .bgra {
        didSet { updateEngine() }
    }
    
    @AppStorage("yuvMatrix") var yCbCrMatrixSetting: YCbCrMatrixSetting = .ITU_R_2020 {
        didSet { updateEngine() }
    }
    
    @AppStorage("colorPrimaries") var colorPrimariesSetting: ColorPrimariesSetting = .P3_D65 {
        didSet { updateEngine() }
    }
    
    @AppStorage("transferFunction") var transferFunctionSetting: TransferFunctionSetting = .untagged {
        didSet { updateEngine() }
    }
    
    @AppStorage("keyframeSetting") var keyframeSetting: KeyframeSetting = .auto {
        didSet { updateEngine() }
    }
    
    @AppStorage("keyframeIntervalSetting") var keyframeIntervalSetting: KeyframeDurationSetting = .unlimited {
        didSet { updateEngine() }
    }
    
    @AppStorage("bFrames") var bFramesSetting = false {
        didSet { updateEngine() }
    }
    
    @AppStorage("bitDepthSetting") var bitDepthSetting: BitDepthSetting = .ten {
        didSet { updateEngine() }
    }
    
    @AppStorage("proResSetting") var proResSetting: ProResSetting = .ProRes422 {
        didSet { updateEngine() }
    }
    
    @AppStorage("outputFolder") var outputFolder: URL = Bundle.main.resourceURL! {
        didSet { updateEngine() }
    }
    @AppStorage("filePath") var filePath: String = "" {
        didSet { updateEngine() }
    }
    @AppStorage("bitDepth") var bitDepth: Int = 10 {
        didSet { updateEngine() }
    }
    
    @AppStorage("maxKeyframeInterval") var maxKeyframeInterval: Int = 120 {
        didSet { updateEngine() }
    }
    @AppStorage("maxKeyframeIntervalDuration") var maxKeyframeIntervalDuration: Double = 10.5 {
        didSet { updateEngine() }
    }
    
    @AppStorage("framesPerSecond") var framesPerSecond: Double = 60.0 {
        didSet { updateEngine() }
    }
    
    @AppStorage("gammaValue") var gammaValue: Double = 1.1 {
        didSet { updateEngine() }
    }
    
    @Published var contentSize = CGSize(width: 1, height: 1)
    private var scaleFactor: Int { Int(NSScreen.main?.backingScaleFactor ?? 2) }
    
    /// A view that renders the screen content.
    lazy var capturePreview: CapturePreview = {
        CapturePreview()
    }()
    
    private var availableApps = [SCRunningApplication]()
    @Published private(set) var availableDisplays = [SCDisplay]()
    @Published private(set) var availableWindows = [SCWindow]()
    
    // MARK: - Audio Properties
    @Published var isAudioCaptureEnabled = true {
        didSet {
            updateEngine()
            if isAudioCaptureEnabled {
                startAudioMetering()
            } else {
                stopAudioMetering()
            }
        }
    }
    @Published var isAppAudioExcluded = false { didSet { updateEngine() } }
    @Published private(set) var audioLevelsProvider = AudioLevelsProvider()
    // A value that specifies how often to retrieve calculated audio levels.
    private let audioLevelRefreshRate: TimeInterval = 0.1
    private var audioMeterCancellable: AnyCancellable?
    
    // The object that manages the SCStream.
    private let captureEngine = CaptureEngine()
    
    private var isSetup = false
    private var iccProfile: CFData?
    
    // Combine subscribers.
    private var subscriptions = Set<AnyCancellable>()
    
    var canRecord: Bool {
        get async {
            do {
                // If the app doesn't have Screen Recording permission, this call generates an exception.
                try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
                return true
            } catch {
                return false
            }
        }
    }
    
    func monitorAvailableContent() async {
        guard !isSetup else { return }
        // Refresh the lists of capturable content.
        await self.refreshAvailableContent()
        Timer.publish(every: 3, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            guard let self = self else { return }
            Task {
                await self.refreshAvailableContent()
            }
        }
        .store(in: &subscriptions)
    }
    
    /// Starts capturing screen content.
    func start() async {
        // Exit early if already running.
        guard !isRunning else { return }
        
        if !isSetup {
            // Starting polling for available screen content.
            await monitorAvailableContent()
            isSetup = true
        }
        
        // If the user enables audio capture, start monitoring the audio stream.
        if isAudioCaptureEnabled {
            startAudioMetering()
        }
        
        do {
            let config = streamConfiguration
            let filter = contentFilter
            // Update the running state.
            isRunning = true
            updateEngine()
            // Start the stream and await new video frames.
            for try await frame in captureEngine.startCapture(configuration: config, filter: filter) {
                capturePreview.updateFrame(frame)
                if contentSize != frame.size {
                    // Update the content size if it changed.
                    contentSize = frame.size
                }
            }
        } catch {
            logger.error("\(error.localizedDescription)")
            // Unable to start the stream. Set the running state to false.
            isRunning = false
        }
    }
    
    /// Stops capturing screen content.
    func stop() async {
        guard isRunning else { return }
        await captureEngine.stopCapture()
        stopAudioMetering()
        isRunning = false
    }
    
    func record() async {
        guard isRunning else { return }
        guard !isRecording else { return }
        await captureEngine.startRecording(options: self.options)
        self.isRecording = true
    }
    
    func stopRecord() async {
        guard isRecording else { return }
        await captureEngine.stopRecording()
        self.isRecording = false
        
    }
    
    private func startAudioMetering() {
        audioMeterCancellable = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            guard let self = self else { return }
            self.audioLevelsProvider.audioLevels = self.captureEngine.audioLevels
        }
    }
    
    private func stopAudioMetering() {
        audioMeterCancellable?.cancel()
        audioLevelsProvider.audioLevels = AudioLevels.zero
    }
    
    /// - Tag: UpdateCaptureConfig
    private func updateEngine() {
        guard isRunning else { return }
        Task {
            await captureEngine.update(configuration: streamConfiguration, filter: contentFilter)
        }
    }
    
    /// - Tag: UpdateFilter
    private var contentFilter: SCContentFilter {
        let filter: SCContentFilter
        switch captureType {
        case .display:
            guard let display = selectedDisplay else { fatalError("No display selected.") }
            var excludedApps = [SCRunningApplication]()
            // If a user chooses to exclude the app from the stream,
            // exclude it by matching its bundle identifier.
            if isAppExcluded {
                excludedApps = availableApps.filter { app in
                    Bundle.main.bundleIdentifier == app.bundleIdentifier
                }
            }
            // Create a content filter with excluded apps.
            filter = SCContentFilter(display: display,
                                     excludingApplications: excludedApps,
                                     exceptingWindows: [])
        case .window:
            guard let window = selectedWindow else { fatalError("No window selected.") }
            
            // Create a content filter that includes a single window.
            filter = SCContentFilter(desktopIndependentWindow: window)
        }
        return filter
    }
    
    private var streamConfiguration: SCStreamConfiguration {
        
        let streamConfig = SCStreamConfiguration()
        
        // Configure audio capture.
        streamConfig.capturesAudio = isAudioCaptureEnabled
        streamConfig.excludesCurrentProcessAudio = isAppAudioExcluded
        
        // Configure the display content width and height.
        if captureType == .display, let display = selectedDisplay {
            streamConfig.width = display.width * scaleFactor
            streamConfig.height = display.height * scaleFactor
        }
        
        // Configure the window content width and height.
        if captureType == .window, let window = selectedWindow {
            streamConfig.width = Int(window.frame.width) * 2
            streamConfig.height = Int(window.frame.height) * 2
        }
        
        self.captureWidth = "\(streamConfig.width)"
        self.captureHeight = "\(streamConfig.height)"
        
        // Set the capture interval at 60 fps.
        streamConfig.minimumFrameInterval = CMTime(value: 1, timescale: CMTimeScale(self.framesPerSecond))
        self.assignPixelFormatAndColorMatrix(streamConfig)
        
        // Increase the depth of the frame queue to ensure high fps at the expense of increasing
        // the memory footprint of WindowServer.
        streamConfig.queueDepth = 20
        
        return streamConfig
    }
    
    func assignPixelFormatAndColorMatrix(_ config: SCStreamConfiguration) {
        config.pixelFormat = self.capturePixelFormat.osTypeFormat()
        if self.bitDepthSetting == .eight {
            if config.pixelFormat == kCVPixelFormatType_420YpCbCr10BiPlanarFullRange {
                config.pixelFormat = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
            } else if config.pixelFormat == kCVPixelFormatType_420YpCbCr10BiPlanarVideoRange {
                config.pixelFormat = kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
            }
        }
        if (self.capturePixelFormat == .biplanarpartial420v || self.capturePixelFormat == .biplanarpartial420v) {
            config.colorMatrix = self.captureYUVMatrix.cfStringFormat()
        }
        config.colorSpaceName = self.captureColorSpace.cfString()
    }
    
    /// - Tag: GetAvailableContent
    private func refreshAvailableContent() async {
        do {
            // Retrieve the available screen content to capture.
            let availableContent = try await SCShareableContent.excludingDesktopWindows(false,
                                                                                        onScreenWindowsOnly: true)
            availableDisplays = availableContent.displays
            
            let windows = filterWindows(availableContent.windows)
            if windows != availableWindows {
                availableWindows = windows
            }
            availableApps = availableContent.applications
            
            if selectedDisplay == nil {
                selectedDisplay = availableDisplays.first
            }
            if selectedWindow == nil {
                selectedWindow = availableWindows.first
            }
        } catch {
            logger.error("Failed to get the shareable content: \(error.localizedDescription)")
        }
    }
    
    private func filterWindows(_ windows: [SCWindow]) -> [SCWindow] {
        windows
        // Sort the windows by app name.
            .sorted { $0.owningApplication?.applicationName ?? "" < $1.owningApplication?.applicationName ?? "" }
        // Remove windows that don't have an associated .app bundle.
            .filter { $0.owningApplication != nil && $0.owningApplication?.applicationName != "" }
        // Remove this app's window from the list.
            .filter { $0.owningApplication?.bundleIdentifier != Bundle.main.bundleIdentifier }
    }
}

extension SCWindow {
    var displayName: String {
        switch (owningApplication, title) {
        case (.some(let application), .some(let title)):
            return "\(application.applicationName): \(title)"
        case (.none, .some(let title)):
            return title
        case (.some(let application), .none):
            return "\(application.applicationName): \(windowID)"
        default:
            return ""
        }
    }
}

extension SCDisplay {
    var displayName: String {
        "Display: \(width) x \(height)"
    }
}
