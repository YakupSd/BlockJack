//
//  RootNavigationController.swift
//  Block-Jack
//

import SwiftUI

// UINavigationController'ı SwiftUI içinde kullanmak için wrapper
struct RootNavigationController<RootView: View>: UIViewControllerRepresentable {

    let nav: UINavigationController
    let rootView: RootView
    let navigationBarTitle: String
    let navigationBarHidden: Bool
    let isNavBarAlphaAnimationActive: Bool
    let isShowRightButton: Bool
    var rightImage: String
    let autoPopPrevious: Bool
    var rightButtonAction: () -> Void

    init(
        nav: UINavigationController,
        rootView: RootView,
        navigationBarTitle: String,
        navigationBarHidden: Bool = false,
        isNavBarAlphaAnimationActive: Bool = false,
        isShowRightButton: Bool = false,
        rightImage: String = "",
        autoPopPrevious: Bool = false,
        rightButtonAction: @escaping () -> Void = {}
    ) {
        self.nav = nav
        self.rootView = rootView
        self.navigationBarTitle = navigationBarTitle
        self.navigationBarHidden = navigationBarHidden
        self.isNavBarAlphaAnimationActive = isNavBarAlphaAnimationActive
        self.isShowRightButton = isShowRightButton
        self.rightImage = rightImage
        self.autoPopPrevious = autoPopPrevious
        self.rightButtonAction = rightButtonAction
    }

    func makeUIViewController(context: Context) -> UINavigationController {
        let vc = CustomHostingController(
            rootView: rootView,
            navigationBarTitle: navigationBarTitle,
            navigationBarHidden: navigationBarHidden,
            autoPopPrevious: autoPopPrevious,
            isNavBarAlphaAnimationActive: isNavBarAlphaAnimationActive,
            isShowRightButton: isShowRightButton,
            rightImage: rightImage,
            rightButtonAction: rightButtonAction
        )

        nav.viewControllers = [vc]
        nav.navigationBar.layer.masksToBounds = false
        nav.delegate = context.coordinator

        // Block-Jack: dark arka plan
        nav.view.backgroundColor = UIColor(ThemeColors.cosmicBlack)

        return nav
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    // MARK: - Coordinator
    class Coordinator: NSObject, UINavigationControllerDelegate {
        var parent: RootNavigationController

        init(_ parent: RootNavigationController) {
            self.parent = parent
        }

        func navigationController(
            _ navigationController: UINavigationController,
            willShow viewController: UIViewController,
            animated: Bool
        ) {
            navigationController.view.frame = UIScreen.main.bounds
            navigationController.navigationBar.isTranslucent = false
            navigationController.view.backgroundColor = UIColor(ThemeColors.cosmicBlack)

            let title = viewController.title ?? ""
            let fontSize: CGFloat = title.count > 20 ? 14 : 17

            navigationController.navigationBar.titleTextAttributes = [
                .font: UIFont.setCustomUIFont(name: .InterBold, size: fontSize),
                .foregroundColor: UIColor.white
            ]
            navigationController.navigationBar.tintColor = UIColor(ThemeColors.neonCyan)
        }
    }
}
