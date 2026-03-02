// HistoryPanelView.swift
// Evapotrack
//
// Summary row on the dashboard that shows log count and links
// to the full HistoryView. No inline log display.

import SwiftUI

struct HistoryPanelView: View {
    var vm: PlantDashboardViewModel
    let waterUnit: WaterUnit
    let maxRetentionCapacity: Double

    var body: some View {
        Section {
            NavigationLink {
                HistoryView(
                    vm: vm,
                    waterUnit: waterUnit,
                    maxRetentionCapacity: maxRetentionCapacity
                )
            } label: {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundStyle(.evPrimaryBlue)
                        .font(.body.weight(.semibold))
                    Text("View All Logs")
                        .fontWeight(.semibold)
                        .foregroundStyle(.evPrimaryBlue)
                    Spacer()
                    Text("\(vm.wateringLogs.count)")
                        .fontWeight(.semibold)
                        .foregroundStyle(.evPrimaryBlue)
                }
            }
        } header: {
            Label {
                Text("History")
            } icon: {
                Image(systemName: "clock")
            }
            .font(.title2.weight(.bold))
            .foregroundStyle(.evDeepNavy)
            .textCase(nil)
        }
    }
}
