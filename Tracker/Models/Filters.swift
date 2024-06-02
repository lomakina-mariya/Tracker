
import Foundation

enum Filters: String, CaseIterable {
    case allTrackers = "Все трекеры"
    case todayTrackers = "Трекеры на сегодня"
    case completedTrackers = "Завершенные"
    case unCompletedTrackers = "Не завершенные"
}
