//
//  StoreView.swift
//  Block-Jack
//
//  IAP (In-App Purchase) mağazası — Altın ve Elmas paketleri.
//  Şimdilik UI-only: satın alma akışı simüle edilir, ileride StoreKit
//  entegrasyonu (SKProductsRequest / StoreKit 2 Transaction API) ile
//  gerçek ürünlere bağlanacak.
//

import SwiftUI

// MARK: - Paket Modelleri

enum StoreTab: Int, CaseIterable {
    case diamonds
    case gold
    case specials

    func titleTR() -> String {
        switch self {
        case .diamonds: return "ELMAS"
        case .gold:     return "ALTIN"
        case .specials: return "ÖZEL"
        }
    }

    func titleEN() -> String {
        switch self {
        case .diamonds: return "GEMS"
        case .gold:     return "GOLD"
        case .specials: return "DEALS"
        }
    }
}

struct StorePackage: Identifiable, Hashable {
    let id: String
    let titleTR: String
    let titleEN: String
    let currencyAmount: Int       // Ana miktar (temel)
    let bonusAmount: Int          // Ekstra bonus
    let bonusLabel: String?       // "+25% BONUS" gibi etiket (nil ise hiç gösterme)
    let priceLabel: String        // "$0.99" / "$4.99" gibi görüntü fiyatı
    let isGold: Bool              // true: altın, false: elmas
    let tag: PackageTag?          // Kart üstündeki rozet (opsiyonel)
    let iconSystemName: String?   // SF Symbol (özel teklifler için)

    var totalAmount: Int { currencyAmount + bonusAmount }
}

enum PackageTag {
    case popular
    case bestValue
    case limited
    case starter

    func titleTR() -> String {
        switch self {
        case .popular: return "EN POPÜLER"
        case .bestValue: return "EN İYİ DEĞER"
        case .limited: return "SINIRLI"
        case .starter: return "YENİ OYUNCU"
        }
    }

    func titleEN() -> String {
        switch self {
        case .popular: return "MOST POPULAR"
        case .bestValue: return "BEST VALUE"
        case .limited: return "LIMITED"
        case .starter: return "NEW PLAYER"
        }
    }

    var color: Color {
        switch self {
        case .popular:   return ThemeColors.neonPink
        case .bestValue: return ThemeColors.electricYellow
        case .limited:   return ThemeColors.neonOrange
        case .starter:   return ThemeColors.neonGreen
        }
    }
}

struct StoreSpecialPackage: Identifiable, Hashable {
    let id: String
    let titleTR: String
    let titleEN: String
    let subtitleTR: String
    let subtitleEN: String
    let goldAmount: Int
    let diamondAmount: Int
    let priceLabel: String
    let tag: PackageTag
}

// MARK: - Katalog

enum StoreCatalog {
    static let diamondPackages: [StorePackage] = [
        StorePackage(id: "gem_tier1",
                     titleTR: "Küçük Paket", titleEN: "Small Pack",
                     currencyAmount: 80, bonusAmount: 0, bonusLabel: nil,
                     priceLabel: "$0.99", isGold: false, tag: nil, iconSystemName: nil),
        StorePackage(id: "gem_tier2",
                     titleTR: "Avantajlı Paket", titleEN: "Handy Pack",
                     currencyAmount: 500, bonusAmount: 125, bonusLabel: "+25% BONUS",
                     priceLabel: "$4.99", isGold: false, tag: nil, iconSystemName: nil),
        StorePackage(id: "gem_tier3",
                     titleTR: "Değerli Paket", titleEN: "Value Pack",
                     currencyAmount: 1200, bonusAmount: 600, bonusLabel: "+50% BONUS",
                     priceLabel: "$9.99", isGold: false, tag: .popular, iconSystemName: nil),
        StorePackage(id: "gem_tier4",
                     titleTR: "Mega Paket", titleEN: "Mega Pack",
                     currencyAmount: 3000, bonusAmount: 2250, bonusLabel: "+75% BONUS",
                     priceLabel: "$19.99", isGold: false, tag: .bestValue, iconSystemName: nil),
        StorePackage(id: "gem_tier5",
                     titleTR: "Nihai Paket", titleEN: "Ultimate Pack",
                     currencyAmount: 8000, bonusAmount: 8000, bonusLabel: "+100% BONUS",
                     priceLabel: "$49.99", isGold: false, tag: nil, iconSystemName: nil)
    ]

