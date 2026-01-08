//
//  TopMostViewController.swift
//  AIMeditationGuide
//
//  Created by  Vladislav on 07.01.2026.
//

import UIKit

extension UIApplication {
    var topMostViewController: UIViewController? {
        guard
            let scene = connectedScenes.first as? UIWindowScene,
            let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController
        else { return nil }

        return root.topMost
    }
}

private extension UIViewController {
    var topMost: UIViewController {
        if let presented = presentedViewController {
            return presented.topMost
        }
        if let nav = self as? UINavigationController, let visible = nav.visibleViewController {
            return visible.topMost
        }
        if let tab = self as? UITabBarController, let selected = tab.selectedViewController {
            return selected.topMost
        }
        return self
    }
}
