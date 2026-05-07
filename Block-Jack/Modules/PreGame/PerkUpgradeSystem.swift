
import SwiftUI
import Combine

// MARK: - Perk Upgrade Core Models
struct PerkUpgradeTierData {
    let tier: Int
    let goldCost: Int
    let diamondCost: Int
    let effectValue: Double
}

enum PerkUpgradeID: String, Codable, CaseIterable {
    // Category 1: Core (Tier 1 is FREE)
    case goldenStamp = "golden_stamp"
    case overkill = "overkill"
    case safeHouse = "safe_house"
    
    // Category 2: Professional (Tier 1 must be PURCHASED)
    case bluePill = "blue_pill"
    case leadPill = "lead_pill"
    case luckyClover = "lucky_clover"
    case momentum = "momentum"
    case midasTouch = "midas_touch"
    
    // Category 3: Legendary (Tier 1 must be PURCHASED)
    case wideLoad = "wide_load"
    case sculptor = "sculptor"
    case glassCannon = "glass_cannon"
    
    // Special (One-Time)
    case lastStand = "last_stand"
    case recycler = "recycler"
}

enum PerkCategory: String, CaseIterable, Codable {
    case core = "CORE"
    case professional = "PROFESSIONAL"
    case legendary = "LEGENDARY"
    case special = "SPECIAL"
    
    var title: String {
        switch self {
        case .core: return UserEnvironment.shared.localizedString("TEMEL AVANTAJLAR", "CORE PERKS")
        case .professional: return UserEnvironment.shared.localizedString("PROFESYONEL TAKVİYELER", "SPECIALTY PERKS")
        case .legendary: return UserEnvironment.shared.localizedString("EFSANEVİ YETENEKLER", "GAME-CHANGERS")
        case .special: return UserEnvironment.shared.localizedString("ÖZEL YETENEKLER", "SPECIAL PERKS")
        }
    }
    
    var isUpgradeable: Bool { self != .special }
}

struct PerkShopItem: Identifiable {
    let id: String
    let name: String
    let description: String
    let category: PerkCategory
    let icon: String
    var isComingSoon: Bool = false
}

