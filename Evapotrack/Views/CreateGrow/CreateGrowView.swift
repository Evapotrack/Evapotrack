// CreateGrowView.swift
// Evapotrack
//
// Form for creating a new grow. Grows are immutable after creation.

import SwiftUI
import Combine

struct CreateGrowView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var vm = CreateGrowViewModel()
    @State private var currentTime = Date()

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var timestampText: String {
        currentTime.formatted(date: .abbreviated, time: .shortened)
    }

    var body: some View {
        Form {
            Section {
                TextField("Grow Name", text: $vm.growName)
                    .autocorrectionDisabled()
            } header: {
                Text("Grow Info")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.evDeepNavy)
                    .textCase(nil)
            }

            Section {
                HStack {
                    Text("Created")
                        .foregroundStyle(Color.evPrimaryText)
                    Spacer()
                    Text(timestampText)
                        .foregroundStyle(Color.evSecondaryText)
                }
            } header: {
                Text("Timestamp")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.evDeepNavy)
                    .textCase(nil)
            } footer: {
                Text("This timestamp is recorded when you save the grow.")
                    .foregroundStyle(Color.evSecondaryText)
            }

            if let error = vm.validationError {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.callout)
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .scrollContentBackground(.hidden)
        .background(Color.evBackground)
        .navigationTitle("Add Grow")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
                    .fontWeight(.bold)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    if vm.save() {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            dismiss()
                        }
                    }
                }
                .fontWeight(.bold)
                .disabled(vm.showSaveConfirmation)
            }
        }
        .onAppear {
            vm.configure(modelContext: modelContext)
        }
        .onReceive(timer) { time in
            currentTime = time
        }
        .overlay {
            if vm.showSaveConfirmation {
                Color.evInkBlack.opacity(0.3)
                    .ignoresSafeArea()
                    .overlay {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 72))
                            .foregroundStyle(.evPrimaryBlue)
                            .transition(.scale.combined(with: .opacity))
                    }
                    .allowsHitTesting(false)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: vm.showSaveConfirmation)
    }
}
