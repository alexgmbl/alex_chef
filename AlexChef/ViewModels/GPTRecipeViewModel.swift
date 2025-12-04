import Foundation

@MainActor
final class GPTRecipeViewModel: ObservableObject {
    @Published var ingredientsText: String = ""
    @Published var followUpText: String = ""
    @Published private(set) var recipe: GeneratedRecipe?
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var followUps: [String] = []

    private let service: GPTRecipeService

    init(service: GPTRecipeService = GPTRecipeService()) {
        self.service = service
    }

    func generateRecipe() async {
        let ingredients = parsedIngredients()
        guard !ingredients.isEmpty else {
            errorMessage = "Add at least one ingredient to get a recipe."
            return
        }

        await sendRequest(ingredients: ingredients, followUpNotes: [])
    }

    func regenerateRecipe() async {
        let ingredients = parsedIngredients()
        if ingredients.isEmpty, let existing = recipe {
            await sendRequest(ingredients: existing.ingredients, followUpNotes: [])
            return
        }

        await sendRequest(ingredients: ingredients, followUpNotes: [])
    }

    func sendFollowUp() async {
        let note = followUpText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !note.isEmpty else { return }
        guard let recipe else {
            errorMessage = "Generate a recipe first, then ask for tweaks."
            return
        }

        var updatedFollowUps = followUps
        updatedFollowUps.append(note)

        followUpText = ""
        await sendRequest(
            ingredients: recipe.ingredients,
            previousRecipe: recipe,
            followUpNotes: updatedFollowUps
        )
    }

    private func parsedIngredients() -> [String] {
        ingredientsText
            .components(separatedBy: CharacterSet(charactersIn: ",\n"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func sendRequest(
        ingredients: [String],
        previousRecipe: GeneratedRecipe? = nil,
        followUpNotes: [String]
    ) async {
        isLoading = true
        errorMessage = nil

        do {
            let prompt = RecipePrompt(
                ingredients: ingredients,
                previousRecipe: previousRecipe,
                followUpNotes: followUpNotes
            )
            let generated = try await service.generateRecipe(prompt: prompt)
            recipe = generated
            followUps = followUpNotes
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
