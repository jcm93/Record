/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A wrapper view around NSVisualEffectView.
*/

import SwiftUI

struct MaterialView: NSViewRepresentable {
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.blendingMode = .behindWindow
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

struct SheetMaterialView: NSViewRepresentable {
    @Environment(\.colorScheme) var colorScheme
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .underWindowBackground
        view.blendingMode = .behindWindow
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

struct OverlayMaterialView: NSViewRepresentable {
    @Environment(\.colorScheme) var colorScheme
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .fullScreenUI
        view.blendingMode = .withinWindow
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
