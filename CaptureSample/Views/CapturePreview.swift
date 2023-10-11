/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view that renders a video frame.
*/

import SwiftUI

struct CapturePreview: NSViewRepresentable {
    
    // A layer that renders the video contents.
    private let contentLayer = CALayer()
    private let encodedContentLayer = CALayer()
    
    init() {
        contentLayer.contentsGravity = .resizeAspect
        //contentLayer.contentsGravity = .topLeft
        //encodedContentLayer.contentsGravity = .topRight
    }
    
    func makeNSView(context: Context) -> CaptureVideoPreview {
        CaptureVideoPreview(layer: contentLayer)
        //CaptureSplitViewPreview(firstLayer: contentLayer, secondLayer: encodedContentLayer)
    }
    
    // Called by ScreenRecorder as it receives new video frames.
    func updateFrame(_ frame: CapturedFrame) {
        contentLayer.contents = frame.surface
        encodedContentLayer.contents = frame.encodedSurface
    }
    
    // The view isn't updatable. Updates to the layer's content are done in outputFrame(frame:).
    func updateNSView(_ nsView: CaptureVideoPreview, context: Context) {}
    
    class CaptureSplitViewPreview: NSSplitView {
        var firstView: NSView
        var secondView: NSView
        
        init(firstLayer: CALayer, secondLayer: CALayer) {
            self.firstView = CaptureVideoPreview(layer: firstLayer)
            self.secondView = CaptureVideoPreview(layer: secondLayer)
            super.init(frame: .zero)
            self.isVertical = true
            self.addSubview(self.firstView)
            self.addSubview(self.secondView)
            firstLayer.contentsScale = 3.0
            secondLayer.contentsScale = 3.0
            //firstLayer.contentsRect = self.visibleRect
            //secondLayer.contentsRect = self.visibleRect
            self.wantsLayer = true
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    class CaptureVideoPreview: NSView {
        // Create the preview with the video layer as the backing layer.
        init(layer: CALayer) {
            super.init(frame: .zero)
            // Make this a layer-hosting view. First set the layer, then set wantsLayer to true.
            self.layer = layer
            wantsLayer = true
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
