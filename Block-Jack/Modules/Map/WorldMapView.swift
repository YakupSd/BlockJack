//
//  WorldMapView.swift
//  Block-Jack
//
//  Sefer (kampanya) haritası. Şu anki içerik DÜNYA 1 — NEON CYBERPUNK
//  teması. 20 sektör, zigzag snake layout, hexagonal neon node'lar.
//
//  Tema geçişi notu:
//  Dünya 2+ eklendiğinde burada basit bir tema switch ile (ör. enum)
//  piksel variant'a (WorldMapPixelBackgroundView + WorldCityNodeView)
//  veya başka dünyaya özel view'lara yönlendirme yapılacak. Mevcut
//  piksel dosyalar kenarda yedekte duruyor — silinmedi.
//
//  NOT: Sadece view katmanı. Game logic / ViewModel iş kuralları değişmiyor.
//

import SwiftUI

struct WorldMapView: View {
    @StateObject var vm: WorldMapViewModel
    @EnvironmentObject var userEnv: UserEnvironment
    @Environment(\.dismiss) private var dismiss
    @State private var didInitialScroll = false

    // Haritanın toplam dikey uzunluğu — 20 sektör için ScrollView içinde
    // rahat görünüm (aynı zamanda SE ekranında da hissedilir uzunluk).
    private let mapHeight: CGFloat = 1400

    var body: some View {
        ZStack {
            // Tema-aware arka plan: aktif dünyaya göre görsel dil değişir.
            // Dünya 1 Neon Cyber, Dünya 2 Concrete Ruins; diğer dünyalar
            // henüz render edilmedi → fallback olarak neon görünüyor.
            themedBackground

            // Ana harita içeriği — scrollable, altta başlar.
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    mapCanvas
                        .id("worldMapAnchor")
                        .padding(.top, 80)      // üst HUD altı
                        .padding(.bottom, 110)  // alt bar üstü
                }
                // Oyuncunun mevcut sektörüne fokuslan. İki aşamalı scroll:
                // - .task ilk yüklemede (layout hazır olana kadar 350ms bekle)
                // - playerLevelId değişirse (yeni bölüm kilidi açıldıysa) tekrar
                // Anchor id'i önce specific ("level_X") sonra generic ("playerNode")
                // olarak dener; böylece absolute-positioned node'larda
                // ScrollViewReader'ın kararsız davranışı üçlü fallback ile tolere
                // edilir.
                .task(id: vm.playerLevelId) {
                    try? await Task.sleep(nanoseconds: 350_000_000)
                    await focusOnPlayer(proxy: proxy)
                    // Bazı cihazlarda ilk scroll layout tamamlanmadan önce
                    // kaybolabiliyor; ikinci bir retry ile garantileyelim.
                    try? await Task.sleep(nanoseconds: 250_000_000)
                    await focusOnPlayer(proxy: proxy, animated: false)
                    didInitialScroll = true
                }
            }

            // CRT / scan efekti — sabit overlay, tüm haritanın üstünde
            WorldMapNeonScanline()
                .blendMode(.multiply)
                .opacity(0.5)

            VStack(spacing: 0) {
                WorldMapHUDView(vm: vm) {
                    HapticManager.shared.play(.buttonTap)
                    dismiss()
                }
                Spacer()
                WorldMapBottomBarView(vm: vm)
            }
        }
        .navigationBarHidden(true)
        .sheet(item: $vm.selectedLevel) { level in
            WorldMapDetailSheet(
                slotId: vm.slotId,
                level: level,
                onEnter: {
                    vm.selectedLevel = nil
                    vm.startLevel(level)
                },
                onDismiss: {
                    vm.selectedLevel = nil
                }
            )
            .presentationDetents([.fraction(0.6), .large])
            .presentationDragIndicator(.visible)
            .presentationBackground(Color(hex: "#05060F"))
            .environmentObject(userEnv)
        }
    }

    // MARK: - Scroll Focus

    /// Oyuncunun bulunduğu sektöre ekranı scroll eder.
    /// Önce level-specific id ("level_X") denenir; başarısız olursa generic
    /// "playerNode" anchor'ına fallback yapar. Absolute-positioned node'larla
    /// ScrollViewReader bazen id'i geç kaydediyor — bu iki aşamalı deneme
    /// bunu tolere eder.
    @MainActor
    private func focusOnPlayer(proxy: ScrollViewProxy, animated: Bool = true) {
        let target = "level_\(vm.playerLevelId)"
        if animated {
            withAnimation(.easeOut(duration: 0.5)) {
                proxy.scrollTo(target, anchor: .center)
                proxy.scrollTo("playerNode", anchor: .center)
            }
        } else {
            proxy.scrollTo(target, anchor: .center)
            proxy.scrollTo("playerNode", anchor: .center)
        }
    }

    // MARK: - Themed Background
    @ViewBuilder
    private var themedBackground: some View {
        switch vm.currentTheme {
        case .concreteRuins:
            WorldMapConcreteBackground()
        case .candyLab:
            WorldMapCandyBackground()
        case .deepAbyss:
            WorldMapAbyssBackground()
        case .coreSingularity:
            WorldMapCoreBackground()
        case .neonGrid:
            WorldMapNeonBackground()
        }
    }

    // MARK: - Map Canvas
    private var mapCanvas: some View {
        GeometryReader { geo in
            let width = geo.size.width

            ZStack {
                // Yol (connections) — en arkada
                WorldNeonPathConnections(
                    levels: vm.levels,
                    positions: vm.nodePositions,
                    segments: vm.connections
                )
                .frame(width: width, height: mapHeight)

                // City node'ları — neon cyber variant
                // Not: .id her zaman "level_<id>" verilir; player node'unu
                // bulmak için ayrıca görünmez bir "playerNode" anchor'ı
                // koyuyoruz (aşağıda). Bu ayrım, sheet dönüşlerinde node
                // kimliğinin hot-swap yapması yüzünden scroll'un patlamamasını
                // garanti eder.
                ForEach(vm.levels) { level in
                    if let pos = vm.nodePositions[level.id] {
                        let x = pos.x * width
                        let y = pos.y * mapHeight
                        WorldCityNeonNode(
                            level: level,
                            isPlayerHere: level.id == vm.playerLevelId,
                            onTap: { vm.selectLevel(level) }
                        )
                        .position(x: x, y: y)
                        .id("level_\(level.id)")
                    }
                }

                // Player anchor — görünmez ama ScrollViewReader için sabit
                // "playerNode" id'li bir hedef. Böylece absolute-positioned
                // node'lar layout değişse bile scroll hedefi değişmez.
                if let playerPos = vm.nodePositions[vm.playerLevelId] {
                    Color.clear
                        .frame(width: 1, height: 1)
                        .position(x: playerPos.x * width, y: playerPos.y * mapHeight)
                        .id("playerNode")
                }

                // Oyuncu işaretçisi — aktif sektörün hemen üstünde hover eden
                // neon diamond cursor
                if let playerPos = vm.nodePositions[vm.playerLevelId] {
                    WorldNeonPlayerCursor()
                        .position(
                            x: playerPos.x * width,
                            y: playerPos.y * mapHeight - 30
                        )
                        .allowsHitTesting(false)
                }
            }
            .frame(width: width, height: mapHeight)
        }
        .frame(height: mapHeight)
    }
}

// MARK: - Preview
#Preview {
    WorldMapView(vm: WorldMapViewModel(slotId: 0, worldId: 1, userEnv: UserEnvironment.shared))
        .environmentObject(UserEnvironment.shared)
        .preferredColorScheme(.dark)
}
