//
//  ScoringInfoView.swift
//  Block-Jack
//
//  A beautiful overlay that explains the V4 Generous Scoring System.
//

import SwiftUI

struct ScoringInfoView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var userEnv: UserEnvironment
    
    var body: some View {
        ZStack {
            // Background Blur
            Color.black.opacity(0.85)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // 1. Base Chips
                        InfoSectionView(title: userEnv.localizedString("1. TABAN CHIP (YERLEŞTİRME)", "1. BASE CHIPS (THE SNAP)"), icon: "square.grid.3x3.fill", color: .white) {
                            Text(userEnv.localizedString(
                                "Her yerleştirilen blok; Kütle, Komşular ve Renk Gruplarına göre chip üretir. Karmaşıklık arttıkça daha fazla chip kazanırsın.",
                                "Every placed block generates chips based on its **Mass**, **Neighbors**, and **Color Clusters**. Higher complexity = more chips."
                            ))
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            
                            HStack(spacing: 12) {
                                MiniStatView(label: userEnv.localizedString("KÜTLE", "MASS"), value: "x25", color: ThemeColors.neonCyan)
                                MiniStatView(label: userEnv.localizedString("KOMŞU", "NEIGHBOR"), value: "x12", color: ThemeColors.electricYellow)
                                MiniStatView(label: userEnv.localizedString("GRUP", "CLUSTER"), value: "x8", color: ThemeColors.neonPink)
                            }
                        }
                        
                        // 2. Color Values
                        InfoSectionView(title: userEnv.localizedString("2. RENK ÇARPANLARI", "2. COLOR MULTIPLIERS"), icon: "paintpalette.fill", color: ThemeColors.neonPurple) {
                            Text(userEnv.localizedString(
                                "Yüksek değerli renklerle satır temizleyerek çarpanını yükselt. Ortalama renk değeri toplam çarpanına eklenir.",
                                "Clear lines with high-value colors to boost your multiplier. The average color value is added to your total mult."
                            ))
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            
                            VStack(spacing: 8) {
                                ColorRowView(colorName: userEnv.localizedString("MOR (PURPLE)", "PURPLE"), value: "+1.5x", color: ThemeColors.blockPurple)
                                ColorRowView(colorName: userEnv.localizedString("SARI (YELLOW)", "YELLOW"), value: "+1.2x", color: ThemeColors.blockYellow)
                                ColorRowView(colorName: userEnv.localizedString("KIRMIZI (RED)", "RED"), value: "+1.0x", color: ThemeColors.blockRed)
                                ColorRowView(colorName: userEnv.localizedString("YEŞİL (GREEN)", "GREEN"), value: "+0.7x", color: ThemeColors.blockGreen)
                                ColorRowView(colorName: userEnv.localizedString("MAVİ (BLUE)", "BLUE"), value: "+0.5x", color: ThemeColors.blockBlue)
                            }
                        }
                        
                        // 3. Patterns & Combos
                        InfoSectionView(title: userEnv.localizedString("3. PATERNLER & KOMBOLAR", "3. PATTERNS & COMBOS"), icon: "bolt.fill", color: ThemeColors.electricYellow) {
                            Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 10) {
                                PatternRow(name: userEnv.localizedString("Mixed (Karışık)", "Mixed"), value: "+2.5")
                                PatternRow(name: userEnv.localizedString("Duo-Tone (2 Renk)", "Duo-Tone"), value: "+5.0")
                                PatternRow(name: userEnv.localizedString("Flush (Tek Renk)", "Flush"), value: "+16.0")
                                PatternRow(name: userEnv.localizedString("Super Flush (2+ Flush)", "Super Flush"), value: "+40.0")
                                Divider().background(Color.gray.opacity(0.3))
                                PatternRow(name: userEnv.localizedString("2'li Kombo", "2-Line Combo"), value: "+6.0")
                                PatternRow(name: userEnv.localizedString("4'lü (QUAD) Kombo", "4-Line (QUAD)"), value: "+24.0")
                            }
                        }
                        
                        // 4. Streak
                        InfoSectionView(title: userEnv.localizedString("4. SERİ (STREAK)", "4. THE STREAK"), icon: "flame.fill", color: ThemeColors.neonOrange) {
                            Text(userEnv.localizedString(
                                "Serini koruyarak her şeyi katla! Bonus başlangıçta doğrusal artar, denge için **3.8x**'te limitlenir.",
                                "Maintain your streak to multiply everything! The bonus grows linearly at first, then caps at **3.8x** to keep things balanced."
                            ))
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            
                            HStack {
                                StreakMilestone(streak: "0", mult: "1.0x")
                                Spacer()
                                Image(systemName: "arrow.right").foregroundColor(.gray)
                                Spacer()
                                StreakMilestone(streak: "10", mult: "2.2x")
                                Spacer()
                                Image(systemName: "arrow.right").foregroundColor(.gray)
                                Spacer()
                                StreakMilestone(streak: "30+", mult: "3.8x")
                            }
                            .padding(.top, 8)
                        }
                        
                        // 5. Estimated Scores
                        InfoSectionView(title: userEnv.localizedString("HEDEFLER & TAHMİNLER", "GOALS & MILESTONES"), icon: "target", color: ThemeColors.neonCyan) {
                            VStack(spacing: 12) {
                                EstimateRow(move: userEnv.localizedString("Tek Karışık Satır", "Single Mixed Line"), score: "700 - 900")
                                EstimateRow(move: userEnv.localizedString("2'li Duo-Tone Kombo", "2-Line Duo-Tone"), score: "3,000 - 5,000")
                                EstimateRow(move: userEnv.localizedString("Tek Mor Flush", "Single Flush (Purple)"), score: "8,000 - 12,000")
                                EstimateRow(move: userEnv.localizedString("4x4 Alan Temizliği", "4x4 Zone Flush"), score: "50,000+")
                            }
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(20)
                }
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(userEnv.localizedString("PUAN SİSTEMİ", "SCORING SYSTEM"))
                    .font(.system(size: 24, weight: .black, design: .monospaced))
                    .foregroundColor(ThemeColors.neonCyan)
                Text(userEnv.localizedString("Matematikte ustalaş, tahtaya hükmet.", "Master the math, dominate the board."))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(24)
        .background(Color.black.opacity(0.3))
        .zIndex(10)
    }
}

