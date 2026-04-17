//
//  MerchantView.swift
//  Block-Jack
//

import SwiftUI

struct MerchantView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var userEnv: UserEnvironment
    @StateObject private var viewModel: MerchantViewModel
    
    let slotId: Int
    
    init(slotId: Int) {
        self.slotId = slotId
        self._viewModel = StateObject(wrappedValue: MerchantViewModel(slotId: slotId))
    }
    
    var body: some View {
        ZStack {
            // Fix Background Scaling (Task 2)
            GeometryReader { geo in
                Image("cyber_merchant_shop")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
            }
            .ignoresSafeArea()
            
            Color.black.opacity(0.5).ignoresSafeArea() // Görünürlük için karartma
            
            VStack(spacing: 0) {
                // Header
                merchantHeader
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Merchant Portrait & Dialogue
                        HStack(alignment: .bottom, spacing: 16) {
                            Image("cyber_merchant_portrait")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 110, height: 110)
                                .cornerRadius(20)
                                .overlay(RoundedRectangle(cornerRadius: 20).stroke(ThemeColors.electricYellow.opacity(0.5), lineWidth: 2))
                                .shadow(color: ThemeColors.electricYellow.opacity(0.3), radius: 10)
                            
                            // Dialogue Bubble
                            VStack(alignment: .leading, spacing: 8) {
                                Text("TÜCCAR KAIRO")
                                    .font(.custom("Outfit-Bold", size: 14))
                                    .foregroundColor(ThemeColors.electricYellow)
                                
                                Text("\"Veri akışında nadir parçalar keşfettim. Elindeki altınlar burada değerli.\"")
                                    .font(.custom("Outfit-Medium", size: 14))
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(12)
                            }
                        }
                        .padding()
                        
                        // Shop Section
                        shopSection
                        
                        // Perk Forge Section
                        forgeSection
                        
                        Spacer(minLength: 50)
                    }
                    .padding()
                }
                
                // Footer
                footerSection
            }
        }
    }
    
    // MARK: - Components
    
    private var merchantHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("TÜCCAR")
                    .font(.custom("Outfit-Bold", size: 32, relativeTo: .largeTitle))
                    .foregroundColor(ThemeColors.electricYellow)
                Text("\"Karanlıkta parlayan her şey altın değildir... ama bunlar öyle.\"")
                    .font(.caption)
                    .italic()
                    .foregroundColor(ThemeColors.textSecondary)
            }
            Spacer()
            
            // Gold Display
            HStack(spacing: 8) {
                Image(systemName: "circle.hexagongrid.fill")
                    .foregroundColor(ThemeColors.electricYellow)
                Text("\(viewModel.currentSlot?.gold ?? 0)")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.1))
            .cornerRadius(20)
        }
        .padding()
        .background(.ultraThinMaterial)
    }
    
    private var shopSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("TEKLİFLER")
                .font(.headline)
                .foregroundColor(ThemeColors.textSecondary)
                .padding(.horizontal)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(viewModel.shopItems) { item in
                    MerchantItemView(viewModel: viewModel, item: item) {
                        if viewModel.buyItem(item) {
                            HapticManager.shared.play(.success)
                        } else {
                            HapticManager.shared.play(.error)
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var forgeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("PERK DEMİRCİSİ")
                    .font(.headline)
                    .foregroundColor(ThemeColors.textSecondary)
                Spacer()
                Text("2 Seç: 1 Yeni")
                    .font(.caption)
                    .foregroundColor(ThemeColors.neonPurple)
            }
            .padding(.horizontal)
            
            VStack(spacing: 20) {
                Text("İki perk'i feda ederek çok daha güçlü veya rastgele bir perk elde et.")
                    .font(.caption)
                    .foregroundColor(ThemeColors.textMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Active Perks Selection
                if let slot = viewModel.currentSlot {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(slot.activePassivePerks) { perk in
                                ForgeSelectionCard(
                                    perk: perk,
                                    isSelected: viewModel.forgeSelection.contains(where: { $0.id == perk.id })
                                ) {
                                    viewModel.toggleForgeSelection(perk)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Forge Button
                Button(action: {
                    viewModel.forge()
                    HapticManager.shared.play(.success)
                }) {
                    HStack {
                        Image(systemName: "hammer.fill")
                        Text("BİRLEŞTİR (FORGE)")
                            .bold()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: viewModel.canForge() ? [ThemeColors.neonPurple, ThemeColors.neonPink] : [Color.gray.opacity(0.3)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(viewModel.canForge() ? .white : .white.opacity(0.5))
                    .cornerRadius(12)
                    .shadow(color: viewModel.canForge() ? ThemeColors.neonPurple.opacity(0.5) : .clear, radius: 10)
                }
                .disabled(!viewModel.canForge())
                .padding(.horizontal)
            }
            .padding(.vertical)
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.1), lineWidth: 1))
            .padding(.horizontal)
        }
    }
    
    private var footerSection: some View {
        Button(action: {
            HapticManager.shared.play(.buttonTap)
            dismiss()
        }) {
            Text(userEnv.localizedString("HARİTAYA DÖN", "BACK TO MAP"))
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.ultraThinMaterial)
                .foregroundColor(.white)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.2), lineWidth: 1))
        }
        .padding()
    }
}

