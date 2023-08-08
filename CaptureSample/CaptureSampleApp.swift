/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The entry point into this app.
*/
import SwiftUI

@main
struct CaptureSampleApp: App {
    @State private var isShowingAlert = false
    
    @State private var presetName: String = ""
    
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
        }
        .commands {
            CommandMenu("Preset") {
                ForEach(self.screenRecorder.presets, id: \.presetName) { preset in
                    Button("\(presetName)") {
                        self.screenRecorder.loadPreset(name: presetName)
                    }
                }
                Divider()
                Button("Save Preset") {
                    isShowingAlert.toggle()
                }
            }
        }
    }
}
