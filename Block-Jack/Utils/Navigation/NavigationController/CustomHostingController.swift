//
//  CustomHostingController.swift
//  Block-Jack
//

import SwiftUI

class CustomHostingController<Content>: UIHostingController<AnyView> where Content: View {
    var shouldShowBackgroundImage = false
    var isShowRightButton = false
    var autoPopPrevious: Bool = false
    var rightImage = ""
    var rightImageSize = CGSize(width: 24, height: 24)
    var navigationBarHidden = false
    var isNavBarAlphaAnimationActive = true
    var rightButtonAction: () -> Void = {}

    public init(
        rootView: Content,
        navigationBarTitle: String,
        navigationBarHidden: Bool = false,
        autoPopPrevious: Bool = false,
        isNavBarAlphaAnimationActive: Bool = false,
        backgroundImage: String = "",
        isShowRightButton: Bool = false,
        rightImage: String = "",
        rightImageSize: CGSize = CGSize(width: 24, height: 24),
        rightButtonAction: @escaping () -> Void = {}
    ) {
        super.init(rootView: AnyView(rootView))
        self.title = navigationBarTitle
        self.shouldShowBackgroundImage = navigationBarHidden
        self.navigationBarHidden = navigationBarHidden
        self.isShowRightButton = isShowRightButton
        self.rightImage = rightImage
        self.rightImageSize = rightImageSize
        self.rightButtonAction = rightButtonAction
        self.isNavBarAlphaAnimationActive = isNavBarAlphaAnimationActive
        self.autoPopPrevious = autoPopPrevious
    }

    @available(*, unavailable)
    @objc dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        // Sol üstteki "<" chevron dahil tüm geri UI'sını gizle. Dashboard
        // gibi root ekranlarda sistem back butonu kafa karıştırıcı
        // oluyordu.
        navigationItem.hidesBackButton = true
        navigationItem.setHidesBackButton(true, animated: false)
        UIScrollView.appearance().bounces = false

        guard let nav = navigationController else { return }
        // navigationBarHidden parametresini gerçekten uygula. Eskiden
        // yalnızca depolanıyor ama hiç set edilmiyordu → nav bar her yerde
        // görünür kalıyordu. Her `viewWillAppear`'da ayarlıyoruz çünkü
        // stack içindeki diğer VC'ler bu state'i değiştiriyor olabilir.
        nav.setNavigationBarHidden(self.navigationBarHidden, animated: animated)

        let backButtonAppearance = UIBarButtonItemAppearance()
        backButtonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.clear]

        // Block-Jack: Synthwave dark nav bar
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(ThemeColors.surfaceDark)
        appearance.shadowColor = .clear
        appearance.backButtonAppearance = backButtonAppearance

        let fontSize: CGFloat = (self.title?.count ?? 0) > 20 ? 14 : 17
        appearance.titleTextAttributes = [
            .font: UIFont.setCustomUIFont(name: .InterBold, size: fontSize),
            .foregroundColor: UIColor.white
        ]

        nav.navigationBar.standardAppearance = appearance
        nav.navigationBar.scrollEdgeAppearance = appearance
        nav.navigationBar.tintColor = UIColor(ThemeColors.neonCyan)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(ThemeColors.cosmicBlack)

        if isShowRightButton && !rightImage.isEmpty {
            let rightButton = UIBarButtonItem(customView: createRightButton(image: rightImage))
            navigationItem.setRightBarButton(rightButton, animated: false)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        disableBackLongPressMenuIfPossible()

        if autoPopPrevious,
           var viewControllers = navigationController?.viewControllers,
           viewControllers.count >= 2 {
            viewControllers.remove(at: viewControllers.count - 2)
            navigationController?.viewControllers = viewControllers
        }
    }

    // MARK: - Private Helpers

    private func disableBackLongPressMenuIfPossible() {
        guard let navBar = navigationController?.navigationBar else { return }
        DispatchQueue.main.async { [weak navBar] in
            guard let navBar = navBar else { return }
            func walk(_ view: UIView) {
                view.gestureRecognizers?.forEach { gesture in
                    if gesture is UILongPressGestureRecognizer { gesture.isEnabled = false }
                }
                view.interactions
                    .filter { $0 is UIContextMenuInteraction }
                    .forEach { view.removeInteraction($0) }
                view.subviews.forEach(walk)
            }
            walk(navBar)
        }
    }

    private func createRightButton(image: String) -> UIButton {
        let button = UIButton(type: .custom)
        if let img = UIImage(named: image) {
            button.setImage(img.resize(targetSize: rightImageSize), for: .normal)
        }
        button.imageView?.contentMode = .scaleAspectFit
        button.tintColor = UIColor(ThemeColors.neonCyan)
        button.addTarget(self, action: #selector(rightButtonTapped), for: .touchUpInside)
        return button
    }

    @objc func rightButtonTapped() { rightButtonAction() }
}

// MARK: - UIImage resize
extension UIImage {
    func resize(targetSize: CGSize) -> UIImage {
        UIGraphicsImageRenderer(size: targetSize).image { _ in
            draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}
