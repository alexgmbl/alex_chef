import Foundation

struct RecipeSearchParameters: Codable, Equatable {
    enum Cuisine: String, CaseIterable, Identifiable, Codable {
        case american
        case italian
        case mexican
        case indian
        case chinese
        case french
        case mediterranean
        case japanese
        case thai

        var id: String { rawValue }

        var title: String {
            rawValue.capitalized
        }
    }

    enum Diet: String, CaseIterable, Identifiable, Codable {
        case vegetarian
        case vegan
        case glutenFree = "gluten free"
        case dairyFree = "dairy free"
        case paleo
        case ketogenic

        var id: String { rawValue }

        var title: String {
            switch self {
            case .glutenFree:
                return "Gluten Free"
            case .dairyFree:
                return "Dairy Free"
            default:
                return rawValue.capitalized
            }
        }
    }

    var query: String
    var cuisine: Cuisine?
    var diet: Diet?
    var maxResults: Int = 10
}
