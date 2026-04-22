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

    /// Ana menüye dön (Dashboard). Nav stack'i tamamen Dashboard tek
    /// viewcontroller'ı kalacak şekilde sıfırlar. Daha önce `push`
    /// ediyordu, bu da [AppStartView, …, Dashboard] şeklinde birikim
    /// yaratıyor ve sistem "geri" hareketiyle AppStartView diriliyordu
    /// (v1.0.0 splash'te takılma bug'ı). Artık root olarak yerleştiriyoruz.
    func popToDashboard() {
        guard let nav = nav else { return }
        let dashboardVC = MainNavigationView.builder.makeView(
            DashboardView().environmentObject(UserEnvironment.shared),
            withNavigationTitle: "",
            navigationBarHidden: true
        )
        let transition = CATransition()
        transition.duration = 0.28
        transition.type = .push
        transition.subtype = .fromLeft
        transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        nav.view.layer.add(transition, forKey: kCATransition)
        nav.setViewControllers([dashboardVC], animated: false)
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
    
    func pushToSaveSlotSelection(mode: SaveSlotSelectionView.Mode = .newGame) {
        let view = MainNavigationView.builder.makeView(
            SaveSlotSelectionView(mode: mode).environmentObject(UserEnvironment.shared),
            withNavigationTitle: "",
            navigationBarHidden: true
        )
        pushFromTop(view: view)
    }
    
    func pushToCharacterSelection(slotId: Int, mode: CharacterSelectionView.Mode = .firstSetup) {
        push(
            CharacterSelectionView(slotId: slotId, mode: mode).environmentObject(UserEnvironment.shared)
        )
    }

    /// Slot Hub ekranına geçiş. Slot seçildikten sonra tüm Market/Karakter/
    /// Galeri ve sefere başlama aksiyonları buradan doğar. Hub içinde her
    /// ekran `slotId` taşır, böylece "hangi oyuncu için" sorusu ortadan
    /// kalkar.
    func pushToSlotHub(slotId: Int) {
        push(
            SlotHubView(slotId: slotId).environmentObject(UserEnvironment.shared)
        )
    }

    /// Run içinden (Map / GameView / GameOver overlay'leri) Ana Menü
    /// basıldığında Dashboard yerine Slot Hub'a dön. Bu sayede kullanıcı
    /// "bu slot için oynuyorum" bağlamını kaybetmiyor; Dashboard'a dönmek
    /// için Hub'daki "SLOT" butonunu kullanması gerekiyor (o da
    /// `popToDashboard` çağırır). Stack'i Dashboard + Hub iki seviyeye
    /// sıfırlıyoruz ki Hub içinden "SLOT" geri dönüşü doğru çalışsın.
    func popToSlotHub(slotId: Int) {
        guard let nav = nav else { return }
        let dashboardVC = MainNavigationView.builder.makeView(
            DashboardView().environmentObject(UserEnvironment.shared),
            withNavigationTitle: "", navigationBarHidden: true
        )
        let hubVC = MainNavigationView.builder.makeView(
            SlotHubView(slotId: slotId).environmentObject(UserEnvironment.shared),
            withNavigationTitle: "", navigationBarHidden: true
        )
        let transition = CATransition()
        transition.duration = 0.28
        transition.type = .push
        transition.subtype = .fromLeft
        transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        nav.view.layer.add(transition, forKey: kCATransition)
        nav.setViewControllers([dashboardVC, hubVC], animated: false)
    }

    /// Hub'dan ve alt ekranlardan Dashboard'a dönüş. Slot bağlamını
    /// temizler; yanlışlıkla aktif slot açık kalırsa `UserEnvironment.spend`
    /// hala o slot'a yönlendirir ve kullanıcı Dashboard'da para
    /// kaybedebilir. Bu yüzden pop öncesi temizlik şart.
    func popToDashboardFromHub() {
        UserEnvironment.shared.clearActiveSlot()
        popToDashboard()
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

    /// Bölüm bitiminde kullanılır — Dashboard + Hub + WorldMap olacak şekilde
    /// stack'i sıfırlar. Böylece WorldMap'ten geri basıldığında Slot Hub'a
    /// oradan da Dashboard'a temiz bir geri-akış oluşur. Eski `pushToWorldMap`
    /// sadece stack'in tepesine WorldMap ekliyordu; bölüm bittikten sonra
    /// "MapView → WorldMap" zincirinde geri dönüşte MapView'a çarpıp kafa
    /// karıştırıyordu.
    func popToWorldMap(slotId: Int) {
        guard let nav = nav else { return }
        let dashboardVC = MainNavigationView.builder.makeView(
            DashboardView().environmentObject(UserEnvironment.shared),
            withNavigationTitle: "", navigationBarHidden: true
        )
        let hubVC = MainNavigationView.builder.makeView(
            SlotHubView(slotId: slotId).environmentObject(UserEnvironment.shared),
            withNavigationTitle: "", navigationBarHidden: true
        )
        let vm = WorldMapViewModel(slotId: slotId, userEnv: UserEnvironment.shared)
        let worldMapVC = MainNavigationView.builder.makeView(
            WorldMapView(vm: vm).environmentObject(UserEnvironment.shared),
            withNavigationTitle: "", navigationBarHidden: true
        )
        let transition = CATransition()
        transition.duration = 0.28
        transition.type = .push
        transition.subtype = .fromLeft
        transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        nav.view.layer.add(transition, forKey: kCATransition)
        nav.setViewControllers([dashboardVC, hubVC, worldMapVC], animated: false)
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
