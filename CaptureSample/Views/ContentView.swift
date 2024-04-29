/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The app's main view.
*/

import SwiftUI
import ScreenCaptureKit
import OSLog
import Combine

struct ContentView: View {
    
    @State var userStopped = false
    @State var disableInput = false
    @State var isUnauthorized = false
    @State var mouseCursorHovering = false
    @State var overlayOpacity = 1.0
    
    @EnvironmentObject var screenRecorder: ScreenRecorder
    
    var body: some View {
        HSplitView {
            ConfigurationView(screenRecorder: screenRecorder, userStopped: $userStopped)
                .frame(minWidth: 330, maxWidth: 330)
                .disabled(disableInput)
            if (screenRecorder.showsEncodePreview) {
                screenRecorder.captureEncodePreview
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .aspectRatio(screenRecorder.contentSize, contentMode: .fit)
                    .padding(8)
                    .overlay {
                        if userStopped {
                            Image(systemName: "nosign")
                                .font(.system(size: 250, weight: .bold))
                                .foregroundColor(Color(white: 0.3, opacity: 1.0))
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color(white: 0.0, opacity: 0.5))
                        }
                    }
                    .overlay {
                        if isUnauthorized {
                            VStack() {
                                Spacer()
                                VStack {
                                    Text("No screen recording permission.")
                                        .font(.largeTitle)
                                        .padding(.top)
                                    Text("Open System Settings and go to Privacy & Security > Screen Recording to grant permission.")
                                        .font(.title2)
                                        .padding(.bottom)
                                }
                                .frame(maxWidth: .infinity)
                                .background(.red)
                                
                            }
                        }
                    }
            } else {
                screenRecorder.capturePreview
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .aspectRatio(screenRecorder.contentSize, contentMode: .fit)
                    .padding(8)
                    .overlay {
                        if userStopped {
                            Image(systemName: "nosign")
                                .font(.system(size: 250, weight: .bold))
                                .foregroundColor(Color(white: 0.3, opacity: 1.0))
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color(white: 0.0, opacity: 0.5))
                        }
                    }
                    .overlay {
                        if isUnauthorized {
                            VStack() {
                                Spacer()
                                VStack {
                                    Text("No screen recording permission.")
                                        .font(.largeTitle)
                                        .padding(.top)
                                    Text("Open System Settings and go to Privacy & Security > Screen Recording to grant permission.")
                                        .font(.title2)
                                        .padding(.bottom)
                                }
                                .frame(maxWidth: .infinity)
                                .background(.red)
                                
                            }
                        }
                    }
                    .overlay(alignment: .leading) {
                        VStack() {
                            CaptureConfigurationOverlay(screenRecorder: self.screenRecorder)
                            Spacer()
                        }
                        .padding(EdgeInsets(top: 75, leading: 75, bottom: 0, trailing: 0))
                        .opacity(overlayOpacity)
                    }
                    .onHover { hover in
                        mouseCursorHovering = hover
                        withAnimation(.easeInOut(duration: 0.25)) {
                            overlayOpacity = hover == true ? 1.0 : 0.0
                        }
                    }
                    .background(.white)
            }
        }
        .navigationTitle("Record")
        .onAppear {
            Task {
                if await screenRecorder.canRecord {
                    await screenRecorder.start()
                } else {
                    isUnauthorized = true
                    disableInput = true
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
