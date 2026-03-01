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
}

struct HowToView: View {
    let context: HowToContext

    @State private var expandedSection: String?

    var body: some View {
        List {
            switch context {
            case .general:
                generalContent
            case .addWatering:
                addWateringContent
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.evBackground)
        .navigationTitle("How To")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - General Context (Grow / Plant List)

    @ViewBuilder
    private var generalContent: some View {
        helpSection("What Is Evapotrack?", highlightWord: "Evapotrack") {
            bullet("Evapotrack helps you track and optimize watering for your plants by recording how much water you add and how much runs off.")
            bullet("The app calculates key metrics like Retained volume, Capacity %, and a recommended Next watering amount based on your history.")
            bullet("All data is stored locally on your device. Nothing is sent to the internet.")
        }

        helpSection("Grows and Plants") {
            bullet("A Grow is a group that contains one or more plants. Use grows to organize plants by location, cycle, or any grouping that makes sense for you.")
            bullet("Tap + on the My Grows screen to create a new grow. Each grow records its name and the date it was created.")
            bullet("Tap a grow to open its plant list. From there, tap + to add plants to that grow.")
            bullet("Deleting a grow will permanently delete all plants inside it and all of their watering logs.")
        }

        helpSection("How to Create a Plant") {
            bullet("Open a grow, then tap + to start creating a new plant.")
            bullet("Enter the required fields: Plant Name, Pot Size, Medium Type, and Max Retention Capacity.")
            bullet("If you already know your Max Retention Capacity, enter it directly. Otherwise, use the built-in calculator to derive it from a test watering.")
            bullet("Plants cannot be edited after creation. Make sure all fields are correct before saving.")
            bullet("Deleting a plant will permanently delete all of its watering logs.")
        }

        helpSection("What Is Max Retention Capacity?") {
            bullet("Max Retention Capacity is the maximum volume of water your growing medium can absorb and hold before runoff begins.")
            bullet("This value is central to how Evapotrack calculates Capacity %, Average Retained, and the Next Watering Amount.")
            bullet("To determine it: water your medium slowly until runoff starts, then subtract the runoff from the water you added. The result is your Max Retention Capacity.")
            bullet("A more saturated medium will produce more runoff. An accurate Max Retention Capacity leads to better recommendations.")
        }

        wateringProtocolSection
    }

    // MARK: - Add Watering Context (Plant Dashboard)

    @ViewBuilder
    private var addWateringContent: some View {
        wateringProtocolSection

        helpSection("How to Log a Watering Event") {
            bullet("From a plant's dashboard, tap + to add a new watering event.")
            bullet("Enter Water Added and Runoff Collected. Both are required.")
            bullet("Set the correct Date and Time. Future dates are not allowed.")
            bullet("Temperature and Humidity are optional. They are recorded for your reference but are not used in any calculations.")
            bullet("Logs cannot be edited after creation. If a log is incorrect, delete it and create a new one.")
        }

        helpSection("What Is Next?", highlightWord: "Next") {
            bullet("Next is the Next Watering Amount shown in the Insights panel.")
            bullet("It estimates how much water your medium will absorb next time by averaging your most recent Retained amount with your Average Retained across all logs.")
            bullet("Next is the exact water amount needed so that, if your medium absorbs the estimated amount, the runoff will be your Goal Runoff %. It is capped by your Max Retention Capacity to prevent over-watering.")
            bullet("Goal Runoff is the estimated runoff you should expect if you apply the recommended Next amount. It is calculated as Next multiplied by your Goal Runoff %.")
            bullet("The more logs you record, the more accurate the recommendation becomes.")
        }
    }

    // MARK: - Shared Sections

    @ViewBuilder
    private var wateringProtocolSection: some View {
        helpSection("Watering Protocol") {
            bullet("Water your medium slowly and evenly, always aiming for runoff.")
            bullet("You must always have runoff. Runoff must always be less than Water Added.")
            bullet("Your runoff goal is based on the Goal Runoff % set for each plant (default 15%).")
            bullet("Collect all runoff in a tray and measure it after the pot finishes draining.")
            bullet("Subtract Runoff Collected from Water Added. This is your Retained volume — the amount of water the medium actually absorbed.")
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
                .fixedSize(horizontal: false, vertical: true)
        }
        .font(.body)
        .foregroundStyle(Color.evPrimaryText)
        .padding(.vertical, 3)
    }
}
