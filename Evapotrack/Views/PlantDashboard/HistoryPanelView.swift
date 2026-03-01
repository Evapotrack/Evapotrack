// HistoryPanelView.swift
// Evapotrack
//
// Summary row on the dashboard that shows log count and links
// to the full HistoryView. No inline log display.

import SwiftUI

struct HistoryPanelView: View {
    let logCount: Int
    let logs: [WateringLog]
    let waterUnit: WaterUnit
    let maxRetentionCapacity: Double
    let onDeleteLog: (WateringLog) -> Void

    var body: some View {
        Section {
            NavigationLink {
                HistoryView(
                    logs: logs,
                    waterUnit: waterUnit,
                    maxRetentionCapacity: maxRetentionCapacity,
                    onDeleteLog: onDeleteLog
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
                    Text("\(logCount)")
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.evSecondaryText)
                }
            }
        } header: {
            Text("History")
                .font(.title2.weight(.bold))
                .foregroundStyle(.evPrimaryBlue)
                .textCase(nil)
        }
    }
}
