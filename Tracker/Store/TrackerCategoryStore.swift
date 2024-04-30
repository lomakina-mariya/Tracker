
import Foundation
import UIKit
import CoreData

enum TrackerCategoryStoreError: Error {
    case decodingErrorInvalidTitle
}

struct TrackerCategoryStoreUpdate {
    let insertedIndexes: IndexSet
    let deletedIndexes: IndexSet
    let updatedIndexes: IndexSet
   
}

protocol TrackerCategoryStoreDelegate: AnyObject {
    func didUpdate(_ store: TrackerCategoryStore, _ update: TrackerCategoryStoreUpdate)
}

final class TrackerCategoryStore: NSObject {
    private let context: NSManagedObjectContext
    private var fetchedResultsController: NSFetchedResultsController<TrackerCategoryCoreData>!
    private var insertedIndexes: IndexSet?
    private var deletedIndexes: IndexSet?
    private var updatedIndexes: IndexSet?
    
    
    weak var delegate: TrackerCategoryStoreDelegate?
    
    convenience override init() {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        try! self.init(context: context)
    }
    
    init(context: NSManagedObjectContext) throws {
        self.context = context
        super.init()
        
        let fetchRequest = TrackerCategoryCoreData.fetchRequest()
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \TrackerCategoryCoreData.title, ascending: true)
        ]
        let controller = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        controller.delegate = self
        self.fetchedResultsController = controller
        try controller.performFetch()
    }
    
    var trackersCategories: [TrackerCategory] {
        guard
            let objects = self.fetchedResultsController.fetchedObjects,
            let categories = try? objects.map({ try self.getCategories(from: $0) })
        else { return [] }
        return categories
    }

    func getCategories(from trackerCategoryStore: TrackerCategoryCoreData) throws -> TrackerCategory {
        guard let title = trackerCategoryStore.title else {
            throw TrackerCategoryStoreError.decodingErrorInvalidTitle
        }
        var trackers: [Tracker] = []
        
        if let trackerSet = trackerCategoryStore.tracker as? Set<TrackerCoreData> {
            for trackerCoreData in trackerSet {
                let tracker = Tracker(
                    id: trackerCoreData.id ?? UUID(),
                    name: trackerCoreData.name ?? "",
                    color: UIColor(named: trackerCoreData.color!) ?? UIColor(),
                    emoji: trackerCoreData.emoji ?? "",
                    schedule: (DaysValueTransformer().reverseTransformedValue(trackerCoreData.schedule) as? [Weekdays?]) ?? [],
                    dateEvent: trackerCoreData.dateEvent
                )
                trackers.append(tracker)
            }
        }
        return TrackerCategory(
            title: title,
            trackers: trackers
        )
    }
}

extension TrackerCategoryStore: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        insertedIndexes = IndexSet()
        deletedIndexes = IndexSet()
        updatedIndexes = IndexSet()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        delegate?.didUpdate(
            self,
            TrackerCategoryStoreUpdate(
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
        case.update:
            if let indexPath = indexPath {
                updatedIndexes?.insert(indexPath.item)
            }
        default:
            break
        }
    }
}
