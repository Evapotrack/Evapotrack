// © 2026 Evapotrack. All rights reserved.
// HowToView.swift
// Evapotrack
//
// Context-aware static help screen. Push navigation only.
// General context (grow/plant list): what is Evapotrack, how to
// use grows and plants, what is Max Retention Capacity, and
// the watering protocol.
// AddWatering context (plant dashboard): watering protocol,
// how to log a watering event, and what Next is.
// Sections are expandable — only one open at a time.

import SwiftUI

enum HowToContext {
    case general
    case addWatering
    case chart
}

struct HowToView: View {
    let context: HowToContext

    @Environment(\.dismiss) private var dismiss
    @State private var expandedSection: String?

    var body: some View {
        List {
            switch context {
            case .general:
                generalContent
            case .addWatering:
                addWateringContent
            case .chart:
                chartContent
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.evBackground)
        .navigationTitle(Strings.howTo)
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.evPrimaryBlue)
                }
                .accessibilityLabel(Strings.backLabel)
            }
        }
    }

    // MARK: - General Context (Grow / Plant List)

    @ViewBuilder
    private var generalContent: some View {
        helpSection(Strings.whatIsEvapotrack, highlightWord: Strings.whatIsEvapotrackHighlight) {
            ForEach(Strings.whatIsEvapotrackBullets, id: \.self) { text in
                bullet(text)
            }
        }

        helpSection(Strings.growsAndPlants, highlightWord: Strings.growsAndPlantsHighlight) {
            ForEach(Strings.growsAndPlantsBullets, id: \.self) { text in
                bullet(text)
            }
        }

        helpSection(Strings.howToCreatePlant, highlightWord: Strings.howToCreatePlantHighlight) {
            ForEach(Strings.howToCreatePlantBullets, id: \.self) { text in
                bullet(text)
            }
        }

        helpSection(Strings.whatIsMaxRetention, highlightWord: Strings.whatIsMaxRetentionHighlight) {
            ForEach(Strings.whatIsMaxRetentionBullets, id: \.self) { text in
                bullet(text)
            }
        }

        wateringProtocolSection

        helpSection(Strings.howToDownloadData, highlightWord: Strings.howToDownloadDataHighlight) {
            ForEach(Strings.howToDownloadDataBullets, id: \.self) { text in
                bullet(text)
            }
        }
    }

    // MARK: - Add Watering Context (Plant Dashboard)

    @ViewBuilder
    private var addWateringContent: some View {
        wateringProtocolSection

        helpSection(Strings.howToLogWatering, highlightWord: Strings.howToLogWateringHighlight) {
            ForEach(Strings.howToLogWateringBullets, id: \.self) { text in
                bullet(text)
            }
        }

        helpSection(Strings.whatIsNext, highlightWord: Strings.whatIsNextHighlight) {
            ForEach(Strings.whatIsNextBullets, id: \.self) { text in
                bullet(text)
            }
        }

        helpSection(Strings.readingTheChart, highlightWord: Strings.readingTheChartHighlight) {
            ForEach(Strings.readingTheChartBullets, id: \.self) { text in
                bullet(text)
            }
        }

        helpSection(Strings.tempHumidityOverlays, highlightWord: Strings.tempHumidityOverlaysHighlight) {
            ForEach(Strings.tempHumidityOverlaysBullets, id: \.self) { text in
                bullet(text)
            }
        }
    }

    // MARK: - Chart Context (History / Chart Screen)

    @ViewBuilder
    private var chartContent: some View {
        helpSection(Strings.readingTheChart, highlightWord: Strings.readingTheChartHighlight) {
            ForEach(Strings.readingTheChartBullets, id: \.self) { text in
                bullet(text)
            }
        }

        helpSection(Strings.tempHumidityOverlays, highlightWord: Strings.tempHumidityOverlaysHighlight) {
            ForEach(Strings.tempHumidityOverlaysBullets, id: \.self) { text in
                bullet(text)
            }
        }

        helpSection(Strings.whatIsNext, highlightWord: Strings.whatIsNextHighlight) {
            ForEach(Strings.whatIsNextBullets, id: \.self) { text in
                bullet(text)
            }
        }

        wateringProtocolSection
    }

    // MARK: - Shared Sections

    @ViewBuilder
    private var wateringProtocolSection: some View {
        helpSection(Strings.wateringProtocol, highlightWord: Strings.wateringProtocolHighlight) {
            ForEach(Strings.wateringProtocolBullets, id: \.self) { text in
                bullet(text)
            }
            Link(destination: URL(string: "https://evapotrack.com/watering-protocol")!) {
                Label(Strings.wateringProtocolLinkLabel, systemImage: "arrow.up.right.square")
                    .font(.body.weight(.medium))
                    .foregroundStyle(Color.evPrimaryBlue)
            }
            .padding(.top, 2)
        }
    }

    // MARK: - Helpers

    private func helpSection<Content: View>(
        _ title: String,
        highlightWord: String? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        let built = content()
        return Section {
            DisclosureGroup(
                isExpanded: Binding(
                    get: { expandedSection == title },
                    set: { isExpanding in
                        withAnimation(.easeInOut(duration: 0.25)) {
                            expandedSection = isExpanding ? title : nil
                        }
                    }
                )
            ) {
                built
            } label: {
                if let word = highlightWord,
                   let range = title.range(of: word) {
                    (Text(title[title.startIndex..<range.lowerBound])
                        .foregroundColor(.evDeepNavy)
                    + Text(title[range])
                        .foregroundColor(.evPrimaryBlue)
                    + Text(title[range.upperBound..<title.endIndex])
                        .foregroundColor(.evDeepNavy))
                    .font(.title3.weight(.bold))
                } else {
                    Text(title)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.evDeepNavy)
                }
            }
        }
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("•")
                .fontWeight(.bold)
                .foregroundStyle(Color.evSlateGray)
            Text(text)
                .fontWeight(.medium)
                .lineLimit(nil)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(.body)
        .foregroundStyle(Color.evPrimaryText)
        .padding(.vertical, 6)
    }
}
