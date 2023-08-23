//
//  PickerView.swift
//  Record
//
//  Created by John Moody on 8/23/23.
//  Copyright © 2023 Apple. All rights reserved.
//

import SwiftUI

//https://www.reddit.com/r/SwiftUI/comments/kkkumj/is_it_possible_in_swiftui_to_recreate_the_hour/

struct PickerView: View {
    @Binding public var seconds: Int
    
    var minutesArray = [Int](0..<59)
    var secondsArray = [Int](0..<59)
    
    private let secondsInMinute = 60
    
    @State private var minuteSelection = 1
    @State private var secondSelection = 0
    
    private let frameHeight: CGFloat = 160
    
    var body: some View {
            HStack {
                
                Picker(selection: self.$minuteSelection, label: Text("")) {
                    ForEach(0 ..< self.minutesArray.count) { index in
                        Text("\(self.minutesArray[index]) m").tag(index)
                    }
                }
                .frame(width: 60)
                .onChange(of: self.minuteSelection) { newValue in
                    seconds = totalInSeconds
                }
                .clipped()
                .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 2))
                
                Picker(selection: self.self.$secondSelection, label: Text("")) {
                    ForEach(0 ..< self.secondsArray.count) { index in
                        Text("\(self.secondsArray[index]) s").tag(index)
                    }
                }
                .frame(width: 60)
                .onChange(of: self.secondSelection) { newValue in
                    seconds = totalInSeconds
                }
                .clipped()
            }
        .onAppear(perform: { updatePickers() })
    }
    
    func updatePickers() {
        minuteSelection = seconds / 60
        secondSelection = seconds - (minuteSelection * 60)
    }
    
    var totalInSeconds: Int {
        return minuteSelection * self.secondsInMinute + secondSelection
    }
}
