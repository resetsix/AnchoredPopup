//
//  AnchoredAnimationManager.swift
//
//  Created by Alisa Mylnikova on 23.10.2024.
//

import SwiftUI

public enum AnchoredPopupPosition {
    case anchorRelative(point: UnitPoint) // popup view will be aligned to anchor view at corresponding proportion
    case screenRelative(point: UnitPoint) // popup view will be aligned to whole screen
}

public extension View {
    func useAsPopupAnchor<V: View>(id: String, duration: CGFloat = 0.3, position: AnchoredPopupPosition, @ViewBuilder contentBuilder: @escaping () -> V) -> some View {
        self.modifier(TriggerButton(id: id, duration: duration, position: position, contentBuilder: contentBuilder))
    }
}

class AnchoredPopup {
    @MainActor static func launchAnchoredAnimation(id: String) {
        AnchoredAnimationManager.shared.changeStateForAnimation(id: id, state: .growing)
    }
}

/// this manager stores states for all the paired growing/shrinking animations
fileprivate class AnchoredAnimationManager: ObservableObject {
    @MainActor static let shared = AnchoredAnimationManager()

    enum GrowingViewState {
        case hidden, growing, displayed, shrinking
    }

    struct AnimationItem {
        var id: String
        var buttonFrame: CGRect
        var state: GrowingViewState
    }

    @Published var animations: [AnimationItem] = []

    func changeStateForAnimation(id: String, state: GrowingViewState) {
        if let index = animations.firstIndex(where: { $0.id == id }) {
            animations[index].state = state
        }
    }

    func updateFrame(for id: String, frame: CGRect) {
        if let index = animations.firstIndex(where: { $0.id == id }) {
            animations[index].buttonFrame = frame
        } else {
            animations.append(AnimationItem(id: id, buttonFrame: frame, state: .hidden))
        }
    }
}

fileprivate struct ButtonFrameInfo: Equatable {
    let id: String
    let frame: CGRect
}

fileprivate struct ButtonFramePreferenceKey: PreferenceKey {
    typealias Value = ButtonFrameInfo
    static let defaultValue: ButtonFrameInfo = ButtonFrameInfo(id: "", frame: .zero)

    static func reduce(value: inout ButtonFrameInfo, nextValue: () -> ButtonFrameInfo) {
        value = nextValue()
    }
}

fileprivate struct TriggerButton<V>: ViewModifier where V: View {
    var id: String
    var duration: CGFloat
    var position: AnchoredPopupPosition
    @ViewBuilder var contentBuilder: () -> V

    func body(content: Content) -> some View {
        content
            .background(GeometryReader { geo in
                Color.clear
                    .preference(key: ButtonFramePreferenceKey.self, value: ButtonFrameInfo(id: id, frame: geo.frame(in: .global)))
            })
            .simultaneousGesture(
                TapGesture().onEnded { gesture in
                    // trigger displaying animation
                    hideKeyboard()
                    AnchoredAnimationManager.shared.changeStateForAnimation(id: id, state: .growing)
                }
            )
            .onPreferenceChange(ButtonFramePreferenceKey.self) { value in
                AnchoredAnimationManager.shared.updateFrame(for: value.id, frame: value.frame)
            }
            .onReceive(AnchoredAnimationManager.shared.$animations) { animations in
                if let animation = animations.first(where: { $0.id == id }) {
                    if animation.state == .growing {
                        WindowManager.openNewWindow {
                            ZStack {
                                AnimatedBackgroundView(id: id)
                                AnchoredAnimationView(id: id, duration: duration, position: position, contentBuilder: contentBuilder)
                            }
                            .fullTap {
                                // trigger hiding animation
                                AnchoredAnimationManager.shared.changeStateForAnimation(id: id, state: .shrinking)
                            }
                        }
                    } else if animation.state == .hidden {
                        WindowManager.closeWindow()
                    }
                }
            }
    }
}

