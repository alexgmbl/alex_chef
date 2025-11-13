# AlexChef

AlexChef is a SwiftUI-based iOS application that helps home cooks discover, search, and save their favorite recipes. The project is structured for scalability with Core Data for local persistence, Swift Package Manager-ready dependencies, and CI powered by GitHub Actions.

## Project Structure

```
AlexChef/
├── App
│   └── AlexChefApp.swift
├── CoreData
│   ├── FavoriteRecipe+CoreDataClass.swift
│   ├── FavoriteRecipe+CoreDataProperties.swift
│   └── RecipeModel.xcdatamodeld
├── Models
│   └── Recipe.swift
├── Persistence
│   └── Persistence.swift
├── Resources
│   ├── Assets.xcassets
│   ├── Info.plist
│   └── Preview Content
│       ├── Preview Assets.xcassets
│       └── SampleData.swift
├── ViewModels
│   └── RecipeViewModel.swift
└── Views
    ├── FavoritesView.swift
    ├── HomeView.swift
    ├── RecipeDetailView.swift
    └── SearchView.swift
```

The Xcode project file lives at `AlexChef.xcodeproj`.

## Features

- **SwiftUI-first UI** with tab navigation for Home, Search, and Favorites.
- **Core Data integration** via `NSPersistentCloudKitContainer`, enabling offline storage and future-ready iCloud sync.
- **Composable architecture** with view models, models, and persistence separated into dedicated folders.
- **Preview-friendly sample data** to experiment quickly with UI states.

## Requirements

- Xcode 16.2 or newer
- iOS 16.0 deployment target

## Branch Strategy

- `main`: production-ready releases.
- `develop`: integration branch for upcoming features.
- Feature branches: `feature/<short-description>` branching off `develop`.

## Getting Started

1. Clone the repository and open `AlexChef.xcodeproj` in Xcode.
2. Select the **AlexChef** scheme and choose an iOS Simulator (e.g., iPhone 15 running the latest available iOS version).
3. Press **⌘R** to build and run.

### Dependencies

The project is configured to use Swift Package Manager.

### Swift Package Manager Dependencies

- [FirebaseFirestore](https://github.com/firebase/firebase-ios-sdk) (via Swift Package Manager, minimum version 10.15.0).

To add additional packages such as other Firebase modules or computer vision models:

1. In Xcode, open **File > Add Packages...**
2. Enter the package URL, e.g. `https://github.com/firebase/firebase-ios-sdk.git`.
3. Select the desired products (FirebaseAnalytics, FirebaseFirestore, etc.) and add them to the **AlexChef** target.

Future shared dependencies can also be tracked with a `Package.resolved` file committed to the repo once packages are added.

## Continuous Integration

GitHub Actions runs `xcodebuild` against the project on pushes and pull requests targeting `main` or `develop`. The workflow file is located at `.github/workflows/ios-ci.yml` and uses `macos-latest` runners with Xcode 16.2 and the latest iOS simulator runtime.

## Core Data Model

The initial data model defines a `FavoriteRecipe` entity with `id`, `title`, `subtitle`, and `recipeDescription` attributes. Favorite management is wired into the UI, allowing users to save and remove recipes from their personal list.

## Next Steps

- Connect to real recipe data sources or APIs.
- Integrate Firebase for cloud synchronization.
- Add authentication and personalized recommendations powered by GPT.
- Expand unit/UI test coverage and add automated UI snapshot tests.

## License

This project is currently proprietary. Update this section once a license is chosen.
