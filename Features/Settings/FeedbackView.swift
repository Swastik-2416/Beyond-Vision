import SwiftUI

/// Lets users tell us what they'd like added or fixed. Feedback is saved on the
/// device and can optionally be emailed to the team.
struct FeedbackView: View {
    @StateObject private var store = FeedbackStore()
    @Environment(\.openURL) private var openURL

    @State private var selectedType: FeedbackType = .feature
    @State private var message = ""
    @State private var showThankYou = false

    private let developerEmail = "c3team21@gmail.com"

    enum FeedbackType: String, CaseIterable, Identifiable {
        case feature = "Feature request"
        case bug = "Bug / fix"
        case other = "Other"
        var id: String { rawValue }
        var icon: String {
            switch self {
            case .feature: return "lightbulb.fill"
            case .bug:     return "ladybug.fill"
            case .other:   return "ellipsis.bubble.fill"
            }
        }
    }

    private var canSubmit: Bool {
        !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                intro
                typePicker
                messageField
                submitButtons

                if showThankYou { thankYou }

                if !store.entries.isEmpty {
                    history
                }
            }
            .padding(20)
        }
        .background(Theme.backgroundGradient.ignoresSafeArea())
        .navigationTitle("Feedback")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("We'd love your thoughts")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .accessibilityAddTraits(.isHeader)
            Text("Tell us what you'd like added or anything you'd like fixed. Your notes are saved on this device.")
                .font(.system(size: 14, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var typePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Type")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
            HStack(spacing: 10) {
                ForEach(FeedbackType.allCases) { type in
                    Button {
                        withAnimation(.spring(response: 0.3)) { selectedType = type }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: type.icon).font(.system(size: 13))
                            Text(type.rawValue).font(.system(size: 13, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(selectedType == type ? .black : .white.opacity(0.85))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(selectedType == type ? AnyShapeStyle(Theme.accent) : AnyShapeStyle(.white.opacity(0.08)),
                                    in: Capsule())
                    }
                    .accessibilityLabel("\(type.rawValue)\(selectedType == type ? ", selected" : "")")
                    .accessibilityAddTraits(selectedType == type ? [.isButton, .isSelected] : .isButton)
                }
            }
        }
    }

    private var messageField: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Your message")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
            ZStack(alignment: .topLeading) {
                if message.isEmpty {
                    Text("What would make Beyond Vision better for you?")
                        .font(.system(size: 15, design: .rounded))
                        .foregroundStyle(.secondary.opacity(0.6))
                        .padding(.top, 14)
                        .padding(.horizontal, 16)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $message)
                    .font(.system(size: 15, design: .rounded))
                    .foregroundStyle(.white)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 140)
                    .padding(8)
            }
            .glassEffect(in: .rect(cornerRadius: 16))
            .accessibilityLabel("Feedback message")
        }
    }

    private var submitButtons: some View {
        VStack(spacing: 12) {
            PrimaryButton("Submit Feedback", systemImage: "paperplane.fill") {
                submit()
            }
            .opacity(canSubmit ? 1 : 0.5)
            .disabled(!canSubmit)

            Button {
                sendEmail()
            } label: {
                Label("Email it to the team", systemImage: "envelope.fill")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .glassEffect(in: .rect(cornerRadius: 16))
            }
            .opacity(canSubmit ? 1 : 0.5)
            .disabled(!canSubmit)
            .accessibilityHint("Opens your mail app with your feedback ready to send")
        }
    }

    private var thankYou: some View {
        Label("Thanks! Your feedback was saved.", systemImage: "checkmark.circle.fill")
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .foregroundStyle(.green)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 6)
            .transition(.opacity)
    }

    private var history: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your submissions")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .accessibilityAddTraits(.isHeader)

            ForEach(store.entries) { entry in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(entry.type)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.accent)
                        Spacer()
                        Text(entry.date, style: .date)
                            .font(.system(size: 12, design: .rounded))
                            .foregroundStyle(.secondary)
                        Button {
                            withAnimation { store.delete(entry) }
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityLabel("Delete this feedback")
                    }
                    Text(entry.message)
                        .font(.system(size: 14, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(14)
                .glassEffect(in: .rect(cornerRadius: 14))
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(entry.type): \(entry.message)")
            }
        }
        .padding(.top, 8)
    }

    private func submit() {
        store.add(type: selectedType.rawValue, message: message)
        message = ""
        withAnimation { showThankYou = true }
        Task {
            try? await Task.sleep(for: .seconds(3))
            withAnimation { showThankYou = false }
        }
    }

    private func sendEmail() {
        let subject = "Beyond Vision Feedback — \(selectedType.rawValue)"
        let body = message
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "mailto:\(developerEmail)?subject=\(encodedSubject)&body=\(encodedBody)") {
            openURL(url)
        }
        // Also keep a local copy so it isn't lost.
        store.add(type: selectedType.rawValue, message: message)
    }
}
