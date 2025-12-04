import Foundation

@MainActor
final class RecipeSearchViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var selectedCuisine: RecipeSearchParameters.Cuisine?
    @Published var selectedDiet: RecipeSearchParameters.Diet?
    @Published private(set) var results: [Recipe] = []
    @Published private(set) var summary: String?
    @Published private(set) var errorMessage: String?
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var lastParameters: RecipeSearchParameters?

    private let searchService: RecipeSearchService
    private let interpreter: RecipeQueryInterpreter
    private let summarizer: RecipeResultsSummarizer

    init(
        searchService: RecipeSearchService = RecipeSearchService(),
        interpreter: RecipeQueryInterpreter = RecipeQueryInterpreter(),
        summarizer: RecipeResultsSummarizer = RecipeResultsSummarizer()
    ) {
        self.searchService = searchService
        self.interpreter = interpreter
        self.summarizer = summarizer
    }

    func searchWithFilters() async {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let parameters = RecipeSearchParameters(
            query: query.isEmpty ? "popular recipes" : query,
            cuisine: selectedCuisine,
            diet: selectedDiet,
            maxResults: 12
        )
        await performSearch(with: parameters)
    }

    func interpretAndSearch() async {
        let parameters = await interpreter.interpret(query: searchText)
        let overridden = RecipeSearchParameters(
            query: parameters.query,
            cuisine: selectedCuisine ?? parameters.cuisine,
            diet: selectedDiet ?? parameters.diet,
            maxResults: parameters.maxResults
        )
        await performSearch(with: overridden)
    }

    private func performSearch(with parameters: RecipeSearchParameters) async {
        isLoading = true
        errorMessage = nil
        summary = nil
        lastParameters = parameters

        do {
            let fetched = try await searchService.search(parameters: parameters)
            results = fetched
            summary = await summarizer.summarize(results: fetched)
        } catch {
            errorMessage = error.localizedDescription
            results = []
        }

        isLoading = false
    }
}
