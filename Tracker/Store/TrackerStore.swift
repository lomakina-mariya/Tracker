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
    func didUpdate(_ store: TrackerStore, _ update: TrackerStoreUpdate)
}

final class TrackerStore: NSObject {
    private let context: NSManagedObjectContext
    private(set) var fetchedResultsController: NSFetchedResultsController<TrackerCoreData>!
    private var insertedIndexes: IndexSet?
    private var deletedIndexes: IndexSet?
    private var updatedIndexes: IndexSet?
    
    weak var delegate: TrackerStoreDelegate?
    private(set) var date: Date
    private(set) var text: String
    
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
    
    func update(with date: Date, text: String?) {
        self.date = date
        self.text = text ?? ""
        fetchedResultsController?.fetchRequest.predicate = createPredicate()
        try? fetchedResultsController?.performFetch()
    }
    
    private func createPredicate() -> NSPredicate {
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
                color: UIColor(named: object.color!) ?? UIColor(),
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

    private func updateExistingTrackers(_ trackerCoreData: TrackerCoreData, with tracker: Tracker) {
        let scheduleString = tracker.schedule.compactMap { $0?.rawValue }.joined(separator: ",")
        guard let (colorString, _) = colorDictionary.first(where: { $0.value == tracker.color }) else { return }
        trackerCoreData.id = tracker.id
        trackerCoreData.name = tracker.name
        trackerCoreData.color = colorString
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
}

extension TrackerStore: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        insertedIndexes = IndexSet()
        deletedIndexes = IndexSet()
        updatedIndexes = IndexSet()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        delegate?.didUpdate(
            self,
            TrackerStoreUpdate(
                insertedIndexes: insertedIndexes!,
                deletedIndexes: deletedIndexes!,
                updatedIndexes: updatedIndexes!
            )
        )
        insertedIndexes = nil
        deletedIndexes = nil
        updatedIndexes = nil
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .delete:
            if let indexPath = indexPath {
                deletedIndexes?.insert(indexPath.item)
            }
        case .insert:
            if let indexPath = newIndexPath {
                insertedIndexes?.insert(indexPath.item)
            }
        case .update:
            if let indexPath = indexPath {
                updatedIndexes?.insert(indexPath.item)
            }
        default:
            break
        }
    }
}

