//
//  Utils.swift
//  AnchoredPopup
//
//  Created by Alisa Mylnikova on 21.01.2025.
//

import SwiftUI
import SwiftUI

@MainActor func hideKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
}

extension View {
    func fullTap(action: @escaping () -> Void) -> some View {
        self.contentShape(Rectangle())
            .onTapGesture {
                action()
            }
    }
}
