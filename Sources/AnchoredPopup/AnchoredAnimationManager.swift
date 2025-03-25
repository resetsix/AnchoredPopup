//
//  AnchoredAnimationManager.swift
//
//  Created by Alisa Mylnikova on 23.10.2024.
//

import SwiftUI
import Combine

/// this manager stores states for all the paired growing/shrinking animations
@MainActor
class AnchoredAnimationManager: ObservableObject {
    static let shared = AnchoredAnimationManager()

    enum GrowingViewState {
        case hidden, growing, displayed, shrinking
    }

    struct AnimationItem: Equatable {
        var id: String
        var buttonFrame: IntRect
        var state: GrowingViewState

        static func == (lhs: AnimationItem, rhs: AnimationItem) -> Bool {
            lhs.id == rhs.id
            && lhs.buttonFrame == rhs.buttonFrame
            && lhs.state == rhs.state
        }
    }

    @Published var animations: [AnimationItem] = []

    private var statePublishers: [String: CurrentValueSubject<AnimationItem?, Never>] = [:]
    private var framePublishers: [String: CurrentValueSubject<AnimationItem?, Never>] = [:]
    private var cancellables = Set<AnyCancellable>()

    static subscript(id: String) -> AnimationItem? {
        shared.animations.first { $0.id == id }
    }

    func changeStateForAnimation(for id: String, state: GrowingViewState) {
        if let index = animations.firstIndex(where: { $0.id == id }) {
            animations[index].state = state
        }
    }

   func updateFrame(for id: String, frame: CGRect) {
        if let index = animations.firstIndex(where: { $0.id == id }) {
            animations[index].buttonFrame = frame.toIntRect()
        } else {
            animations.append(AnimationItem(id: id, buttonFrame: frame.toIntRect(), state: .hidden))
        }
    }

    func statePublisher(for id: String) -> CurrentValueSubject<AnimationItem?, Never> {
        if let publisher = statePublishers[id] {
            return publisher
        }

        // Track the last emitted value for comparison
        var lastValue: AnimationItem? = nil

        // Create a CurrentValueSubject to hold the current value
        let subject = CurrentValueSubject<AnimationItem?, Never>(nil)

        // Generate the publisher and handle state changes
        $animations
            .map { animations in
                animations.first { $0.id == id }
            }
            .compactMap { $0 }
            .filter { newItem in
                if let last = lastValue {
                    // Only emit if the item has changed from the last value
                    if last.state != newItem.state {
                        lastValue = newItem // Update the last value
                        return true // Emit if there's a change
                    } else {
                        return false // Don't emit if no change
                    }
                } else {
                    lastValue = newItem // Set initial value
                    return true // Emit the first time
                }
            }
            .sink { newItem in
                // Emit the value to the CurrentValueSubject
                subject.send(newItem)
            }
            .store(in: &cancellables)

        statePublishers[id] = subject
        return subject
    }

    func framePublisher(for id: String) -> CurrentValueSubject<AnimationItem?, Never> {
        if let publisher = framePublishers[id] {
            return publisher
        }

        // Track the last emitted value for comparison
        var lastValue: AnimationItem? = nil

        // Create a CurrentValueSubject to hold the current value
        let subject = CurrentValueSubject<AnimationItem?, Never>(nil)

        // Generate the publisher and handle state changes
        $animations
            .map { animations in
                animations.first { $0.id == id }
            }
            .compactMap { $0 }
            .filter { newItem in
                if let last = lastValue {
                    // Only emit if the item has changed from the last value
                    if last.buttonFrame != newItem.buttonFrame {
                        lastValue = newItem // Update the last value
                        return true // Emit if there's a change
                    } else {
                        return false // Don't emit if no change
                    }
                } else {
                    lastValue = newItem // Set initial value
                    return true // Emit the first time
                }
            }
            .sink { newItem in
                // Emit the value to the CurrentValueSubject
                subject.send(newItem)
            }
            .store(in: &cancellables)

        framePublishers[id] = subject
        return subject
    }
}

struct TriggerButton<V>: ViewModifier where V: View {
    @State var id: String
    var params: PopupParameters
    @ViewBuilder var contentBuilder: () -> V

    @State private var cancellable: AnyCancellable?

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { geo in
                    Color.clear
                        .preference(key: ButtonFramePreferenceKey.self, value: ButtonFrameInfo(id: id, frame: geo.frame(in: .global)))
                }
            }
            .onPreferenceChange(ButtonFramePreferenceKey.self) { value in
                DispatchQueue.main.async {
                    if id == value.id {
                        AnchoredAnimationManager.shared.updateFrame(for: value.id, frame: value.frame)
                    }
                }
            }
            .simultaneousGesture(
                TapGesture().onEnded { gesture in
                    // trigger displaying animation
                    hideKeyboard()
                    AnchoredAnimationManager.shared.changeStateForAnimation(for: id, state: .growing)
                }
            )
            .onReceive(AnchoredAnimationManager.shared.statePublisher(for: id)) { animation in
                if animation?.state == .growing {
                    WindowManager.openNewWindow(id: id, isPassthrough: params.isPassthrough) {
                        ZStack {
                            AnimatedBackgroundView(id: $id, background: params.background)
                                .simultaneousGesture(
                                    TapGesture().onEnded {
                                        if params.closeOnTapOutside {
                                            // trigger hiding animation
                                            AnchoredAnimationManager.shared.changeStateForAnimation(for: id, state: .shrinking)
                                        }
                                    }
                                )
                            AnchoredAnimationView(id: id, params: params, contentBuilder: contentBuilder)
                        }
                    }
                } else if animation?.state == .hidden {
                    WindowManager.closeWindow(id: id)
                }
            }
    }
}

