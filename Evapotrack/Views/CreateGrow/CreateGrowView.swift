// CreateGrowView.swift
// Evapotrack
//
// Form for creating a new grow. Grows are immutable after creation.

import SwiftUI

struct CreateGrowView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var vm = CreateGrowViewModel()
    @State private var currentTime = Date()
    @State private var dismissTask: Task<Void, Never>?

    private var timestampText: String {
        currentTime.formatted(date: .abbreviated, time: .shortened)
    }

    var body: some View {
        Form {
            Section {
                TextField("Grow Name", text: $vm.growName)
                    .autocorrectionDisabled()
                    .textLimit($vm.growName, maxLength: AppConstants.maxGrowNameLength)
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
                    .font(.body)
                    .fontWeight(.bold)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    if vm.save() {
                        HapticService.success()
                        dismissTask = Task {
                            try? await Task.sleep(for: .seconds(1))
                            dismiss()
                        }
                    }
                }
                .font(.body)
                .fontWeight(.bold)
                .disabled(vm.showSaveConfirmation)
            }
        }
        .onAppear {
            vm.resetState()
            vm.configure(modelContext: modelContext)
            currentTime = Date()
        }
        .overlay {
            if vm.showSaveConfirmation {
                Color.evInkBlack.opacity(0.2)
                    .ignoresSafeArea()
                    .overlay {
                        VStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 56))
                                .foregroundStyle(.evPrimaryBlue)
                            Text("Saved")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(Color.evPrimaryText)
                        }
                        .padding(28)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.evBackground)
                                .shadow(color: .black.opacity(0.1), radius: 12, y: 4)
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                    .allowsHitTesting(false)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: vm.showSaveConfirmation)
        .onDisappear { dismissTask?.cancel() }
    }
}