// MARK: - Perk Registry (The Source of Truth for Costs & Effects)
struct PerkUpgradeRegistry {
    static func tierData(for id: PerkUpgradeID, tier: Int) -> PerkUpgradeTierData {
        // Guard for tier bounds
        let safeTier = max(0, min(5, tier))
        
        switch id {
        case .goldenStamp:
            let values = [0: 0.0, 1: 0.10, 2: 0.15, 3: 0.17, 4: 0.20, 5: 0.25]
            let gold = [1: 0, 2: 200, 3: 400, 4: 600, 5: 1000]
            let diamond = [1: 0, 2: 0, 3: 0, 4: 50, 5: 100]
            return PerkUpgradeTierData(tier: safeTier, goldCost: gold[safeTier] ?? 0, diamondCost: diamond[safeTier] ?? 0, effectValue: values[safeTier] ?? 0.0)
            
        case .overkill:
            let values = [0: 0.0, 1: 0.15, 2: 0.25, 3: 0.35, 4: 0.50, 5: 0.75]
            let gold = [1: 0, 2: 250, 3: 450, 4: 700, 5: 1200]
            let diamond = [1: 0, 2: 0, 3: 0, 4: 60, 5: 120]
            return PerkUpgradeTierData(tier: safeTier, goldCost: gold[safeTier] ?? 0, diamondCost: diamond[safeTier] ?? 0, effectValue: values[safeTier] ?? 0.0)
            
        case .safeHouse:
            let values = [0: 0.0, 1: 20.0, 2: 40.0, 3: 75.0, 4: 120.0, 5: 200.0]
            let gold = [1: 0, 2: 150, 3: 350, 4: 550, 5: 900]
            let diamond = [1: 0, 2: 0, 3: 0, 4: 40, 5: 80]
            return PerkUpgradeTierData(tier: safeTier, goldCost: gold[safeTier] ?? 0, diamondCost: diamond[safeTier] ?? 0, effectValue: values[safeTier] ?? 0.0)
            
        case .bluePill, .leadPill:
            let values = [0: 0.0, 1: 0.50, 2: 1.0, 3: 1.5, 4: 2.0, 5: 3.0]
            let gold = [1: 250, 2: 300, 3: 600, 4: 850, 5: 1100]
            let diamond = [1: 0, 2: 0, 3: 0, 4: 50, 5: 100]
            return PerkUpgradeTierData(tier: safeTier, goldCost: gold[safeTier] ?? 0, diamondCost: diamond[safeTier] ?? 0, effectValue: values[safeTier] ?? 0.0)
            
        case .luckyClover:
            let values = [0: 0.0, 1: 5.0, 2: 10.0, 3: 15.0, 4: 25.0, 5: 40.0]
            let gold = [1: 200, 2: 370, 3: 520, 4: 880, 5: 1150]
            let diamond = [1: 0, 2: 0, 3: 0, 4: 55, 5: 110]
            return PerkUpgradeTierData(tier: safeTier, goldCost: gold[safeTier] ?? 0, diamondCost: diamond[safeTier] ?? 0, effectValue: values[safeTier] ?? 0.0)
            
        case .momentum:
            let values = [0: 0.0, 1: 0.50, 2: 0.75, 3: 1.0, 4: 1.5, 5: 2.0]
            let gold = [1: 250, 2: 330, 3: 530, 4: 700, 5: 1200]
            let diamond = [1: 0, 2: 0, 3: 0, 4: 60, 5: 120]
            return PerkUpgradeTierData(tier: safeTier, goldCost: gold[safeTier] ?? 0, diamondCost: diamond[safeTier] ?? 0, effectValue: values[safeTier] ?? 0.0)
            
        case .midasTouch:
            let values = [0: 0.0, 1: 3.0, 2: 5.0, 3: 10.0, 4: 18.0, 5: 30.0]
            let gold = [1: 250, 2: 380, 3: 580, 4: 800, 5: 1000]
            let diamond = [1: 0, 2: 0, 3: 0, 4: 45, 5: 90]
            return PerkUpgradeTierData(tier: safeTier, goldCost: gold[safeTier] ?? 0, diamondCost: diamond[safeTier] ?? 0, effectValue: values[safeTier] ?? 0.0)
            
        case .wideLoad:
            let values = [0: 3.0, 1: 3.0, 2: 4.0, 3: 5.0, 4: 6.0, 5: 7.0]
            let gold = [1: 200, 2: 300, 3: 500, 4: 800, 5: 1400]
            let diamond = [1: 0, 2: 0, 3: 0, 4: 70, 5: 140]
            return PerkUpgradeTierData(tier: safeTier, goldCost: gold[safeTier] ?? 0, diamondCost: diamond[safeTier] ?? 0, effectValue: values[safeTier] ?? 3.0)
            
        case .sculptor:
            let values = [0: 0.0, 1: 1.0, 2: 2.0, 3: 3.0, 4: 5.0, 5: 999.0] // 999 = unlimited
            let gold = [1: 250, 2: 380, 3: 580, 4: 850, 5: 1300]
            let diamond = [1: 0, 2: 0, 3: 0, 4: 65, 5: 130]
            return PerkUpgradeTierData(tier: safeTier, goldCost: gold[safeTier] ?? 0, diamondCost: diamond[safeTier] ?? 0, effectValue: values[safeTier] ?? 0.0)
            
        case .glassCannon:
            let values = [0: 1.0, 1: 1.2, 2: 1.5, 3: 1.5, 4: 2.0, 5: 2.5]
            let gold = [1: 250, 2: 400, 3: 550, 4: 850, 5: 1500]
            let diamond = [1: 0, 2: 0, 3: 0, 4: 75, 5: 150]
            return PerkUpgradeTierData(tier: safeTier, goldCost: gold[safeTier] ?? 0, diamondCost: diamond[safeTier] ?? 0, effectValue: values[safeTier] ?? 1.0)
            
        case .lastStand:
            return PerkUpgradeTierData(tier: 1, goldCost: 500, diamondCost: 50, effectValue: 1.0)
            
        case .recycler:
            return PerkUpgradeTierData(tier: 1, goldCost: 450, diamondCost: 45, effectValue: 0.25)
        }
    }
    
