// © 2026 Evapotrack. All rights reserved.
// PhotoLifecycleTests.swift
// EvapotrackDevTests
//
// The database and the photo files must never disagree in a way that loses
// data: a photo is copied into place before its log is saved (and removed
// again if the save fails), and deleted only after the deletion of its log,
// plant or grow is saved. Also covers the launch-time cleanup and the
// Add Watering form's photo flow.

import XCTest
import SwiftData
@testable import EvapotrackDev

@MainActor
final class PhotoLifecycleTests: XCTestCase {

    private struct SaveFailed: Error {}
    private let failingSave: SaveHandler = { _ in throw SaveFailed() }
    private let now = Date(timeIntervalSince1970: 1_760_000_000)

    private var directory: URL!
    private var store: PhotoStore!

    override func setUpWithError() throws {
        directory = try TestImages.makeTemporaryDirectory()
        store = TestImages.makeStore(in: directory)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    private func makeContext() throws -> ModelContext {
        ModelContext(try PersistenceController.makeInMemoryContainer())
    }

    private func seed(_ context: ModelContext) throws -> (Grow, Plant) {
        let grow = Grow(growName: "Tent")
        context.insert(grow)
        let plant = Plant(plantName: "P1", potSize: "3 gal", mediumType: "coco", maxRetentionCapacity: 4.5, grow: grow)
        context.insert(plant)
        try context.save()
        return (grow, plant)
    }

    private func prepare() throws -> PreparedPhoto {
        try TestImages.preparePhoto(in: store, scratch: directory)
    }

    private func newLog(_ index: Int = 0) -> WateringLog {
        WateringLog(waterAdded: 1.2, runoffCollected: 0.18, dateTime: WateringHistory.start.addingTimeInterval(Double(index) * 86_400))
    }

    /// Adds a saved log with a stored photo.
    private func addLogWithPhoto(to plant: Plant, in context: ModelContext, index: Int = 0) throws -> (WateringLog, UUID) {
        let photo = try prepare()
        let log = newLog(index)
        try WateringLogService(modelContext: context, photoStore: store).addLog(log, to: plant, photo: photo)
        return (log, photo.id)
    }

    // MARK: - Adding

    func test_addLog_withPhoto_storesTheFiles_andOnlyTheIdentifier() throws {
        let context = try makeContext()
        let (_, plant) = try seed(context)
        let photo = try prepare()
        let log = newLog()

        try WateringLogService(modelContext: context, photoStore: store).addLog(log, to: plant, photo: photo)

        XCTAssertEqual(log.photoFileID, photo.id)
        XCTAssertNotNil(store.detailURL(for: photo.id))
        XCTAssertNotNil(store.thumbnailURL(for: photo.id))
        XCTAssertFalse(TestImages.exists(photo.detailURL), "the incoming copy is removed after the save")
        let saved = try XCTUnwrap(try context.fetch(FetchDescriptor<WateringLog>()).first)
        XCTAssertEqual(saved.photoFileID, photo.id)
    }

    func test_addLog_failedSave_removesThePlacedPhoto_andKeepsThePreparedOneForRetry() throws {
        let context = try makeContext()
        let (_, plant) = try seed(context)
        let photo = try prepare()

        let failing = WateringLogService(modelContext: context, photoStore: store, save: failingSave)
        XCTAssertThrowsError(try failing.addLog(newLog(), to: plant, photo: photo))

        XCTAssertNil(store.detailURL(for: photo.id), "no stored file without a saved log")
        XCTAssertNil(store.thumbnailURL(for: photo.id))
        XCTAssertTrue(TestImages.exists(photo.detailURL), "the grower can retry with the same photo")
        XCTAssertTrue(plant.wateringLogs.isEmpty)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<WateringLog>()), 0)

