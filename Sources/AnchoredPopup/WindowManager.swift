//
//  WindowManager.swift
//  Beyond
//
//  Created by Alisa Mylnikova on 19.12.2024.
//

import SwiftUI

@MainActor
final class WindowManager {
	static let shared = WindowManager()
    private var windows: [String: UIWindow] = [:]

    static func openNewWindow<Content: View>(id: String, content: ()->Content) {
		guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
			print("No valid scene available")
			return
		}

//        if shared.windows.contains(where: { $0.key == id }) {
//            return
//        }

        print("openNewWindow", id)
		let window = UIWindow(windowScene: scene)
		window.backgroundColor = .clear
		let controller = UIHostingController(rootView: content()
            .environment(\.anchoredPopupDismiss) {
                Task {
                    await AnchoredAnimationManager.shared.changeStateForAnimation(for: id, state: .shrinking)
                }
            })
		controller.view.backgroundColor = .clear
		window.rootViewController = controller
		window.windowLevel = .alert + 1
		window.makeKeyAndVisible()
        shared.windows[id] = window
	}

    static func closeWindow(id: String) {
        print("closeWindow", id)
        shared.windows[id]?.isHidden = true
        shared.windows.removeValue(forKey: id)
	}
}
