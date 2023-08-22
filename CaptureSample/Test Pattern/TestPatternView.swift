/*
See LICENSE folder for this sample’s licensing information.

Abstract:
ContentView class that returns a `CIImage` for the current time.
*/

import SwiftUI
import CoreImage.CIFilterBuiltins

/// - Tag: ContentView
struct TestPatternView: View {
    
    @State var fps: Int
    
    var body: some View {
        // Create a Metal view with its own renderer.
        let renderer = Renderer(imageProvider: { (time: CFTimeInterval, scaleFactor: CGFloat, headroom: CGFloat) -> CIImage in
            
            var image: CIImage
            
            // Animate a shifting red and yellow checkerboard pattern.
            let pointsShiftPerSecond = 5.0 * Double(self.fps)
            let checkerFilter = CIFilter.stripesGenerator()
            checkerFilter.width = 20.0
            checkerFilter.color0 = CIColor.red
            checkerFilter.color1 = CIColor.yellow
            checkerFilter.center = CGPoint(x: time * pointsShiftPerSecond, y: time * pointsShiftPerSecond)
            image = checkerFilter.outputImage ?? CIImage.empty()
            
            return image.cropped(to: CGRect(x: 0, y: 0,
                                            width: 512.0 * scaleFactor,
                                            height: 384.0 * scaleFactor))
        })

        MetalView(renderer: renderer, fps: self.fps)
    }
}


#Preview {
    TestPatternView(fps: 30)
}