        // Retry succeeds with the same prepared photo.
        let log = newLog()
        try WateringLogService(modelContext: context, photoStore: store).addLog(log, to: plant, photo: photo)
        XCTAssertEqual(log.photoFileID, photo.id)
        XCTAssertNotNil(store.detailURL(for: photo.id))
    }

    func test_addLog_whenThePhotoCannotBeCopied_savesNothing() throws {
        let context = try makeContext()
        let (_, plant) = try seed(context)
        let photo = try prepare()
        try FileManager.default.removeItem(at: photo.detailURL)

        XCTAssertThrowsError(try WateringLogService(modelContext: context, photoStore: store).addLog(newLog(), to: plant, photo: photo))
        XCTAssertTrue(plant.wateringLogs.isEmpty)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<WateringLog>()), 0)
    }

    // MARK: - Deleting

    func test_deleteLog_removesItsPhoto_afterTheDeletionIsSaved() throws {
        let context = try makeContext()
        let (_, plant) = try seed(context)
        let (log, photoID) = try addLogWithPhoto(to: plant, in: context)

        try WateringLogService(modelContext: context, photoStore: store).deleteLog(log)

        XCTAssertNil(store.detailURL(for: photoID))
        XCTAssertNil(store.thumbnailURL(for: photoID))
    }

    func test_deleteLog_failedSave_keepsThePhoto() throws {
        let context = try makeContext()
        let (_, plant) = try seed(context)
        let (log, photoID) = try addLogWithPhoto(to: plant, in: context)

        XCTAssertThrowsError(try WateringLogService(modelContext: context, photoStore: store, save: failingSave).deleteLog(log))

        XCTAssertNotNil(store.detailURL(for: photoID), "the log still exists, so its photo must too")
        XCTAssertEqual(try context.fetch(FetchDescriptor<WateringLog>()).first?.photoFileID, photoID)
    }

    func test_deletePlant_removesItsLogsPhotos_afterTheDeletionIsSaved() throws {
        let context = try makeContext()
        let (_, plant) = try seed(context)
        let (_, first) = try addLogWithPhoto(to: plant, in: context, index: 0)
        let (_, second) = try addLogWithPhoto(to: plant, in: context, index: 1)

        XCTAssertThrowsError(try PlantService(modelContext: context, photoStore: store, save: failingSave).deletePlant(plant))
        XCTAssertNotNil(store.detailURL(for: first))
        XCTAssertNotNil(store.detailURL(for: second))

        try PlantService(modelContext: context, photoStore: store).deletePlant(plant)
        XCTAssertNil(store.detailURL(for: first))
        XCTAssertNil(store.detailURL(for: second))
    }

    func test_deleteGrow_removesAllItsPhotos_afterTheDeletionIsSaved() throws {
        let context = try makeContext()
        let (grow, plant) = try seed(context)
        let (_, photoID) = try addLogWithPhoto(to: plant, in: context)

        XCTAssertThrowsError(try GrowService(modelContext: context, photoStore: store, save: failingSave).deleteGrow(grow))
        XCTAssertNotNil(store.detailURL(for: photoID))

        try GrowService(modelContext: context, photoStore: store).deleteGrow(grow)
        XCTAssertNil(store.detailURL(for: photoID))
    }

    // MARK: - Launch cleanup

    func test_launchCleanup_removesOnlyPhotosNoLogRefersTo() throws {
        let context = try makeContext()
        let (_, plant) = try seed(context)
        let (_, keptID) = try addLogWithPhoto(to: plant, in: context)

        // A photo copied into place just before a crash, whose log was never saved.
        let orphan = try prepare()
        try store.commit(orphan)

        PhotoMaintenance.removeOrphanedFiles(context: context, store: store)

        XCTAssertNotNil(store.detailURL(for: keptID))
        XCTAssertNil(store.detailURL(for: orphan.id))
    }

    func test_missingPhotoFile_isReportedAsUnavailable_notAnError() throws {
        let context = try makeContext()
        let (_, plant) = try seed(context)
        let (log, photoID) = try addLogWithPhoto(to: plant, in: context)
        store.deletePhoto(id: photoID) // e.g. restored from an incomplete backup

        XCTAssertEqual(log.photoFileID, photoID, "the log keeps its data")
        XCTAssertNil(store.detailURL(for: photoID))
        XCTAssertNil(PhotoImageLoader.loadImage(at: directory.appending(path: "missing.heic"), maxPixelSize: 100))
    }

    // MARK: - Add Watering form

    private func makeFormVM() throws -> (AddWateringLogViewModel, Plant) {
        let context = try makeContext()
        let (_, plant) = try seed(context)
        let vm = AddWateringLogViewModel(plant: plant, dateProvider: MockDateProvider(fixedDate: now), photoStore: store)
        vm.configure(modelContext: context, waterUnit: .liters, temperatureUnit: .celsius)
        vm.dateTime = now.addingTimeInterval(-3600)
        vm.waterAddedText = "1.2"
        vm.runoffCollectedText = "0.2"
        return (vm, plant)
    }

    /// A picked file as PhotosPicker would deliver it.
    private func pickedFile() throws -> PickedImageFile {
        let url = directory.appending(path: "picked-\(UUID().uuidString).jpg")
        try TestImages.writeJPEG(width: 1200, height: 900, to: url)
        return PickedImageFile(url: url)
    }

    func test_form_pickedPhoto_isPrepared_andSavedWithTheLog() async throws {
        let (vm, plant) = try makeFormVM()
        let picked = try pickedFile()

        vm.loadPhoto { picked }
        XCTAssertTrue(vm.isProcessingPhoto)
        await vm.photoTask?.value

        let photo = try XCTUnwrap(vm.preparedPhoto)
        XCTAssertFalse(TestImages.exists(picked.url), "the picked original is not kept")
        XCTAssertTrue(vm.save())
        let log = try XCTUnwrap(plant.wateringLogs.first)
        XCTAssertEqual(log.photoFileID, photo.id)
        XCTAssertNotNil(store.detailURL(for: photo.id))

        vm.discardUnsavedPhoto() // closing after saving must not delete anything
        XCTAssertNotNil(store.detailURL(for: photo.id))
    }

    func test_form_saveIsBlocked_whilePreparing() async throws {
        let (vm, plant) = try makeFormVM()
        let picked = try pickedFile()
        let (gate, open) = AsyncStream<Void>.makeStream()

        vm.loadPhoto {
            for await _ in gate { break }
            return picked
        }
        XCTAssertTrue(vm.isProcessingPhoto)
        XCTAssertFalse(vm.save())
        XCTAssertTrue(plant.wateringLogs.isEmpty)

        open.yield()
        await vm.photoTask?.value
        XCTAssertNotNil(vm.preparedPhoto)
        XCTAssertTrue(vm.save())
    }

    func test_form_replacingOrRemovingThePhoto_discardsThePreparedFiles() async throws {
        let (vm, _) = try makeFormVM()
        let firstPick = try pickedFile()
        vm.loadPhoto { firstPick }
        await vm.photoTask?.value
        let first = try XCTUnwrap(vm.preparedPhoto)

        let secondPick = try pickedFile()
        vm.loadPhoto { secondPick }
        XCTAssertFalse(TestImages.exists(first.detailURL), "replaced photo is discarded")
        await vm.photoTask?.value
        let second = try XCTUnwrap(vm.preparedPhoto)
        XCTAssertNotEqual(first.id, second.id)

        vm.removePhoto()
        XCTAssertEqual(vm.photoState, .empty)
        XCTAssertFalse(TestImages.exists(second.detailURL))
        XCTAssertFalse(TestImages.exists(second.thumbnailURL))
    }

    func test_form_cancel_discardsTheUnsavedPhoto() async throws {
        let (vm, plant) = try makeFormVM()
        let picked = try pickedFile()
        vm.loadPhoto { picked }
        await vm.photoTask?.value
        let photo = try XCTUnwrap(vm.preparedPhoto)

        vm.discardUnsavedPhoto()

        XCTAssertFalse(TestImages.exists(photo.detailURL))
        XCTAssertNil(store.detailURL(for: photo.id))
        XCTAssertTrue(plant.wateringLogs.isEmpty)
    }

    func test_form_unreadablePick_showsFailure_andTheLogCanStillBeSaved() async throws {
        let (vm, plant) = try makeFormVM()
        let url = directory.appending(path: "broken.jpg")
        try Data("not an image".utf8).write(to: url)

        vm.loadPhoto { PickedImageFile(url: url) }
        await vm.photoTask?.value

        XCTAssertEqual(vm.photoState, .failed)
        XCTAssertTrue(vm.save())
        XCTAssertNil(plant.wateringLogs.first?.photoFileID)
    }

    func test_form_loaderReturningNothing_showsFailure() async throws {
        let (vm, _) = try makeFormVM()
        vm.loadPhoto { nil }
        await vm.photoTask?.value
        XCTAssertEqual(vm.photoState, .failed)
    }
}
