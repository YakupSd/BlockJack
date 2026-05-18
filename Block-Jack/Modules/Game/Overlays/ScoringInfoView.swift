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
                        InfoSectionView(title: userEnv.labelBaseChipsTitle, icon: "square.grid.3x3.fill", color: .white) {
                            Text(userEnv.labelBaseChipsDesc)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            
                            HStack(spacing: 12) {
                                MiniStatView(label: userEnv.labelMass, value: "x25", color: ThemeColors.neonCyan)
                                MiniStatView(label: userEnv.labelNeighbor, value: "x12", color: ThemeColors.electricYellow)
                                MiniStatView(label: userEnv.labelCluster, value: "x8", color: ThemeColors.neonPink)
                            }
                        }
                        
                        // 2. Color Values
                        InfoSectionView(title: userEnv.labelColorMultipliersTitle, icon: "paintpalette.fill", color: ThemeColors.neonPurple) {
                            Text(userEnv.labelColorMultipliersDesc)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            
                            VStack(spacing: 8) {
                                ColorRowView(colorName: userEnv.labelColorPurple, value: "+1.5x", color: ThemeColors.blockPurple)
                                ColorRowView(colorName: userEnv.labelColorYellow, value: "+1.2x", color: ThemeColors.blockYellow)
                                ColorRowView(colorName: userEnv.labelColorRed, value: "+1.0x", color: ThemeColors.blockRed)
                                ColorRowView(colorName: userEnv.labelColorGreen, value: "+0.7x", color: ThemeColors.blockGreen)
                                ColorRowView(colorName: userEnv.labelColorBlue, value: "+0.5x", color: ThemeColors.blockBlue)
                            }
                        }
                        
                        // 3. Patterns & Combos
                        InfoSectionView(title: userEnv.labelPatternsTitle, icon: "bolt.fill", color: ThemeColors.electricYellow) {
                            Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 10) {
                                PatternRow(name: userEnv.labelPatternMixed, value: "+2.5")
                                PatternRow(name: userEnv.labelPatternDuoTone, value: "+5.0")
                                PatternRow(name: userEnv.labelPatternFlush, value: "+16.0")
                                PatternRow(name: userEnv.labelPatternSuperFlush, value: "+40.0")
                                Divider().background(Color.gray.opacity(0.3))
                                PatternRow(name: userEnv.labelPattern2LineCombo, value: "+6.0")
                                PatternRow(name: userEnv.labelPattern4LineCombo, value: "+24.0")
                            }
                        }
                        
                        // 4. Streak
                        InfoSectionView(title: userEnv.labelStreakTitle, icon: "flame.fill", color: ThemeColors.neonOrange) {
                            Text(userEnv.labelStreakDesc)
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
                        InfoSectionView(title: userEnv.labelGoalsTitle, icon: "target", color: ThemeColors.neonCyan) {
                            VStack(spacing: 12) {
                                EstimateRow(move: userEnv.labelGoalSingleMixedLine, score: "700 - 900")
                                EstimateRow(move: userEnv.labelGoal2LineDuoTone, score: "3,000 - 5,000")
                                EstimateRow(move: userEnv.labelGoalSinglePurpleFlush, score: "8,000 - 12,000")
                                EstimateRow(move: userEnv.labelGoalZoneFlush, score: "50,000+")
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
                Text(userEnv.labelScoringSystem)
                    .font(.system(size: 24, weight: .black, design: .monospaced))
                    .foregroundColor(ThemeColors.neonCyan)
                Text(userEnv.labelScoringSystemDesc)
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
            Text(userEnv.labelPts).font(.system(size: 8)).foregroundColor(.gray)
        }
    }
}

#Preview {
    ScoringInfoView()
}
