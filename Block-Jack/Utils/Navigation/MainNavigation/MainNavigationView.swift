//
//  MainNavigationView.swift
//  Block-Jack
//

import SwiftUI
import UIKit
import Combine

// MARK: - View Builder (Factory)
final class MainNavigationView: CustomViewBuilder {

    static let builder = MainNavigationView()
    private init() {}

    func makeView<T>(
        _ view: T,
        withNavigationTitle title: String,
        navigationBarHidden: Bool = false,
        autoPopPrevious: Bool = false,
        isNavBarAlphaAnimationActive: Bool = false,
        backgroundImage: String = "",
        isShowRightButton: Bool = false,
        rightImage: String = "",
        rightImageSize: CGSize = CGSize(width: 24, height: 24),
        isBackAnimationActive: Bool = false,
        rightButtonAction: @escaping () -> Void = {}
    ) -> UIViewController where T: View {
        CustomHostingController(
            rootView: view,
            navigationBarTitle: title,
            navigationBarHidden: navigationBarHidden,
            autoPopPrevious: autoPopPrevious,
            isNavBarAlphaAnimationActive: isNavBarAlphaAnimationActive,
            isShowRightButton: isShowRightButton,
            rightImage: rightImage,
            rightImageSize: rightImageSize,
            rightButtonAction: rightButtonAction
        )
    }
}

// MARK: - Router Singleton
final class MainViewsRouter: Router {
    static let shared = MainViewsRouter()
    var nav: UINavigationController?

    // MARK: - Push (sağdan)
    func pushTo(view: UIViewController) {
        let transition = CATransition()
        transition.duration = 0.28
        transition.type = .push
        transition.subtype = .fromRight
        transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        nav?.view.layer.add(transition, forKey: kCATransition)
        nav?.pushViewController(view, animated: false)
    }

    // MARK: - Pop (sola geri)
    func popTo(view: UIViewController) {
        let transition = CATransition()
        transition.duration = 0.28
        transition.type = .push
        transition.subtype = .fromLeft
        transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        nav?.view.layer.add(transition, forKey: kCATransition)
        nav?.pushViewController(view, animated: false)
    }

    // MARK: - Present (modal fullscreen)
    func present(
        view: UIViewController,
        animated: Bool = true,
        presentationStyle: UIModalPresentationStyle = .fullScreen,
        transitionStyle: UIModalTransitionStyle = .coverVertical
    ) {
        view.modalPresentationStyle = presentationStyle
        view.modalTransitionStyle = transitionStyle
        (nav?.topViewController ?? nav)?.present(view, animated: animated)
    }

    // MARK: - Pop from bottom (aşağı süpürüp geri)
    func popFromBottom() {
        guard let nav = nav else { return }
        guard let snapshot = nav.view.snapshotView(afterScreenUpdates: false) else {
            nav.popViewController(animated: false)
            return
        }
        let containerView: UIView = nav.view.superview ?? nav.view
        snapshot.frame = nav.view.bounds
        containerView.addSubview(snapshot)
        nav.popViewController(animated: false)
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut]) {
            snapshot.transform = CGAffineTransform(translationX: 0, y: snapshot.bounds.height)
        } completion: { _ in
            snapshot.removeFromSuperview()
        }
    }

    // MARK: - Push from top (yukarıdan gelme)
    func pushFromTop(view: UIViewController) {
        guard let nav = nav else { return }
        guard let snapshot = nav.view.snapshotView(afterScreenUpdates: false) else {
            nav.pushViewController(view, animated: false)
            return
        }
        let containerView: UIView = nav.view.superview ?? nav.view
        snapshot.frame = nav.view.bounds
        containerView.addSubview(snapshot)
        nav.pushViewController(view, animated: false)
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut]) {
            snapshot.transform = CGAffineTransform(translationX: 0, y: -snapshot.bounds.height)
        } completion: { _ in
            snapshot.removeFromSuperview()
        }
    }

    // MARK: - Pop N Controller
    func popViewControllers(count: Int) {
        guard let nav = nav, count > 0, nav.viewControllers.count > count else { return }
        let transition = CATransition()
        transition.duration = 0.28
        transition.type = .push
        transition.subtype = .fromLeft
        nav.view.layer.add(transition, forKey: kCATransition)
        let targetIndex = nav.viewControllers.count - count - 1
        if targetIndex >= 0 {
            nav.popToViewController(nav.viewControllers[targetIndex], animated: false)
        }
    }
    
    // MARK: - Dismiss Modal
    func dismissModal() {
        (nav?.topViewController ?? nav)?.dismiss(animated: true)
    }
}

