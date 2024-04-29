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
            VStack {
                //GroupBox {
                    Picker("Capture", selection: $screenRecorder.applicationFilterIsInclusive) {
                        Text("Exclude:")
                            .tag(true)
                            .font(.title)
                        Text("Include:")
                            .tag(false)
                            .font(.title)
                    }
                    .pickerStyle(.radioGroup)
                    .horizontalRadioGroupLayout()
                    .controlSize(.large)
                    //.background(.clear)
                //}
                .frame(width: 440, height: 100)
                .labelsHidden()
                .background(.thickMaterial)
                .cornerRadius(20.0)
                GroupBox {
                    LazyVGrid(columns: columns) {
                        ForEach(screenRecorder.availableApps, id: \.self) { app in
                            var dumb = false
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
                                    .toggleStyle(OtherCheckboxToggleStyle())
                                    Text(app.applicationName)
                                        .font(.title2)
                                        .tag(app)
                                        .fontWeight(.regular)
                                        .opacity(0.8)
                                    Spacer(minLength: 1)
                                    //Rectangle()
                                    //.fill(.quinary)
                                    //.frame(width: 1, height: 200)
                                }
                                .frame(height: 25)
                                /*Rectangle()
                                 .fill(.quinary)
                                 .frame(width: 1000, height: 1)
                                 .gridCellColumns(2)*/
                            }
                        }
                    }
                    .padding(EdgeInsets(top: 20, leading: 0, bottom: 20, trailing: -32))
                }
                .frame(width: 440)
                .labelsHidden()
                .background(.thickMaterial)
                .cornerRadius(20.0)
            }
        case .window:
            EmptyView()
            /*Picker("Window", selection: $screenRecorder.selectedWindow) {
                ForEach(screenRecorder.availableWindows, id: \.self) { window in
                    Text(window.displayName)
                        .tag(SCWindow?.some(window))
                }
            }
            .controlSize(.large)
            .frame(width: 500)
            .onHover(perform: { hovering in
                Task {
                    await self.screenRecorder.refreshAvailableContent()
                }
            })*/
        }
        
    }
}

struct ApplicationProxy: Identifiable {
    var id: ObjectIdentifier
    
    var isToggled = false
    var application: SCRunningApplication
}

struct OtherCheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
                RoundedRectangle(cornerRadius: 5.0)
                    .stroke(lineWidth: 1)
                    .frame(width: 22, height: 22)
                    .cornerRadius(5.0)
                    .overlay {
                        if configuration.isOn {
                            Image(systemName: "checkmark")
                        }
                    }
                .background(
                    Color.clear
                        .contentShape(RoundedRectangle(cornerRadius: 5.0))
                        .onTapGesture {
                            withAnimation(.snappy(duration: 0.1)) {
                                configuration.isOn.toggle()
                            }
                        }
                )
        }
        .onTapGesture {
            withAnimation(.snappy(duration: 0.1)) {
                configuration.isOn.toggle()
            }
        }
    }
}
