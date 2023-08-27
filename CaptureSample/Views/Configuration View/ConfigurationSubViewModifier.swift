//
//  ConfigurationSubViewModifier.swift
//  Record
//
//  Created by John Moody on 8/26/23.
//  Copyright © 2023 Apple. All rights reserved.
//

import Foundation
import SwiftUI

struct ConfigurationSubViewStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(width: 260)
            .padding(EdgeInsets(top: 13, leading: 15, bottom: 13, trailing: 15))
            .controlSize(.small)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 5))
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(Color(.quaternaryLabelColor), lineWidth: 1)
            )
    }
}
