import Foundation

struct Recipe: Identifiable, Hashable {
    enum Category: String, CaseIterable, Identifiable {
        case breakfast
        case lunch
        case dinner
        case dessert
        case seasonal

        var id: String { rawValue }

        var title: String {
            rawValue.capitalized
        }

        var iconName: String {
            switch self {
            case .breakfast: return "sunrise"
            case .lunch: return "fork.knife"
            case .dinner: return "moon.stars"
            case .dessert: return "cup.and.saucer"
            case .seasonal: return "leaf"
            }
        }
    }

    let id: UUID
    let title: String
    let subtitle: String
    let category: Category
    let description: String
    let ingredients: [String]
    let instructions: [String]
}
