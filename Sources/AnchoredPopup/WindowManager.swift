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
	private var newWindow: UIWindow?

	static func openNewWindow<Content: View>(content: ()->Content) {
		guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
			print("No valid scene available")
			return
		}

		let window = UIWindow(windowScene: scene)
		window.backgroundColor = .clear
		let controller = UIHostingController(rootView: content())
		controller.view.backgroundColor = .clear
		window.rootViewController = controller
		window.windowLevel = .alert + 1
		window.makeKeyAndVisible()
        shared.newWindow = window
	}

    static func closeWindow() {
        shared.newWindow?.isHidden = true
        shared.newWindow = nil
	}
}
