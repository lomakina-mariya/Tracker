
import CoreData
import Foundation
import UIKit

final class TrackerCategoryStore: NSObject {
    private let context: NSManagedObjectContext
    
    convenience override init() {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        try! self.init(context: context)
    }
    
    init(context: NSManagedObjectContext) throws {
        self.context = context
        super.init()
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
    
    func fetchAllCategory() -> [String] {
        var categories: [String] = []
        let fetchRequest: NSFetchRequest<TrackerCategoryCoreData> = TrackerCategoryCoreData.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        do {
            let result = try context.fetch(fetchRequest)
            categories = result.map { $0.title ?? "" }
            return categories
        } catch {
            return []
        }
    }
    
    func updateCategory(withTitle title: String, newName: String) throws {
        let fetchRequest: NSFetchRequest<TrackerCategoryCoreData> = TrackerCategoryCoreData.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "title == %@", title)
        do {
            let result = try context.fetch(fetchRequest)
            guard let category = result.first else { return }
            category.title = newName
            try context.save()
        } catch {
            throw error
        }
    }
    
    func deleteCategory(title: String) throws {
        do {
            guard let category = try fetchCategory(with: title) else { return }
            context.delete(category)
            try context.save()
        } catch {
            throw error
        }
    }

}
