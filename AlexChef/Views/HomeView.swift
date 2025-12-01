import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = RecipeViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                featuredRecipes
                categoryGrid
            }
            .padding()
        }
        .navigationTitle("Discover")
        .navigationDestination(for: Recipe.self) { recipe in
            RecipeDetailView(recipe: recipe)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Welcome back!")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text("What will you cook today?")
                .font(.largeTitle.weight(.bold))
        }
    }

    private var featuredRecipes: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Featured Recipes")
                .font(.title2.weight(.semibold))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(viewModel.recipes.prefix(5)) { recipe in
                        NavigationLink(value: recipe) {
                            RecipeCardView(recipe: recipe)
                        }
                    }
                }
            }
        }
    }

    private var categoryGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Browse by Category")
                .font(.title2.weight(.semibold))
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                ForEach(Recipe.Category.allCases) { category in
                    NavigationLink {
                        CategoryRecipeListView(category: category)
                    } label: {
                        CategoryCard(category: category)
                    }
                }
            }
        }
    }
}

private struct RecipeCardView: View {
    let recipe: Recipe

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.accentColor.opacity(0.2))
                .frame(width: 220, height: 140)
                .overlay(
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 60, height: 60)
                )
            Text(recipe.title)
                .font(.headline)
                .foregroundStyle(.primary)
            Text(recipe.subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(width: 220, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(uiColor: .systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

private struct CategoryCard: View {
    let category: Recipe.Category

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: category.iconName)
                .font(.largeTitle)
                .foregroundStyle(Color.accentColor)
                .frame(width: 44, height: 44)
                .background(Circle().fill(Color.accentColor.opacity(0.15)))
            Text(category.title)
                .font(.headline)
                .foregroundStyle(.primary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }
}

private struct CategoryRecipeListView: View {
    @StateObject private var viewModel = RecipeViewModel()
    let category: Recipe.Category

    var body: some View {
        List {
            Section {
                ForEach(viewModel.recipes(for: category)) { recipe in
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
        }
        .navigationTitle(category.title)
    }
}
