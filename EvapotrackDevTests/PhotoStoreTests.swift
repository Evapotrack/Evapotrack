// © 2026 Evapotrack. All rights reserved.
// PhotoStoreTests.swift
// EvapotrackDevTests
//
// Photo file storage: naming, commit/discard/delete, the launch-time sweep
// of files no log refers to, and the usage figure shown in Settings. Every
// test uses a store in a temporary folder.

import XCTest
@testable import EvapotrackDev

final class PhotoStoreTests: XCTestCase {

    private var directory: URL!
    private var store: PhotoStore!

    override func setUpWithError() throws {
        directory = try TestImages.makeTemporaryDirectory()
        store = TestImages.makeStore(in: directory)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    private func prepare() throws -> PreparedPhoto {
        try TestImages.preparePhoto(in: store, scratch: directory)
    }

    // MARK: - Commit, discard, delete

    func test_preparedPhoto_waitsInThisLaunchsIncomingFolder() throws {
        let photo = try prepare()
        XCTAssertEqual(photo.detailURL.deletingLastPathComponent().standardizedFileURL, store.sessionIncomingDirectory.standardizedFileURL)
        XCTAssertNil(store.detailURL(for: photo.id), "not stored until committed")
    }

    func test_commit_placesBothFiles_andKeepsTheIncomingCopyForRetry() throws {
        let photo = try prepare()
        try store.commit(photo)

        let detail = try XCTUnwrap(store.detailURL(for: photo.id))
        let thumbnail = try XCTUnwrap(store.thumbnailURL(for: photo.id))
        XCTAssertEqual(detail.lastPathComponent, "\(photo.id.uuidString).\(photo.fileExtension)")
        XCTAssertEqual(thumbnail.lastPathComponent, "\(photo.id.uuidString)_thumb.\(photo.fileExtension)")
        XCTAssertEqual(detail.deletingLastPathComponent().standardizedFileURL, store.rootDirectory.standardizedFileURL)
        XCTAssertTrue(TestImages.exists(photo.detailURL))

        store.discard(photo)
        XCTAssertFalse(TestImages.exists(photo.detailURL))
        XCTAssertFalse(TestImages.exists(photo.thumbnailURL))
        XCTAssertNotNil(store.detailURL(for: photo.id), "discarding the incoming copy keeps the stored photo")
    }

    func test_commit_whenTheIncomingFileIsGone_throwsAndLeavesNothing() throws {
        let photo = try prepare()
        try FileManager.default.removeItem(at: photo.thumbnailURL)

        XCTAssertThrowsError(try store.commit(photo))
        XCTAssertNil(store.detailURL(for: photo.id), "no half-copied photo")
        XCTAssertNil(store.thumbnailURL(for: photo.id))
    }

    func test_deletePhoto_removesBothFiles_andIgnoresMissingOnes() throws {
        let photo = try prepare()
        try store.commit(photo)

        store.deletePhoto(id: photo.id)
        XCTAssertNil(store.detailURL(for: photo.id))
        XCTAssertNil(store.thumbnailURL(for: photo.id))

        store.deletePhoto(id: photo.id) // already gone: no error, no crash
        store.deletePhoto(id: UUID())
    }

    // MARK: - Sweep

    func test_sweep_removesUnreferencedFiles_andKeepsReferencedOnes() throws {
        let kept = try prepare()
        let orphan = try prepare()
        try store.commit(kept)
        try store.commit(orphan)

        let removed = store.sweep(referencedIDs: [kept.id])

        XCTAssertEqual(removed, 2, "the orphan's detail image and thumbnail")
        XCTAssertNotNil(store.detailURL(for: kept.id))
        XCTAssertNotNil(store.thumbnailURL(for: kept.id))
        XCTAssertNil(store.detailURL(for: orphan.id))
        XCTAssertNil(store.thumbnailURL(for: orphan.id))
    }

    func test_sweep_removesEarlierLaunchesIncomingFolders_butNotThisLaunchs() throws {
        let current = try prepare()
        let stale = store.incomingRoot.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: stale, withIntermediateDirectories: true)
        try Data("left over".utf8).write(to: stale.appending(path: "source.jpg"))

        store.sweep(referencedIDs: [])

        XCTAssertFalse(TestImages.exists(stale))
        XCTAssertTrue(TestImages.exists(current.detailURL), "a photo being prepared right now survives")
    }

    func test_sweep_leavesUnrelatedFilesAlone() throws {
        try FileManager.default.createDirectory(at: store.rootDirectory, withIntermediateDirectories: true)
        let unrelated = store.rootDirectory.appending(path: "notes.txt")
        try Data("keep".utf8).write(to: unrelated)

        store.sweep(referencedIDs: [])
        XCTAssertTrue(TestImages.exists(unrelated))
    }

    func test_sweep_withNoFolderYet_doesNothing() {
        XCTAssertEqual(store.sweep(referencedIDs: []), 0)
    }

    // MARK: - Usage

    func test_usage_countsPhotosAndBytes_ofStoredPhotosOnly() throws {
        XCTAssertEqual(store.usage(), PhotoUsage(photoCount: 0, totalBytes: 0))

        let first = try prepare()
        let second = try prepare()
        try store.commit(first)
        try store.commit(second)
        _ = try prepare() // still incoming: not counted

        let usage = store.usage()
        XCTAssertEqual(usage.photoCount, 2)
        XCTAssertEqual(usage.totalBytes, Int64(first.byteCount + second.byteCount))
    }

    // MARK: - File names

    func test_photoID_parsesDetailAndThumbnailNames_only() {
        let id = UUID()
        XCTAssertEqual(PhotoStore.photoID(fromFileName: "\(id.uuidString).heic"), id)
        XCTAssertEqual(PhotoStore.photoID(fromFileName: "\(id.uuidString)_thumb.jpg"), id)
        XCTAssertNil(PhotoStore.photoID(fromFileName: "notes.txt"))
        XCTAssertNil(PhotoStore.photoID(fromFileName: id.uuidString))
        XCTAssertNil(PhotoStore.photoID(fromFileName: ".incoming"))
    }
}
