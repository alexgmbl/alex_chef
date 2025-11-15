import CoreData
import Foundation

extension FavoriteRecipe {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<FavoriteRecipe> {
        NSFetchRequest<FavoriteRecipe>(entityName: "FavoriteRecipe")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var subtitle: String?
    @NSManaged public var recipeDescription: String?
}

extension FavoriteRecipe: Identifiable {}
