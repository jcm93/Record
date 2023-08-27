/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view that provides the UI to configure screen capture.
*/

import SwiftUI
import ScreenCaptureKit

/// The app's configuration user interface.
struct ConfigurationView: View {
    
    private let sectionSpacing: CGFloat = 20
    private let verticalLabelSpacing: CGFloat = 8
    
    private let alignmentOffset: CGFloat = 10
    
    @StateObject private var audioPlayer = AudioPlayer()
    @ObservedObject var screenRecorder: ScreenRecorder
    @Binding var userStopped: Bool
    
    private let scaleWidth: Int = 0
    private let scaleHeight: Int = 0
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack {
                    Form {
                        Spacer()
                            .frame(minHeight: 10)
                        
                        HeaderView("Video")
                            .padding(EdgeInsets(top: 0, leading: 0, bottom: 1, trailing: 0))
                        
                        VideoCaptureConfigurationView(screenRecorder: self.screenRecorder)
                        
                        Spacer()
                            .frame(minHeight: 8)
                        
                        HeaderView("Audio")
                        
                        AudioConfigurationView(screenRecorder: self.screenRecorder)
                        
                        Spacer()
                            .frame(minHeight: 8)
                        
                        HeaderView("Encoder")
                            .padding(EdgeInsets(top: 0, leading: 0, bottom: 1, trailing: 0))
                        
                        EncoderConfigurationView(screenRecorder: self.screenRecorder)
                        
                        Group {
                            HeaderView("Output")
                            
                            OutputConfigurationView(screenRecorder: self.screenRecorder)
                        }
                        .offset(CGSize(width: 0, height: -18))
                    }
                    
                    Spacer()
                        .frame(minHeight: 7)
                    
                    AppControlsConfigurationView(screenRecorder: self.screenRecorder, userStopped: self.$userStopped)
                }
                .frame(minHeight: geometry.size.height)
            }
            .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 6))
            .background(MaterialView())
            .frame(width: geometry.size.width)
        }
        .background(MaterialView())
    }
}

/// A view that displays a styled header for the Video and Audio sections.
struct HeaderView: View {
    
    private let title: String
    private let alignmentOffset: CGFloat = 10.0
    
    init(_ title: String) {
        self.title = title
    }
    
    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundColor(.secondary)
            .padding(EdgeInsets(top: 0, leading: 6, bottom: 0, trailing: 0))
            //.alignmentGuide(.leading) { _ in alignmentOffset }
    }
}

extension HorizontalAlignment {
    /// A custom alignment for image titles.
    private struct ImageTitleAlignment: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            // Default to trailing
            context[HorizontalAlignment.trailing]
        }
    }


    /// A guide for aligning titles.
    static let imageTitleAlignmentGuide = HorizontalAlignment(
        ImageTitleAlignment.self
    )
}
