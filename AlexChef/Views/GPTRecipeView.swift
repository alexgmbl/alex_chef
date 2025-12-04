import SwiftUI

struct GPTRecipeView: View {
    @StateObject private var viewModel = GPTRecipeViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                inputSection
                actionButtons
                responseSection
                followUpSection
            }
            .padding()
        }
        .navigationTitle("AI Chef")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("GPT Recipe Studio")
                .font(.largeTitle.weight(.bold))
            Text("Generate a recipe from your pantry, then ask GPT to adapt it for servings or dietary needs.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ingredients")
                .font(.headline)
            Text("Paste a list or separate with commas. We'll feed these to GPT as the available pantry items.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            TextEditor(text: $viewModel.ingredientsText)
                .frame(minHeight: 120)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(uiColor: .secondarySystemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2))
                )
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                Task { await viewModel.generateRecipe() }
            } label: {
                Label("Generate Recipe", systemImage: "wand.and.stars")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isLoading)

            Button {
                Task { await viewModel.regenerateRecipe() }
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.isLoading)
        }
    }

    private var responseSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if viewModel.isLoading {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Asking GPT for a recipe...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            if let message = viewModel.errorMessage {
                Label(message, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.red)
                    .padding(.vertical, 4)
            }

            if let recipe = viewModel.recipe {
                GeneratedRecipeView(recipe: recipe)
            } else {
                placeholderCard
            }
        }
    }

    private var followUpSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ask GPT to adjust")
                .font(.headline)
            Text("Request more servings, swap ingredients, or add dietary constraints.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(alignment: .top, spacing: 12) {
                TextEditor(text: $viewModel.followUpText)
                    .frame(minHeight: 70)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(uiColor: .secondarySystemBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2))
                    )

                Button {
                    Task { await viewModel.sendFollowUp() }
                } label: {
                    Label("Ask", systemImage: "paperplane")
                        .frame(width: 80)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isLoading)
            }

            if !viewModel.followUps.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Applied follow-ups")
                        .font(.subheadline.weight(.semibold))
                    ForEach(Array(viewModel.followUps.enumerated()), id: \.0) { index, note in
                        Label("\(index + 1). \(note)", systemImage: "arrowshape.turn.up.right")
                            .labelStyle(.titleAndIcon)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(uiColor: .tertiarySystemBackground))
                )
            }
        }
    }

    private var placeholderCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("No recipe yet", systemImage: "sparkles")
                .font(.headline)
            Text("Enter a few pantry items and tap Generate to see GPT craft a recipe with steps and ingredients.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }
}

private struct GeneratedRecipeView: View {
    let recipe: GeneratedRecipe

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.title)
                    .font(.title2.weight(.semibold))
                Text(recipe.description)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            if let servings = recipe.servings {
                Label("Serves \(servings)", systemImage: "person.2")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Ingredients")
                    .font(.headline)
                ForEach(recipe.ingredients, id: \.self) { item in
                    Label(item, systemImage: "checkmark.circle")
                        .labelStyle(.titleAndIcon)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Steps")
                    .font(.headline)
                ForEach(Array(recipe.steps.enumerated()), id: \.0) { index, step in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(index + 1)")
                            .font(.subheadline.weight(.semibold))
                            .frame(width: 24, height: 24)
                            .background(Circle().fill(Color.accentColor.opacity(0.15)))
                        Text(step)
                            .font(.body)
                            .multilineTextAlignment(.leading)
                    }
                }
            }

            if !recipe.dietaryNotes.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Notes")
                        .font(.headline)
                    HStack(spacing: 8) {
                        ForEach(recipe.dietaryNotes, id: \.self) { note in
                            Text(note)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule().fill(Color.accentColor.opacity(0.15))
                                )
                        }
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }
}
