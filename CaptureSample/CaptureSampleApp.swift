/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The entry point into this app.
*/
import SwiftUI

@main
struct CaptureSampleApp: App {
    @State private var isShowingAlert = false
    @State private var isShowingDeleteAlert = false
    
    @State private var presetName: String = ""
    
    @State var selectedPreset: OptionsStorable!
    
    @StateObject var screenRecorder = ScreenRecorder()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(screenRecorder)
                .frame(minWidth: 960, minHeight: 724)
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
        }
        Window("Test Pattern", id: "testpattern") {
            TestPatternView(fps: $screenRecorder.framesPerSecond)
        }
    }
}