fileprivate struct AnchoredAnimationView<V>: View where V: View {
    var id: String
    var params: PopupParameters
    var contentBuilder: () -> V

    @State private var animatableOpacity: CGFloat = 0
    @State private var animatableScale: CGSize = .zero
    @State private var animatableOffset: CGSize = .zero

    @State private var triggerButtonFrame: IntRect = .zero
    @State private var contentSize: IntSize = .zero

    @State private var semaphore = DispatchSemaphore(value: 1)

    var body: some View {
        VStack {
            contentBuilder()
                .overlay(GeometryReader { geo in
                    Color.clear.onAppear {
                        DispatchQueue.main.async {
                            contentSize = geo.size.toIntSize()
                            if let animation = AnchoredAnimationManager.shared.animations.first(where: { $0.id == id }) {
                                setupAndLaunchAnimation(animation)
                            }
                        }
                    }
                })
                .scaleEffect(animatableScale)
                .offset(animatableOffset)
                .position(x: triggerButtonFrame.floatMidX, y: triggerButtonFrame.floatMidY)
                .opacity(animatableOpacity)
                .ignoresSafeArea()
                .simultaneousGesture(
                    TapGesture().onEnded { gesture in
                        if params.closeOnTap {
                            // trigger hiding animation
                            AnchoredAnimationManager.shared.changeStateForAnimation(for: id, state: .shrinking)
                        }
                    }
                )
        }
        .onReceive(AnchoredAnimationManager.shared.framePublisher(for: id)) { animation in
            if let animation, triggerButtonFrame == .zero {
                triggerButtonFrame = animation.buttonFrame
            }
        }
        .onReceive(AnchoredAnimationManager.shared.statePublisher(for: id)) { animation in
            if let animation {
                setupAndLaunchAnimation(animation)
            }
        }
    }

    private func setupAndLaunchAnimation(_ animation: AnchoredAnimationManager.AnimationItem) {
        if contentSize == .zero || triggerButtonFrame == .zero { return }

        print(animation.state)
        semaphore.wait()
        if let animation = AnchoredAnimationManager[id] {
            if animation.state == .growing {
                setHiddenState()

                if #available(iOS 17.0, *) {
                    withAnimation(params.animation) {
                        setDisplayedState()
                    } completion: {
                        AnchoredAnimationManager.shared.changeStateForAnimation(for: id, state: .displayed)
                        semaphore.signal()
                    }
                } else {
                    withAnimation(params.animation) {
                        setDisplayedState()
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        AnchoredAnimationManager.shared.changeStateForAnimation(for: id, state: .displayed)
                        semaphore.signal()
                    }
                }
            } else if animation.state == .shrinking {
                if #available(iOS 17.0, *) {
                    withAnimation(params.animation) {
                        setHiddenState()
                    } completion: {
                        AnchoredAnimationManager.shared.changeStateForAnimation(for: id, state: .hidden)
                        semaphore.signal()
                    }
                } else {
                    withAnimation(params.animation) {
                        setHiddenState()
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        AnchoredAnimationManager.shared.changeStateForAnimation(for: id, state: .hidden)
                        semaphore.signal()
                    }
                }
            } else {
                semaphore.signal()
            }
        }
    }

    private func setHiddenState() {
        animatableOffset = .zero
        animatableScale = calculateHiddenScale()
        animatableOpacity = 0
    }

    private func setDisplayedState() {
        animatableOffset = calculateDisplayedOffset()
        animatableScale = CGSize(width: 1, height: 1)
        animatableOpacity = 1
    }

    /// start with popup matching trigger's position and size
    private func calculateHiddenScale() -> CGSize {
        let tw = triggerButtonFrame.floatWidth
        let th = triggerButtonFrame.floatHeight
        let pw = contentSize.floatWidth
        let ph = contentSize.floatHeight
        return CGSize(width: tw/pw, height: th/ph)
    }

    /// starting position is center of the trigger
    private func calculateDisplayedOffset() -> CGSize {
        let cw = contentSize.floatWidth
        let ch = contentSize.floatHeight

        switch params.position {
        case .anchorRelative(let p):
            let tw = triggerButtonFrame.floatWidth
            let th = triggerButtonFrame.floatHeight

            // difference between centers
            let w = cw/2 - tw/2
            let h = ch/2 - th/2

            // normalization: (0, 1) -> (1, -1)
            let px = -2 * p.x + 1
            let py = -2 * p.y + 1

            // the content view center is currently same as anchor view
            // +/- the difference between centers
            return CGSize(width: w * px, height: h * py)

        case .screenRelative(let p):
            let tx = triggerButtonFrame.floatMidX
            let ty = triggerButtonFrame.floatMidY
            let sw = UIScreen.main.bounds.width
            let sh = UIScreen.main.bounds.height

            // normalization: (0, 1) -> (1, -1)
            let px = -2 * p.x + 1
            let py = -2 * p.y + 1

            // the content view center is currently same as anchor view
            // -tx: put middle of popup into (0,0)
            // sw * p.x: put middle of popup into required unit point of screen
            // cw/2 * px: align required unit point of popup with the screen
            return CGSize(width: -tx + sw * p.x + cw/2 * px, height: -ty + sh * p.y + ch/2 * py)
        }
    }
}

//func withAnimation(_ animation: Animation, closure: ()->(), completion: @escaping ()->()) {
//    if #available(iOS 17.0, *) {
//        withAnimation(animation) {
//            //DispatchQueue.main.async {
//                closure()
//            //}
//        } completion: {
//            completion()
//        }
//    } else {
//        withAnimation(animation) {
//            //DispatchQueue.main.async {
//                closure()
//            //}
//        }
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
//            completion()
//        }
//    }
//}
