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
    private let cellSize: CGFloat = 26
    private let cellSpacing: CGFloat = 1
    
    init(slotId: Int, nodeType: NodeType? = nil) {
        _vm = StateObject(wrappedValue: GameViewModel(slotId: slotId, nodeType: nodeType))
    }

    var body: some View {
        ZStack {
            // Fix Background Scaling (Task 2)
            // Fix Background Scaling (Task 2)
            GeometryReader { geo in
                Image("cyber_battle_arena")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
            }
            .ignoresSafeArea()
            .blur(radius: 5)
            
            Color.black.opacity(0.6).ignoresSafeArea() // Görünürlük için karartma

            // Synthwave grid pattern (dekoratif)
            backgroundGrid

            VStack(spacing: 0) {
                // 1. Timer & Controls Bar
                timerSection

                if vm.run.round.isBossRound {
                    bossHeaderView
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                // 2. Score HUD
                ScoreHUDView(vm: vm)

                // 3. Progress bar (hedefe doğru)
                progressBar

                Spacer()

                // 4. Grid
                gridSection
                    .offset(x: vm.shakeAmount * CGFloat.random(in: -1...1), 
                            y: vm.shakeAmount * CGFloat.random(in: -1...1))
                    .animation(.none, value: vm.shakeAmount) // Immediate shake, no smoothing

                Spacer()
                
                // 5. Overdrive & Perks & Block Tray
                VStack(spacing: 12) {
                    PassivePerkHUDView(vm: vm)
                    
                    inventoryTray
                    
                    OverdriveHUDView(vm: vm)
                        .padding(.horizontal, 32)
                        
                    BlockTrayView(vm: vm)
                        .padding(.horizontal, 16)
                }
                .padding(.bottom, 32)
            }

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
                BlockTileView(block: block, tileSize: cellSize)
                    .scaleEffect(0.85) // Görsel olarak ufalsın
                    .position(x: vm.dragLocation.x, y: vm.dragLocation.y - 70) // Parmağın yukarısında dursun
                    .shadow(color: block.color.color, radius: 10)
                    .ignoresSafeArea()
            }
            
            // --- OVERDRIVE EXPLOSION TARGET OVERLAY ---
            if vm.isTargetingOverdrive {
                if let pos = gridPosition(from: vm.dragLocation) {
                    let step = cellSize + cellSpacing
                    // Target area = 3x3 (1 step left/right, up/down)
                    Rectangle()
                        .fill(ThemeColors.neonPink.opacity(0.4))
                        .frame(width: step * 3, height: step * 3)
                        .overlay(Rectangle().stroke(ThemeColors.neonPink, lineWidth: 2))
                        .position(
                            x: gridOrigin.x + CGFloat(pos.col) * step + step/2,
                            y: gridOrigin.y + CGFloat(pos.row) * step + step/2 - 70 // Visual offset for drag
                        )
                        .ignoresSafeArea()
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
        .navigationBarHidden(true)
    }

    // MARK: - Timer Section (with Home & Pause)
    private var timerSection: some View {
        VStack(spacing: 4) {
            HStack(spacing: 12) {
                // Home Butonu
                Button {
                    HapticManager.shared.play(.buttonTap)
                    vm.saveGameState()
                    MainViewsRouter.shared.popToDashboard()
                } label: {
                    Image("ui_home")
                        .resizable()
                        .frame(width: 36, height: 36)
                        .background(ThemeColors.surfaceDark)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(ThemeColors.gridStroke, lineWidth: 1))
                }

                // Can (Lives) Göstergesi
                HStack(spacing: 3) {
                    ForEach(1...vm.run.maxLives, id: \.self) { i in
                        Image(systemName: i <= vm.run.lives ? "heart.fill" : "heart")
                            .font(.system(size: 10))
                            .foregroundStyle(i <= vm.run.lives ? ThemeColors.neonPink : ThemeColors.gridStroke)
                            .scaleEffect(i == vm.run.lives && vm.run.lives < 3 ? 1.2 : 1.0)
                            .animation(.spring(response: 0.3), value: vm.run.lives)
                    }
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 11))
                        .foregroundStyle(vm.timer.ratio < 0.15 ? ThemeColors.neonPink : ThemeColors.textSecondary)
                    Text(String(format: "%.1f", vm.timer.timeRemaining))
                        .font(.setCustomFont(name: .InterBold, size: 14))
                        .foregroundStyle(ThemeColors.timerColor(ratio: vm.timer.ratio))
                        .contentTransition(.numericText())
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(vm.timer.ratio < 0.15 ? ThemeColors.neonPink.opacity(0.15) : Color.clear)
                )
                .overlay(
                    Capsule().stroke(vm.timer.ratio < 0.15 ? ThemeColors.neonPink.opacity(0.4) : Color.clear, lineWidth: 1)
                )
                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: vm.timer.ratio < 0.15)
                
                Spacer()

                // Pause butonu
                Button {
                    vm.pauseGame()
                    HapticManager.shared.play(.buttonTap)
                } label: {
                    Image("ui_pause")
                        .resizable()
                        .frame(width: 36, height: 36)
                        .background(ThemeColors.surfaceDark)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(ThemeColors.gridStroke, lineWidth: 1))
                }
            }
            .padding(.horizontal, 20)

            TimerBarView(
                ratio: vm.timer.ratio,
                isFogMode: vm.run.round.modifier == .fog
            )
            .padding(.horizontal, 16)
        }
        .padding(.top, 8)
    }

    // MARK: - Progress Bar
    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(ThemeColors.gridDark).frame(height: 4)
                Capsule()
                    .fill(ThemeColors.neonCyanGradient)
                    .frame(width: geo.size.width * vm.run.scoreProgress, height: 4)
                    .animation(.spring(response: 0.4), value: vm.run.scoreProgress)
            }
        }
        .frame(height: 4)
        .padding(.horizontal, 20)
        .padding(.top, 6)
    }

    // MARK: - Grid Section
    private var gridSection: some View {
        ZStack {
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
                    }
                )
                .contentShape(Rectangle())
        }
        .padding(.horizontal, 12)
        .onChange(of: vm.dragLocation) { newLocation in
            if vm.isDragging {
                let pos = gridPosition(from: newLocation)
                vm.updateDrag(location: newLocation, gridPosition: pos)
            } else if vm.isTargetingOverdrive {
                // Sadece tetikleme izleme (görsel target için hesaplanacak ama vm'e ekstra gitmesi gerekmiyor)
            }
        }
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
    private func gridPosition(from globalPoint: CGPoint) -> GridPosition? {
        let step = cellSize + cellSpacing
        
        // Eğer bir blok sürükleniyorsa onun boyutlarını al, yoksa (overdrive vb.) 1x1 varsay
        let blockRows = vm.draggingBlock?.rows ?? 1
        let blockCols = vm.draggingBlock?.cols ?? 1
        
        // Blok görsel olarak parmağın 70px yukarısına çizildiği için (y - 70), mantıksal kontrolü de yukarı kaydırıyoruz.
        let localX = globalPoint.x - gridOrigin.x
        let localY = (globalPoint.y - 70) - gridOrigin.y
        
        // Bloğun merkezini parmağa hizalamak için top-left anchor'ı geriye doğru hesaplıyoruz
        // (BlockTileView merkezlendiği için yarım boyut kadar ofsetliyoruz)
        let anchorX = localX - (CGFloat(blockCols) * step) / 2
        let anchorY = localY - (CGFloat(blockRows) * step) / 2
        
        // Int(...) yerine round(...) kullanarak %50'den fazla girdiğinde o hücreye "mıknatıslanmasını" sağlıyoruz
        let col = Int(round(anchorX / step))
        let row = Int(round(anchorY / step))

        // Geçerli grid sınırları içinde mi?
        guard row > -5, row < BoardViewModel.size + 5,
              col > -5, col < BoardViewModel.size + 5 else { return nil }

        return GridPosition(row: row, col: col)
    }
    
    // MARK: - Boss Header
    private var bossHeaderView: some View {
        HStack(spacing: 12) {
            Image(vm.currentBoss.imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 44, height: 44)
                .clipShape(Circle())
                .overlay(Circle().stroke(ThemeColors.neonPink, lineWidth: 1))
                .shadow(color: ThemeColors.neonPink.opacity(0.5), radius: 5)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("BÖLÜM PATRONU")
                    .font(.setCustomFont(name: .InterBlack, size: 10))
                    .foregroundStyle(ThemeColors.neonPink)
                    .tracking(2)
                
                Text(vm.currentBoss.name)
                    .font(.setCustomFont(name: .InterExtraBold, size: 18))
                    .foregroundStyle(.white)
            }
            
            Spacer()
            
            // Phase indicator or static "FIGHT"
            Text("DUEL")
                .font(.setCustomFont(name: .InterBlack, size: 12))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(ThemeColors.neonPink.opacity(0.2))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(ThemeColors.neonPink, lineWidth: 1))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(
            LinearGradient(colors: [ThemeColors.neonPink.opacity(0.15), .clear], startPoint: .top, endPoint: .bottom)
        )
    }

    // MARK: - Inventory Tray
    private var inventoryTray: some View {
        Group {
            if !vm.run.inventory.isEmpty {
                HStack(spacing: 12) {
                    ForEach(vm.run.inventory) { item in
                        Button(action: {
                            withAnimation(.spring()) {
                                vm.useItem(item)
                            }
                        }) {
                            VStack(spacing: 2) {
                                Text(item.icon)
                                    .font(.title3)
                                Text(item.name)
                                    .font(.system(size: 8))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .frame(width: 50, height: 50)
                            .background(.ultraThinMaterial)
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.2), lineWidth: 1))
                            .shadow(color: .black.opacity(0.3), radius: 3)
                        }
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.black.opacity(0.3))
                .cornerRadius(15)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                EmptyView()
            }
        }
    }
}
