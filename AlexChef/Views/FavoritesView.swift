import CoreData
import SwiftUI

struct FavoritesView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \FavoriteRecipe.title, ascending: true)],
        animation: .easeInOut
    ) private var favorites: FetchedResults<FavoriteRecipe>

    var body: some View {
        Group {
            if favorites.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(favorites) { recipe in
                        NavigationLink(destination: FavoriteDetailView(recipe: recipe)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(recipe.title ?? "Unknown Recipe")
                                    .font(.headline)
                                if let subtitle = recipe.subtitle {
                                    Text(subtitle)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
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
    let recipe: FavoriteRecipe

    var body: some View {
        List {
            Section(header: Text("Description")) {
                Text(recipe.recipeDescription ?? "Delicious meal" )
            }
        }
        .navigationTitle(recipe.title ?? "Recipe")
    }
}
