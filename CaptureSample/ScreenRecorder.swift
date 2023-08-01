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

public enum RateControlSetting: Int, Codable, CaseIterable {
    case cbr
    case abr
    case crf
}

public enum CaptureColorSpace: Int, Codable, CaseIterable {
    case displayp3
    case displayp3hlg
    case displayp3pq
    case extendedlineardisplayp3
    case srgb
    case linearsrgb
    case extendedlinearsrgb
    case genericgraygamma22
    case lineargray
    case extendedgray
    case extendedlineargray
    case genericrgblinear
    case cmyk
    case xyz
    case genericlab
    case acescg
    case adobergb98
    case dcip3
    case itur709
    case rommrgb
    case itur2020
    case itur2020hlg
    case itur2020pq
    case extendedlinearitur2020
    
    func cfString() -> CFString {
        switch self {
        case .displayp3:
            return CGColorSpace.displayP3
        case .displayp3hlg:
            return CGColorSpace.displayP3_HLG
        case .displayp3pq:
            return CGColorSpace.displayP3_PQ
        case .extendedlineardisplayp3:
            return CGColorSpace.extendedLinearDisplayP3
        case .srgb:
            return CGColorSpace.sRGB
        case .linearsrgb:
            return CGColorSpace.linearSRGB
        case .extendedlinearsrgb:
            return CGColorSpace.extendedLinearSRGB
        case .genericgraygamma22:
            return CGColorSpace.genericGrayGamma2_2
        case .lineargray:
            return CGColorSpace.linearGray
        case .extendedgray:
            return CGColorSpace.extendedGray
        case .extendedlineargray:
            return CGColorSpace.extendedLinearGray
        case .genericrgblinear:
            return CGColorSpace.genericRGBLinear
        case .cmyk:
            return CGColorSpace.genericCMYK
        case .xyz:
            return CGColorSpace.genericXYZ
        case .genericlab:
            return CGColorSpace.genericLab
        case .acescg:
            return CGColorSpace.acescgLinear
        case .adobergb98:
            return CGColorSpace.adobeRGB1998
        case .dcip3:
            return CGColorSpace.dcip3
        case .itur709:
            return CGColorSpace.itur_709
        case .rommrgb:
            return CGColorSpace.rommrgb
        case .itur2020:
            return CGColorSpace.itur_2020
        case .itur2020hlg:
            return CGColorSpace.itur_2020_HLG
        case .itur2020pq:
            return CGColorSpace.itur_2020_PQ
        case .extendedlinearitur2020:
            return CGColorSpace.extendedLinearITUR_2020
        }
    }
    
}

@MainActor
class ScreenRecorder: ObservableObject {
    
    /// The supported capture types.
    enum CaptureType: Int, Codable, CaseIterable {
        case display
        case window
    }
    
    enum EncoderSetting: Int, Codable, CaseIterable {
        case H264
        case H265
    }
    
    enum ContainerSetting: Int, Codable, CaseIterable {
        case mov
        case mp4
    }
    
    enum YCbCrMatrixSetting: Int, Codable, CaseIterable {
        case ITU_R_2020
        case ITU_R_709_2
        case ITU_R_601_2
        case SMPTE_240M_1995
        case untagged
        func stringValue() -> CFString? {
            switch self {
            case .ITU_R_2020:
                return kCVImageBufferYCbCrMatrix_ITU_R_2020
            case .ITU_R_709_2:
                return kCVImageBufferYCbCrMatrix_ITU_R_709_2
            case .untagged:
                return nil
            case .ITU_R_601_2:
                return kCVImageBufferYCbCrMatrix_ITU_R_601_4
            case .SMPTE_240M_1995:
                return kCVImageBufferYCbCrMatrix_SMPTE_240M_1995
            }
        }
    }
    
    enum ColorPrimariesSetting: Int, Codable, CaseIterable {
        case P3_D65
        case DCI_P3
        case ITU_R_709_2
        case EBU_3213
        case SMPTE_C
        case ITU_R_2020
        case P22
        case untagged
        func stringValue() -> CFString? {
            switch self {
            case .DCI_P3:
                return kCVImageBufferColorPrimaries_DCI_P3
            case .P3_D65:
                return kCVImageBufferColorPrimaries_P3_D65
            case .untagged:
                return nil
            case .ITU_R_709_2:
                return kCVImageBufferColorPrimaries_ITU_R_709_2
            case .EBU_3213:
                return kCVImageBufferColorPrimaries_EBU_3213
            case .SMPTE_C:
                return kCVImageBufferColorPrimaries_SMPTE_C
            case .ITU_R_2020:
                return kCVImageBufferColorPrimaries_ITU_R_2020
            case .P22:
                return kCVImageBufferColorPrimaries_P22
            }
        }
    }
    
