
import Foundation

final class TrackersViewModel {
    
    //MARK: - Properties
    
    private var currentDate = Date().dateWithoutTime()
    private var text = ""
    private var trackerStore = TrackerStore(date: Date.distantPast, text: "")
    private var trackerRecordStore = TrackerRecordStore()
    private(set) var categories: [TrackerCategory] = [] {
        didSet {
            categoriesBinding?(categories)
        }
    }
    var categoriesBinding: Binding<[TrackerCategory]>?
    private(set) var isCategoriesEmpty: Bool = false {
        didSet {
            isCategoriesEmptyBinding?(isCategoriesEmpty)
        }
    }
    var isCategoriesEmptyBinding: Binding<Bool>?
    
    init() {
        trackerStore.delegate = self
        categories = getTrackersFromStore()
        isCategoriesEmpty = categories.isEmpty
    }
    
    // MARK: - Private Function
    
    private func getTrackersFromStore() -> [TrackerCategory] {
        return trackerStore.trackersCategories
    }
    
    private func reloadVisibleCategories(text: String?, date: Date) {
        trackerStore.update(with: date, text: text)
    }
    
    // MARK: - Internal Function
    
    func updateStore(with date: Date, text: String) {
        currentDate = date
        self.text = text
        trackerStore.update(with: currentDate, text: self.text)
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
    
    func completeTracker(id: UUID, date: Date) {
        do {
            try trackerRecordStore.addOrDeleteRecord(id: id, date: date)
        } catch {
            print("Ошибка сохранения изменения трекера \(error)")
        }
    }
}

// MARK: - TrackerStoreDelegate
extension TrackersViewModel: TrackerStoreDelegate {
    func didUpdate() {
        updateStore(with: currentDate, text: text)
    }
}

