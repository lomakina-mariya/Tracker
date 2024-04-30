
import Foundation
import UIKit
import CoreData


final class TrackerStore: NSObject {
    private let context: NSManagedObjectContext
    private var fetchedResultsController: NSFetchedResultsController<TrackerCoreData>!
    
    convenience override init() {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        try! self.init(context: context)
    }
    
    init(context: NSManagedObjectContext) throws {
        self.context = context
        super.init()
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

    func updateExistingTrackers(_ trackerCoreData: TrackerCoreData, with tracker: Tracker) {
        guard let (colorString, _) = colorDictionary.first(where: { $0.value == tracker.color }) else { return }
        trackerCoreData.id = tracker.id
        trackerCoreData.name = tracker.name
        trackerCoreData.color = colorString
        trackerCoreData.emoji = tracker.emoji
        trackerCoreData.schedule = DaysValueTransformer().transformedValue(tracker.schedule) as? NSObject
        trackerCoreData.dateEvent = tracker.dateEvent
    }
    
    func fetchCategory(with title: String) throws -> TrackerCategoryCoreData? {
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

