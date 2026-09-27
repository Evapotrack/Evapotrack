// © 2026 Evapotrack. All rights reserved.
// AddWateringLogView.swift
// Evapotrack
//
// Form for adding a new watering log. Logs are immutable after creation.
// User enters water/runoff in display unit and temperature in display
// temp unit. All values converted to internal units on save.
// An optional photo is chosen with the system photo picker, which runs
// outside the app: no Photos permission is requested and only the chosen
// photo is shared with Evapotrack.

import SwiftUI
import PhotosUI

struct AddWateringLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(SettingsViewModel.self) private var settingsVM
    @State private var vm: AddWateringLogViewModel
    @State private var isShowingHowTo = false
    @State private var dismissTask: Task<Void, Never>?
    @State private var pickerItem: PhotosPickerItem?
    @State private var viewerItem: PhotoViewerItem?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .title) private var helpButtonSize: CGFloat = 56
    @ScaledMetric(relativeTo: .largeTitle) private var checkmarkSize: CGFloat = 56

    init(plant: Plant) {
        _vm = State(wrappedValue: AddWateringLogViewModel(plant: plant))
    }

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private var waterUnit: WaterUnit { settingsVM.settings.waterUnit }
    private var tempUnit: TemperatureUnit { settingsVM.settings.temperatureUnit }
    private var sectionHeaderFont: Font {
        horizontalSizeClass == .regular ? .headline.weight(.bold) : .title2.weight(.bold)
    }

    var body: some View {
        Form {
            Section {
                TextField(
                    Strings.waterAddedField(waterUnit.abbreviation),
                    text: $vm.waterAddedText
                )
                .keyboardType(.decimalPad)
                .textLimit($vm.waterAddedText, maxLength: AppConstants.maxNumericInputLength)
                .accessibilityLabel(Strings.waterAddedAccessibility(waterUnit.abbreviation))

                TextField(
                    Strings.runoffCollectedField(waterUnit.abbreviation),
                    text: $vm.runoffCollectedText
                )
                .keyboardType(.decimalPad)
                .textLimit($vm.runoffCollectedText, maxLength: AppConstants.maxNumericInputLength)
                .accessibilityLabel(Strings.runoffCollectedAccessibility(waterUnit.abbreviation))
            } header: {
                Text(Strings.water)
                    .font(sectionHeaderFont)
                    .foregroundStyle(.evDeepNavy)
                    .textCase(nil)
            }

            Section {
                DatePicker(Strings.date, selection: $vm.dateTime, in: ...Date.now, displayedComponents: .date)
                DatePicker(Strings.time, selection: $vm.dateTime, in: ...Date.now, displayedComponents: .hourAndMinute)
            } header: {
                Text(Strings.dateAndTime)
                    .font(sectionHeaderFont)
                    .foregroundStyle(.evDeepNavy)
                    .textCase(nil)
            }

            Section {
                TextField(
                    Strings.temperatureField(tempUnit.abbreviation),
                    text: $vm.temperatureText
                )
                .keyboardType(.decimalPad)
                .textLimit($vm.temperatureText, maxLength: AppConstants.maxNumericInputLength)
                .accessibilityLabel(Strings.temperatureAccessibility(tempUnit.abbreviation))
                .accessibilityHint(Strings.optional)

                TextField(Strings.humidityField, text: $vm.humidityText)
                    .keyboardType(.decimalPad)
                    .textLimit($vm.humidityText, maxLength: AppConstants.maxNumericInputLength)
                    .accessibilityLabel(Strings.humidityPercent)
                    .accessibilityHint(Strings.optional)
            } header: {
                Text(Strings.environment)
                    .font(sectionHeaderFont)
                    .foregroundStyle(.evDeepNavy)
                    .textCase(nil)
            }

            Section {
                photoContent
            } header: {
                Text(Strings.photoSection)
                    .font(sectionHeaderFont)
                    .foregroundStyle(.evDeepNavy)
                    .textCase(nil)
            } footer: {
                Text(Strings.photoFooter)
            }

            if let error = vm.validationError {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.callout)
                }
            }

            Section {
                Button {
                    isShowingHowTo = true
                } label: {
                    HStack {
                        Spacer()
                        Image(systemName: "questionmark.circle.fill")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .frame(width: helpButtonSize, height: helpButtonSize)
                            .background(Color.evPrimaryBlue)
                            .clipShape(Circle())
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Strings.helpLabel)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .scrollContentBackground(.hidden)
        .background(Color.evBackground)
        .navigationTitle(Strings.addWateringEvent)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(Strings.cancel) {
                    vm.discardUnsavedPhoto()
                    dismiss()
                }
                .font(.body)
                .fontWeight(.bold)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(Strings.save) {
                    if vm.save() { finishSaving() }
                }
                .font(.body)
                .fontWeight(.bold)
                .disabled(vm.showSaveConfirmation || vm.isProcessingPhoto)
            }
        }
        // A chosen photo would be lost by a swipe-down, so closing the form
        // takes Cancel or Save while one is attached.
        .interactiveDismissDisabled(hasUnsavedPhoto)
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            pickerItem = nil
            vm.loadPhoto { try await item.loadTransferable(type: PickedImageFile.self) }
        }
        .fullScreenCover(item: $viewerItem) { item in
            PhotoViewer(item: item)
        }
        .alert(Strings.retainedOverCapacityTitle, isPresented: $vm.isShowingCapacityConfirmation) {
            Button(Strings.saveAnyway) {
                if vm.save(confirmedOverCapacity: true) { finishSaving() }
            }
            Button(Strings.reviewValues, role: .cancel) {}
        } message: {
            Text(vm.capacityConfirmationMessage)
        }
        .navigationDestination(isPresented: $isShowingHowTo) {
            HowToView(context: .addWatering)
                .interactiveDismissDisabled(hasUnsavedPhoto)
        }
        .onAppear {
            vm.resetState()
            vm.configure(
                modelContext: modelContext,
                waterUnit: waterUnit,
                temperatureUnit: tempUnit
            )
        }
        .overlay {
            if vm.showSaveConfirmation {
                Color.evInkBlack.opacity(0.2)
                    .ignoresSafeArea()
                    .overlay {
                        VStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: checkmarkSize))
                                .foregroundStyle(.evPrimaryBlue)
                            Text(Strings.saved)
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
                    .accessibilityAddTraits(.isModal)
                    .accessibilityLabel(Strings.savedLabel)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: vm.showSaveConfirmation)
        .onDisappear { dismissTask?.cancel() }
    }

    private var hasUnsavedPhoto: Bool {
        vm.preparedPhoto != nil || vm.isProcessingPhoto
    }

    // MARK: - Photo

    @ViewBuilder
    private var photoContent: some View {
        switch vm.photoState {
        case .empty:
            photoPicker(Strings.addPhoto, systemImage: "photo.badge.plus")
        case .processing:
            HStack(spacing: 12) {
                HStack(spacing: 12) {
                    ProgressView()
                    Text(Strings.preparingPhoto)
                        .foregroundStyle(Color.evSecondaryText)
                }
                .accessibilityElement(children: .combine)
                Spacer(minLength: 0)
                Button(Strings.cancel) {
                    vm.removePhoto()
                }
                .buttonStyle(.borderless)
                .frame(minHeight: 44)
            }
        case .ready(let photo):
            Button {
                showViewer(PhotoViewerItem(source: .prepared(photo), date: vm.dateTime))
            } label: {
                WateringPhotoThumbnail(source: .prepared(photo), maxHeight: 160)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Strings.viewPhoto)
            .accessibilityHint(Strings.viewPhotoHint)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 24) {
                    replacePhotoButton
                    removePhotoButton
                    Spacer(minLength: 0)
                }
                VStack(alignment: .leading, spacing: 12) {
                    replacePhotoButton
                    removePhotoButton
                }
            }
        case .failed:
            Label(Strings.photoFailed, systemImage: "exclamationmark.triangle")
                .foregroundStyle(.red)
                .font(.callout)
            photoPicker(Strings.chooseAnotherPhoto, systemImage: "photo.badge.plus")
        }
    }

    private var replacePhotoButton: some View {
        photoPicker(Strings.replacePhoto, systemImage: "arrow.triangle.2.circlepath")
            .buttonStyle(.borderless)
    }

    private var removePhotoButton: some View {
        Button(role: .destructive) {
            vm.removePhoto()
        } label: {
            Label(Strings.removePhoto, systemImage: "trash")
                .frame(minHeight: 44)
        }
        .buttonStyle(.borderless)
    }

    /// The system photo picker, limited to still images.
    private func photoPicker(_ title: String, systemImage: String) -> some View {
        PhotosPicker(selection: $pickerItem, matching: .images) {
            Label(title, systemImage: systemImage)
                .frame(minHeight: 44)
        }
    }

    /// Opens the full-screen photo viewer (without the slide-up animation
    /// when Reduce Motion is on).
    private func showViewer(_ item: PhotoViewerItem) {
        var transaction = Transaction()
        transaction.disablesAnimations = reduceMotion
        withTransaction(transaction) {
            viewerItem = item
        }
    }

    /// Confirms the save with a haptic and closes the form after a moment.
    private func finishSaving() {
        HapticService.success()
        dismissTask = Task {
            try? await Task.sleep(for: .seconds(1))
            dismiss()
        }
    }
}
