import CoreData
import Foundation

final class RecipeStorage {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
    }

    @discardableResult
    func save(recipe: Recipe, notes: String? = nil) throws -> PersistentRecipe {
        let storedRecipe = try fetchRecipe(by: recipe.id) ?? PersistentRecipe(context: context)

        storedRecipe.id = recipe.id
        storedRecipe.title = recipe.title
        storedRecipe.subtitle = recipe.subtitle
        storedRecipe.recipeDescription = recipe.description
        storedRecipe.category = recipe.category.rawValue
        storedRecipe.instructions = recipe.instructions
        storedRecipe.notes = notes ?? storedRecipe.notes
        storedRecipe.lastUpdated = Date()

        replaceIngredients(for: storedRecipe, with: recipe.ingredients)

        try context.save()
        return storedRecipe
    }

    func update(recipe: PersistentRecipe, notes: String?, instructions: [String]? = nil, ingredients: [String]? = nil) throws {
        recipe.notes = notes
        if let instructions {
            recipe.instructions = instructions
        }
        if let ingredients {
            replaceIngredients(for: recipe, with: ingredients)
        }
        recipe.lastUpdated = Date()
        try context.save()
    }

    func fetchRecipe(by id: UUID) throws -> PersistentRecipe? {
        let request = PersistentRecipe.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    func fetchRecipes() throws -> [PersistentRecipe] {
        let request = PersistentRecipe.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \PersistentRecipe.lastUpdated, ascending: false)]
        return try context.fetch(request)
    }

    func delete(recipe: PersistentRecipe) throws {
        context.delete(recipe)
        try context.save()
    }

    // MARK: - Helpers

    private func replaceIngredients(for recipe: PersistentRecipe, with names: [String]) {
        if let currentIngredients = recipe.ingredients as? Set<Ingredient> {
            currentIngredients.forEach(context.delete)
        }
        let newIngredients = names.map { name -> Ingredient in
            let ingredient = Ingredient(context: context)
            ingredient.id = UUID()
            ingredient.name = name
            ingredient.recipe = recipe
            return ingredient
        }
        recipe.ingredients = NSSet(array: newIngredients)
    }
}
