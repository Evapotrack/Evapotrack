// © 2026 Evapotrack. All rights reserved.
// DataStoreErrorView.swift
// Evapotrack
//
// Shown instead of the app when the data store cannot be opened, so a
// migration or storage failure never looks like an empty app. Tells the
// grower their data was not deleted and warns against deleting the app.

import SwiftUI

struct DataStoreErrorView: View {
    @ScaledMetric(relativeTo: .largeTitle) private var iconSize: CGFloat = 52

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "externaldrive.badge.exclamationmark")
                    .font(.system(size: iconSize))
                    .foregroundStyle(Color.evWarmOrange)
                    .accessibilityHidden(true)

                Text(Strings.dataStoreErrorTitle)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.evPrimaryText)
                    .multilineTextAlignment(.center)

                Text(Strings.dataStoreErrorMessage)
                    .font(.body)
                    .foregroundStyle(Color.evSecondaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(32)
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
        }
        .background(Color.evBackground)
    }
}
