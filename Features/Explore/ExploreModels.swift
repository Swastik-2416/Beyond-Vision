import Foundation

struct SampleExperience: Identifiable {
    let id = UUID()
    let name: String
    let imageName: String
    let description: String
    let category: String
    let isFeatured: Bool
}

enum ExperienceCategory: String, CaseIterable {
    case all = "All"
    case animals = "Animals"
    case vehicles = "Vehicles"

    var icon: String {
        switch self {
        case .all:      return "square.grid.2x2"
        case .animals:  return "pawprint.fill"
        case .vehicles: return "car.fill"
        }
    }
}

let sampleExperiences: [SampleExperience] = [
    SampleExperience(name: "Golden Retriever", imageName: "dog",
                     description: "A playful golden retriever dog is sitting on the beach facing the sea.",
                     category: "Animals", isFeatured: true),
    SampleExperience(name: "Sunbathing Cat", imageName: "cat",
                     description: "A cute cat is sunbathing near the window.",
                     category: "Animals", isFeatured: false),
    SampleExperience(name: "Forest Ride", imageName: "motorcycle",
                     description: "A motorcycle is standing on a lone road of a forest.",
                     category: "Vehicles", isFeatured: false),
    SampleExperience(name: "Mountain Lake", imageName: "boat",
                     description: "A boat is in the middle of a sea covered by forest and mountains.",
                     category: "Vehicles", isFeatured: false),
    SampleExperience(name: "Clear Skies", imageName: "aeroplane",
                     description: "An aeroplane is flying on a clear sky.",
                     category: "Vehicles", isFeatured: false),
    SampleExperience(name: "Teddy Bear", imageName: "bear",
                     description: "It's a cute fluffy white teddy bear.",
                     category: "Animals", isFeatured: false),
]