    static func effectDescription(for id: PerkUpgradeID, tier: Int) -> String {
        let data = tierData(for: id, tier: tier)
        let v = data.effectValue
        
        switch id {
        case .goldenStamp: return "-\(Int(v * 100))% Target Score"
        case .overkill: return "\(Int(v * 100))% Carry Over"
        case .safeHouse: return "+\(Int(v)) Gold / Rest"
        case .bluePill: return "Blue Score x\((1.0 + v).formatted())"
        case .leadPill: return "Green Score x\((1.0 + v).formatted())"
        case .luckyClover: return "Streak Limit +\(Int(v))"
        case .momentum: return "Streak Bonus +\(Int(v * 100))%"
        case .midasTouch: return "+\(Int(v)) Gold per Flush"
        case .wideLoad: return "Storage: \(Int(v)) Blocks"
        case .sculptor: return v > 100 ? "Unlimited Rotations" : "\(Int(v)) Rotation / Round"
        case .glassCannon: 
            if tier <= 2 { return "HP=1 -> x\(v.formatted()) Score" }
            else if tier <= 4 { return "HP<=2 -> x\(v.formatted()) Score" }
            else { return "HP<=3 -> x\(v.formatted()) Score" }
        case .lastStand: return "One free revive per run"
        case .recycler: return "\(Int(v * 100))% chance to refresh storage"
        }
    }
    
    static func formattedValue(_ val: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        return formatter.string(from: NSNumber(value: val)) ?? "\(val)"
    }
}

// MARK: - Registry & Items
struct PerkShopRegistry {
    static func items(for category: PerkCategory) -> [PerkShopItem] {
        switch category {
        case .core:
            return [
                PerkShopItem(id: "golden_stamp", name: "GOLDEN STAMP", description: "Reduces target score needed to win.", category: .core, icon: "seal.fill"),
                PerkShopItem(id: "overkill", name: "OVERKILL", description: "Carries over excess score to next round.", category: .core, icon: "bolt.fill"),
                PerkShopItem(id: "safe_house", name: "SAFE HOUSE", description: "Bonus gold at rest sites.", category: .core, icon: "house.fill")
            ]
        case .professional:
            return [
                PerkShopItem(id: "blue_pill", name: "BLUE PILL", description: "Boost score from blue blocks.", category: .professional, icon: "pills.fill"),
                PerkShopItem(id: "lead_pill", name: "LEAD PILL", description: "Boost score from green blocks.", category: .professional, icon: "pills.fill"),
                PerkShopItem(id: "lucky_clover", name: "LUCKY CLOVER", description: "Higher maximum streak limit.", category: .professional, icon: "leaf.fill"),
                PerkShopItem(id: "momentum", name: "MOMENTUM", description: "Huge bonus at streak milestones.", category: .professional, icon: "speedometer"),
                PerkShopItem(id: "midas_touch", name: "MIDAS TOUCH", description: "Gold bonus for perfect flushes.", category: .professional, icon: "sparkles")
            ]
        case .legendary:
            return [
                PerkShopItem(id: "wide_load", name: "WIDE LOAD", description: "Extra storage capacity for blocks.", category: .legendary, icon: "tray.full.fill"),
                PerkShopItem(id: "sculptor", name: "SCULPTOR", description: "Allows rotating blocks during play.", category: .legendary, icon: "rotate.right.fill"),
                PerkShopItem(id: "glass_cannon", name: "GLASS CANNON", description: "Massive score boost at low health.", category: .legendary, icon: "flame.fill")
            ]
        case .special:
            return [
                PerkShopItem(id: "last_stand", name: "LAST STAND", description: "Survive a lethal hit once per run.", category: .special, icon: "heart.text.square.fill"),
                PerkShopItem(id: "recycler", name: "RECYCLER", description: "Chance to refresh tray on multi-clear.", category: .special, icon: "arrow.3.trianglepath")
            ]
        }
    }
}

