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
    
    // Category 3: Special (One-Time)
    case lastStand = "last_stand"
    case recycler = "recycler"
    
    // Category 4: Elite (Tier 1 must be PURCHASED)
    case echoes = "echoes"
    case clockwork = "clockwork"
    case vampiricCore = "vampiric_core"
    case chainPulse = "chain_pulse"
    case staticCharge = "static_charge"
    case heavyDuty = "heavy_duty"
    case phantomSiphon = "phantom_siphon"
    case doubleDown = "double_down"
    case tacticalLens = "tactical_lens"
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
    var icon: String { "perk_\(id)" }
    var isComingSoon: Bool = false
}

// MARK: - Perk Registry (The Source of Truth for Costs & Effects)
struct PerkUpgradeRegistry {
    static func tierData(for id: PerkUpgradeID, tier: Int) -> PerkUpgradeTierData {
        // Guard for tier bounds
        let safeTier = max(0, min(5, tier))
        
        switch id {
        case .goldenStamp:
            let values = [0: 0.0, 1: 0.15, 2: 0.25, 3: 0.35, 4: 0.45, 5: 0.60]
            let gold = [1: 0, 2: 300, 3: 600, 4: 1000, 5: 2000]
            let diamond = [1: 0, 2: 0, 3: 20, 4: 80, 5: 150]
            return PerkUpgradeTierData(tier: safeTier, goldCost: gold[safeTier] ?? 0, diamondCost: diamond[safeTier] ?? 0, effectValue: values[safeTier] ?? 0.0)
            
        case .overkill:
            let values = [0: 0.0, 1: 0.30, 2: 0.45, 3: 0.60, 4: 0.75, 5: 1.00]
            let gold = [1: 0, 2: 350, 3: 700, 4: 1200, 5: 2500]
            let diamond = [1: 0, 2: 0, 3: 30, 4: 100, 5: 200]
            return PerkUpgradeTierData(tier: safeTier, goldCost: gold[safeTier] ?? 0, diamondCost: diamond[safeTier] ?? 0, effectValue: values[safeTier] ?? 0.0)
            
        case .safeHouse:
            let values = [0: 0.0, 1: 50.0, 2: 100.0, 3: 150.0, 4: 250.0, 5: 400.0]
            let gold = [1: 0, 2: 250, 3: 500, 4: 800, 5: 1500]
            let diamond = [1: 0, 2: 0, 3: 25, 4: 60, 5: 120]
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
            
        case .echoes:
            let values = [0: 0.0, 1: 1.0, 2: 1.25, 3: 1.5, 4: 1.75, 5: 2.0]
            let gold = [1: 600, 2: 700, 3: 850, 4: 1100, 5: 1500]
            return PerkUpgradeTierData(tier: safeTier, goldCost: gold[safeTier] ?? 0, diamondCost: 0, effectValue: values[safeTier] ?? 0.0)
            
        case .clockwork:
            let values = [0: 0.0, 1: 0.05, 2: 0.10, 3: 0.15, 4: 0.20, 5: 0.30]
            let gold = [1: 600, 2: 700, 3: 850, 4: 1100, 5: 1500]
            return PerkUpgradeTierData(tier: safeTier, goldCost: gold[safeTier] ?? 0, diamondCost: 0, effectValue: values[safeTier] ?? 0.0)
            
        case .vampiricCore:
            let values = [0: 0.0, 1: 0.10, 2: 0.15, 3: 0.20, 4: 0.25, 5: 0.40]
            let gold = [1: 600, 2: 700, 3: 850, 4: 1100, 5: 1500]
            return PerkUpgradeTierData(tier: safeTier, goldCost: gold[safeTier] ?? 0, diamondCost: 0, effectValue: values[safeTier] ?? 0.0)
            
        case .chainPulse:
            let values = [0: 0.0, 1: 0.20, 2: 0.30, 3: 0.40, 4: 0.50, 5: 0.75]
            let gold = [1: 600, 2: 700, 3: 850, 4: 1100, 5: 1500]
            return PerkUpgradeTierData(tier: safeTier, goldCost: gold[safeTier] ?? 0, diamondCost: 0, effectValue: values[safeTier] ?? 0.0)
            
        case .staticCharge:
            let values = [0: 0.0, 1: 1.0, 2: 1.2, 3: 1.5, 4: 1.8, 5: 2.5]
            let gold = [1: 600, 2: 700, 3: 850, 4: 1100, 5: 1500]
            return PerkUpgradeTierData(tier: safeTier, goldCost: gold[safeTier] ?? 0, diamondCost: 0, effectValue: values[safeTier] ?? 0.0)
            
        case .heavyDuty:
            let values = [0: 0.0, 1: 1.5, 2: 2.0, 3: 2.5, 4: 3.5, 5: 5.0]
            let gold = [1: 800, 2: 950, 3: 1100, 4: 1400, 5: 2000]
            return PerkUpgradeTierData(tier: safeTier, goldCost: gold[safeTier] ?? 0, diamondCost: 0, effectValue: values[safeTier] ?? 0.0)
            
        case .phantomSiphon:
            let values = [0: 0.0, 1: 2.0, 2: 3.0, 3: 4.0, 4: 6.0, 5: 10.0]
            let gold = [1: 800, 2: 950, 3: 1100, 4: 1400, 5: 2000]
            return PerkUpgradeTierData(tier: safeTier, goldCost: gold[safeTier] ?? 0, diamondCost: 0, effectValue: values[safeTier] ?? 0.0)
            
        case .doubleDown:
            let values = [0: 0.0, 1: 1.0, 2: 2.0, 3: 3.0, 4: 4.0, 5: 5.0]
            let gold = [1: 800, 2: 950, 3: 1100, 4: 1400, 5: 2000]
            return PerkUpgradeTierData(tier: safeTier, goldCost: gold[safeTier] ?? 0, diamondCost: 0, effectValue: values[safeTier] ?? 0.0)
            
        case .tacticalLens:
            let values = [0: 0.0, 1: 1.0, 2: 1.0, 3: 1.0, 4: 1.0, 5: 1.0]
            let gold = [1: 800, 2: 950, 3: 1100, 4: 1400, 5: 2000]
            return PerkUpgradeTierData(tier: safeTier, goldCost: gold[safeTier] ?? 0, diamondCost: 0, effectValue: values[safeTier] ?? 0.0)
        }
    }
    
