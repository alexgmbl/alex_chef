import Foundation
import CoreData

extension PersistentRecipe {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<PersistentRecipe> {
        NSFetchRequest<PersistentRecipe>(entityName: "Recipe")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var subtitle: String?
    @NSManaged public var category: String?
    @NSManaged public var recipeDescription: String?
    @NSManaged public var instructions: [String]?
    @NSManaged public var notes: String?
    @NSManaged public var lastUpdated: Date?
    @NSManaged public var ingredients: NSSet?
}

// MARK: Generated accessors for ingredients
extension PersistentRecipe {
    @objc(addIngredientsObject:)
    @NSManaged public func addToIngredients(_ value: Ingredient)

    @objc(removeIngredientsObject:)
    @NSManaged public func removeFromIngredients(_ value: Ingredient)

    @objc(addIngredients:)
    @NSManaged public func addToIngredients(_ values: NSSet)

    @objc(removeIngredients:)
    @NSManaged public func removeFromIngredients(_ values: NSSet)
}

extension PersistentRecipe: Identifiable {
    var displayTitle: String { title ?? "Recipe" }
    var displaySubtitle: String { subtitle ?? "" }
    var detailText: String { recipeDescription ?? "" }
    var savedIngredients: [Ingredient] {
        (ingredients as? Set<Ingredient> ?? [])
            .sorted { ($0.name ?? "").localizedCaseInsensitiveCompare($1.name ?? "") == .orderedAscending }
    }
    var savedInstructions: [String] { instructions ?? [] }
}
