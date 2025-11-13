import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = RecipeViewModel()

    var body: some View {
        List {
            ForEach(viewModel.filteredRecipes) { recipe in
                NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(recipe.title)
                            .font(.headline)
                        Text(recipe.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Search")
        .searchable(text: $viewModel.searchQuery, prompt: "Search recipes")
    }
}
