import Foundation
import CoreData

extension Ingredient {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Ingredient> {
        NSFetchRequest<Ingredient>(entityName: "Ingredient")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var quantity: String?
    @NSManaged public var recipe: PersistentRecipe?
}

extension Ingredient: Identifiable {
    var displayName: String { name ?? "Ingredient" }
    var displayQuantity: String { quantity ?? "" }
}
