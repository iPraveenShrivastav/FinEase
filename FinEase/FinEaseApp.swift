//
//  FinEaseApp.swift
//  FinEase
//
//  Created by isdp on 04/04/26.
//

import SwiftUI
import SwiftData

@main
struct FinEaseApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [TransactionRecord.self, SavingsGoalRecord.self])
    }
}
