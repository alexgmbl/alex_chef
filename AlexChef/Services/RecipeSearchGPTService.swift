import Foundation

struct RecipeQueryInterpreter {
    private let urlSession: URLSession

    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    func interpret(query: String) async -> RecipeSearchParameters {
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let configuration = GPTRecipeService.Configuration.load(), !normalized.isEmpty else {
            return heuristicParameters(from: normalized)
        }

        let prompt = InterpretationPrompt(query: normalized)
        let requestBody = ProxyRequestBody(system: prompt.systemPrompt, user: prompt.userPrompt)

        var request = URLRequest(url: configuration.proxyURL)
        request.httpMethod = "POST"
        request.httpBody = try? JSONEncoder().encode(requestBody)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = configuration.apiToken, !token.isEmpty {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        do {
            let (data, response) = try await urlSession.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
                return heuristicParameters(from: normalized)
            }

            if let decoded = try? JSONDecoder().decode(QueryInterpretationResponse.self, from: data) {
                return decoded.parameters
            }

            if let decodedParameters = try? JSONDecoder().decode(RecipeSearchParameters.self, from: data) {
                return decodedParameters
            }
        } catch { }

        return heuristicParameters(from: normalized)
    }

    private func heuristicParameters(from query: String) -> RecipeSearchParameters {
        let lowercase = query.lowercased()

        let cuisine: RecipeSearchParameters.Cuisine? = {
            if lowercase.contains("italian") || lowercase.contains("pasta") { return .italian }
            if lowercase.contains("mexican") || lowercase.contains("taco") { return .mexican }
            if lowercase.contains("indian") || lowercase.contains("curry") { return .indian }
            if lowercase.contains("sushi") || lowercase.contains("ramen") { return .japanese }
            if lowercase.contains("thai") { return .thai }
            if lowercase.contains("mediterranean") { return .mediterranean }
            if lowercase.contains("french") { return .french }
            if lowercase.contains("chinese") || lowercase.contains("stir fry") { return .chinese }
            if lowercase.contains("bbq") { return .american }
            return nil
        }()

        let diet: RecipeSearchParameters.Diet? = {
            if lowercase.contains("vegan") { return .vegan }
            if lowercase.contains("vegetarian") { return .vegetarian }
            if lowercase.contains("gluten") { return .glutenFree }
            if lowercase.contains("dairy free") || lowercase.contains("lactose") { return .dairyFree }
            if lowercase.contains("keto") || lowercase.contains("ketogenic") { return .ketogenic }
            if lowercase.contains("paleo") { return .paleo }
            return nil
        }()

        let cleanedQuery = query.isEmpty ? "" : query

        return RecipeSearchParameters(
            query: cleanedQuery.ifEmpty("trending recipes"),
            cuisine: cuisine,
            diet: diet,
            maxResults: 10
        )
    }
}

struct RecipeResultsSummarizer {
    private let urlSession: URLSession

    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    func summarize(results: [Recipe]) async -> String? {
        guard !results.isEmpty else { return nil }
        guard let configuration = GPTRecipeService.Configuration.load() else {
            return heuristicSummary(for: results)
        }

        let prompt = SummaryPrompt(recipes: results)
        let requestBody = ProxyRequestBody(system: prompt.systemPrompt, user: prompt.userPrompt)

        var request = URLRequest(url: configuration.proxyURL)
        request.httpMethod = "POST"
        request.httpBody = try? JSONEncoder().encode(requestBody)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = configuration.apiToken, !token.isEmpty {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        do {
            let (data, response) = try await urlSession.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
                return heuristicSummary(for: results)
            }

            if let decoded = try? JSONDecoder().decode(SummaryResponse.self, from: data) {
                return decoded.summary
            }

            if let summaryText = String(data: data, encoding: .utf8) {
                return summaryText.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        } catch { }

        return heuristicSummary(for: results)
    }

    private func heuristicSummary(for results: [Recipe]) -> String {
        let highlights = results.prefix(3).map { $0.title }.joined(separator: ", ")
        return "Top picks: \(highlights)."
    }
}

private struct InterpretationPrompt {
    let query: String

    var systemPrompt: String {
        """
        You translate natural-language recipe searches into API-friendly parameters.
        Return a JSON object with:
        - query: short keyword-based search phrase
        - cuisine: one of american, italian, mexican, indian, chinese, french, mediterranean, japanese, thai (optional)
        - diet: one of vegetarian, vegan, "gluten free", "dairy free", paleo, ketogenic (optional)
        Do not return Markdown or prose—JSON only.
        """
    }

    var userPrompt: String {
        "User query: \(query)"
    }
}

private struct SummaryPrompt {
    let recipes: [Recipe]

    var systemPrompt: String {
        """
        You are a culinary assistant summarizing recipe search results.
        Provide a short paragraph (1-3 sentences) highlighting variety and dietary notes.
        Avoid Markdown and return plain text only.
        """
    }

    var userPrompt: String {
        let titles = recipes.prefix(5).map { $0.title }.joined(separator: ", ")
        let diets = recipes.flatMap { recipe in
            recipe.ingredients.filter { $0.localizedCaseInsensitiveContains("vegan") || $0.localizedCaseInsensitiveContains("gluten") }
        }
        let dietNotes = diets.isEmpty ? "no explicit dietary tags" : "notes: \(diets.joined(separator: ", "))"
        return "Summarize these recipes: \(titles). Dietary context: \(dietNotes)."
    }
}

private struct ProxyRequestBody: Codable {
    let system: String
    let user: String
}

private struct QueryInterpretationResponse: Codable {
    let parameters: RecipeSearchParameters
}

private struct SummaryResponse: Codable {
    let summary: String
}

private extension String {
    func ifEmpty(_ fallback: String) -> String {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? fallback : self
    }
}
