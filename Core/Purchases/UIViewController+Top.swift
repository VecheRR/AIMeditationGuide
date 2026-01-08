//
//  UIViewController+Top.swift
//  AIMeditationGuide
//
//  Created by  Vladislav on 07.01.2026.
//

import UIKit

extension UIApplication {
    var topViewController: UIViewController? {
        guard
            let scene = connectedScenes.first as? UIWindowScene,
            let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController
        else { return nil }

        return root.topMost
    }
}

private extension UIViewController {
    var topMost: UIViewController {
        if let presented = presentedViewController { return presented.topMost }
        if let nav = self as? UINavigationController { return nav.visibleViewController?.topMost ?? nav }
        if let tab = self as? UITabBarController { return tab.selectedViewController?.topMost ?? tab }
        return self
    }
}
