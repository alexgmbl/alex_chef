import CoreData
import SwiftUI

struct RecipeDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest private var savedRecipes: FetchedResults<PersistentRecipe>

    @State private var notesText: String = ""

    let recipe: Recipe

    var isFavorite: Bool {
        savedRecipes.contains(where: { $0.id == recipe.id })
    }

    private var savedRecipe: PersistentRecipe? {
        savedRecipes.first
    }

    init(recipe: Recipe) {
        self.recipe = recipe
        _savedRecipes = FetchRequest(
            sortDescriptors: [],
            predicate: NSPredicate(format: "id == %@", recipe.id as CVarArg),
            animation: .default
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                descriptionSection
                ingredientsSection
                instructionsSection
                notesSection
            }
            .padding()
        }
        .navigationTitle(recipe.title)
        .toolbar {
            Button(action: toggleFavorite) {
                Label(isFavorite ? "Remove Favorite" : "Save", systemImage: isFavorite ? "heart.fill" : "heart")
            }
        }
        .onAppear(perform: syncNotes)
        .onChange(of: savedRecipe?.notes) { _, _ in
            syncNotes()
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

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Your Notes")
                    .font(.title2.weight(.semibold))
                if savedRecipe != nil {
                    Spacer()
                    Button("Save Notes", action: saveNotes)
                        .buttonStyle(.bordered)
                }
            }

            if savedRecipe == nil {
                Text("Save this recipe to start adding personal notes and tweaks.")
                    .foregroundStyle(.secondary)
            } else {
                TextEditor(text: $notesText)
                    .frame(minHeight: 120)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
            }
        }
    }

    private func toggleFavorite() {
        let storage = RecipeStorage(context: viewContext)

        do {
            if let savedRecipe {
                try storage.delete(recipe: savedRecipe)
                notesText = ""
            } else {
                try storage.save(recipe: recipe, notes: notesText)
            }
        } catch {
            print("Failed to update favorites: \(error)")
        }
    }

    private func saveNotes() {
        guard let savedRecipe else { return }
        let storage = RecipeStorage(context: viewContext)

        do {
            try storage.update(recipe: savedRecipe, notes: notesText)
        } catch {
            print("Failed to save notes: \(error)")
        }
    }

    private func syncNotes() {
        notesText = savedRecipe?.notes ?? ""
    }
}
