//
//  Block_JackApp.swift
//  Block-Jack
//
//  Created by Yakup Suda on 15.04.2026.
//

import SwiftUI
import CoreData

@main
struct Block_JackApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