// MARK: - Subviews

struct MerchantItemView: View {
    @EnvironmentObject var userEnv: UserEnvironment
    @ObservedObject var viewModel: MerchantViewModel
    let item: MerchantViewModel.ShopItem
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // Icon / Art
                ZStack {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(ThemeColors.surfaceMid)
                        .frame(width: 80, height: 80)
                    
                    if let perk = item.perk {
                        Text(perk.icon)
                            .font(.system(size: 40))
                    } else if let consumable = item.consumableType {
                        if consumable == .lifeRestoration {
                            Image(systemName: "heart.fill")
                                .font(.largeTitle)
                                .foregroundColor(ThemeColors.neonPink)
                        } else {
                            // Inventory capacity check logic
                            let maxSlots = userEnv.unlockedUpgradeIDs.contains(MetaUpgrade.extraSlot.rawValue) ? 4 : 3
                            if (viewModel.currentSlot?.inventory.count ?? 0) >= maxSlots {
                                // Handle full inventory
                            }
                        }
                    }
                    
                    if item.isSold {
                        Color.black.opacity(0.6).cornerRadius(15)
                        Text("SATILDI")
                            .font(.caption2)
                            .bold()
                            .foregroundColor(.white)
                            .rotationEffect(.degrees(-20))
                    }
                }
                
                VStack(spacing: 4) {
                    Text(item.perk?.name ?? (item.consumableType == .lifeRestoration ? "Yaşam İksiri" : "Bilinmeyen"))
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(.white)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "circle.hexagongrid.fill")
                            .font(.caption2)
                            .foregroundColor(ThemeColors.electricYellow)
                        Text("\(item.cost)")
                            .font(.caption)
                            .bold()
                            .foregroundColor(ThemeColors.electricYellow)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(item.isSold ? Color.gray.opacity(0.2) : ThemeColors.electricYellow.opacity(0.5), lineWidth: 1)
            )
            .shadow(color: item.isSold ? .clear : ThemeColors.electricYellow.opacity(0.2), radius: 8)
        }
        .disabled(item.isSold)
    }
}

struct ForgeSelectionCard: View {
    let perk: PassivePerk
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Text(perk.icon)
                    .font(.title)
                Text(perk.name)
                    .font(.caption2)
                    .foregroundColor(.white)
            }
            .frame(width: 80, height: 80)
            .background(isSelected ? ThemeColors.neonPurple.opacity(0.2) : Color.white.opacity(0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? ThemeColors.neonPurple : Color.clear, lineWidth: 2)
            )
        }
    }
}
