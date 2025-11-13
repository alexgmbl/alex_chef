import CoreData
import SwiftUI

struct RecipeDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [],
        animation: .default
    ) private var favorites: FetchedResults<FavoriteRecipe>

    let recipe: Recipe

    var isFavorite: Bool {
        favorites.contains(where: { $0.id == recipe.id })
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                descriptionSection
                ingredientsSection
                instructionsSection
            }
            .padding()
        }
        .navigationTitle(recipe.title)
        .toolbar {
            Button(action: toggleFavorite) {
                Label(isFavorite ? "Remove Favorite" : "Save", systemImage: isFavorite ? "heart.fill" : "heart")
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(recipe.subtitle)
                .font(.title3)
                .foregroundStyle(.secondary)
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.accentColor.opacity(0.2))
                .frame(height: 200)
                .overlay(
                    Image(systemName: "fork.knife")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.accentColor)
                )
        }
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About this recipe")
                .font(.title2.weight(.semibold))
            Text(recipe.description)
                .font(.body)
        }
    }

    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ingredients")
                .font(.title2.weight(.semibold))
            ForEach(recipe.ingredients, id: \.self) { ingredient in
                Label(ingredient, systemImage: "checkmark.circle")
                    .labelStyle(.titleAndIcon)
            }
        }
    }

    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Instructions")
                .font(.title2.weight(.semibold))
            ForEach(Array(zip(recipe.instructions.indices, recipe.instructions)), id: \.0) { index, instruction in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(index + 1)")
                        .font(.headline)
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(Color.accentColor.opacity(0.2)))
                    Text(instruction)
                        .font(.body)
                        .multilineTextAlignment(.leading)
                }
            }
        }
    }

    private func toggleFavorite() {
        if let favorite = favorites.first(where: { $0.id == recipe.id }) {
            viewContext.delete(favorite)
        } else {
            let favorite = FavoriteRecipe(context: viewContext)
            favorite.id = recipe.id
            favorite.title = recipe.title
            favorite.subtitle = recipe.subtitle
            favorite.recipeDescription = recipe.description
        }

        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}
