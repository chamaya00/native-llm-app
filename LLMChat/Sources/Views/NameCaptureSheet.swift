import SwiftUI

struct NameCaptureSheet: View {
    @Binding var isPresented: Bool
    let onConfirm: (String) -> Void

    @State private var name: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 12) {
                Text("🇻🇳")
                    .font(.system(size: 56))
                Text("Xin chào!")
                    .font(.largeTitle.weight(.bold))
                Text("Bạn tên là gì?\nTôi sẽ gọi tên bạn trong suốt buổi học.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                TextField("Nhập tên của bạn...", text: $name)
                    .textFieldStyle(.plain)
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .focused($isFocused)
                    .onSubmit { confirmIfReady() }
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()

                Button(action: confirmIfReady) {
                    Text("Bắt đầu học!")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(name.trimmingCharacters(in: .whitespaces).isEmpty
                            ? Color.gray : Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        .interactiveDismissDisabled()
        .onAppear { isFocused = true }
    }

    private func confirmIfReady() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        Haptics.notification(.success)
        isPresented = false
        onConfirm(trimmed)
    }
}
