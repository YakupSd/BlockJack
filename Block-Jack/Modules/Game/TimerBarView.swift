//
//  TimerBarView.swift
//  Block-Jack
//

import SwiftUI

struct TimerBarView: View {
    let ratio: Double       // 0.0 – 1.0
    let isFogMode: Bool     // Boss: Fog modifier

    @State private var pulse = false

    var barColor: Color { ThemeColors.timerColor(ratio: ratio) }
    var isCritical: Bool { ratio < 0.1 }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Arka plan
                RoundedRectangle(cornerRadius: 4)
                    .fill(ThemeColors.gridDark)

                if isFogMode {
                    // Fog boss: barı gizle
                    fogOverlay
                } else {
                    // Normal bar
                    RoundedRectangle(cornerRadius: 4)
                        .fill(barColor)
                        .frame(width: geo.size.width * max(0, ratio))
                        .animation(.linear(duration: 0.05), value: ratio)

                    // Glow efekti
                    RoundedRectangle(cornerRadius: 4)
                        .fill(barColor.opacity(0.3))
                        .frame(width: geo.size.width * max(0, ratio))
                        .blur(radius: 4)
                        .animation(.linear(duration: 0.05), value: ratio)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .frame(height: 8)
        .overlay {
            // Kritik: kırmızı kenar pulse
            if isCritical && !isFogMode {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(ThemeColors.neonPink.opacity(pulse ? 0.8 : 0.2), lineWidth: 2)
                    .animation(.easeInOut(duration: 0.4).repeatForever(), value: pulse)
            }
        }
        .onAppear {
            pulse = true
        }
    }

    private var fogOverlay: some View {
        HStack(spacing: 4) {
            ForEach(0..<12, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 2)
                    .fill(ThemeColors.textMuted.opacity(0.4))
                    .frame(width: 8, height: 8)
            }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        TimerBarView(ratio: 1.0, isFogMode: false)
        TimerBarView(ratio: 0.6, isFogMode: false)
        TimerBarView(ratio: 0.2, isFogMode: false)
        TimerBarView(ratio: 0.05, isFogMode: false)
        TimerBarView(ratio: 0.5, isFogMode: true)
    }
    .padding()
    .background(ThemeColors.cosmicBlack)
}
