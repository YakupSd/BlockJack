//
//  PerkStatsView.swift
//  Block-Jack
//

import SwiftUI

struct PerkStatsView: View {
    @EnvironmentObject var userEnv: UserEnvironment
    @ObservedObject var careerVM: CareerStatsViewModel
    
    var sortedPerks: [(String, PerkCareerStats)] {
        careerVM.careerStats.perkStats
            .sorted { $0.value.timesUsed > $1.value.timesUsed }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            if sortedPerks.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 32))
                        .foregroundStyle(ThemeColors.textMuted)
                    Text(userEnv.labelNoPerksUsed)
                        .font(.setCustomFont(name: .InterMedium, size: 14))
                        .foregroundStyle(ThemeColors.textMuted)
                }
                .frame(maxWidth: .infinity)
                .padding(32)
            } else {
                VStack(spacing: 8) {
                    HStack {
                        Text(userEnv.language == .turkish ? "Toplam Perk Türü: \(sortedPerks.count)" : "Total Unique Perks: \(sortedPerks.count)")
                            .font(.setCustomFont(name: .InterMedium, size: 12))
                            .foregroundStyle(ThemeColors.textMuted)
                        Spacer()
                    }
                }
                .padding(.bottom, 8)
                
                ForEach(sortedPerks, id: \.0) { perkID, stats in
                    PerkStatRow(
                        perkID: perkID,
                        stats: stats,
                        careerVM: careerVM
                    )
                }
            }
            
            Spacer(minLength: 20)
        }
    }
}

// MARK: - Perk Stat Row
struct PerkStatRow: View {
    @EnvironmentObject var userEnv: UserEnvironment
    let perkID: String
    let stats: PerkCareerStats
    let careerVM: CareerStatsViewModel
    
    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(ThemeColors.neonPurple.opacity(0.2))
                    
                    if perkID.isEmpty {
                        Image(systemName: "questionmark")
                            .foregroundStyle(ThemeColors.neonPurple)
                    } else {
                        Image(perkID)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 36, height: 36)
                    }
                }
                .frame(width: 50, height: 50)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(perkID.isEmpty ? "Unknown" : perkID.uppercased())
                        .font(.setCustomFont(name: .InterBold, size: 13))
                        .foregroundStyle(ThemeColors.neonPurple)
                    
                    HStack(spacing: 12) {
                        Label("\(stats.timesUsed)x", systemImage: "repeat")
                            .font(.setCustomFont(name: .InterMedium, size: 11))
                            .foregroundStyle(ThemeColors.textMuted)
                        
                        Label("\(stats.averageRunScore) avg", systemImage: "target")
                            .font(.setCustomFont(name: .InterMedium, size: 11))
                            .foregroundStyle(ThemeColors.textMuted)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(careerVM.getFormattedDamage(stats.totalDamageDealt))
                        .font(.setCustomFont(name: .InterBold, size: 14))
                        .foregroundStyle(ThemeColors.neonPink)
                    
                    Text(userEnv.language == .turkish ? "hasar" : "damage")
                        .font(.setCustomFont(name: .InterMedium, size: 10))
                        .foregroundStyle(ThemeColors.textMuted)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(ThemeColors.surfaceDark.opacity(0.5))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(ThemeColors.gridStroke.opacity(0.5), lineWidth: 1))
            )
        }
    }
}

#Preview {
    PerkStatsView(careerVM: CareerStatsViewModel())
        .environmentObject(UserEnvironment.shared)
}
