import Foundation
import CoreData

extension UserPreferences {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserPreferences> {
        NSFetchRequest<UserPreferences>(entityName: "UserPreferences")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var preferredUnits: String?
    @NSManaged public var dietaryRestrictions: [String]?
    @NSManaged public var updatedAt: Date?
}

extension UserPreferences: Identifiable {
    var wrappedPreferredUnits: String { preferredUnits ?? "system" }
    var restrictionList: [String] { dietaryRestrictions ?? [] }
}