    enum TransferFunctionSetting: Int, Codable, CaseIterable {
        case ITU_R_709_2
        case SMPTE_240M_1995
        case useGamma
        case sRGB
        case ITU_R_2020
        case SMPTE_ST_428_1
        case ITU_R_2100_HLG
        case SMPTE_ST_2084_PQ
        case untagged
        func stringValue() -> CFString? {
            switch self {
            case .ITU_R_709_2:
                return kCVImageBufferTransferFunction_ITU_R_709_2
            case .SMPTE_240M_1995:
                return kCVImageBufferTransferFunction_SMPTE_240M_1995
            case .useGamma:
                return kCVImageBufferTransferFunction_UseGamma
            case .sRGB:
                return kCVImageBufferTransferFunction_sRGB
            case .ITU_R_2020:
                return kCVImageBufferTransferFunction_ITU_R_2020
            case .SMPTE_ST_428_1:
                return kCVImageBufferTransferFunction_SMPTE_ST_428_1
            case .ITU_R_2100_HLG:
                return kCVImageBufferTransferFunction_ITU_R_2100_HLG
            case .SMPTE_ST_2084_PQ:
                return kCVImageBufferTransferFunction_SMPTE_ST_2084_PQ
            case .untagged:
                return nil
            }
        }
    }
    
    enum KeyframeSetting: Int, Codable, CaseIterable {
        case auto
        case custom
    }
    
    enum KeyframeDurationSetting: Int, Codable, CaseIterable {
        case unlimited
        case custom
    }
    
    enum BitDepthSetting: Int, Codable, CaseIterable {
        case eight
        case ten
    }
    
    enum CapturePixelFormat: Int, Codable, CaseIterable {
        case bgra
        case l10r
        case biplanarpartial420v
        case biplanarfull420f
        func osTypeFormat() -> OSType {
            switch self {
            case .bgra:
                return kCVPixelFormatType_32BGRA
            case .l10r:
                return kCVPixelFormatType_ARGB2101010LEPacked
            case .biplanarpartial420v:
                return kCVPixelFormatType_420YpCbCr10BiPlanarVideoRange
            case .biplanarfull420f:
                return kCVPixelFormatType_420YpCbCr10BiPlanarFullRange
            }
        }
        func stringValue() -> String {
            switch self {
            case .bgra:
                return "BGRA"
            case .l10r:
                return "l10r"
            case .biplanarpartial420v:
                return "420v"
            case .biplanarfull420f:
                return "420f"
            }
        }
    }
    
    enum CaptureYUVMatrix: Int, Codable, CaseIterable {
        case itu_r_709
        case itu_r_601
        case smpte_240m_1995
        func cfStringFormat() -> CFString {
            switch self {
            case .itu_r_709:
                return CGDisplayStream.yCbCrMatrix_ITU_R_709_2
            case .itu_r_601:
                return CGDisplayStream.yCbCrMatrix_ITU_R_601_4
            case .smpte_240m_1995:
                return CGDisplayStream.yCbCrMatrix_SMPTE_240M_1995
            }
        }
        func stringValue() -> String {
            switch self {
            case .itu_r_709:
                return "709"
            case .itu_r_601:
                return "601"
            case .smpte_240m_1995:
                return "SMPTE 240M 1995"
            }
        }
    }
    
    private let logger = Logger()
    
    private var options: Options {
        //self.streamConfiguration.minimumFrameInterval = CMTime(value: 1, timescale: CMTimeScale(self.framesPerSecond))
        if self.usesICCProfile {
            self.iccProfile = NSScreen.main?.colorSpace?.cgColorSpace?.copyICCData()
        }
        let outputExtension = self.containerSetting == .mov ? "mov" : "mp4"
        let fileName = "Record \(Date()).\(outputExtension)"
        let outputURL = self.outputFolder.appending(path: fileName)
        let fileType: AVFileType = self.containerSetting == .mov ? AVFileType.mov : AVFileType.mp4
        let codec = self.encoderSetting == .H264 ? kCMVideoCodecType_H264 : kCMVideoCodecType_HEVC
        let bitrate = self.bitRate
        let width = Int(self.captureWidth)!
        let height = Int(self.captureHeight)!
        let pixelFormat = self.pixelFormatSetting.osTypeFormat()
        let colorPrimaries = self.colorPrimariesSetting.stringValue()
        let transferFunction = self.transferFunctionSetting.stringValue()
        let yuvMatrix = self.yCbCrMatrixSetting.stringValue()
        let bitDepth = self.bitDepth
        let usesICC = self.usesICCProfile
        let iccProfile = self.iccProfile
        let maxKeyFrameIntervalDuration = self.maxKeyframeIntervalDuration
        let maxKeyFrameInterval = self.maxKeyframeInterval
        let rateControl = self.rateControlSetting
        let bFrames = self.bFramesSetting
        let crfValue = self.crfValue as CFNumber
        let gammaValue = self.gammaValue
        let convertsColorSpace = self.pixelTransferEnabled
        let targetColorSpace = self.convertTargetColorSpace.cfString()
        
        let options = Options(destMovieURL: outputURL, destFileType: fileType, destWidth: width, destHeight: height, destBitRate: bitrate, codec: codec, pixelFormat: pixelFormat, maxKeyFrameIntervalDuration: maxKeyFrameIntervalDuration, maxKeyFrameInterval: maxKeyframeInterval, rateControl: rateControl, crfValue: crfValue, verbose: false, iccProfile: iccProfile, bitDepth: bitDepth, colorPrimaries: colorPrimaries, transferFunction: transferFunction, yuvMatrix: yuvMatrix, bFrames: bFrames, gammaValue: gammaValue, convertsColorSpace: convertsColorSpace, targetColorSpace: targetColorSpace, usesICC: usesICC)
        
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