    static let goldPackages: [StorePackage] = [
        StorePackage(id: "gold_tier1",
                     titleTR: "Başlangıç Kesesi", titleEN: "Starter Pouch",
                     currencyAmount: 500, bonusAmount: 0, bonusLabel: nil,
                     priceLabel: "$0.99", isGold: true, tag: nil, iconSystemName: nil),
        StorePackage(id: "gold_tier2",
                     titleTR: "Küçük Kese", titleEN: "Small Sack",
                     currencyAmount: 2500, bonusAmount: 500, bonusLabel: "+20% BONUS",
                     priceLabel: "$4.99", isGold: true, tag: nil, iconSystemName: nil),
        StorePackage(id: "gold_tier3",
                     titleTR: "Dolu Kese", titleEN: "Full Sack",
                     currencyAmount: 6000, bonusAmount: 2400, bonusLabel: "+40% BONUS",
                     priceLabel: "$9.99", isGold: true, tag: .popular, iconSystemName: nil),
        StorePackage(id: "gold_tier4",
                     titleTR: "Hazine Sandığı", titleEN: "Treasure Chest",
                     currencyAmount: 15000, bonusAmount: 9000, bonusLabel: "+60% BONUS",
                     priceLabel: "$19.99", isGold: true, tag: .bestValue, iconSystemName: nil),
        StorePackage(id: "gold_tier5",
                     titleTR: "Dağı Altın", titleEN: "Mountain of Gold",
                     currencyAmount: 40000, bonusAmount: 40000, bonusLabel: "+100% BONUS",
                     priceLabel: "$49.99", isGold: true, tag: nil, iconSystemName: nil)
    ]

    static let specialPackages: [StoreSpecialPackage] = [
        StoreSpecialPackage(
            id: "special_starter",
            titleTR: "Başlangıç Paketi", titleEN: "Starter Bundle",
            subtitleTR: "Yeni yolculuğuna güçlü başla",
            subtitleEN: "Launch your journey with style",
            goldAmount: 1500, diamondAmount: 150,
            priceLabel: "$1.99", tag: .starter
        ),
        StoreSpecialPackage(
            id: "special_pro",
            titleTR: "Pro Paketi", titleEN: "Pro Bundle",
            subtitleTR: "Elmas ve altın birlikte",
            subtitleEN: "Diamonds & gold combined",
            goldAmount: 8000, diamondAmount: 750,
            priceLabel: "$9.99", tag: .popular
        ),
        StoreSpecialPackage(
            id: "special_elite",
            titleTR: "Elit Paketi", titleEN: "Elite Bundle",
            subtitleTR: "Hafta sonu özel — tüm ilerlemeye tam güç",
            subtitleEN: "Weekend only — maximum progression",
            goldAmount: 25000, diamondAmount: 2500,
            priceLabel: "$24.99", tag: .limited
        ),
        StoreSpecialPackage(
            id: "special_legend",
            titleTR: "Efsane Paketi", titleEN: "Legend Bundle",
            subtitleTR: "Oyun içi tüm kilitleri aç",
            subtitleEN: "Unlock the full arsenal",
            goldAmount: 60000, diamondAmount: 7500,
            priceLabel: "$49.99", tag: .bestValue
        )
    ]
}

// MARK: - StoreView

struct StoreView: View {
    @EnvironmentObject var userEnv: UserEnvironment
    @State private var selectedTab: StoreTab = .diamonds
    @State private var pendingPackage: PendingPurchase? = nil
    @State private var successToast: String? = nil

