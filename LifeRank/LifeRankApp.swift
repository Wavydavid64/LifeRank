//
//  LifeRankApp.swift
//  LifeRank
//
//  Created by David Howard on 9/4/26.
//

import SwiftUI
import SwiftData

@main
struct LifeRankApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [ActivityRecord.self, XPEventRecord.self])
    }
}
