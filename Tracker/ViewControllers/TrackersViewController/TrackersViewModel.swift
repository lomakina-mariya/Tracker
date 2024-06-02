
import Foundation

final class TrackersViewModel {
    
    //MARK: - Properties
    
    private var currentDate = Date().dateWithoutTime()
    private var text = ""
    private var completedFilter: Bool?
    private var trackerStore = TrackerStore(date: Date.distantPast, text: "")
    private var trackerRecordStore = TrackerRecordStore()
    private(set) var categories: [TrackerCategory] = [] {
        didSet {
            categoriesBinding?(categories)
        }
    }
    var categoriesBinding: Binding<[TrackerCategory]>?

    init() {
        trackerStore.delegate = self
        categories = getTrackersFromStore()
    }
    
    // MARK: - Function
    
    private func getTrackersFromStore() -> [TrackerCategory] {
        return trackerStore.trackersCategories
    }
    
  
    func updateStore(with date: Date, text: String, completedFilter: Bool?) {
        currentDate = date
        self.text = text
        trackerStore.update(with: currentDate, text: self.text, completedFilter: completedFilter)
        categories = getTrackersFromStore()
    }
    
    func completedDays(for id: UUID) -> (number: Int, completed: Bool) {
        let days = try? trackerRecordStore.fetchDays(for: id)
        let number = days?.count ?? 0
        let completed = (days?.contains(currentDate) ?? false) && currentDate <= Date().dateWithoutTime()
        return (number, completed)
    }
     
    func addNewTracker(_ tracker: Tracker, with category: TrackerCategory) {
        try? trackerStore.addNewTracker(tracker, with: category)
    }
    
    func deleteTracker(_ tracker: Tracker) {
        try? trackerStore.deleteTracker(tracker)
    }
    
    func completeTracker(id: UUID, date: Date) {
        do {
            try trackerRecordStore.addOrDeleteRecord(id: id, date: date)
        } catch {
            print("Ошибка сохранения изменения трекера \(error)")
        }
    }
    
    func togglePin(_ tracker: Tracker) {
        try? trackerStore.togglePin(tracker)
    }
}

// MARK: - TrackerStoreDelegate
extension TrackersViewModel: TrackerStoreDelegate {
    func didUpdate() {
        updateStore(with: currentDate, text: text, completedFilter: self.completedFilter)
    }
}

