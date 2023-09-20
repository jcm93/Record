//
//  HotkeysPreferencesView.swift
//  Record
//
//  Created by John Moody on 9/19/23.
//  Copyright © 2023 Apple. All rights reserved.
//

import SwiftUI

class HotkeyPreferenceController {
    
    private let screenRecorder: ScreenRecorder
    
    private var callbacks = [String : (() -> Void)]()
    
    init(screenRecorder: ScreenRecorder) {
        self.screenRecorder = screenRecorder
    }
    
    func callback(forCharacters characters: String) -> (() -> Void)? {
        return self.callbacks[characters]
    }
    
    func setCallback(_ callback: @escaping () -> Void, forString hotkeyString: String) {
        self.callbacks[hotkeyString] = callback
    }
}

struct HotkeysPreferencesView: View {
    
    private let screenRecorder: ScreenRecorder
    private let controller: HotkeyPreferenceController
    
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

struct HotkeySelectorView: View {
    
    private let commandName: String
    private let controller: HotkeyPreferenceController
    
    var body: some View {
        HStack {
            Text("\(commandName):")
            Text("test")
                .frame(width: 50)
        }
    }
}
