//
//  AdaptiveOverlayLayout.swift
//  Block-Jack
//
//  Node overlay'larının (RestSiteView, BattleRewardView, MysteryEventView,
//  TreasureRoomView) ortak düzen sarmalayıcısı.
//
//  Önceki durum: her overlay VStack { Spacer; içerik; Spacer; footer } + sabit
//  padding.top(40) + 32-36pt başlık kullanıyordu. iPhone SE gibi kısa ekranlarda
//  içerik ScrollView olmadığı için sıkışıyor, başlık + 2-3 kart + footer üst
//  üste biniyor, dinamik yazı tipinde kırpılıyordu.
//
//  Bu wrapper:
//    • İçeriği ScrollView içine alıyor (küçük ekranda doğal scroll; uzun
//      ekranda Spacer'larla ortalıyor)
//    • Header + content + footer'ı tek sorumlulukta topluyor
//    • Safe area paddinglerini dinamik yönetiyor
//    • Başlıkları minimumScaleFactor/lineLimit ile koruyor
//

import SwiftUI

struct AdaptiveOverlay<Header: View, Content: View, Footer: View>: View {
    private let header: () -> Header
    private let content: () -> Content
    private let footer: () -> Footer
    private let hasFooter: Bool

    init(
        @ViewBuilder header: @escaping () -> Header,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder footer: @escaping () -> Footer
    ) {
        self.header = header
        self.content = content
        self.footer = footer
        self.hasFooter = true
    }

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 24) {
                        header()
                            .padding(.top, max(geo.safeAreaInsets.top + 4, 16))

                        content()
                            .frame(maxWidth: .infinity)

                        Color.clear.frame(height: 8)
                    }
                    // Önce genişliği ekran genişliğiyle sabitle, sonra minHeight ver.
                    // SwiftUI frame API'si width + minHeight'ı tek çağrıda
                    // kabul etmediği için iki adıma bölüyoruz.
                    .frame(width: geo.size.width, alignment: .top)
                    .frame(
                        minHeight: geo.size.height - (hasFooter ? 96 : 24),
                        alignment: .top
                    )
                }

                if hasFooter {
                    footer()
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, max(geo.safeAreaInsets.bottom + 6, 14))
                        .background(
                            LinearGradient(
                                colors: [Color.black.opacity(0.0),
                                         Color.black.opacity(0.55)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

// Footer yoksa pratik kısa form
extension AdaptiveOverlay where Footer == EmptyView {
    init(
        @ViewBuilder header: @escaping () -> Header,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.header = header
        self.content = content
        self.footer = { EmptyView() }
        self.hasFooter = false
    }
}

// MARK: - Ortak Başlık

/// Overlay başlığı için tek-doğrulukta, dinamik-tip güvenli kart.
struct OverlayTitleBlock: View {
    let title: String
    let subtitle: String?
    let color: Color

    init(_ title: String, subtitle: String? = nil, color: Color) {
        self.title = title
        self.subtitle = subtitle
        self.color = color
    }

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.custom("Outfit-Bold", size: 30, relativeTo: .largeTitle))
                .foregroundColor(color)
                .shadow(color: color.opacity(0.8), radius: 8)
                .lineLimit(1)
                .minimumScaleFactor(0.55)

            if let subtitle {
                Text(subtitle)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 20)
    }
}
