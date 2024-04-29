/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The entry point into this app.
*/
import SwiftUI
import OSLog
import SystemExtensions

let startupTime = Date()

@main
struct CaptureSampleApp: App {
    @State private var isShowingAlert = false
    @State private var isShowingDeleteAlert = false
    @State private var isShowingErrorAlert = false
    
    @State private var presetName: String = ""
    
    @State private var isExporting = false
    
    @State var selectedPreset: OptionsStorable!
    
    var logger = Logger.application
  
    var extensionActivated = false
    
    @StateObject var screenRecorder = ScreenRecorder()
  
    var requestDelegate = CameraExtensionRequestDelegate()
    
    @State private var currentLog: TextDocument?
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(screenRecorder)
                .frame(minWidth: 1440, minHeight: 900)
                .background(.black)
                .alert("Enter Name", isPresented: $isShowingAlert, actions: {
                    TextField("Preset Name", text: $presetName)
                    Button("Confirm") {
                        self.screenRecorder.savePreset(name: presetName)
                    }
                    Button("Cancel", role: .cancel) {
                        self.isShowingAlert = false
                    }
                }, message: {
                    Text("Enter a name for your preset.")
                })
                .alert("Delete Preset", isPresented: $isShowingDeleteAlert, actions: {
                    Button("Confirm") {
                        self.screenRecorder.deletePreset(presetName: self.screenRecorder.selectedPreset!.presetName)
                    }
                    Button("Cancel", role: .cancel) {
                        self.isShowingDeleteAlert = false
                    }
                }, message: {
                    Text("Are you sure you want to remove the preset \"\(self.screenRecorder.selectedPreset?.presetName ?? "")\"?")
                })
                .alert("Error", isPresented: $screenRecorder.isShowingError, actions: {
                    Button("OK") {
                        self.screenRecorder.isShowingError = false
                    }
                }, message: {
                    Text("\(self.screenRecorder.errorText)")
                })
                .fileExporter(isPresented: $isExporting, document: self.currentLog, contentType: .plainText, defaultFilename: "Record.log", onCompletion: {
                    result in
                    switch result {
                    case .success:
                        logger.notice("Successfully output log to file")
                    case .failure:
                        logger.notice("Did not output log to file")
                    }
                })
        }
        .commands {
            CommandMenu("Preset") {
                Picker("Presets", selection: $screenRecorder.selectedPreset) {
                    ForEach(self.screenRecorder.presets, id: \.self) { preset in
                        Text(preset.presetName)
                            .tag(OptionsStorable?.some(preset))
                    }
                    if self.screenRecorder.selectedPreset == nil {
                        Text("Unsaved")
                            .tag(nil as OptionsStorable?)
                    }
                }
                .pickerStyle(.inline)
                Divider()
                Button("Save Preset") {
                    isShowingAlert.toggle()
                }
                if (self.screenRecorder.selectedPreset != nil) {
                    Button("Delete Preset") {
                        isShowingDeleteAlert.toggle()
                    }
                }
            }
            CommandMenu("Logs") {
                Button("Save Current Log") {
                    Task {
                        self.currentLog = await logger.generateLog()
                        if self.currentLog != nil {
                            isExporting = true
                        }
                    }
                }
            }
            CommandMenu("Camera Extension") {
                Button("Install Camera Extension...") {
                    self.screenRecorder.installExtension()
                }
                Button("Uninstall Camera Extension...") {
                    self.screenRecorder.uninstallExtension()
                }
            }
        }
        Window("Test Pattern", id: "testpattern") {
            TestPatternView(fps: $screenRecorder.framesPerSecond)
        }
    }
}

class CameraExtensionRequestDelegate: NSObject, OSSystemExtensionRequestDelegate {
    func request(_ request: OSSystemExtensionRequest, actionForReplacingExtension existing: OSSystemExtensionProperties, withExtension ext: OSSystemExtensionProperties) -> OSSystemExtensionRequest.ReplacementAction {
        return .replace
    }
    
    func requestNeedsUserApproval(_ request: OSSystemExtensionRequest) {
        Logger.application.info("Camera extension requires user approval.")
    }
    
    func request(_ request: OSSystemExtensionRequest, didFinishWithResult result: OSSystemExtensionRequest.Result) {
        switch result {
        case .completed:
            Logger.application.info("Camera extension installation is complete.")
        case .willCompleteAfterReboot:
            Logger.application.info("Camera extension installation will complete after reboot.")
        default:
            Logger.application.info("poop.")
        }
    }
    
    func request(_ request: OSSystemExtensionRequest, didFailWithError error: Error) {
        Logger.application.error("Camera extension installation failed with error \(error, privacy: .public)")
    }
    
    
}
