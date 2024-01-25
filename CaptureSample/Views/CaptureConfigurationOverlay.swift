//
//  CaptureConfigurationOverlay.swift
//  Record
//
//  Created by John Moody on 1/21/24.
//  Copyright © 2024 jcm. All rights reserved.
//

import SwiftUI
import ScreenCaptureKit

struct CaptureConfigurationOverlay: View {
    @ObservedObject var screenRecorder: ScreenRecorder
    
    var availableApps = [SCRunningApplication]()
    
    var columns = [GridItem(.flexible(minimum: 100, maximum: 200)), GridItem(.flexible(minimum: 100, maximum: 200))]
    
    var body: some View {
        
        switch screenRecorder.captureType {
        case .display:
            GroupBox {
                LazyVGrid(columns: columns) {
                    ForEach(screenRecorder.availableApps, id: \.self) { app in
                        VStack {
                            HStack {
                                Toggle("butt", isOn: Binding( get: {
                                    return screenRecorder.selectedApplications.contains(app)
                                }, set: { isOn in
                                    if isOn { screenRecorder.selectedApplications.insert(app) }
                                    else { screenRecorder.selectedApplications.remove(app) }
                                    UserDefaults.standard.setValue(isOn, forKey: app.bundleIdentifier)
                                }))
                                .controlSize(.large)
                                Text(app.applicationName)
                                    .font(.title2)
                                    .tag(app)
                                    .fontWeight(.regular)
                                    .opacity(0.8)
                                Spacer(minLength: 1)
                                Rectangle()
                                    .fill(.quinary)
                                    //.padding(EdgeInsets(top: -20, leading: 0, bottom: -20, trailing: 0))
                                    .frame(width: 1, height: 200)
                            }
                            .frame(height: 25)
                            Rectangle()
                                .fill(.quinary)
                                .frame(width: 1000, height: 1)
                                //.padding(EdgeInsets(top: 0, leading: -20, bottom: 0, trailing: -20))
                                .gridCellColumns(2)
                        }
                    }
                }
                .padding(EdgeInsets(top: 20, leading: 0, bottom: 20, trailing: -32))
            }
            /*Grid {
                List(screenRecorder.availableApps, selection: $screenRecorder.selectedApplications) { app in
                    HStack {
                        Toggle("butt", isOn: Binding( get: { 
                            return screenRecorder.selectedApplications.contains(app)
                        }, set: { isOn in
                            if isOn { screenRecorder.selectedApplications.insert(app) }
                            else { screenRecorder.selectedApplications.remove(app) }
                        }))
                            .controlSize(.large)
                        Text(app.applicationName)
                            .font(.title2)
                            .frame(height: 30)
                            .tag(app)
                    }
                }
            }*/
            .frame(width: 440)
            .labelsHidden()
            .background(OverlayMaterialView())
            .cornerRadius(20.0)
            //.padding(EdgeInsets(top: 50, leading: 0, bottom: 50, trailing: 0))
            //.opacity(0.6)
            
            
            

        case .window:
            Picker("Window", selection: $screenRecorder.selectedWindow) {
                ForEach(screenRecorder.availableWindows, id: \.self) { window in
                    Text(window.displayName)
                        .tag(SCWindow?.some(window))
                }
            }
            .onHover(perform: { hovering in
                Task {
                    await self.screenRecorder.refreshAvailableContent()
                }
            })
        }
        
    }
}

struct ApplicationProxy: Identifiable {
    var id: ObjectIdentifier
    
    var isToggled = false
    var application: SCRunningApplication
}
