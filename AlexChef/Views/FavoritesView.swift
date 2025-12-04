import CoreData
import SwiftUI

struct FavoritesView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \PersistentRecipe.title, ascending: true)],
        animation: .easeInOut
    ) private var favorites: FetchedResults<PersistentRecipe>

    var body: some View {
        Group {
            if favorites.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(favorites) { recipe in
                        NavigationLink(destination: FavoriteDetailView(recipe: recipe)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(recipe.displayTitle)
                                    .font(.headline)
                                Text(recipe.displaySubtitle)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .onDelete(perform: deleteItems)
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Favorites")
        .toolbar { EditButton() }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart")
                .font(.system(size: 48))
                .foregroundStyle(Color.accentColor)
            Text("No favorites yet")
                .font(.headline)
            Text("Save recipes you love to quickly find them here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .multilineTextAlignment(.center)
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(16)
        .padding()
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { favorites[$0] }.forEach(viewContext.delete)
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

private struct FavoriteDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    let recipe: PersistentRecipe
    @State private var notes: String = ""

    var body: some View {
        List {
            Section(header: Text("Description")) {
                Text(recipe.detailText.isEmpty ? "Delicious meal" : recipe.detailText)
            }

            if !recipe.savedIngredients.isEmpty {
                Section(header: Text("Ingredients")) {
                    ForEach(recipe.savedIngredients) { ingredient in
                        Text(ingredient.displayName)
                    }
                }
            }

            if !recipe.savedInstructions.isEmpty {
                Section(header: Text("Instructions")) {
                    ForEach(Array(recipe.savedInstructions.enumerated()), id: \.0) { index, instruction in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Step \(index + 1)").font(.headline)
                            Text(instruction)
                        }
                    }
                }
            }

            Section(header: Text("Personal Notes")) {
                TextEditor(text: $notes)
                    .frame(minHeight: 120)
                Button("Save Notes") {
                    saveNotes()
                }
            }
        }
        .navigationTitle(recipe.displayTitle)
        .onAppear {
            notes = recipe.notes ?? ""
        }
    }

    private func saveNotes() {
        let storage = RecipeStorage(context: viewContext)
        do {
            try storage.update(recipe: recipe, notes: notes)
        } catch {
            print("Failed to persist notes: \(error)")
        }
    }
}
