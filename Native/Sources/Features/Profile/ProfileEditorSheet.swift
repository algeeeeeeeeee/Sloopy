import SwiftUI
import PhotosUI
import UIKit

struct ProfileEditorSheet: View {
    @Environment(\.tint) private var tint

    private var accentColor: Color { tint ?? .blue }

    @Environment(\.dismiss) private var dismiss

    @AppStorage("sloopy-profile-name")
    private var profileName = "My profile"

    @AppStorage("sloopy-avatar")
    private var avatar = "🌿"

    @AppStorage("sloopy-native-avatar-image")
    private var avatarImage = ""

    @State private var selectedPhoto: PhotosPickerItem?

    private let avatars = ["🌿", "🌙", "☁️", "✨", "🌼", "🌊"]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 15) {
                        profilePreview
                            .frame(width: 72, height: 72)
                            .clipShape(RoundedRectangle(cornerRadius: 20))

                        VStack(alignment: .leading, spacing: 5) {
                            Text("Your profile")
                                .font(.headline)
                            Text("This appears at the top of Home.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 5)
                }

                Section("Display name") {
                    TextField("Your name", text: $profileName)
                        .textInputAutocapitalization(.words)
                        .onChange(of: profileName) { _, newValue in
                            if newValue.count > 24 {
                                profileName = String(newValue.prefix(24))
                            }
                        }
                }

                Section("Profile photo") {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Label("Choose from Photos", systemImage: "photo")
                    }

                    if !avatarImage.isEmpty {
                        Button("Remove photo and use avatar") {
                            avatarImage = ""
                        }
                        .foregroundStyle(.secondary)
                    }
                }

                Section("Or choose an avatar") {
                    HStack(spacing: 10) {
                        ForEach(avatars, id: \.self) { choice in
                            Button {
                                avatar = choice
                                avatarImage = ""
                            } label: {
                                Text(choice)
                                    .font(.system(size: 25))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                    .background(
                                        avatar == choice && avatarImage.isEmpty
                                            ? accentColor.opacity(0.16)
                                            : Color(uiColor: .secondarySystemGroupedBackground),
                                        in: RoundedRectangle(cornerRadius: 13)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle("Edit profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onChange(of: selectedPhoto) { _, item in
                guard let item else { return }
                Task { await loadPhoto(item) }
            }
        }
    }

    @ViewBuilder
    private var profilePreview: some View {
        if let data = Data(base64Encoded: avatarImage),
           let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            Text(avatar)
                .font(.system(size: 38))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(accentColor.opacity(0.13))
        }
    }

    private func loadPhoto(_ item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }

        let maxDimension: CGFloat = 512
        let scale = min(1, maxDimension / max(image.size.width, image.size.height))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: size)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }

        guard let jpeg = resized.jpegData(compressionQuality: 0.78) else { return }
        await MainActor.run {
            avatarImage = jpeg.base64EncodedString()
        }
    }
}