    static func effectDescription(for id: PerkUpgradeID, tier: Int) -> String {
        let data = tierData(for: id, tier: tier)
        let v = data.effectValue
        let isTR = UserEnvironment.shared.language == .turkish
        
        switch id {
        case .goldenStamp: 
            return isTR ? "Hedef skor %\(Int(v * 100)) azalır." : "Reduces target score by \(Int(v * 100))%."
        case .overkill: 
            return isTR ? "Artan puanların %\(Int(v * 100))'i aktarılır." : "Carries over \(Int(v * 100))% of excess score."
        case .safeHouse: 
            return isTR ? "Dinlenme alanlarında +\(Int(v)) Altın verir." : "Grants +\(Int(v)) Gold at rest sites."
        case .bluePill: 
            return isTR ? "Mavi blok puanları ×\((1.0 + v).formatted()) artar." : "Blue block score increased by ×\((1.0 + v).formatted())."
        case .leadPill: 
            return isTR ? "Yeşil blok puanları ×\((1.0 + v).formatted()) artar." : "Green block score increased by ×\((1.0 + v).formatted())."
        case .luckyClover: 
            return isTR ? "Seri (Streak) limiti +\(Int(v)) artar." : "Increases streak limit by +\(Int(v))."
        case .momentum: 
            return isTR ? "Seri bonusu %\(Int(v * 100)) artar." : "Increases streak bonus by \(Int(v * 100))%."
        case .midasTouch: 
            return isTR ? "Her Flush (Temizlik) +\(Int(v)) Altın verir." : "Grants +\(Int(v)) Gold per Flush."
        case .wideLoad: 
            return isTR ? "Blok haznesi \(Int(v)) slot olur." : "Tray capacity increased to \(Int(v)) slots."
        case .sculptor: 
            if v > 100 { return isTR ? "Sınırsız blok döndürme." : "Unlimited block rotations." }
            return isTR ? "Tur başına \(Int(v)) döndürme hakkı." : "Allows \(Int(v)) rotations per round."
        case .glassCannon: 
            let hp = tier <= 2 ? 1 : (tier <= 4 ? 2 : 3)
            return isTR ? "Can \(hp) veya altındayken puanlar ×\(v.formatted()) artar." : "Score ×\(v.formatted()) when HP is \(hp) or less."
        case .lastStand: 
            return isTR ? "Her run'da \(tier) kez ücretsiz canlanma." : "Revive for free \(tier) time(s) per run."
        case .recycler: 
            return isTR ? "Hazneyi yenileme şansı %\(Int(v * 100))." : "\(Int(v * 100))% chance to refresh tray."
        case .echoes: 
            return isTR ? "En iyi hamle puanının ×\(v.formatted()) kadarı eklenir." : "Repeats \(Int(v * 100))% of best move score."
        case .clockwork: 
            return isTR ? "Zaman bonusu çarpanı %\(Int(v * 100)) artar." : "Time bonus increases multiplier by \(Int(v * 100))%."
        case .vampiricCore: 
            return isTR ? "Her 5k puanda %\(Int(v * 100)) can şansı." : "\(Int(v * 100))% chance for +1 Life every 5k pts."
        case .chainPulse: 
            return isTR ? "Zincirleme reaksiyon şansı %\(Int(v * 100))." : "\(Int(v * 100))% chance for chain reaction."
        case .staticCharge: 
            return isTR ? "Statik hücreler Overdrive'ı ×\(v.formatted()) doldurur." : "Static cells charge overdrive ×\(v.formatted())."
        case .heavyDuty: 
            return isTR ? "Ağır blok çarpanı ×\(v.formatted()) artar." : "Heavy cells multiplier ×\(v.formatted())."
        case .phantomSiphon: 
            return isTR ? "Hayalet hücreler +\(Int(v))sn süre verir." : "Phantom cells grant +\(Int(v))s time."
        case .doubleDown: 
            return isTR ? "Son hamlede temizlik: +\(Int(v)) ek hamle." : "Clear on last move: +\(Int(v)) extra moves."
        case .tacticalLens: 
            return isTR ? "En iyi yerleşimi sahada vurgular." : "Highlights the best placement on grid."
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
                PerkShopItem(id: "golden_stamp", name: "GOLDEN STAMP", description: UserEnvironment.shared.localizedString("Kazanmak için gereken hedef skoru düşürür.", "Reduces target score needed to win."), category: .core),
                PerkShopItem(id: "overkill", name: "OVERKILL", description: UserEnvironment.shared.localizedString("Artan puanları bir sonraki tura aktarır.", "Carries over excess score to next round."), category: .core),
                PerkShopItem(id: "safe_house", name: "SAFE HOUSE", description: UserEnvironment.shared.localizedString("Dinlenme alanlarında ekstra altın verir.", "Bonus gold at rest sites."), category: .core)
            ]
        case .professional:
            return [
                PerkShopItem(id: "blue_pill", name: "BLUE PILL", description: UserEnvironment.shared.localizedString("Mavi bloklardan gelen puanı artırır.", "Boost score from blue blocks."), category: .professional),
                PerkShopItem(id: "lead_pill", name: "LEAD PILL", description: UserEnvironment.shared.localizedString("Yeşil bloklardan gelen puanı artırır.", "Boost score from green blocks."), category: .professional),
                PerkShopItem(id: "lucky_clover", name: "LUCKY CLOVER", description: UserEnvironment.shared.localizedString("Maksimum seri (streak) limitini yükseltir.", "Higher maximum streak limit."), category: .professional),
                PerkShopItem(id: "momentum", name: "MOMENTUM", description: UserEnvironment.shared.localizedString("Seri hedeflerinde büyük bonus sağlar.", "Huge bonus at streak milestones."), category: .professional),
                PerkShopItem(id: "midas_touch", name: "MIDAS TOUCH", description: UserEnvironment.shared.localizedString("Kusursuz temizlikte (flush) altın bonusu.", "Gold bonus for perfect flushes."), category: .professional)
            ]
        case .legendary:
            return [
                PerkShopItem(id: "wide_load", name: "WIDE LOAD", description: UserEnvironment.shared.localizedString("Bloklar için ekstra hazne kapasitesi.", "Extra storage capacity for blocks."), category: .legendary),
                PerkShopItem(id: "sculptor", name: "SCULPTOR", description: UserEnvironment.shared.localizedString("Oyun sırasında blokları döndürmeni sağlar.", "Allows rotating blocks during play."), category: .legendary),
                PerkShopItem(id: "glass_cannon", name: "GLASS CANNON", description: UserEnvironment.shared.localizedString("Düşük canda devasa puan bonusu verir.", "Massive score boost at low health."), category: .legendary)
            ]
        case .special:
            return [
                PerkShopItem(id: "last_stand", name: "LAST STAND", description: UserEnvironment.shared.localizedString("Ölümcül bir darbeden bir kez kurtul.", "Survive a lethal hit once per run."), category: .special),
                PerkShopItem(id: "recycler", name: "RECYCLER", description: UserEnvironment.shared.localizedString("Çoklu temizlemede hazneyi yenileme şansı.", "Chance to refresh tray on multi-clear."), category: .special)
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
                .presentationDetents([.large])
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
                Text(userEnv.labelPerkShopStoreCaps)
                    .font(.setCustomFont(name: .InterBlack, size: 20))
                    .foregroundStyle(.white)
                Text(userEnv.labelMetaProgressionCaps)
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
    @EnvironmentObject var userEnv: UserEnvironment
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
                    if isLocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(ThemeColors.textMuted)
                    } else {
                        Image(item.icon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 28, height: 28)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name).font(.setCustomFont(name: .InterBlack, size: 18)).foregroundStyle(.white)
                    Text(item.description).font(.setCustomFont(name: .InterMedium, size: 12)).foregroundStyle(ThemeColors.textSecondary).lineLimit(2)
                }
                
