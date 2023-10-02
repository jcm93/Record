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
    
    private let logger = Logger.capture
    
    //MARK: Presets, options storage
    
    func savePreset(name: String) {
        let options = self.getStoredOptions(name: name)
        var presets = self.presets
        presets.append(options)
        self.savePresets(presets: presets)
        self.selectedPreset = options
    }
    
    func loadPreset(name: String) {
        let presets = self.presets
        if let selectedPreset = presets.filter({ return $0.presetName == name }).first {
            self.setOptionsFromStorable(selectedPreset)
            self.matchesPreset = true
            self.presetName = name
        } else {
            logger.error("Preset \(name) not found.")
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
        self.presetName = storedOptions.presetName
        self.doesScale = storedOptions.scales
        self.matchesPreset = true
        self.usesReplayBuffer = storedOptions.usesReplayBuffer
        self.replayBufferDuration = storedOptions.replayBufferDuration
    }
    
    func getStoredOptions(name: String?) -> OptionsStorable {
        let storableOptions = OptionsStorable(fileType: self.containerSetting, bitrate: self.bitRate, pixelFormat: self.capturePixelFormat, primaries: self.colorPrimariesSetting, transfer: self.transferFunctionSetting, yuv: self.yCbCrMatrixSetting, bitDepth: self.bitDepth, usesICC: self.usesICCProfile, maxKeyFrameDuration: self.maxKeyframeIntervalDuration, maxKeyFrameInterval: self.maxKeyframeInterval, rateControl: self.rateControlSetting, bFrames: self.bFramesSetting, crfValue: self.crfValue, gammaValue: self.gammaValue, convertsColorSpace: self.pixelTransferEnabled, targetColorSpace: self.convertTargetColorSpace, encoderSetting: self.encoderSetting, proResSetting: self.proResSetting, encoderPixelFormat: self.pixelFormatSetting, presetName: name ?? "", scales: self.doesScale, usesReplayBuffer: self.usesReplayBuffer, replayBufferDuration: self.replayBufferDuration)
        return storableOptions
    }
    
    @Published var dummy: String = ""
    
    var options: Options {
        if self.usesICCProfile {
            self.iccProfile = NSScreen.main?.colorSpace?.cgColorSpace?.copyICCData()
        }
        
        let storableOptions = self.getStoredOptions(name: "")
        let options = self.optionsFromPreset(storableOptions: storableOptions)
        return options
    }
    
    var presets: [OptionsStorable] {
        if let data = UserDefaults.standard.data(forKey: "presets") {
            do {
                let decoder = JSONDecoder()
                let options = try decoder.decode([OptionsStorable].self, from: data)
                return options
            } catch {
                logger.error("Error decoding stored presets; re-initalizing")
                return [OptionsStorable]()
            }
        } else {
            return [OptionsStorable]()
        }
    }
    
    func savePresets(presets: [OptionsStorable]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(presets)
            UserDefaults.standard.setValue(data, forKey: "presets")
        } catch {
            logger.error("Error saving presets. No presets will be saved.")
        }
    }
    
    func deletePreset(presetName: String) {
        var currentOptions = self.presets
        currentOptions.removeAll(where: {$0.presetName == presetName})
        self.savePresets(presets: currentOptions)
    }
    
    func optionsFromPreset(storableOptions: OptionsStorable) -> Options {
        let outputURL = self.outputFolder
        let fileType = storableOptions.fileType == .mov ? AVFileType.mov : AVFileType.mp4
        let width = self.doesScale ? self.scaleWidth : self.captureWidth
        let height = self.doesScale ? self.scaleHeight : self.captureHeight
        let codec = getCodecType(storableOptions)
        let options = Options(outputFolder: outputURL, destFileType: fileType, destWidth: width, destHeight: height, destBitRate: storableOptions.bitrate, codec: codec, pixelFormat: storableOptions.encoderPixelFormat.osTypeFormat(), maxKeyFrameIntervalDuration: storableOptions.maxKeyFrameDuration, maxKeyFrameInterval: storableOptions.maxKeyFrameInterval, rateControl: storableOptions.rateControl, crfValue: storableOptions.crfValue as CFNumber, verbose: false, iccProfile: self.iccProfile, bitDepth: storableOptions.bitDepth, colorPrimaries: storableOptions.primaries.stringValue(), transferFunction: storableOptions.transfer.stringValue(), yuvMatrix: storableOptions.yuv.stringValue(), bFrames: storableOptions.bFrames, gammaValue: storableOptions.gammaValue, convertsColorSpace: storableOptions.convertsColorSpace, targetColorSpace: storableOptions.targetColorSpace.cfString(), usesICC: storableOptions.usesICC, scales: storableOptions.scales, usesReplayBuffer: storableOptions.usesReplayBuffer, replayBufferDuration: storableOptions.replayBufferDuration)
        return options
    }
    
    //MARK: Observed variables
    
    @Published var isRunning = false
    @Published var isRecording = false
    
    @Published var captureWidth: Int = 0
    @Published var captureHeight: Int = 0
    
    @AppStorage("scaleWidth") var scaleWidth: Int = 0
    @AppStorage("scaleHeight") var scaleHeight: Int = 0
    
    @AppStorage("doesScale") var doesScale: Bool = false
    
    @Published var matchesPreset = false
    @Published var presetName = ""
    @Published var selectedPreset: OptionsStorable? {
        willSet {
            if newValue != nil {
                setOptionsFromStorable(newValue!)
            }
        }
    }
    
    @Published var errorText = ""
    @Published var isShowingError = false
    
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
    
    @AppStorage("usesTargetFPS") var usesTargetFPS = false {
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
    
    @AppStorage("outputFolder") var outputFolder: URL = Bundle.main.resourceURL!
    
    @AppStorage("filePath") var filePath: String = ""
    
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
    
    @AppStorage("usesReplayBuffer") var usesReplayBuffer: Bool = false {
        didSet { updateEngine() }
    }
    
    @AppStorage("replayBufferDuration") var replayBufferDuration: Int = 30 {
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
            /*if isAudioCaptureEnabled {
                startAudioMetering()
            } else {
                stopAudioMetering()
            }*/
        }
    }
    @Published var isAppAudioExcluded = false { didSet { updateEngine() } }
    
    //MARK: Capture functions
    
    // The object that manages the SCStream.
    private let captureEngine = CaptureEngine()
    
    private var isSetup = false
    private var iccProfile: CFData?
    
    // Combine subscribers.
    private var subscriptions = Set<AnyCancellable>()
    
    func dimensionsChanged(width: Int, height: Int) {
        //this is a pretty silly function
        if width == 0 && height == 0 {
            return
        }
        let aspectRatio = Double(self.captureWidth) / Double(self.captureHeight)
        if height > 0 {
            let prospectiveWidth = aspectRatio * Double(height)
            //ignore changes within 10 pixels for fine tuning
            if abs(Double(scaleWidth) - prospectiveWidth) > 10 {
                //force even numbers
                self.scaleWidth = Int(round(prospectiveWidth / 2.0)) * 2
            }
        } else {
            let prospectiveHeight = Double(width) / aspectRatio
            if abs(Double(scaleHeight) - prospectiveHeight) > 10 {
                self.scaleHeight = Int(round(prospectiveHeight / 2.0)) * 2
            }
        }
        //this should be rewritten someday
    }
    
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
            //startAudioMetering()
        }
        
        do {
            let config = streamConfiguration
            let filter = contentFilter
            // Update the running state.
            isRunning = true
            updateEngine()
            // Start the stream and await new video frames.
            for try await frame in captureEngine.startCapture(configuration: config, filter: filter) {
                self.capturePreview.updateFrame(frame)
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
        //stopAudioMetering()
        isRunning = false
    }
    
    func record() async {
        guard isRunning else { return }
        guard !isRecording else { return }
        guard self.filePath != "" else {
            self.isRecording = false
            self.errorText = "No output folder selected."
            //todo add an alert
            self.isShowingError = true
            return
        }
        logger.notice("\(self.options.description, privacy: .public)")
        do {
            try await captureEngine.startRecording(options: self.options)
            self.isRecording = true
        } catch {
            self.isRecording = false
            self.errorText = error.localizedDescription
            self.isShowingError = true
        }
    }
    
    func stopRecord() async {
        do {
            guard isRecording else { return }
            try await captureEngine.stopRecording()
            self.isRecording = false
        } catch {
            self.errorText = "Error while stopping recording. \(error)"
            self.isShowingError = true
            logger.critical("Error while stopping recording. \(error, privacy: .public)")
            self.isRecording = false
        }
    }
    
    func saveReplayBuffer() {
        do {
            guard isRecording else { return }
            try captureEngine.saveReplayBuffer()
        } catch {
            self.errorText = "Error while stopping recording. \(error)"
            self.isShowingError = true
            logger.critical("Error while stopping recording. \(error, privacy: .public)")
            self.isRecording = false
        }
    }
    
    /*private func startAudioMetering() {
        audioMeterCancellable = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            guard let self = self else { return }
            self.audioLevelsProvider.audioLevels = self.captureEngine.audioLevels
        }
    }*/
    
    /*private func stopAudioMetering() {
        audioMeterCancellable?.cancel()
        audioLevelsProvider.audioLevels = AudioLevels.zero
    }*/
    
    /// - Tag: UpdateCaptureConfig
    private func updateEngine() {
        guard isRunning else { return }
        Task {
            await captureEngine.update(configuration: streamConfiguration, filter: contentFilter)
        }
        self.selectedPreset = nil
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
            streamConfig.width = Int(window.frame.width) * scaleFactor
            streamConfig.height = Int(window.frame.height) * scaleFactor
        }
        
        self.captureWidth = streamConfig.width
        self.captureHeight = streamConfig.height
        //self.aspectRatio = Double(streamConfig.width) / Double(streamConfig.height)
        
        if (self.usesTargetFPS) {
            streamConfig.minimumFrameInterval = CMTime(value: 1, timescale: CMTimeScale(self.framesPerSecond + 1))
        } else {
            streamConfig.minimumFrameInterval = CMTime(value: 1, timescale: CMTimeScale(0))
        }
        self.assignPixelFormatAndColorMatrix(streamConfig)
        
        // Increase the depth of the frame queue to ensure high fps at the expense of increasing
        // the memory footprint of WindowServer.
        streamConfig.queueDepth = 5
        
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
    func refreshAvailableContent() async {
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
