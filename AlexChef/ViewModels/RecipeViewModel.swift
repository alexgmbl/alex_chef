import Combine
import Foundation

final class RecipeViewModel: ObservableObject {
    @Published private(set) var recipes: [Recipe]
    @Published var searchQuery: String = ""

    init(recipes: [Recipe] = SampleData.recipes) {
        self.recipes = recipes
    }

    var filteredRecipes: [Recipe] {
        guard !searchQuery.isEmpty else { return recipes }
        return recipes.filter { recipe in
            recipe.title.localizedCaseInsensitiveContains(searchQuery) ||
            recipe.subtitle.localizedCaseInsensitiveContains(searchQuery)
        }
    }

    func recipes(for category: Recipe.Category) -> [Recipe] {
        recipes.filter { $0.category == category }
    }
}
