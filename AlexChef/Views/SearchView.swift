import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = RecipeSearchViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                queryInput
                filterPickers
                actionButtons
                statusSection
                summarySection
                resultsSection
            }
            .padding()
        }
        .navigationTitle("Search")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recipe Finder")
                .font(.largeTitle.weight(.bold))
            Text("Search the web for recipes, filter by cuisine or diet, and let GPT translate natural requests into smart filters.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var queryInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What are you craving?")
                .font(.headline)
            TextField("e.g. spicy vegetarian noodles for two", text: $viewModel.searchText)
                .textFieldStyle(.roundedBorder)
        }
    }

    private var filterPickers: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Filters")
                .font(.headline)
            HStack(spacing: 12) {
                Picker("Cuisine", selection: $viewModel.selectedCuisine) {
                    Text("Any Cuisine").tag(RecipeSearchParameters.Cuisine?.none)
                    ForEach(RecipeSearchParameters.Cuisine.allCases) { cuisine in
                        Text(cuisine.title).tag(Optional(cuisine))
                    }
                }
                .pickerStyle(.menu)

                Picker("Diet", selection: $viewModel.selectedDiet) {
                    Text("Any Diet").tag(RecipeSearchParameters.Diet?.none)
                    ForEach(RecipeSearchParameters.Diet.allCases) { diet in
                        Text(diet.title).tag(Optional(diet))
                    }
                }
                .pickerStyle(.menu)
            }
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                Task { await viewModel.searchWithFilters() }
            } label: {
                Label("Search", systemImage: "magnifyingglass")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isLoading)

            Button {
                Task { await viewModel.interpretAndSearch() }
            } label: {
                Label("Interpret with GPT", systemImage: "sparkles")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.isLoading)
        }
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if viewModel.isLoading {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Fetching recipes...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            if let message = viewModel.errorMessage {
                Label(message, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.red)
                    .font(.subheadline)
            }

            if let parameters = viewModel.lastParameters {
                FilterSummaryView(parameters: parameters)
            }
        }
    }

    private var summarySection: some View {
        Group {
            if let summary = viewModel.summary {
                VStack(alignment: .leading, spacing: 8) {
                    Text("GPT Summary")
                        .font(.headline)
                    Text(summary)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(uiColor: .secondarySystemBackground))
                )
            }
        }
    }

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Results")
                .font(.headline)

            if viewModel.results.isEmpty && !viewModel.isLoading {
                VStack(alignment: .leading, spacing: 8) {
                    Text("No recipes yet")
                        .font(.subheadline.weight(.semibold))
                    Text("Search by keyword or let GPT convert a natural request into recipe filters.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(uiColor: .secondarySystemBackground))
                )
            }

            ForEach(viewModel.results) { recipe in
                NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                    RecipeResultRow(recipe: recipe)
                }
            }
        }
    }
}

private struct RecipeResultRow: View {
    let recipe: Recipe

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(recipe.title)
                .font(.headline)
            Text(recipe.subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(recipe.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }
}

private struct FilterSummaryView: View {
    let parameters: RecipeSearchParameters

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Using filters")
                .font(.subheadline.weight(.semibold))
            HStack(spacing: 8) {
                FilterPill(text: parameters.query)
                if let cuisine = parameters.cuisine {
                    FilterPill(text: cuisine.title)
                }
                if let diet = parameters.diet {
                    FilterPill(text: diet.title)
                }
            }
        }
    }
}

private struct FilterPill: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(Color.accentColor.opacity(0.15))
            )
    }
}
