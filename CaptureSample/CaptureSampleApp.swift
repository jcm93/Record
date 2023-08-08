/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The entry point into this app.
*/
import SwiftUI

@main
struct CaptureSampleApp: App {
    
    @StateObject var screenRecorder = ScreenRecorder()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(screenRecorder)
                .frame(minWidth: 960, minHeight: 724)
                .background(.black)
        }
        .commands {
            CommandMenu("Preset") {
                Button("Test") {
                    
                    //let options = try JSONSerialization.data(withJSONObject: self.options)
                    //print(options)
                }
                Divider()
                Button("Save Preset") {
                    Task {
                        screenRecorder.savePreset()
                    }
                }
                Button("Load Preset") {
                    Task {
                        screenRecorder.loadPreset()
                    }
                }
            }
        }
    }
}
