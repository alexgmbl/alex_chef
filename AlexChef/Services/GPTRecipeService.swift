import Foundation

struct GPTRecipeService {
    struct Configuration {
        let proxyURL: URL
        let apiToken: String?

        static func load() -> Configuration? {
            guard let urlString = Bundle.main.infoDictionary?["GPT_PROXY_URL"] as? String,
                  let url = URL(string: urlString) else {
                return nil
            }

            let token = Bundle.main.infoDictionary?["GPT_PROXY_TOKEN"] as? String
            return Configuration(proxyURL: url, apiToken: token)
        }
    }

    enum ServiceError: LocalizedError {
        case missingConfiguration
        case invalidResponse
        case requestFailed(statusCode: Int)

        var errorDescription: String? {
            switch self {
            case .missingConfiguration:
                return "Configure GPT_PROXY_URL to enable GPT-powered recipes."
            case .invalidResponse:
                return "The AI chef returned an unexpected response."
            case .requestFailed(let statusCode):
                return "The server responded with status code \(statusCode)."
            }
        }
    }

    private let urlSession: URLSession

    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    func generateRecipe(prompt: RecipePrompt) async throws -> GeneratedRecipe {
        guard let configuration = Configuration.load() else {
            return fallbackRecipe(for: prompt)
        }

        let requestBody = ProxyRequestBody(system: prompt.systemPrompt, user: prompt.userPrompt)
        var request = URLRequest(url: configuration.proxyURL)
        request.httpMethod = "POST"
        request.httpBody = try JSONEncoder().encode(requestBody)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = configuration.apiToken, !token.isEmpty {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await urlSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ServiceError.invalidResponse
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            throw ServiceError.requestFailed(statusCode: httpResponse.statusCode)
        }

        if let decoded = try? JSONDecoder().decode(ProxyResponse.self, from: data) {
            return decoded.recipe
        }

        if let decodedRecipe = try? JSONDecoder().decode(GeneratedRecipe.self, from: data) {
            return decodedRecipe
        }

        throw ServiceError.invalidResponse
    }

    private func fallbackRecipe(for prompt: RecipePrompt) -> GeneratedRecipe {
        let base = GeneratedRecipe.mock(for: prompt.ingredients)

        guard !prompt.followUpNotes.isEmpty else {
            return base
        }

        let appendedSteps = base.steps + prompt.followUpNotes.map { note in
            "Adjustment requested: \(note)"
        }

        return GeneratedRecipe(
            title: base.title,
            description: base.description,
            servings: base.servings,
            ingredients: base.ingredients,
            steps: appendedSteps,
            dietaryNotes: base.dietaryNotes + ["Follow-ups applied"]
        )
    }
}

private struct ProxyRequestBody: Codable {
    let system: String
    let user: String
}

private struct ProxyResponse: Codable {
    let recipe: GeneratedRecipe
}
