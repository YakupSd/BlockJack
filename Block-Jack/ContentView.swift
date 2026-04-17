//
//  ContentView.swift
//  Block-Jack
//
//  Root view — tüm navigasyon DashboardView üzerinden yönetilir.

import SwiftUI

struct ContentView: View {
    var body: some View {
        DashboardView()
    }
}

#Preview {
    ContentView()
        .environmentObject(UserEnvironment.shared)
}
