import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "RecipeModel")
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        let description = container.persistentStoreDescriptions.first
        description?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let viewContext = controller.container.viewContext
        for recipe in SampleData.recipes {
            let savedRecipe = PersistentRecipe(context: viewContext)
            savedRecipe.id = recipe.id
            savedRecipe.title = recipe.title
            savedRecipe.subtitle = recipe.subtitle
            savedRecipe.recipeDescription = recipe.description
            savedRecipe.category = recipe.category.rawValue
            savedRecipe.instructions = recipe.instructions
            savedRecipe.lastUpdated = Date()

            let ingredients = recipe.ingredients.map { name -> Ingredient in
                let ingredient = Ingredient(context: viewContext)
                ingredient.id = UUID()
                ingredient.name = name
                ingredient.recipe = savedRecipe
                return ingredient
            }

            savedRecipe.ingredients = NSSet(array: ingredients)
        }

        let preferences = UserPreferences(context: viewContext)
        preferences.id = UUID()
        preferences.preferredUnits = "system"
        preferences.dietaryRestrictions = ["vegetarian"]
        preferences.updatedAt = Date()
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return controller
    }()
}
