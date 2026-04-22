//
//  GameView.swift
//  Block-Jack
//

import SwiftUI

struct GameView: View {
    @StateObject private var vm: GameViewModel
    @EnvironmentObject var userEnv: UserEnvironment
    @Environment(\.dismiss) var dismiss

    // Grid placement için coordinate space
    @State private var gridOrigin: CGPoint = .zero
    private let cellSize: CGFloat = 24
    private let cellSpacing: CGFloat = 1
    
    // Drag overlay için — vm.dragLocation'dan ayrı tutulur (performans!)
    @State private var dragPosition: CGPoint = .zero
    
    // Partikül sistemi
    @StateObject private var particleManager = ClearParticleManager()
    
    init(slotId: Int, nodeType: NodeType? = nil) {
        _vm = StateObject(wrappedValue: GameViewModel(slotId: slotId, nodeType: nodeType))
    }

    var body: some View {
        ZStack {
            // Performans: Arkaplan katmanları tek `drawingGroup(opaque: true)`
            // altında cache'leniyor. Eskiden her oyun frame'inde blur(5) + Canvas
            // grid çizimi yeniden yapılıyordu → fps kaynağı.
            //
            // `.drawingGroup` static içeriği (image + darken + canvas grid)
            // tek off-screen bitmap'e render eder, sonra onu ekrana blit eder.
            ZStack {
                GeometryReader { geo in
                    Image("cyber_battle_arena")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                        .blur(radius: 5)
                }
                Color.black.opacity(0.6)
                backgroundGrid
            }
            .ignoresSafeArea()
            .drawingGroup(opaque: true)
            .allowsHitTesting(false)

            // MARK: - MAIN LAYOUT (UI REVIZE)
            // Dikey bütçe (doc): HUD 44 + barLine 12 + score 32 + enemy 44 + grid ≥220 + overdrive 48 + tray 80
            // ScrollView yok — her şey ekrana sığmalı.
            VStack(spacing: GameLayout.sectionSpacing) {
                // 1) TEK ŞERİT HUD — karakter | bölüm | süre
                TopHUDBar(vm: vm)

                // 2) CAN + ZAMAN BARI — tek ince şerit
                LifeAndTimerStrip(vm: vm)

                // Boss header (sadece boss round'larda) — kompakt şerit
                if vm.run.round.isBossRound {
                    bossHeaderView
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                // 3) SKOR SATIRI — kompakt (içinde ilerleme çubuğu da)
                VStack(spacing: 4) {
                    ScoreHUDView(vm: vm)
                    progressBar
                        .padding(.horizontal, GameLayout.horizontalPadding)
                }

                // AAA: Boss Intent (varsa)
                if let intent = vm.bossIntent {
                    BossIntentPill(text: intent)
                        .padding(.top, 2)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                // 4) DÜŞMAN BANNER — kompakt, 44pt (sadece aktif atak varken)
                if vm.enemy.currentAttack != nil {
                    EnemyHUDView(vm: vm)
                        .padding(.horizontal, GameLayout.horizontalPadding)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }

                // 5) AKTİF PERKLER — yatay tek şerit
                PassivePerkHUDView(vm: vm)

                // Consumable inventory (item varsa)
                inventoryTray

                Spacer(minLength: 0)

                // 6) GRID + Partikül
                // Kart dekoru dış wrapper — grid'in kendi boyutuna dokunmuyor,
                // drag koordinatları doğru kalıyor.
                ZStack(alignment: .topLeading) {
                    gridSection
                        // Performans: body içinde CGFloat.random(...) çağrısı
                        // her re-render'da yeni değer üretiyor, shakeAmount
                        // spring ile 0'a dönerken sürekli body invalidate
                        // döngüsü oluşturuyordu. Deterministic offset ile
                        // aynı görsel shake hissi, sıfır reactive storm.
                        .offset(x: vm.shakeAmount * 0.6,
                                y: -vm.shakeAmount * 0.85)
                        .animation(.none, value: vm.shakeAmount)

                    ClearParticleOverlayView(manager: particleManager)
                        .offset(x: gridOrigin.x, y: gridOrigin.y)
                        .allowsHitTesting(false)
                }
                .padding(6)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(ThemeColors.cellEmpty.opacity(0.5))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(ThemeColors.cardBorder, lineWidth: 1)
                        )
                )
                .padding(.horizontal, GameLayout.horizontalPadding)

                Spacer(minLength: 0)

                // 7) OVERDRIVE — kompakt kart
                OverdriveHUDView(vm: vm, onDragChanged: { newLocation in
                    dragPosition = newLocation
                })
                .padding(.horizontal, GameLayout.horizontalPadding)

                // 8) BLOK TEPSİSİ — overflow fix (GeometryReader içinde)
                BlockTrayView(vm: vm, onDragChanged: { newLocation in
                    dragPosition = newLocation
                })
                .padding(.horizontal, GameLayout.horizontalPadding)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            vm.enemy.isTrayLocked ? ThemeColors.electricYellow : Color.clear,
                            lineWidth: 2
                        )
                        .padding(.horizontal, GameLayout.horizontalPadding)
                        .allowsHitTesting(false)
                )
            }
            .padding(.bottom, 10)

