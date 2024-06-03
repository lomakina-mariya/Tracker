
import Foundation

extension Int {
    func days() -> String {
        let remainder10 = self % 10
        let remainder100 = self % 100
        
        if self == 1 {
            return "\(self) \("day1".localized)"
        } else if remainder10 == 1 && remainder100 != 11 {
            return "\(self) \("day0".localized)"
        } else if remainder10 >= 2 && remainder10 <= 4 && (remainder100 < 10 || remainder100 >= 20) {
            return "\(self) \("day2".localized)"
        } else {
            return "\(self) \("days".localized)"
        }
    }
}
