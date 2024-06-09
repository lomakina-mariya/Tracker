
import XCTest
import SnapshotTesting
@testable import Tracker


final class TrackerTests: XCTestCase {

    func testViewController() {
        let viewModel = TrackersViewModel()
        let trackersViewController = TrackersViewController(viewModel: viewModel)
        viewModel.updateCategories(with: Date(), text: "", completedFilter: nil)
        trackersViewController.trackersCollectionView.reloadData()
        assertSnapshot(matching: trackersViewController, as: .image)
    }

}