// MARK: - Convenience pushTo helpers
extension MainViewsRouter {

    /// SwiftUI view'ı direkt push et
    func push<V: View>(
        _ view: V,
        title: String = "",
        navBarHidden: Bool = true
    ) {
        let vc = MainNavigationView.builder.makeView(
            view,
            withNavigationTitle: title,
            navigationBarHidden: navBarHidden
        )
        pushTo(view: vc)
    }

    /// Ana menüye dön (Dashboard)
    func popToDashboard() {
        push(
            DashboardView().environmentObject(UserEnvironment.shared),
            title: "",
            navBarHidden: true
        )
    }

    /// Oyun ekranına git
    func pushToGame(slotId: Int, nodeType: NodeType? = nil) {
        push(
            GameView(slotId: slotId, nodeType: nodeType).environmentObject(UserEnvironment.shared),
            title: "",
            navBarHidden: true
        )
    }
    
    // MARK: - Pre-Game Flow Helpers
    
    func pushToSaveSlotSelection(mode: SaveSlotSelectionView.Mode) {
        let view = MainNavigationView.builder.makeView(
            SaveSlotSelectionView(mode: mode).environmentObject(UserEnvironment.shared),
            withNavigationTitle: "",
            navigationBarHidden: true
        )
        pushFromTop(view: view)
    }
    
    func pushToCharacterSelection(slotId: Int) {
        push(
            CharacterSelectionView(slotId: slotId).environmentObject(UserEnvironment.shared)
        )
    }
    
    func pushToPerkSelection(slotId: Int, characterId: String) {
        push(
            PerkSelectionView(slotId: slotId, characterId: characterId).environmentObject(UserEnvironment.shared)
        )
    }
    
    // MARK: - Map Flow Helpers (Phase 2 & 9)
    
    func pushToMap(slotId: Int) {
        push(
            MapView(slotId: slotId).environmentObject(UserEnvironment.shared)
        )
    }
    
    func pushToWorldMap(slotId: Int) {
        let vm = WorldMapViewModel(slotId: slotId, userEnv: UserEnvironment.shared)
        push(
            WorldMapView(vm: vm).environmentObject(UserEnvironment.shared)
        )
    }
    
    func popToMap(slotId: Int) {
        if let nav = nav, let mapVC = nav.viewControllers.first(where: { String(describing: type(of: $0)).contains("MapView") || String(describing: type(of: $0)).contains("MapHost") }) {
            nav.popToViewController(mapVC, animated: true)
        } else {
            pushToMap(slotId: slotId)
        }
    }
    
    func pushToMerchant(slotId: Int) {
        let vc = MainNavigationView.builder.makeView(MerchantView(slotId: slotId).environmentObject(UserEnvironment.shared), withNavigationTitle: "", navigationBarHidden: true)
        present(view: vc, animated: true, presentationStyle: .overFullScreen, transitionStyle: .crossDissolve)
    }
    
    func pushToTreasure(slotId: Int) {
        let vc = MainNavigationView.builder.makeView(TreasureRoomView(slotId: slotId).environmentObject(UserEnvironment.shared), withNavigationTitle: "", navigationBarHidden: true)
        present(view: vc, animated: true, presentationStyle: .overFullScreen, transitionStyle: .crossDissolve)
    }
    
    func pushToRest(slotId: Int) {
        let vc = MainNavigationView.builder.makeView(RestSiteView(slotId: slotId).environmentObject(UserEnvironment.shared), withNavigationTitle: "", navigationBarHidden: true)
        present(view: vc, animated: true, presentationStyle: .overFullScreen, transitionStyle: .crossDissolve)
    }
    
    func pushToMystery(slotId: Int) {
        let vc = MainNavigationView.builder.makeView(MysteryEventView(slotId: slotId).environmentObject(UserEnvironment.shared), withNavigationTitle: "", navigationBarHidden: true)
        present(view: vc, animated: true, presentationStyle: .overFullScreen, transitionStyle: .crossDissolve)
    }
}
