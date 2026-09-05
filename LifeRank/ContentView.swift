//
//  ContentView.swift
//  LifeRank
//
//  Created by David Howard on 9/4/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Character", systemImage: "person.crop.square") {
                CharacterView()
            }
            Tab("Skills", systemImage: "list.bullet") {
                SkillsView()
            }
            Tab("Log", systemImage: "plus.circle") {
                LogActivityView()
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [ActivityRecord.self, XPEventRecord.self], inMemory: true)
}