fileprivate struct AnimatedBackgroundView: View {
    var id: String

    @State private var animatableOpacity: CGFloat = 0

    var body: some View {
        Color.black.opacity(0.3)
            .background(Blur(radius: 6))
            .ignoresSafeArea()
            .opacity(animatableOpacity)
            .onReceive(AnchoredAnimationManager.shared.$animations) { animations in
                if let animation = animations.first(where: { $0.id == id }) {
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

fileprivate struct AnchoredAnimationView<V>: View where V: View {
    var id: String
    var duration: CGFloat
    var position: AnchoredPopupPosition
    var contentBuilder: () -> V

    @State private var animatableOpacity: CGFloat = 0
    @State private var animatableScale: CGSize = .zero
    @State private var animatableOffset: CGSize = .zero

    @State private var triggerButtonFrame: CGRect = .zero
    @State private var contentSize: CGSize = .zero

    var body: some View {
        VStack {
            contentBuilder()
                .background(GeometryReader { geo in
                    Color.clear.onAppear {
                        DispatchQueue.main.async {
                            contentSize = geo.size
                            if let animation = AnchoredAnimationManager.shared.animations.first(where: { $0.id == id }) {
                                setupAndLaunchAnimation(animation)
                            }
                        }
                    }
                })
                .scaleEffect(animatableScale)
                .offset(animatableOffset)
                .position(x: triggerButtonFrame.midX, y: triggerButtonFrame.midY)
                .opacity(animatableOpacity)
                .ignoresSafeArea()
                .simultaneousGesture(
                    TapGesture().onEnded { gesture in
                        // trigger hiding animation
                        AnchoredAnimationManager.shared.changeStateForAnimation(id: id, state: .shrinking)
                    }
                )
        }
        .onReceive(AnchoredAnimationManager.shared.$animations) { animations in
            if let animation = animations.first(where: { $0.id == id }) {
                setupAndLaunchAnimation(animation)
            }
        }
        .onAppear {
            if let animation = AnchoredAnimationManager.shared.animations.first(where: { $0.id == id }) {
                setupAndLaunchAnimation(animation)
            }
        }
    }

    private func setupAndLaunchAnimation(_ animation: AnchoredAnimationManager.AnimationItem) {
        if contentSize == .zero { return }
        if triggerButtonFrame == .zero { // initial setup, and contentSize is ready
            DispatchQueue.main.async {
                triggerButtonFrame = animation.buttonFrame
                setHiddenState()
            }
        }

        DispatchQueue.main.async {
            if animation.state == .growing {
                withAnimation(Animation.easeInOut(duration: duration)) {
                    setDisplayedState()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                    AnchoredAnimationManager.shared.changeStateForAnimation(id: id, state: .displayed)
                }
            } else if animation.state == .shrinking {
                withAnimation(Animation.easeInOut(duration: duration)) {
                    setHiddenState()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                    // let the manager know that the animation is finished, this means that transparant sheet can be dismissed
                    AnchoredAnimationManager.shared.changeStateForAnimation(id: id, state: .hidden)
                }
            }
        }
    }

    private func setHiddenState() {
        animatableOffset = calculateHiddenOffset()
        animatableScale = .zero
        animatableOpacity = 0
    }

    private func setDisplayedState() {
        animatableOffset = calculateDisplayedOffset()
        animatableScale = CGSize(width: 1, height: 1)
        animatableOpacity = 1
    }

    private func calculateHiddenOffset() -> CGSize {
        switch position {
        case .anchorRelative(let p):
            let tw = triggerButtonFrame.width
            let th = triggerButtonFrame.height

            let w = -tw/2
            let h = -th/2

            let px = -2 * p.x + 1
            let py = -2 * p.y + 1

            return CGSize(width: w * px, height: h * py)

        case .screenRelative:
            return .zero
        }
    }

    private func calculateDisplayedOffset() -> CGSize {
        let point: UnitPoint
        let tx, ty, tw, th: CGFloat

        switch position {
        case .anchorRelative(let p):
            point = p
            tx = triggerButtonFrame.midX
            ty = triggerButtonFrame.midY
            tw = triggerButtonFrame.width
            th = triggerButtonFrame.height
        case .screenRelative(let p):
            point = p
            tx = UIScreen.main.bounds.midX
            ty = UIScreen.main.bounds.midY
            tw = UIScreen.main.bounds.width
            th = UIScreen.main.bounds.height
        }

        let cw = contentSize.width
        let ch = contentSize.height

        // difference between centers
        let w = cw/2 - tw/2
        let h = ch/2 - th/2

        // .topLeading UnitPoint: (0, 0)
        // (tx + x, ty + y)
        // .topTrailing UnitPoint: (1, 0)
        // (tx - x, ty + y) etc.
        // normalization: (0, 1) -> (1, -1)
        let px = -2 * point.x + 1
        let py = -2 * point.y + 1

        // the content view center is currently same as anchor view
        // +/- the difference between centers
        return CGSize(width: w * px, height: h * py)
    }
}
