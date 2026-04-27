//
//  RestSiteView.swift
//  Block-Jack
//
//  Dinlenme node overlay'ı. Can onarımı veya altın seçimi.
//  Safe House perk'i varsa otomatik +100 altın ve kullanıcıya görsel bildirim.
//
//  Layout: AdaptiveOverlay kullanılıyor → SE gibi küçük ekranlarda ScrollView
//  içinde gezinir, başlık/metin minimumScaleFactor ile kırpılmadan sığar.
//

import SwiftUI

struct RestSiteView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var userEnv: UserEnvironment

    let slotId: Int
    @State private var hasActed = false
    @State private var showMessage = false
    @State private var message = ""
    @State private var safeHouseToastVisible = false

    private var safeHouseTier: Int {
        guard let slot = SaveManager.shared.slots.first(where: { $0.id == slotId }) else {
            return 0
        }
        return slot.activePassivePerks.first(where: { $0.id == "safe_house" })?.tier ?? 0
    }

    var body: some View {
        ZStack {
            backgroundLayer

            AdaptiveOverlay(
                header: {
                    OverlayTitleBlock(
                        "GÜVENLİ BÖLGE",
                        subtitle: "Sistemlerini optimize et ve dinlen.",
                        color: ThemeColors.neonCyan
                    )
                },
                content: {
                    if showMessage {
                        messageCard
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        actionButtons
                    }
                },
                footer: {
                    Button(action: {
                        NotificationCenter.default.post(name: NSNotification.Name("mapOverlayDidDismiss"), object: nil)
                        dismiss()
                    }) {
                        Text(hasActed ? "AYRIL" : "ŞİMDİLİK DEĞİL")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.1))
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            )

            safeHouseToast
                .animation(.spring(duration: 0.35), value: safeHouseToastVisible)
        }
        .onAppear { checkSafeHouseBonus() }
    }

    // MARK: - Background

    private var backgroundLayer: some View {
        ZStack {
            GeometryReader { geo in
                // .fill kırptığı için küçük ekranlarda yazılar görünmüyordu.
                // Burada arka plan “tam sığsın” (fit) + ortala.
                Image("cyber_rest_station")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .background(Color.black)
                    .clipped()
            }
            .ignoresSafeArea()

            Color.black.opacity(0.72).ignoresSafeArea()

            RadialGradient(
                colors: [ThemeColors.neonCyan.opacity(0.22), .clear],
                center: .center,
                startRadius: 0,
                endRadius: 600
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - Seçim kartları

    private var actionButtons: some View {
        VStack(spacing: 16) {
            restButton(
                title: "SİSTEM ONARIMI",
                icon: "heart.fill",
                desc: "+1 Yaşam Puanı kazan.",
                color: ThemeColors.neonPink
            ) {
                SaveManager.shared.updateLives(slotId: slotId, amount: 1)
                completeAction("Sistemler onarıldı. +1 Can eklendi.")
            }

            restButton(
                title: "VERİ MADENCİLİĞİ",
                icon: "cpu.fill",
                desc: "Hızlıca veri topla ve 50 Altın kazan.",
                color: ThemeColors.electricYellow
            ) {
                SaveManager.shared.updateGold(slotId: slotId, amount: 50)
                completeAction("Veriler toplandı. +50 Altın kazanıldı.")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private func restButton(
        title: String,
        icon: String,
        desc: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 48, height: 48)
                    .background(color.opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.custom("Outfit-Bold", size: 16))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(desc)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(color.opacity(0.35), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Onay mesajı

    private var messageCard: some View {
        VStack(spacing: 14) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 52))
                .foregroundColor(ThemeColors.success)
                .shadow(color: ThemeColors.success.opacity(0.8), radius: 8)

            Text(message)
                .font(.title3.weight(.semibold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(ThemeColors.success.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
    }

    // MARK: - Safe House bildirimi

    private var safeHouseToast: some View {
        VStack {
            if safeHouseToastVisible {
                HStack(spacing: 10) {
                    Image(systemName: "shield.lefthalf.filled")
                        .foregroundColor(ThemeColors.electricYellow)
                    Text(userEnv.localizedString("SAFE HOUSE (L\(safeHouseTier)) bonusu: +\(50 + (safeHouseTier * 50)) Altın", "SAFE HOUSE (L\(safeHouseTier)) bonus: +\(50 + (safeHouseTier * 50)) Gold"))
                        .font(.footnote.weight(.bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.black.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(ThemeColors.electricYellow.opacity(0.6), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.top, 70)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            Spacer()
        }
    }

    // MARK: - Safe House bonusu

    private func checkSafeHouseBonus() {
        let tier = safeHouseTier
        guard tier > 0 else { return }
        
        let bonusAmount = 50 + (tier * 50)
        
        // Gecikmeli olarak uygula, kullanıcı ekranı tanısın
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            HapticManager.shared.play(.success)
            SaveManager.shared.updateGold(slotId: slotId, amount: bonusAmount)
            withAnimation { safeHouseToastVisible = true }

            // 2.2s sonra toast'u kapat
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                withAnimation { safeHouseToastVisible = false }
            }
        }
    }

    // MARK: - Helpers

    private func completeAction(_ msg: String) {
        HapticManager.shared.play(.success)
        withAnimation(.spring()) {
            message = msg
            hasActed = true
            showMessage = true
        }
    }
}
