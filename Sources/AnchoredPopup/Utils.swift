//
//  Utils.swift
//  AnchoredPopup
//
//  Created by Alisa Mylnikova on 21.01.2025.
//

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

struct ButtonFrameInfo: Equatable {
    let id: String
    let frame: CGRect
}

struct ButtonFramePreferenceKey: PreferenceKey {
    typealias Value = ButtonFrameInfo
    static let defaultValue: ButtonFrameInfo = ButtonFrameInfo(id: "", frame: .zero)

    static func reduce(value: inout ButtonFrameInfo, nextValue: () -> ButtonFrameInfo) {
        if value != nextValue() {
            value = nextValue()
        }
    }
}

struct AnimatedBackgroundView: View {
    var id: String
    var background: AnchoredPopupBackground

    @State private var animatableOpacity: CGFloat = 0

    var body: some View {
        Group {
            switch background {
            case .none:
                EmptyView()
            case .color(let color):
                color
            case .blur(let radius):
                Blur(radius: radius)
            case .view(let anyView):
                anyView
            }
        }
        .ignoresSafeArea()
        .opacity(animatableOpacity)
        .onReceive(AnchoredAnimationManager.shared.publisher(for: id)) { animation in
            if let animation {
                setupAndLaunchAnimation(animation)
            }
        }
    }

    private func setupAndLaunchAnimation(_ animation: AnchoredAnimationManager.AnimationItem) {
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.2)) {
                if animation.state == .growing {
                    setDisplayedState()
                } else if animation.state == .shrinking {
                    setHiddenState()
                }
            }
        }
    }

    private func setHiddenState() {
        animatableOpacity = 0
    }

    private func setDisplayedState() {
        animatableOpacity = 1
    }
}
