//
//  EvapotrackDevApp.swift
//  EvapotrackDev
//
//  Created by Dana Lefebvre Jr on 3/1/26.
//

import SwiftUI
import CoreData

@main
struct EvapotrackDevApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
