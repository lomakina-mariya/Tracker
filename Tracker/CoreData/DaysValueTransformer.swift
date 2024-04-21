
import Foundation

@objc
final class DaysValueTransformer: ValueTransformer {
    
    override class func transformedValueClass() -> AnyClass { NSData.self }
    override class func allowsReverseTransformation() -> Bool { true }
    
    override func transformedValue(_ value: Any?) -> Any? {
        if let data = value as? NSData {
            return data
        }
        guard let days = value as? [Weekdays] else { return nil }
        return try? JSONEncoder().encode(days)
    }

    override func reverseTransformedValue(_ value: Any?) -> Any? {
        if let data = value as? [Weekdays] {
            return data
        }
        guard let data = value as? NSData else { return nil }
        return try? JSONDecoder().decode([Weekdays].self, from: data as Data)
    }
    
    static func register() {
        ValueTransformer.setValueTransformer(
            DaysValueTransformer(),
            forName: NSValueTransformerName(rawValue: String(describing: DaysValueTransformer.self))
        )
    }
}
