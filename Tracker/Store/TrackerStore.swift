import Foundation
import UIKit
import CoreData

enum TrackerCategoryStoreError: Error {
    case decodingErrorInvalidCategory
}

struct TrackerStoreUpdate {
    let insertedIndexes: IndexSet
    let deletedIndexes: IndexSet
    let updatedIndexes: IndexSet
}

protocol TrackerStoreDelegate: AnyObject {
    func didUpdate()
}

final class TrackerStore: NSObject {
    //MARK: - Properties
    
    private let context: NSManagedObjectContext
    private(set) var fetchedResultsController: NSFetchedResultsController<TrackerCoreData>!
    private var insertedIndexes: IndexSet?
    private var deletedIndexes: IndexSet?
    private var updatedIndexes: IndexSet?
    
    weak var delegate: TrackerStoreDelegate?
    private(set) var date: Date
    private(set) var text: String
    
    var trackersCategories: [TrackerCategory] {
        var trackerCategories: [TrackerCategory] = []
        var trackerDictionary: [String: [Tracker]] = [:]
        
        guard let objects = fetchedResultsController.fetchedObjects else {
            return []
        }
        
        for object in objects {
            guard let categoryTitle = object.category?.title else {
                continue
            }
            let tracker = Tracker(
                id: object.id ?? UUID(),
                name: object.name ?? "",
                color: object.color ?? "Color selection 17",
                emoji: object.emoji ?? "",
                schedule: object.schedule?.components(separatedBy: ",").map { Weekdays(rawValue: $0) } ?? [],
                dateEvent: object.dateEvent
            )
            if var trackers = trackerDictionary[categoryTitle] {
                trackers.append(tracker)
                trackerDictionary[categoryTitle] = trackers
            } else {
                trackerDictionary[categoryTitle] = [tracker]
            }
        }
        
        for (categoryTitle, trackers) in trackerDictionary {
            let trackerCategory = TrackerCategory(title: categoryTitle, trackers: trackers)
            trackerCategories.append(trackerCategory)
        }
        
        return trackerCategories
    }
    
    //MARK: - Init
    
    convenience init(date: Date, text: String) {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        try! self.init(context: context, date: date, text: text)
    }
    
    init(context: NSManagedObjectContext, date: Date, text: String) throws {
        self.context = context
        self.date = date
        self.text = text
        super.init()
    
        fetchedResultsController = createFetchedResultsController()
        try? fetchedResultsController?.performFetch()
    }
    
    // MARK: - Private Function
    
    private func createPredicate() -> NSPredicate {
        guard date != Date.distantPast else { return NSPredicate(value: true) }
        let calendar = Calendar.current
        let weekdayNumber = calendar.component(.weekday, from: date)
        let filterWeekday = Weekdays.fromNumberValue(weekdayNumber)
        let weekdayPredicate = NSPredicate(format: "%K CONTAINS[c] %@", #keyPath(TrackerCoreData.schedule), filterWeekday)
        let datePredicate = NSPredicate(format: "%K == %@", #keyPath(TrackerCoreData.dateEvent), date as CVarArg)
        var finalPredicate = NSCompoundPredicate(type: .or, subpredicates: [datePredicate, weekdayPredicate])
        if text != "" {
            let textPredicate = NSPredicate(format: "%K CONTAINS[c] %@", #keyPath(TrackerCoreData.name), text)
            finalPredicate = NSCompoundPredicate(type: .and, subpredicates: [textPredicate, finalPredicate])
        }
        return finalPredicate
    }
    
    private func createFetchedResultsController() -> NSFetchedResultsController<TrackerCoreData>? {
        let fetchRequest = TrackerCoreData.fetchRequest()
        fetchRequest.predicate = createPredicate()
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \TrackerCoreData.name, ascending: true)
        ]
        
        let controller = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        controller.delegate = self
        return controller
    }
    
    private func updateExistingTrackers(_ trackerCoreData: TrackerCoreData, with tracker: Tracker) {
        let scheduleString = tracker.schedule.compactMap { $0?.rawValue }.joined(separator: ",")
        //guard let (colorString, _) = colorDictionary.first(where: { $0.value == tracker.color }) else { return }
        trackerCoreData.id = tracker.id
        trackerCoreData.name = tracker.name
        trackerCoreData.color = tracker.color
        trackerCoreData.emoji = tracker.emoji
        trackerCoreData.schedule = scheduleString
        trackerCoreData.dateEvent = tracker.dateEvent
    }
    
    private func fetchCategory(with title: String) throws -> TrackerCategoryCoreData? {
        let fetchRequest: NSFetchRequest<TrackerCategoryCoreData> = TrackerCategoryCoreData.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "title == %@", title)
        
        do {
            let result = try context.fetch(fetchRequest)
            return result.first
        } catch {
            throw error
        }
    }
    
    // MARK: - Internal Function
    
    func update(with date: Date, text: String?) {
        self.date = date
        self.text = text ?? ""
        fetchedResultsController?.fetchRequest.predicate = createPredicate()
        try? fetchedResultsController?.performFetch()
    }
    
    func addNewTracker(_ tracker: Tracker, with category: TrackerCategory) throws {
        let trackerCoreData = TrackerCoreData(context: context)
        updateExistingTrackers(trackerCoreData, with: tracker)
        
        if let existingCategory = try fetchCategory(with: category.title) {
            existingCategory.addToTracker(trackerCoreData)
        } else {
            let newCategory = TrackerCategoryCoreData(context: context)
            newCategory.title = category.title
            newCategory.addToTracker(trackerCoreData)
        }
        try context.save()
    }
}

// MARK: - FetchedResultsControllerDelegate

extension TrackerStore: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        delegate?.didUpdate()
    }
}