    var body: some View {
        ZStack {
            ThemeColors.backgroundGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                currencyRow
                tabSelector
                    .padding(.top, 8)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        switch selectedTab {
                        case .diamonds:
                            ForEach(StoreCatalog.diamondPackages) { pkg in
                                currencyCard(pkg)
                            }
                        case .gold:
                            ForEach(StoreCatalog.goldPackages) { pkg in
                                currencyCard(pkg)
                            }
                        case .specials:
                            ForEach(StoreCatalog.specialPackages) { pkg in
                                specialCard(pkg)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }

                footer
            }

            if let toast = successToast {
                toastOverlay(text: toast)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(10)
            }
        }
        .alert(item: $pendingPackage) { pending in
            Alert(
                title: Text(userEnv.localizedString("Satın Alma Onayı", "Confirm Purchase")),
                message: Text(pending.confirmationText(lang: userEnv.language)),
                primaryButton: .default(Text(pending.price), action: {
                    performPurchase(pending)
                }),
                secondaryButton: .cancel(Text(userEnv.localizedString("İptal", "Cancel")))
            )
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button {
                HapticManager.shared.play(.buttonTap)
                MainViewsRouter.shared.dismissModal()
            } label: {
                Image("ui_close")
                    .resizable()
                    .frame(width: 44, height: 44)
                    .background(ThemeColors.surfaceDark)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(ThemeColors.gridStroke, lineWidth: 1))
            }

            Spacer()

            VStack(spacing: 2) {
                Text(userEnv.localizedString("MAĞAZA", "STORE"))
                    .font(.setCustomFont(name: .InterBlack, size: 24))
                    .foregroundStyle(ThemeColors.neonCyan)
                    .tracking(3)
                Text(userEnv.localizedString("GERÇEK PARA İLE", "REAL MONEY"))
                    .font(.setCustomFont(name: .InterBold, size: 9))
                    .tracking(3)
                    .foregroundStyle(ThemeColors.textMuted)
            }

            Spacer()

            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    // MARK: - Currency Row

    private var currencyRow: some View {
        HStack(spacing: 12) {
            currencyCapsule(iconName: "icon_gold", value: userEnv.gold, color: ThemeColors.electricYellow)
            currencyCapsule(iconName: "icon_diamond", value: userEnv.diamonds, color: ThemeColors.neonCyan)
        }
        .padding(.horizontal, 20)
    }

    private func currencyCapsule(iconName: String, value: Int, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(iconName)
                .resizable()
                .frame(width: 22, height: 22)
            Text("\(value)")
                .font(.setCustomFont(name: .InterExtraBold, size: 18))
                .foregroundStyle(color)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(color.opacity(0.4), lineWidth: 1))
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        HStack(spacing: 8) {
            ForEach(StoreTab.allCases, id: \.rawValue) { tab in
                Button {
                    HapticManager.shared.play(.buttonTap)
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedTab = tab
                    }
                } label: {
                    Text(userEnv.localizedString(tab.titleTR(), tab.titleEN()))
                        .font(.setCustomFont(name: .InterExtraBold, size: 13))
                        .tracking(2)
                        .foregroundStyle(
                            selectedTab == tab ? ThemeColors.cosmicBlack : ThemeColors.textSecondary
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            ZStack {
                                if selectedTab == tab {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(tabColor(tab))
                                        .shadow(color: tabColor(tab).opacity(0.6), radius: 12)
                                } else {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(ThemeColors.surfaceDark)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(ThemeColors.gridStroke, lineWidth: 1)
                                        )
                                }
                            }
                        )
                }
            }
        }
        .padding(.horizontal, 20)
    }

    private func tabColor(_ tab: StoreTab) -> Color {
        switch tab {
        case .diamonds: return ThemeColors.neonCyan
        case .gold:     return ThemeColors.electricYellow
        case .specials: return ThemeColors.neonPink
        }
    }

    // MARK: - Currency Card (Diamond / Gold)

    private func currencyCard(_ pkg: StorePackage) -> some View {
        let accent: Color = pkg.isGold ? ThemeColors.electricYellow : ThemeColors.neonCyan
        let iconName: String = pkg.isGold ? "icon_gold" : "icon_diamond"

        return Button {
            HapticManager.shared.play(.buttonTap)
            pendingPackage = PendingPurchase(
                id: pkg.id,
                title: userEnv.localizedString(pkg.titleTR, pkg.titleEN),
                amountText: "\(pkg.totalAmount)",
                price: pkg.priceLabel,
                iconName: iconName,
                isGold: pkg.isGold,
                goldAmount: pkg.isGold ? pkg.totalAmount : 0,
                diamondAmount: pkg.isGold ? 0 : pkg.totalAmount
            )
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(accent.opacity(0.12))
                        .frame(width: 78, height: 78)
                    Image(iconName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 48, height: 48)
                        .shadow(color: accent.opacity(0.5), radius: 8)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(userEnv.localizedString(pkg.titleTR, pkg.titleEN))
                        .font(.setCustomFont(name: .InterBold, size: 12))
                        .tracking(1)
                        .foregroundStyle(ThemeColors.textSecondary)

                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(pkg.totalAmount)")
                            .font(.setCustomFont(name: .InterBlack, size: 26))
                            .foregroundStyle(accent)
                        Text(pkg.isGold
                             ? userEnv.localizedString("ALTIN", "GOLD")
                             : userEnv.localizedString("ELMAS", "GEMS"))
                            .font(.setCustomFont(name: .InterExtraBold, size: 11))
                            .tracking(2)
                            .foregroundStyle(ThemeColors.textMuted)
                    }

                    if let bonus = pkg.bonusLabel {
                        Text(bonus)
                            .font(.setCustomFont(name: .InterExtraBold, size: 9))
                            .tracking(2)
                            .foregroundStyle(ThemeColors.neonGreen)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(ThemeColors.neonGreen.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }

                Spacer()

                priceBadge(pkg.priceLabel, accent: accent)
            }
            .padding(14)
            .background(cardBackground(accent: accent, tag: pkg.tag))
            .overlay(alignment: .topTrailing) {
                if let tag = pkg.tag {
                    tagBadge(tag)
                        .offset(x: -10, y: -8)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Special Card (Bundle)

    private func specialCard(_ pkg: StoreSpecialPackage) -> some View {
        Button {
            HapticManager.shared.play(.buttonTap)
            pendingPackage = PendingPurchase(
                id: pkg.id,
                title: userEnv.localizedString(pkg.titleTR, pkg.titleEN),
                amountText: "\(pkg.goldAmount) + \(pkg.diamondAmount)",
                price: pkg.priceLabel,
                iconName: "icon_diamond",
                isGold: false,
                goldAmount: pkg.goldAmount,
                diamondAmount: pkg.diamondAmount
            )
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(userEnv.localizedString(pkg.titleTR, pkg.titleEN))
                            .font(.setCustomFont(name: .InterBlack, size: 18))
                            .foregroundStyle(ThemeColors.textPrimary)
                            .tracking(1)
                        Text(userEnv.localizedString(pkg.subtitleTR, pkg.subtitleEN))
                            .font(.setCustomFont(name: .InterMedium, size: 11))
                            .foregroundStyle(ThemeColors.textMuted)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                    }
                    Spacer()
                    priceBadge(pkg.priceLabel, accent: pkg.tag.color)
                }

                HStack(spacing: 10) {
                    bundleRewardCapsule(
                        iconName: "icon_gold",
                        amount: pkg.goldAmount,
                        color: ThemeColors.electricYellow
                    )
                    bundleRewardCapsule(
                        iconName: "icon_diamond",
                        amount: pkg.diamondAmount,
                        color: ThemeColors.neonCyan
                    )
                }
            }
            .padding(14)
            .background(cardBackground(accent: pkg.tag.color, tag: pkg.tag))
            .overlay(alignment: .topTrailing) {
                tagBadge(pkg.tag)
                    .offset(x: -10, y: -8)
            }
        }
        .buttonStyle(.plain)
    }

    private func bundleRewardCapsule(iconName: String, amount: Int, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(iconName)
                .resizable()
                .frame(width: 20, height: 20)
            Text("\(amount)")
                .font(.setCustomFont(name: .InterExtraBold, size: 15))
                .foregroundStyle(color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(color.opacity(0.35), lineWidth: 1))
    }

    // MARK: - Shared UI

    private func priceBadge(_ label: String, accent: Color) -> some View {
        Text(label)
            .font(.setCustomFont(name: .InterBlack, size: 15))
            .tracking(1)
            .foregroundStyle(ThemeColors.cosmicBlack)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(accent)
                    .shadow(color: accent.opacity(0.5), radius: 8)
            )
    }

    private func cardBackground(accent: Color, tag: PackageTag?) -> some View {
        let strokeColor: Color = tag?.color ?? accent.opacity(0.3)
        let strokeWidth: CGFloat = tag == nil ? 1 : 1.5
        return RoundedRectangle(cornerRadius: 16)
            .fill(ThemeColors.surfaceDark)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(strokeColor, lineWidth: strokeWidth)
            )
    }

    private func tagBadge(_ tag: PackageTag) -> some View {
        Text(userEnv.localizedString(tag.titleTR(), tag.titleEN()))
            .font(.setCustomFont(name: .InterBlack, size: 9))
            .tracking(2)
            .foregroundStyle(ThemeColors.cosmicBlack)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule().fill(tag.color)
                    .shadow(color: tag.color.opacity(0.6), radius: 6)
            )
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 4) {
            Text(userEnv.localizedString(
                "Satın alımlar hesabınıza bağlıdır.",
                "Purchases are tied to your account."
            ))
            .font(.setCustomFont(name: .InterMedium, size: 10))
            .foregroundStyle(ThemeColors.textMuted)
            Text(userEnv.localizedString(
                "Geri Yükle · Kullanım Şartları · Gizlilik",
                "Restore · Terms · Privacy"
            ))
            .font(.setCustomFont(name: .InterMedium, size: 10))
            .foregroundStyle(ThemeColors.textMuted.opacity(0.75))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(ThemeColors.cosmicBlack.opacity(0.4))
    }

    // MARK: - Toast

    private func toastOverlay(text: String) -> some View {
        VStack {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(ThemeColors.neonGreen)
                Text(text)
                    .font(.setCustomFont(name: .InterBold, size: 13))
                    .foregroundStyle(ThemeColors.textPrimary)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(ThemeColors.surfaceDark)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(ThemeColors.neonGreen.opacity(0.6), lineWidth: 1)
                    )
                    .shadow(color: ThemeColors.neonGreen.opacity(0.5), radius: 14)
            )
            .padding(.top, 60)
            Spacer()
        }
    }

    // MARK: - Purchase Flow (MOCK)
    //
    // StoreKit entegrasyonu eklenene kadar bu fonksiyon simüle edilmiş
    // bir satın alma akışı çalıştırır:
    //   1) Onay alındıktan sonra seçilen miktar UserEnvironment'a eklenir.
    //   2) Coin SFX + success haptic çalınır.
    //   3) Ekranda başarı toast'u gösterilir.
    //
    // Production'da burada StoreKit 2'nin Product.purchase() çağrısı
    // yapılacak, Transaction.finish() ile doğrulama tamamlanacak.

    private func performPurchase(_ pending: PendingPurchase) {
        if pending.goldAmount > 0 {
            userEnv.earn(gold: pending.goldAmount)
        }
        if pending.diamondAmount > 0 {
            userEnv.earn(diamonds: pending.diamondAmount)
        }

        HapticManager.shared.play(.success)
        AudioManager.shared.playSFX(.coin)

        let msg: String
        if pending.goldAmount > 0 && pending.diamondAmount > 0 {
            msg = userEnv.localizedString(
                "+\(pending.goldAmount) Altın, +\(pending.diamondAmount) Elmas eklendi!",
                "+\(pending.goldAmount) Gold, +\(pending.diamondAmount) Gems added!"
            )
        } else if pending.goldAmount > 0 {
            msg = userEnv.localizedString(
                "+\(pending.goldAmount) Altın eklendi!",
                "+\(pending.goldAmount) Gold added!"
            )
        } else {
            msg = userEnv.localizedString(
                "+\(pending.diamondAmount) Elmas eklendi!",
                "+\(pending.diamondAmount) Gems added!"
            )
        }

        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            successToast = msg
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation(.easeOut(duration: 0.3)) {
                successToast = nil
            }
        }
    }
}

// MARK: - Pending Purchase Model

struct PendingPurchase: Identifiable {
    let id: String
    let title: String
    let amountText: String
    let price: String
    let iconName: String
    let isGold: Bool
    let goldAmount: Int
    let diamondAmount: Int

    func confirmationText(lang: AppLanguage) -> String {
        switch lang {
        case .turkish:
            return "\(title)\n\n\(amountText) karşılığı \(price) ödenecek.\n(UI-Only · StoreKit yakında)"
        case .english:
            return "\(title)\n\n\(amountText) for \(price).\n(UI-Only · StoreKit coming soon)"
        }
    }
}

// MARK: - Preview

#Preview {
    StoreView()
        .environmentObject(UserEnvironment.shared)
}
