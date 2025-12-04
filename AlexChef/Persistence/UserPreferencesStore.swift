import CoreData
import Foundation

final class UserPreferencesStore {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
    }

    func loadPreferences() throws -> UserPreferences {
        let request = UserPreferences.fetchRequest()
        request.fetchLimit = 1
        if let existing = try context.fetch(request).first {
            return existing
        }

        let preferences = UserPreferences(context: context)
        preferences.id = UUID()
        preferences.preferredUnits = "system"
        preferences.dietaryRestrictions = []
        preferences.updatedAt = Date()
        try context.save()
        return preferences
    }

    @discardableResult
    func update(preferredUnits: String? = nil, dietaryRestrictions: [String]? = nil) throws -> UserPreferences {
        let preferences = try loadPreferences()
        if let preferredUnits {
            preferences.preferredUnits = preferredUnits
        }
        if let dietaryRestrictions {
            preferences.dietaryRestrictions = dietaryRestrictions
        }
        preferences.updatedAt = Date()
        try context.save()
        return preferences
    }

    func delete(_ preferences: UserPreferences) throws {
        context.delete(preferences)
        try context.save()
    }
}