// MARK: - Subviews

struct InfoSectionView<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    let content: Content
    
    init(title: String, icon: String, color: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.color = color
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
            
            content
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.05)))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(color.opacity(0.3), lineWidth: 1))
        }
    }
}

struct MiniStatView: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.gray)
            Text(value)
                .font(.system(size: 16, weight: .black))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.3))
        .cornerRadius(8)
    }
}

struct ColorRowView: View {
    let colorName: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(colorName).font(.caption).foregroundColor(.white)
            Spacer()
            Text(value).font(.caption.bold()).foregroundColor(color)
        }
        .padding(.horizontal, 8)
    }
}

struct PatternRow: View {
    let name: String
    let value: String
    var body: some View {
        GridRow {
            Text(name).font(.caption).foregroundColor(.gray)
            Text(value).font(.caption.bold()).foregroundColor(.white)
        }
    }
}

struct StreakMilestone: View {
    let streak: String
    let mult: String
    var body: some View {
        VStack(spacing: 2) {
            Text(streak).font(.caption2).foregroundColor(.gray)
            Text(mult).font(.subheadline.bold()).foregroundColor(ThemeColors.neonOrange)
        }
    }
}

struct EstimateRow: View {
    @EnvironmentObject var userEnv: UserEnvironment
    let move: String
    let score: String
    var body: some View {
        HStack {
            Text(move).font(.caption).foregroundColor(.gray)
            Spacer()
            Text(score).font(.caption.bold()).foregroundColor(ThemeColors.neonCyan)
            Text(userEnv.localizedString("puan", "pts")).font(.system(size: 8)).foregroundColor(.gray)
        }
    }
}

#Preview {
    ScoringInfoView()
}
