import SwiftUI

struct FlashcardSheet: View {
    let flashcards: [Flashcard]
    let flashcardImages: [UUID: UIImage]
    let onFinish: () -> Void

    @State private var currentIndex: Int = 0
    @State private var viewedIndices: Set<Int> = []
    @State private var isFlipped: Bool = false
    @State private var dragOffset: CGSize = .zero

    private var allViewed: Bool { viewedIndices.count >= flashcards.count }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                progressBar

                ZStack {
                    if flashcards.isEmpty {
                        Text("Không có thẻ học")
                            .foregroundStyle(.secondary)
                    } else {
                        cardStack
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                bottomControls
            }
            .navigationTitle("Thẻ học (\(currentIndex + 1)/\(flashcards.count))")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color(.systemGray5)).frame(height: 4)
                Capsule()
                    .fill(Color.blue)
                    .frame(width: geo.size.width * progress, height: 4)
                    .animation(.tutorSpring, value: progress)
            }
        }
        .frame(height: 4)
        .padding(.horizontal)
        .padding(.top, 12)
    }

    private var progress: Double {
        guard !flashcards.isEmpty else { return 0 }
        return Double(viewedIndices.count) / Double(flashcards.count)
    }

    // MARK: - Card Stack

    private var cardStack: some View {
        let card = flashcards[currentIndex]
        return FlashcardView(
            flashcard: card,
            image: flashcardImages[card.id],
            isFlipped: isFlipped
        )
        .padding(.horizontal, 24)
        .offset(x: dragOffset.width)
        .rotationEffect(.degrees(dragOffset.width / 20))
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation
                }
                .onEnded { value in
                    handleSwipe(value.translation.width)
                }
        )
        .onTapGesture {
            withAnimation(.tutorSpring) {
                isFlipped.toggle()
                if isFlipped { viewedIndices.insert(currentIndex) }
                Haptics.impact(.light)
            }
        }
        .id(currentIndex)
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        VStack(spacing: 12) {
            Text(isFlipped ? "Vuốt để tiếp tục" : "Nhấn để lật thẻ")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                if currentIndex > 0 {
                    Button {
                        navigate(by: -1)
                    } label: {
                        Image(systemName: "chevron.left.circle.fill")
                            .font(.title)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Button(action: onFinish) {
                    Text(allViewed ? "Luyện tập ngay!" : "Bỏ qua")
                        .font(.headline)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 12)
                        .background(allViewed ? Color.blue : Color(.secondarySystemBackground))
                        .foregroundStyle(allViewed ? .white : .secondary)
                        .clipShape(Capsule())
                }
                .animation(.tutorSpring, value: allViewed)

                Spacer()

                if currentIndex < flashcards.count - 1 {
                    Button {
                        navigate(by: 1)
                    } label: {
                        Image(systemName: "chevron.right.circle.fill")
                            .font(.title)
                            .foregroundStyle(.blue)
                    }
                }
            }
            .padding(.horizontal, 24)
        }
        .padding(.bottom, 32)
        .padding(.top, 12)
    }

    // MARK: - Navigation

    private func navigate(by delta: Int) {
        let next = currentIndex + delta
        guard next >= 0, next < flashcards.count else { return }
        withAnimation(.tutorSpring) {
            currentIndex = next
            isFlipped = false
            dragOffset = .zero
        }
        Haptics.impact(.light)
    }

    private func handleSwipe(_ dx: CGFloat) {
        if abs(dx) > 80 {
            navigate(by: dx < 0 ? 1 : -1)
        }
        withAnimation(.tutorSpring) { dragOffset = .zero }
    }
}

// MARK: - Single Flashcard View

private struct FlashcardView: View {
    let flashcard: Flashcard
    let image: UIImage?
    let isFlipped: Bool

    var body: some View {
        ZStack {
            if !isFlipped {
                frontFace
            } else {
                backFace
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            }
        }
        .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
        .animation(.tutorSpring, value: isFlipped)
    }

    // MARK: Front

    private var frontFace: some View {
        VStack(spacing: 20) {
            // Image or shimmer placeholder
            if let img = image {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 180)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                gradientPlaceholder
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            VStack(spacing: 6) {
                Text(flashcard.wordEntry.english)
                    .font(.largeTitle.weight(.bold))
                Text(flashcard.wordEntry.partOfSpeech)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .italic()
            }

            Text("Nhấn để xem nghĩa")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .frame(height: 380)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 4)
    }

    // MARK: Back

    private var backFace: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(flashcard.wordEntry.vietnamese)
                    .font(.title.weight(.bold))
                Text(flashcard.wordEntry.english)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Label("Gợi nhớ", systemImage: "lightbulb.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.orange)
                Text(flashcard.mnemonicVi)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(flashcard.exampleEn)
                    .font(.subheadline.italic())
                Text(flashcard.exampleVi)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 380)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 4)
    }

    // MARK: - Gradient Placeholder (Phase 3 fallback)

    private var gradientPlaceholder: some View {
        let hue = Double(abs(flashcard.wordEntry.english.hashValue) % 360) / 360.0
        return LinearGradient(
            colors: [
                Color(hue: hue, saturation: 0.5, brightness: 0.85),
                Color(hue: hue + 0.1, saturation: 0.6, brightness: 0.7),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            VStack {
                Text(flashcard.wordEntry.english.prefix(1).uppercased())
                    .font(.system(size: 64, weight: .bold))
                    .foregroundStyle(.white.opacity(0.6))
            }
        )
    }
}
