
import SwiftUI
import SwiftData

@Model
final class SloopyNote {
    var text: String
    var createdAt: Date

    init(text: String) {
        self.text = text
        self.createdAt = .now
    }
}

struct NotesScreen: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \SloopyNote.createdAt, order: .reverse)
    private var notes: [SloopyNote]

    @State private var draft = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                VStack(spacing: 12) {
                    TextField(
                        "What's on your mind?",
                        text: $draft,
                        axis: .vertical
                    )
                    .lineLimit(3...6)
                    .font(.body)
                    .padding(13)
                    .background(
                        Color(uiColor: .secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: 14)
                    )

                    Button(action: addNote) {
                        Label("Save note", systemImage: "plus")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(13)
                            .background(
                                Color.accentColor,
                                in: RoundedRectangle(cornerRadius: 14)
                            )
                            .foregroundStyle(.white)
                    }
                    .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
                }
                .padding(16)
                .background(.background, in: RoundedRectangle(cornerRadius: 20))

                if notes.isEmpty {
                    ContentUnavailableView(
                        "No notes yet",
                        systemImage: "note.text",
                        description: Text("Your little thoughts will live here.")
                    )
                } else {
                    List {
                        ForEach(notes) { note in
                            VStack(alignment: .leading, spacing: 7) {
                                Text(note.text)
                                    .font(.body)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Text(note.createdAt, style: .date)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 5)
                        }
                        .onDelete(perform: deleteNotes)
                    }
                    .listStyle(.plain)
                }

                Spacer(minLength: 0)
            }
            .padding(18)
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Quick Notes.")
            .toolbar {
                EditButton()
            }
        }
    }

    private func addNote() {
        let value = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return }

        modelContext.insert(SloopyNote(text: value))
        draft = ""
    }

    private func deleteNotes(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(notes[index])
        }
    }
}
