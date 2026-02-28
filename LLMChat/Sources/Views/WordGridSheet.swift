import SwiftUI

struct WordGridSheet: View {
    let words: [WordEntry]
    @Binding var selectedWords: [WordEntry]
    let onConfirm: () -> Void
    let onDismiss: () -> Void

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(words) { word in
                            WordCell(
                                word: word,
                                isSelected: selectedWords.contains(where: { $0.id == word.id })
                            ) {
                                toggleSelection(word)
                            }
                        }
                    }
                    .padding()
                }

                Divider()

                confirmBar
            }
            .navigationTitle("Chọn từ vựng")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Hủy") { onDismiss() }
                }
            }
        }
    }

    private var confirmBar: some View {
        VStack(spacing: 4) {
            Text(selectionLabel)
                .font(.caption)
                .foregroundStyle(.secondary)

            Button(action: onConfirm) {
                Text("Học \(selectedWords.count) từ này")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(selectedWords.isEmpty ? Color.gray : Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(selectedWords.isEmpty)
            .padding()
        }
        .background(Color(.systemBackground))
    }

    private var selectionLabel: String {
        switch selectedWords.count {
        case 0: return "Chọn 1–3 từ"
        case 1: return "Đã chọn 1 từ"
        default: return "Đã chọn \(selectedWords.count) từ"
        }
    }

    private func toggleSelection(_ word: WordEntry) {
        if let idx = selectedWords.firstIndex(where: { $0.id == word.id }) {
            selectedWords.remove(at: idx)
            Haptics.impact(.light)
        } else if selectedWords.count < 3 {
            selectedWords.append(word)
            Haptics.impact(.medium)
        } else {
            Haptics.notification(.warning)
        }
    }
}

// MARK: - Word Cell

private struct WordCell: View {
    let word: WordEntry
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(word.vietnamese)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(isSelected ? .white : .primary)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.white)
                            .font(.caption)
                    }
                }

                Text(word.english)
                    .font(.caption)
                    .foregroundStyle(isSelected ? .white.opacity(0.85) : .secondary)

                Text("\(word.partOfSpeech) · \(word.partOfSpeech.partOfSpeechVietnamese)")
                    .font(.caption2)
                    .foregroundStyle(isSelected ? .white.opacity(0.65) : Color(.tertiaryLabel))
                    .italic()
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? Color.blue : Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .animation(.tutorSpring, value: isSelected)
    }
}

private extension String {
    var partOfSpeechVietnamese: String {
        switch self.lowercased() {
        case "noun":         return "danh từ"
        case "verb":         return "động từ"
        case "adjective":    return "tính từ"
        case "adverb":       return "trạng từ"
        case "pronoun":      return "đại từ"
        case "preposition":  return "giới từ"
        case "conjunction":  return "liên từ"
        case "interjection": return "thán từ"
        case "phrase":       return "cụm từ"
        default:             return self
        }
    }
}