            // Score popupları
            ForEach(vm.scorePopups) { popup in
                ScorePopupView(popup: popup)
                    .position(popup.position)
            }
            
            // --- BIG COMBO LABEL ---
            if let bigLabel = vm.showBigComboLabel {
                VStack(spacing: 6) {
                    Text(bigLabel)
                        .font(.setCustomFont(name: .InterBlack, size: 42))
                        .foregroundStyle(.white)
                        .shadow(color: vm.run.streak >= 5 ? ThemeColors.neonPink : ThemeColors.electricYellow, radius: 15)
                        .shadow(color: ThemeColors.neonPink, radius: 5)
                }
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.2).combined(with: .opacity),
                    removal: .scale(scale: 1.5).combined(with: .opacity)
                ))
                .zIndex(100)
                .animation(.spring(response: 0.3), value: vm.run.streak)
            }

            // --- DRAG OVERLAY (BLOCK) ---
            if vm.isDragging, let block = vm.draggingBlock {
                BlockTileView(block: block, tileSize: cellSize * 1.1)
                    .scaleEffect(0.9)
                    .opacity(0.9)
                    .position(x: dragPosition.x, y: dragPosition.y - 80) // Offset further from finger
                    .shadow(color: block.color.color.opacity(0.6), radius: 15)
                    .ignoresSafeArea()
                    .transition(.opacity)
            }
            
            // --- OVERDRIVE EXPLOSION TARGET OVERLAY ---
            if vm.isTargetingOverdrive {
                if let pos = targetingGridPosition(from: dragPosition) {
                    let step = cellSize + cellSpacing
                    RoundedRectangle(cornerRadius: 4)
                        .fill(ThemeColors.neonPink.opacity(0.35))
                        .frame(width: step * 3, height: step * 3)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(ThemeColors.neonPink, lineWidth: 2)
                                .shadow(color: ThemeColors.neonPink, radius: 8)
                        )
                        .position(
                            x: gridOrigin.x + CGFloat(pos.col) * step + step / 2,
                            y: gridOrigin.y + CGFloat(pos.row) * step + step / 2
                        )
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                }
            }

            // Overlay'ler
            if vm.phase == .roundComplete {
                BattleRewardView(slotId: vm.activeSlotId) {
                    dismiss()
                }
            }
            if vm.phase == .bossIntro {
                BossIntroOverlay(vm: vm)
            }
            if vm.phase == .chapterComplete {
                ChapterCompleteOverlay(vm: vm)
            }
            
            // Tutorial Overlay (independent of phase, but pauses game)
            if vm.showTutorial {
                TutorialOverlay(vm: vm)
                    .zIndex(200)
            }
            
            // --- FULL SCREEN FLASH (Juiciness) ---
            Color.white
                .opacity(vm.flashOpacity)
                .ignoresSafeArea()
                .allowsHitTesting(false)
                .zIndex(300)
            if vm.phase == .bossDialogue {
                BossDialogueOverlay(vm: vm, boss: vm.currentBoss)
            }
            if vm.phase == .gameOver {
                GameOverOverlay(vm: vm)
            }
            if vm.phase == .paused {
                PauseOverlay(vm: vm)
            }
            
            // --- DÜŞMAN SALDIRI UYARISI ---
            if vm.showEnemyAttackWarning && vm.phase == .playing {
                EnemyAttackWarningOverlay(vm: vm)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.85).combined(with: .opacity),
                        removal: .opacity
                    ))
                    .zIndex(50)
                    .animation(.spring(response: 0.3), value: vm.showEnemyAttackWarning)
            }
        }
        .onAppear {
            if vm.run.round.isBossRound {
                AudioManager.shared.playMusic(.boss)
            } else {
                AudioManager.shared.playMusic(.battle)
            }
            
            vm.gridSpaceConverter = self.gridPosition(from:)
            if vm.phase == .menu {
                vm.startRound()
            }
        }
        .onChange(of: vm.particleBurst) { oldValue, event in
            guard let event = event else { return }
            let step = cellSize + cellSpacing
            
            switch event.kind {
            case .lineClear(let positions, let color):
                particleManager.emitLineClear(
                    positions: positions,
                    cellSize: cellSize,
                    spacing: cellSpacing,
                    burstColor: color
                )
            case .zoneBlast(let centerRow, let centerCol, let radius, let color):
                let cx = CGFloat(centerCol) * step + cellSize / 2
                let cy = CGFloat(centerRow) * step + cellSize / 2
                particleManager.emitZoneBlast(centerX: cx, centerY: cy, radius: radius, color: color)
                
            case .overdriveBoom(let centerRow, let centerCol):
                let cx = CGFloat(centerCol) * step + cellSize / 2
                let cy = CGFloat(centerRow) * step + cellSize / 2
                particleManager.emitOverdriveBoom(centerX: cx, centerY: cy)
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Progress Bar (hedef puan ilerlemesi)
    /// Top HUD altında ince bir progress bar — kullanıcı hedefe yaklaştıkça dolan cyan bar.
    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(ThemeColors.gridDark)
                    .frame(height: 4)

                Capsule()
                    .fill(ThemeColors.neonCyanGradient)
                    .frame(width: geo.size.width * vm.run.scoreProgress, height: 4)
                    .animation(.spring(response: 0.4), value: vm.run.scoreProgress)
            }
        }
        .frame(height: 4)
    }

    // MARK: - Grid Section
    /// NOT: GridView'e PADDING UYGULANMAMALI — gridOrigin kayarsa drag/ghost/overdrive
    /// targeting yanlış hücreye düşer. Kart dekoru dış wrapper'da.
    private var gridSection: some View {
        GridView(
            board: vm.board,
            cellSize: cellSize,
            isPhantomMode: vm.run.round.modifier == .phantom,
            isPhantomVisible: vm.isPhantomVisible,
            flashPositions: vm.clearFlashPositions
        )
        .background(
            GeometryReader { geo in
                Color.clear.onAppear {
                    gridOrigin = geo.frame(in: .global).origin
                }
                .onChange(of: geo.frame(in: .global).origin) { _, newOrigin in
                    gridOrigin = newOrigin
                }
            }
        )
        .contentShape(Rectangle())
    }

    // MARK: - Background grid pattern (dekoratif)
    private var backgroundGrid: some View {
        Canvas { ctx, size in
            let spacing: CGFloat = 30
            for x in stride(from: 0, through: size.width, by: spacing) {
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                ctx.stroke(path, with: .color(ThemeColors.gridStroke.opacity(0.15)), lineWidth: 0.5)
            }
            for y in stride(from: 0, through: size.height, by: spacing) {
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                ctx.stroke(path, with: .color(ThemeColors.gridStroke.opacity(0.15)), lineWidth: 0.5)
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Coordinate conversion
    
    /// Blok sürükleme için: 80px yukarı offset + blok merkez hizalama
    private func gridPosition(from globalPoint: CGPoint) -> GridPosition? {
        let step = cellSize + cellSpacing
        
        // Overdrive hedefleme modunda ayrı hesaplama kullan
        if vm.isTargetingOverdrive {
            return targetingGridPosition(from: globalPoint)
        }
        
        let blockRows = vm.draggingBlock?.rows ?? 1
        let blockCols = vm.draggingBlock?.cols ?? 1
        
        // Offset mapping: 80px above the finger (blok sürükleme)
        let localX = globalPoint.x - gridOrigin.x
        let localY = (globalPoint.y - 80) - gridOrigin.y
        
        let anchorX = localX - (CGFloat(blockCols) * step) / 2
        let anchorY = localY - (CGFloat(blockRows) * step) / 2
        
        let col = Int(round(anchorX / step))
        let row = Int(round(anchorY / step))

        guard row > -2, row < BoardViewModel.size + 1,
              col > -2, col < BoardViewModel.size + 1 else { return nil }

        return GridPosition(row: row, col: col)
    }
    
    /// Overdrive hedefleme için: DOĞRUDAN parmak altındaki hücreyi döndürür (offset yok)
    private func targetingGridPosition(from globalPoint: CGPoint) -> GridPosition? {
        let step = cellSize + cellSpacing
        let localX = globalPoint.x - gridOrigin.x
        let localY = globalPoint.y - gridOrigin.y
        let col = Int(round((localX - step / 2) / step))
        let row = Int(round((localY - step / 2) / step))
        guard row >= 0, row < BoardViewModel.size,
              col >= 0, col < BoardViewModel.size else { return nil }
        return GridPosition(row: row, col: col)
    }
    
    // MARK: - Boss Header (UI Revize — kompakt 44pt boss şeridi)
    private var bossHeaderView: some View {
        HStack(spacing: 10) {
            Image(vm.currentBoss.imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 34, height: 34)
                .clipShape(Circle())
                .overlay(Circle().stroke(ThemeColors.neonPink, lineWidth: 1))
                .shadow(color: ThemeColors.neonPink.opacity(0.5), radius: 4)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(userEnv.localizedString("BÖLÜM PATRONU", "CHAPTER BOSS"))
                    .font(.setCustomFont(name: .InterBlack, size: 9))
                    .foregroundStyle(ThemeColors.neonPink)
                    .tracking(1.8)
                
                Text(vm.currentBoss.name)
                    .font(.setCustomFont(name: .InterExtraBold, size: 14))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }
            
            Spacer(minLength: 6)
            
            Text("DUEL")
                .font(.setCustomFont(name: .InterBlack, size: 10))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(ThemeColors.neonPink.opacity(0.2))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(ThemeColors.neonPink, lineWidth: 1))
        }
        .padding(.horizontal, GameLayout.horizontalPadding)
        .padding(.vertical, 6)
        .background(
            LinearGradient(
                colors: [ThemeColors.neonPink.opacity(0.18), .clear],
                startPoint: .top, endPoint: .bottom
            )
        )
    }

    // MARK: - Inventory Tray (consumable item'lar — yeni UI dili)
    @ViewBuilder
    private var inventoryTray: some View {
        if !vm.run.inventory.isEmpty {
            HStack(spacing: 6) {
                ForEach(vm.run.inventory) { item in
                    Button {
                        withAnimation(.spring()) {
                            vm.useItem(item)
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(item.icon)
                                .font(.system(size: 16))
                            Text(item.name)
                                .font(.setCustomFont(name: .InterBold, size: 9))
                                .foregroundColor(.white)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(
                            Capsule().fill(ThemeColors.cardBg)
                        )
                        .overlay(
                            Capsule().stroke(ThemeColors.cardBorder, lineWidth: 1)
                        )
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, GameLayout.horizontalPadding)
            .transition(.move(edge: .trailing).combined(with: .opacity))
        }
    }
}
