import Foundation

struct SampleData {
    static let recipes: [Recipe] = [
        Recipe(
            id: UUID(),
            title: "Summer Berry Salad",
            subtitle: "Fresh berries with mint and lime",
            category: .seasonal,
            description: "A vibrant mix of strawberries, blueberries, and raspberries tossed with mint and a squeeze of lime.",
            ingredients: [
                "1 cup strawberries",
                "1 cup blueberries",
                "1 cup raspberries",
                "Fresh mint leaves",
                "1 lime"
            ],
            instructions: [
                "Wash and slice the strawberries.",
                "Combine all berries in a bowl.",
                "Tear mint leaves and add on top.",
                "Squeeze lime juice over the salad and toss gently."
            ]
        ),
        Recipe(
            id: UUID(),
            title: "Herb Roasted Chicken",
            subtitle: "Classic roast chicken with rosemary and thyme",
            category: .dinner,
            description: "A comforting roast chicken infused with aromatic herbs and served with roasted vegetables.",
            ingredients: [
                "1 whole chicken",
                "2 tbsp olive oil",
                "Fresh rosemary",
                "Fresh thyme",
                "Salt & pepper"
            ],
            instructions: [
                "Preheat oven to 400°F (200°C).",
                "Rub the chicken with olive oil, salt, and pepper.",
                "Stuff the cavity with rosemary and thyme.",
                "Roast for 60 minutes or until juices run clear."
            ]
        )
    ]
}