                Spacer()
                
                if current >= 5 {
                    Text(userEnv.labelMaxCaps).font(.setCustomFont(name: .InterBlack, size: 12)).foregroundStyle(ThemeColors.electricYellow).padding(.horizontal, 10).padding(.vertical, 4).background(ThemeColors.electricYellow.opacity(0.1)).clipShape(Capsule())
                }
            }
            
            if item.category.isUpgradeable {
                tierIndicator(level: current, color: color)
            }
            
            HStack(spacing: 12) {
                if current > 0 {
                    let effect = PerkUpgradeRegistry.effectDescription(for: PerkUpgradeID(rawValue: item.id)!, tier: current)
                    Text(effect)
                        .font(.setCustomFont(name: .InterBold, size: 13))
                        .foregroundStyle(color)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                } else if isLocked {
                    Text(userEnv.labelLockedCaps)
                        .font(.setCustomFont(name: .InterBold, size: 12))
                        .foregroundStyle(ThemeColors.textMuted)
                }
                
                Spacer(minLength: 0)
                
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
                
                Text(isLocked ? userEnv.btnUnlockCaps : userEnv.btnUpgradeCaps)
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
    @EnvironmentObject var userEnv: UserEnvironment
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
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    ZStack {
                        Circle().fill(color.opacity(0.1)).frame(width: 100, height: 100)
                        Image(item.icon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
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
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 40)
                    
                    if nextTier <= 5 {
                        comparisonView(current: current, next: nextTier, color: color)
                            .padding(.horizontal, 20)
                    }
                    
                    Spacer(minLength: 40)
                    
                    if nextTier <= 5 {
                        upgradeActionBlock(isLocked: isLocked, nextTier: nextTier)
                    } else {
                        Text(userEnv.labelMaxLevelReachedCaps)
                            .font(.setCustomFont(name: .InterBlack, size: 16))
                            .foregroundStyle(ThemeColors.electricYellow)
                            .padding(.bottom, 40)
                    }
                }
            }
        }
    }
    
    private func comparisonView(current: Int, next: Int, color: Color) -> some View {
        VStack(spacing: 16) {
            comparisonNode(title: userEnv.labelCurrentTierCaps, desc: current == 0 ? (userEnv.language == .turkish ? "Kilitli" : "Locked") : PerkUpgradeRegistry.effectDescription(for: PerkUpgradeID(rawValue: item.id)!, tier: current), color: ThemeColors.textMuted)
            
            Image(systemName: "arrow.down")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(color)
            
            comparisonNode(title: userEnv.labelNextTierCaps, desc: PerkUpgradeRegistry.effectDescription(for: PerkUpgradeID(rawValue: item.id)!, tier: next), color: color)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    private func comparisonNode(title: String, desc: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.setCustomFont(name: .InterBold, size: 10))
                .foregroundStyle(ThemeColors.textMuted)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.05))
                .clipShape(Capsule())
                
            Text(desc)
                .font(.setCustomFont(name: .InterBlack, size: 15))
                .foregroundStyle(color)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    private func upgradeActionBlock(isLocked: Bool, nextTier: Int) -> some View {
        let nextData = PerkUpgradeRegistry.tierData(for: PerkUpgradeID(rawValue: item.id)!, tier: nextTier)
        let canAfford = viewModel.canAfford(item)
        
        return VStack(spacing: 16) {
            Button {
                viewModel.upgrade(item)
            } label: {
                Text(isLocked ? userEnv.btnUnlockPerkCaps : userEnv.formatUpgradeToTierCaps(tier: nextTier))
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
    @EnvironmentObject var userEnv: UserEnvironment
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
                
                Text(userEnv.labelSuccessCaps)
                    .font(.setCustomFont(name: .InterBlack, size: 40))
                    .foregroundStyle(.white)
                
                Text(userEnv.labelPerkLevelUpgradedCaps)
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
