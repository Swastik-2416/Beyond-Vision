import SwiftUI
import PhotosUI

/// Gallery of sample images plus the ability to bring in your own photo. Tapping
/// any image opens the haptic DetailView.
struct ExploreView: View {
    @ObservedObject var haptics: HapticManager
    @StateObject private var vision = VisionManager()

    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var isShowingDetail = false
    @State private var appeared = false
    @State private var selectedCategory: ExperienceCategory = .all
    @State private var searchText = ""
    @State private var showHowItWorks = false

    private var filteredExperiences: [SampleExperience] {
        sampleExperiences.filter { exp in
            let matchesCategory = selectedCategory == .all || exp.category == selectedCategory.rawValue
            let matchesSearch = searchText.isEmpty ||
                exp.name.localizedCaseInsensitiveContains(searchText) ||
                exp.category.localizedCaseInsensitiveContains(searchText)
            return matchesCategory && matchesSearch && !exp.isFeatured
        }
    }

    private var featuredExperience: SampleExperience? {
        sampleExperiences.first(where: { $0.isFeatured })
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header
                content
            }
            .navigationDestination(isPresented: $isShowingDetail) {
                if let img = selectedImage {
                    DetailView(image: img,
                               explainerText: "Your photo. Touch to feel the objects inside it.",
                               haptics: haptics, vision: vision)
                }
            }
        }
        .onChange(of: selectedItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    selectedImage = uiImage
                    isShowingDetail = true
                }
            }
        }
        .onAppear { withAnimation { appeared = true } }
        .sheet(isPresented: $showHowItWorks) {
            HowItWorksSheet()
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Explore")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .accessibilityAddTraits(.isHeader)
                Text("Touch. Feel. Discover.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)

            Spacer()

            HStack(spacing: 12) {
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Image(systemName: "plus")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                }
                .accessibilityLabel("Upload image")
                .accessibilityHint("Opens your photo library to choose a custom image to explore")

                Button { showHowItWorks = true } label: {
                    Image(systemName: "questionmark.circle")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                }
                .accessibilityLabel("How it works")
                .accessibilityHint("Opens a guide explaining how to use the app")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .glassEffect(in: .capsule)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    private var content: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                searchBar

                if let featured = featuredExperience, searchText.isEmpty {
                    featuredSection(featured)
                }

                experiencesSection
            }
            .padding(.top, 12)
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .font(.system(size: 16, weight: .medium))
                .accessibilityHidden(true)
            TextField("Search experiences…", text: $searchText)
                .font(.system(size: 16, design: .rounded))
                .foregroundStyle(.white)
                .accessibilityLabel("Search experiences")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .glassEffect(in: .rect(cornerRadius: 14))
        .padding(.horizontal, 20)
    }

    private func featuredSection(_ featured: SampleExperience) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Featured")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .accessibilityAddTraits(.isHeader)
                .padding(.horizontal, 20)

            if let img = UIImage(named: featured.imageName) {
                NavigationLink {
                    DetailView(image: img, explainerText: featured.description, haptics: haptics, vision: vision)
                } label: {
                    FeaturedCard(experience: featured, image: img)
                }
                .accessibilityLabel("Featured: \(featured.name), \(featured.category)")
                .accessibilityHint("Double tap to open and explore this image through haptic touch")
                .padding(.horizontal, 20)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 30)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: appeared)
            }
        }
    }

    private var experiencesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Experiences")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Text("\(filteredExperiences.count) items")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("\(filteredExperiences.count) experiences available")
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(ExperienceCategory.allCases, id: \.self) { category in
                        CategoryChip(title: category.rawValue, icon: category.icon,
                                     isSelected: selectedCategory == category) {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                selectedCategory = category
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .accessibilityLabel("Filter by category")

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                ForEach(Array(filteredExperiences.enumerated()), id: \.element.id) { index, experience in
                    if let img = UIImage(named: experience.imageName) {
                        NavigationLink {
                            DetailView(image: img, explainerText: experience.description, haptics: haptics, vision: vision)
                        } label: {
                            ExperienceCard(experience: experience, image: img)
                        }
                        .accessibilityLabel("\(experience.name), \(experience.category)")
                        .accessibilityHint("Double tap to open and feel the depth of this image through haptic vibrations")
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 30)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double(index) * 0.08 + 0.2), value: appeared)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
    }
}
