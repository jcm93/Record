/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view that renders a video frame.
*/

import SwiftUI
import CoreGraphics
import AVFoundation

struct CaptureSingleViewPreview: NSViewRepresentable {
    
    // A layer that renders the video contents.
    private let contentLayer = CALayer()
    
    init() {
        //contentLayer.contentsGravity = .resizeAspect
        contentLayer.contentsGravity = .resizeAspect
    }
    
    func makeNSView(context: Context) -> CaptureVideoPreview {
        CaptureVideoPreview(layer: contentLayer)
    }
    
    // Called by ScreenRecorder as it receives new video frames.
    func updateFrame(_ frame: CapturedFrame) {
        contentLayer.contents = frame.surface
    }
    
    // The view isn't updatable. Updates to the layer's content are done in outputFrame(frame:).
    func updateNSView(_ nsView: CaptureVideoPreview, context: Context) {
        
    }
}

struct CaptureSplitViewPreview: NSViewRepresentable {
    
    // A layer that renders the video contents.
    private let contentLayer = CALayer()
    private let encodedContentLayer = AVSampleBufferDisplayLayer()
    private let renderer: AVQueuedSampleBufferRendering
    
    init() {
        //contentLayer.contentsGravity = .resizeAspect
        contentLayer.contentsGravity = .topLeft
        encodedContentLayer.contentsGravity = .topRight
        self.renderer = encodedContentLayer
    }
    
    func makeNSView(context: Context) -> CaptureSplitViewPreview {
        //CaptureVideoPreview(layer: contentLayer)
        CaptureSplitViewPreview(firstLayer: contentLayer, secondLayer: encodedContentLayer)
    }
    
    // Called by ScreenRecorder as it receives new video frames.
    func updateFrame(_ frame: CapturedFrame) {
        IOSurfaceLock(frame.surface!, [], nil)
        contentLayer.contents = frame.surface
        if let frame = frame.encodedFrame {
            self.renderer.enqueue(frame)
        }
        IOSurfaceUnlock(frame.surface!, [], nil)
        //encodedContentLayer.contents = frame.encodedSurface
    }
    
    // The view isn't updatable. Updates to the layer's content are done in outputFrame(frame:).
    func updateNSView(_ nsView: CaptureSplitViewPreview, context: Context) {
        
    }
    
    class CaptureSplitViewPreview: NSSplitView {
        var firstView: NSView
        var secondView: NSView
        
        override var dividerColor: NSColor { return .red }
        override var dividerThickness: CGFloat { return 3.0 }
        
        init(firstLayer: CALayer, secondLayer: CALayer) {
            self.firstView = CaptureVideoPreview(layer: firstLayer)
            self.secondView = CaptureVideoPreview(layer: secondLayer)
            super.init(frame: .zero)
            self.isVertical = true
            self.addSubview(self.firstView)
            self.addSubview(self.secondView)
            //secondView.layer?.contentsScale = scale
            self.wantsLayer = true
            if #available(macOS 14.0, *) {
                (self.secondView.layer as! AVSampleBufferDisplayLayer).wantsExtendedDynamicRangeContent = true
            } else {
                // Fallback on earlier versions
            }
        }
        
        override func viewDidEndLiveResize() {
            super.viewDidEndLiveResize()
            IOSurfaceLock(firstView.layer!.contents as! IOSurface, [], nil)
            let scale = CGFloat(IOSurfaceGetHeight(firstView.layer!.contents as! IOSurface)) / self.frame.height
            firstView.layer?.contentsScale = scale
            IOSurfaceUnlock(firstView.layer!.contents as! IOSurface, [], nil)
            if let surface = secondView.layer?.contents as? IOSurface {
                let otherScale = CGFloat(IOSurfaceGetHeight(surface)) / self.frame.height
                secondView.layer?.contentsScale = otherScale
            }
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
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
