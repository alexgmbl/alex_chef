import Foundation

struct RecipeSearchService {
    struct Configuration {
        let apiKey: String
        let baseURL: URL

        static func load() -> Configuration? {
            guard let key = Bundle.main.infoDictionary?["RECIPE_API_KEY"] as? String,
                  !key.isEmpty else {
                return nil
            }

            if let urlString = Bundle.main.infoDictionary?["RECIPE_API_URL"] as? String,
               let url = URL(string: urlString) {
                return Configuration(apiKey: key, baseURL: url)
            }

            guard let defaultURL = URL(string: "https://api.spoonacular.com/recipes/complexSearch") else {
                return nil
            }

            return Configuration(apiKey: key, baseURL: defaultURL)
        }
    }

    enum ServiceError: LocalizedError {
        case missingConfiguration
        case invalidResponse

        var errorDescription: String? {
            switch self {
            case .missingConfiguration:
                return "Configure RECIPE_API_KEY to search live recipes."
            case .invalidResponse:
                return "The recipe service returned an unexpected response."
            }
        }
    }

    private let urlSession: URLSession

    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    func search(parameters: RecipeSearchParameters) async throws -> [Recipe] {
        guard let configuration = Configuration.load() else {
            return fallbackResults(for: parameters)
        }

        var components = URLComponents(url: configuration.baseURL, resolvingAgainstBaseURL: false)
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "apiKey", value: configuration.apiKey),
            URLQueryItem(name: "query", value: parameters.query),
            URLQueryItem(name: "number", value: String(parameters.maxResults)),
            URLQueryItem(name: "addRecipeInformation", value: "true")
        ]

        if let cuisine = parameters.cuisine?.rawValue {
            queryItems.append(URLQueryItem(name: "cuisine", value: cuisine))
        }

        if let diet = parameters.diet?.rawValue {
            queryItems.append(URLQueryItem(name: "diet", value: diet))
        }

        components?.queryItems = queryItems

        guard let requestURL = components?.url else {
            throw ServiceError.invalidResponse
        }

        let (data, response) = try await urlSession.data(from: requestURL)
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw ServiceError.invalidResponse
        }

        guard let decoded = try? JSONDecoder().decode(SpoonacularSearchResponse.self, from: data) else {
            throw ServiceError.invalidResponse
        }

        return decoded.results.map { $0.toRecipe() }
    }

    private func fallbackResults(for parameters: RecipeSearchParameters) -> [Recipe] {
        let source = SampleData.recipes
        let baseQuery = parameters.query.trimmingCharacters(in: .whitespacesAndNewlines)

        let filtered = source.filter { recipe in
            baseQuery.isEmpty ||
                recipe.title.localizedCaseInsensitiveContains(baseQuery) ||
                recipe.subtitle.localizedCaseInsensitiveContains(baseQuery)
        }

        return filtered.prefix(parameters.maxResults).map { recipe in
            Recipe(
                id: recipe.id,
                title: recipe.title,
                subtitle: recipe.subtitle,
                category: parameters.cuisine != nil ? .dinner : recipe.category,
                description: recipe.description,
                ingredients: recipe.ingredients,
                instructions: recipe.instructions
            )
        }
    }
}

private struct SpoonacularSearchResponse: Decodable {
    let results: [Result]

    struct Result: Decodable {
        let id: Int
        let title: String
        let summary: String?
        let readyInMinutes: Int?
        let servings: Int?
        let cuisines: [String]?
        let diets: [String]?
        let extendedIngredients: [ExtendedIngredient]?
        let analyzedInstructions: [Instruction]?

        struct ExtendedIngredient: Decodable {
            let original: String?
        }

        struct Instruction: Decodable {
            let steps: [Step]?
        }

        struct Step: Decodable {
            let number: Int?
            let step: String
        }

        func toRecipe() -> Recipe {
            let subtitleParts: [String] = [
                cuisines?.first,
                diets?.first,
                readyInMinutes.flatMap { "Ready in \($0) min" },
                servings.flatMap { "Serves \($0)" }
            ].compactMap { $0 }

            let instructions = analyzedInstructions?.first?.steps?.map { $0.step } ?? []
            let ingredients = extendedIngredients?.compactMap { $0.original?.trimmingCharacters(in: .whitespacesAndNewlines) } ?? []
            let fallbackCategory: Recipe.Category = cuisines?.contains { cuisine in
                cuisine.lowercased().contains("dessert")
            } == true ? .dessert : .dinner

            return Recipe(
                id: UUID(),
                title: title,
                subtitle: subtitleParts.joined(separator: " • ").ifEmpty("Tap to view details"),
                category: fallbackCategory,
                description: summary?.removingHTMLTags().ifEmpty("A web recipe found for your search query.") ?? "A web recipe found for your search query.",
                ingredients: ingredients.ifEmpty(["Ingredients available on the source page."]),
                instructions: instructions.ifEmpty(["Open the source recipe for full instructions."])
            )
        }
    }
}

private extension String {
    func removingHTMLTags() -> String {
        guard let data = data(using: .utf8) else { return self }
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        let attributed = try? NSAttributedString(data: data, options: options, documentAttributes: nil)
        return attributed?.string.trimmingCharacters(in: .whitespacesAndNewlines) ?? self
    }

    func ifEmpty(_ fallback: String) -> String {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? fallback : self
    }
}

private extension Array where Element == String {
    func ifEmpty(_ fallback: [String]) -> [String] {
        isEmpty ? fallback : self
    }
}