// MARK: - View Model
class PerkShopViewModel: ObservableObject {
    @Published var selectedCategory: PerkCategory = .core
    @Published var selectedItem: PerkShopItem? = nil
    @Published var showDetailSheet: Bool = false
    @Published var showSuccessAnimation: Bool = false
    
    let userEnv: UserEnvironment
    
    init(userEnv: UserEnvironment) {
        self.userEnv = userEnv
    }
    
    private var activeSlot: SaveSlot? {
        guard let slotId = userEnv.activeSlotId else { return nil }
        return SaveManager.shared.slots.first(where: { $0.id == slotId })
    }
    
    func currentTier(for id: String) -> Int {
        return activeSlot?.perkLevels[id] ?? 0
    }
    
    func isOwned(_ item: PerkShopItem) -> Bool {
        if item.category == .core { return true }
        return currentTier(for: item.id) >= 1
    }
    
    func canAfford(_ item: PerkShopItem) -> Bool {
        guard let slot = activeSlot else { return false }
        let current = currentTier(for: item.id)
        if current >= 5 { return false }
        
        let nextTier = current + 1
        let nextData = PerkUpgradeRegistry.tierData(for: PerkUpgradeID(rawValue: item.id)!, tier: nextTier)
        
        return slot.gold >= nextData.goldCost && userEnv.diamonds >= nextData.diamondCost
    }
    
    func upgrade(_ item: PerkShopItem) {
        guard let slotId = userEnv.activeSlotId else { return }
        let current = currentTier(for: item.id)
        let nextTier = current + 1
        let nextData = PerkUpgradeRegistry.tierData(for: PerkUpgradeID(rawValue: item.id)!, tier: nextTier)
        
        let success = SaveManager.shared.upgradeMetaPerk(
            slotId: slotId,
            perkId: item.id,
            goldCost: nextData.goldCost,
            diamondCost: nextData.diamondCost
        )
        
        if success {
            triggerSuccess()
        }
    }
    
    private func triggerSuccess() {
        HapticManager.shared.play(.success)
        AudioManager.shared.playSFX(.perkUnlock)
        
        // Close detail sheet immediately so success animation is visible on main screen
        self.selectedItem = nil
        
        withAnimation { showSuccessAnimation = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                self.showSuccessAnimation = false
            }
        }
    }
}

// MARK: - Views
struct PerkUpgradeView: View {
    @EnvironmentObject var userEnv: UserEnvironment
    @StateObject private var viewModel: PerkShopViewModel
    @Environment(\.dismiss) var dismiss
    
    init(userEnv: UserEnvironment) {
        _viewModel = StateObject(wrappedValue: PerkShopViewModel(userEnv: userEnv))
    }
    
