import Foundation

struct GeneratedRecipe: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String
    let description: String
    let servings: Int?
    let ingredients: [String]
    let steps: [String]
    let dietaryNotes: [String]

    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        servings: Int? = nil,
        ingredients: [String],
        steps: [String],
        dietaryNotes: [String] = []
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.servings = servings
        self.ingredients = ingredients
        self.steps = steps
        self.dietaryNotes = dietaryNotes
    }
}

extension GeneratedRecipe {
    static func mock(for ingredients: [String]) -> GeneratedRecipe {
        GeneratedRecipe(
            title: "AI Pantry Creation",
            description: "A chef-crafted idea based on the ingredients you provided.",
            servings: 2,
            ingredients: ingredients.isEmpty ? ["1 tsp curiosity"] : ingredients,
            steps: [
                "Prep the ingredients listed above and preheat your oven to 375°F (190°C).",
                "Sauté aromatics in a skillet, then fold in the highlighted ingredients.",
                "Transfer to an oven-safe dish, bake until golden and fragrant, and serve warm."
            ],
            dietaryNotes: ["Customizable", "AI-generated"]
        )
    }
}
