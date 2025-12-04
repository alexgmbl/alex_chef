import Foundation

struct RecipePrompt {
    let ingredients: [String]
    let previousRecipe: GeneratedRecipe?
    let followUpNotes: [String]

    init(
        ingredients: [String],
        previousRecipe: GeneratedRecipe? = nil,
        followUpNotes: [String] = []
    ) {
        self.ingredients = ingredients
        self.previousRecipe = previousRecipe
        self.followUpNotes = followUpNotes
    }

    var systemPrompt: String {
        """
        You are an expert chef helping home cooks. Respond with a JSON payload containing:
        - title (string)
        - description (string)
        - servings (integer, optional)
        - ingredients (array of strings)
        - steps (array of strings, each a concise instruction)
        - dietaryNotes (array of short strings)
        Keep instructions clear, actionable, and sized for a home kitchen.
        """
    }

    var userPrompt: String {
        var lines: [String] = []
        lines.append("Available ingredients:")
        ingredients.enumerated().forEach { index, ingredient in
            lines.append("\(index + 1). \(ingredient)")
        }

        if let previousRecipe {
            lines.append("\nCurrent recipe to adapt:")
            lines.append("Title: \(previousRecipe.title)")
            lines.append("Description: \(previousRecipe.description)")
            lines.append("Ingredients: \(previousRecipe.ingredients.joined(separator: ", "))")
            lines.append("Steps: \(previousRecipe.steps.joined(separator: " | "))")
        }

        if !followUpNotes.isEmpty {
            lines.append("\nFollow-up requests:")
            followUpNotes.enumerated().forEach { index, note in
                lines.append("\(index + 1). \(note)")
            }
        } else {
            lines.append("\nRequest: Create one recipe with a short description, ingredient list, and step-by-step instructions.")
        }

        lines.append("\nReturn only the JSON payload—no prose or Markdown.")
        return lines.joined(separator: "\n")
    }
}
