/*
See LICENSE folder for this sample’s licensing information.

Abstract:
ContentView class that returns a `CIImage` for the current time.
*/

import SwiftUI
import CoreImage.CIFilterBuiltins

/// - Tag: ContentView
struct TestPatternView: View {
    
    @Binding var fps: Double
    
    var body: some View {
        GeometryReader { geometry in
            // Create a Metal view with its own renderer.
            let renderer = Renderer(imageProvider: { (time: CFTimeInterval, scaleFactor: CGFloat, headroom: CGFloat) -> CIImage in
                
                var image: CIImage
                
                // Animate a shifting red and yellow checkerboard pattern.
                let pointsShiftPerSecond = 500.0
                let checkerFilter = CIFilter.stripesGenerator()
                checkerFilter.width = 20.0
                checkerFilter.color0 = CIColor.black
                checkerFilter.color1 = CIColor.gray
                checkerFilter.center = CGPoint(x: time * pointsShiftPerSecond, y: time * pointsShiftPerSecond)
                let otherStripes = CIFilter.stripesGenerator()
                otherStripes.width = 50.0
                otherStripes.color0 = CIColor.black
                otherStripes.color1 = CIColor.gray
                otherStripes.center = CGPoint(x: time * pointsShiftPerSecond, y: time * pointsShiftPerSecond)
                let filter = CIFilter.barsSwipeTransition()
                filter.inputImage = checkerFilter.outputImage ?? CIImage.empty()
                image = filter.outputImage ?? CIImage.empty()
                
                return image.cropped(to: CGRect(x: 0, y: 0,
                                                width: geometry.size.width * scaleFactor,
                                                height: geometry.size.height * scaleFactor))
            })
            
            MetalView(renderer: renderer, fps: Int(self.fps))
        }
    }
}