    var body: some View {
        ZStack {
            ThemeColors.cosmicBlack.ignoresSafeArea()
            
            VStack(spacing: 0) {
                header
                categoryTabs
                
                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(PerkShopRegistry.items(for: viewModel.selectedCategory)) { item in
                            PerkShopCard(item: item, viewModel: viewModel)
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 100)
                }
            }
            
            if viewModel.showSuccessAnimation {
                SuccessLevelUpOverlay()
                    .transition(.opacity)
                    .zIndex(100)
            }
        }
        .navigationBarHidden(true)
        .sheet(item: $viewModel.selectedItem) { item in
            PerkDetailSheet(item: item, viewModel: viewModel)
                .presentationDetents([.medium, .large])
        }
    }
    
    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                Text(userEnv.localizedString("PERK MAĞAZASI", "PERK SHOP"))
                    .font(.setCustomFont(name: .InterBlack, size: 20))
                    .foregroundStyle(.white)
                Text(userEnv.localizedString("META İLERLEME SİSTEMİ", "META PROGRESSION"))
                    .font(.setCustomFont(name: .InterBold, size: 10))
                    .foregroundStyle(ThemeColors.neonCyan)
                    .tracking(2)
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                currencyDisplay(icon: "icon_gold", value: userEnv.gold, color: ThemeColors.electricYellow)
                currencyDisplay(icon: "icon_diamond", value: userEnv.diamonds, color: ThemeColors.neonCyan)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(ThemeColors.surfaceDark.opacity(0.8))
    }
    
    private var categoryTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 15) {
                ForEach(PerkCategory.allCases, id: \.self) { cat in
                    Button {
                        withAnimation(.spring()) { viewModel.selectedCategory = cat }
                    } label: {
                        Text(cat.title)
                            .font(.setCustomFont(name: .InterBlack, size: 12))
                            .foregroundStyle(viewModel.selectedCategory == cat ? .black : .white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(viewModel.selectedCategory == cat ? categoryColor(cat) : Color.white.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .background(Color.black.opacity(0.3))
    }
    
    private func currencyDisplay(icon: String, value: Int, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(icon).resizable().frame(width: 14, height: 14)
            Text(PerkUpgradeRegistry.formattedValue(value))
                .font(.setCustomFont(name: .InterBold, size: 12))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(color.opacity(0.3), lineWidth: 1))
    }
    
    private func categoryColor(_ cat: PerkCategory) -> Color {
        switch cat {
        case .core: return ThemeColors.neonCyan
        case .professional: return ThemeColors.neonPurple
        case .legendary: return ThemeColors.electricYellow
        case .special: return Color(hex: "9C27B0")
        }
    }
}

struct PerkShopCard: View {
    let item: PerkShopItem
    @ObservedObject var viewModel: PerkShopViewModel
    
    var body: some View {
        let current = viewModel.currentTier(for: item.id)
        let isLocked = item.category != .core && current == 0
        let color = categoryColor(item.category)
        
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                ZStack {
                    Circle().fill(color.opacity(0.15)).frame(width: 50, height: 50)
                    Image(systemName: isLocked ? "lock.fill" : item.icon)
                        .font(.system(size: 20))
                        .foregroundStyle(isLocked ? ThemeColors.textMuted : color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name).font(.setCustomFont(name: .InterBlack, size: 18)).foregroundStyle(.white)
                    Text(item.description).font(.setCustomFont(name: .InterMedium, size: 12)).foregroundStyle(ThemeColors.textSecondary).lineLimit(2)
                }
                
                Spacer()
                
                if current >= 5 {
                    Text("MAX").font(.setCustomFont(name: .InterBlack, size: 12)).foregroundStyle(ThemeColors.electricYellow).padding(.horizontal, 10).padding(.vertical, 4).background(ThemeColors.electricYellow.opacity(0.1)).clipShape(Capsule())
                }
            }
            
            if item.category.isUpgradeable {
                tierIndicator(level: current, color: color)
            }
            
            HStack {
                if current > 0 {
                    let effect = PerkUpgradeRegistry.effectDescription(for: PerkUpgradeID(rawValue: item.id)!, tier: current)
                    Text(effect).font(.setCustomFont(name: .InterBold, size: 14)).foregroundStyle(color)
                } else if isLocked {
                    Text("LOCKED").font(.setCustomFont(name: .InterBold, size: 12)).foregroundStyle(ThemeColors.textMuted)
                }
                
                Spacer()
                
                if current < 5 {
                    upgradeButton(isLocked: isLocked, nextTier: current + 1)
                }
            }
        }
        .padding(20)
        .background(ThemeColors.surfaceDark.opacity(isLocked ? 0.4 : 0.6))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(isLocked ? Color.white.opacity(0.05) : color.opacity(0.2), lineWidth: 1))
        .opacity(isLocked ? 0.7 : 1.0)
    }
    
    private func tierIndicator(level: Int, color: Color) -> some View {
        HStack(spacing: 6) {
            ForEach(1...5, id: \.self) { i in
                Capsule()
                    .fill(i <= level ? color : Color.white.opacity(0.1))
                    .frame(height: 4)
            }
        }
    }
    
    private func upgradeButton(isLocked: Bool, nextTier: Int) -> some View {
        let nextData = PerkUpgradeRegistry.tierData(for: PerkUpgradeID(rawValue: item.id)!, tier: nextTier)
        let canAfford = viewModel.canAfford(item)
        
        return Button {
            viewModel.selectedItem = item
        } label: {
            HStack(spacing: 6) {
                VStack(alignment: .leading, spacing: 0) {
                    if nextData.goldCost > 0 {
                        HStack(spacing: 2) {
                            Text(PerkUpgradeRegistry.formattedValue(nextData.goldCost)).font(.setCustomFont(name: .InterBold, size: 10))
                            Image("icon_gold").resizable().frame(width: 10, height: 10)
                        }
                    }
                    if nextData.diamondCost > 0 {
                        HStack(spacing: 2) {
                            Text(PerkUpgradeRegistry.formattedValue(nextData.diamondCost)).font(.setCustomFont(name: .InterBold, size: 10))
                            Image("icon_diamond").resizable().frame(width: 10, height: 10)
                        }
                    }
                }
                
                Text(isLocked ? "UNLOCK" : "UPGRADE")
                    .font(.setCustomFont(name: .InterBlack, size: 11))
                    .lineLimit(1)
                    .fixedSize()
            }
            .foregroundStyle(canAfford ? .black : Color.white.opacity(0.5))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(canAfford ? categoryColor(item.category) : ThemeColors.surfaceDark)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(!canAfford)
    }
    
    private func categoryColor(_ cat: PerkCategory) -> Color {
        switch cat {
        case .core: return ThemeColors.neonCyan
        case .professional: return ThemeColors.neonPurple
        case .legendary: return ThemeColors.electricYellow
        case .special: return Color(hex: "9C27B0")
        }
    }
}

