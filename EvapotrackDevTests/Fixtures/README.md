# Test fixtures

## `shipped-1.0.store`: a store written by the App Store build

`MigrationTests.test_storeWrittenByTheAppStoreBuild_opensWithEveryRecord` opens a real store file written by the released app and checks that nothing is lost when it is upgraded to the current schema. Until the file is added here, that test is **skipped** (it shows as skipped in Xcode, not as passed).

How to capture it:

1. Check out the released code: `git checkout 89cc8c8` (App Store 1.0). Alternatively, install the App Store build on a simulator through TestFlight.
2. Run it on an iOS simulator. Erase the simulator first, or delete the app, so it starts empty.
3. On My Grows, tap **Try Example Data**. The test expects exactly that data: one grow, two plants with capacities 1.6 L and 2.1 L, and six logs each.
4. Stop the app in Xcode.
5. Find the store with `xcrun simctl get_app_container booted com.evapotrack.app data`, then look in `Library/Application Support/`.
6. Copy `default.store` here as `shipped-1.0.store`. If `default.store-wal` and `default.store-shm` exist, copy them as `shipped-1.0.store-wal` and `shipped-1.0.store-shm`.
7. Check the files' Target Membership in Xcode: they must be in **EvapotrackDevTests**, so they are copied into the test bundle.
8. Switch back to the current branch and run the tests. The test should now run instead of being skipped.

The store only holds the sample data, so it is safe to commit.