struct PerkDetailSheet: View {
    let item: PerkShopItem
    @ObservedObject var viewModel: PerkShopViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        let current = viewModel.currentTier(for: item.id)
        let nextTier = current + 1
        let isLocked = item.category != .core && current == 0
        let color = categoryColor(item.category)
        
        ZStack {
            ThemeColors.surfaceDark.ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header
                ZStack {
                    Circle().fill(color.opacity(0.1)).frame(width: 100, height: 100)
                    Image(systemName: item.icon).font(.system(size: 40)).foregroundStyle(color)
                }
                .padding(.top, 40)
                
                VStack(spacing: 8) {
                    Text(item.name).font(.setCustomFont(name: .InterBlack, size: 28)).foregroundStyle(.white)
                    Text(item.category.title).font(.setCustomFont(name: .InterBold, size: 14)).foregroundStyle(color).tracking(3)
                }
                
                Text(item.description)
                    .font(.setCustomFont(name: .InterMedium, size: 16))
                    .foregroundStyle(ThemeColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                if nextTier <= 5 {
                    comparisonView(current: current, next: nextTier, color: color)
                        .padding(.horizontal, 20)
                }
                
                Spacer()
                
                if nextTier <= 5 {
                    upgradeActionBlock(isLocked: isLocked, nextTier: nextTier)
                } else {
                    Text("MAX LEVEL REACHED")
                        .font(.setCustomFont(name: .InterBlack, size: 16))
                        .foregroundStyle(ThemeColors.electricYellow)
                        .padding(.bottom, 40)
                }
            }
        }
    }
    
    private func comparisonView(current: Int, next: Int, color: Color) -> some View {
        HStack(spacing: 20) {
            comparisonNode(title: "CURRENT", desc: current == 0 ? "Locked" : PerkUpgradeRegistry.effectDescription(for: PerkUpgradeID(rawValue: item.id)!, tier: current), color: ThemeColors.textMuted)
            Image(systemName: "arrow.right").foregroundStyle(color)
            comparisonNode(title: "NEXT", desc: PerkUpgradeRegistry.effectDescription(for: PerkUpgradeID(rawValue: item.id)!, tier: next), color: color)
        }
        .padding(20)
        .background(Color.black.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    private func comparisonNode(title: String, desc: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title).font(.setCustomFont(name: .InterBold, size: 10)).foregroundStyle(ThemeColors.textMuted)
            Text(desc).font(.setCustomFont(name: .InterBlack, size: 14)).foregroundStyle(color)
        }
    }
    
    private func upgradeActionBlock(isLocked: Bool, nextTier: Int) -> some View {
        let nextData = PerkUpgradeRegistry.tierData(for: PerkUpgradeID(rawValue: item.id)!, tier: nextTier)
        let canAfford = viewModel.canAfford(item)
        
        return VStack(spacing: 16) {
            Button {
                viewModel.upgrade(item)
            } label: {
                Text(isLocked ? "UNLOCK PERK" : "UPGRADE TO TIER \(nextTier)")
                    .font(.setCustomFont(name: .InterBlack, size: 16))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(canAfford ? categoryColor(item.category) : ThemeColors.textMuted)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            .disabled(!canAfford)
            
            HStack(spacing: 20) {
                if nextData.goldCost > 0 { costItem(icon: "icon_gold", val: nextData.goldCost) }
                if nextData.diamondCost > 0 { costItem(icon: "icon_diamond", val: nextData.diamondCost) }
            }
        }
        .padding(20)
        .padding(.bottom, 20)
    }
    
    private func costItem(icon: String, val: Int) -> some View {
        HStack(spacing: 6) {
            Image(icon).resizable().frame(width: 16, height: 16)
            Text(PerkUpgradeRegistry.formattedValue(val)).font(.setCustomFont(name: .InterBold, size: 14)).foregroundStyle(.white)
        }
    }
    
    private func categoryColor(_ cat: PerkCategory) -> Color {
        switch cat {
        case .core: return ThemeColors.neonCyan
        case .professional: return ThemeColors.neonPurple
        case .legendary: return ThemeColors.electricYellow
        case .special: return Color(hex: "9C27B0")
        }
    }
}

struct SuccessLevelUpOverlay: View {
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var circleScale: CGFloat = 1.0
    @State private var circleOpacity: Double = 0.5
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8).ignoresSafeArea()
            
            Circle()
                .stroke(ThemeColors.electricYellow, lineWidth: 2)
                .scaleEffect(circleScale)
                .opacity(circleOpacity)
            
            VStack(spacing: 20) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(ThemeColors.electricYellow)
                    .shadow(color: ThemeColors.electricYellow.opacity(0.5), radius: 20)
                
                Text(UserEnvironment.shared.localizedString("BAŞARILI!", "SUCCESS!"))
                    .font(.setCustomFont(name: .InterBlack, size: 40))
                    .foregroundStyle(.white)
                
                Text(UserEnvironment.shared.localizedString("PERK SEVİYESİ YÜKSELDİ", "PERK LEVEL UPGRADED"))
                    .font(.setCustomFont(name: .InterBold, size: 16))
                    .foregroundStyle(ThemeColors.textSecondary)
            }
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }
            withAnimation(.easeOut(duration: 1.5)) {
                circleScale = 2.0
                circleOpacity = 0
            }
        }
    }
}
