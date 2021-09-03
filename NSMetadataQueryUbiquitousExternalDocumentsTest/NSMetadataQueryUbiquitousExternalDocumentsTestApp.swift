import SwiftUI
import UniformTypeIdentifiers

@main
struct NSMetadataQueryUbiquitousExternalDocumentsTestApp: App {
    @State private var adding: AddMode? = nil
    @State private var addedItems = [URL]()

    var body: some Scene {
        WindowGroup {
            NavigationView {
                List {
                    Section("Added items") {
                        ForEach(addedItems, id: \.absoluteString) { added in
                            Text(added.lastPathComponent)
                        }
                    }
                }
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        Button(action: { adding = .file }, label: {
                            Label("Add file", systemImage: "doc.badge.plus")
                        })
                        Button(action: { adding = .folder }, label: {
                            Label("Add folder", systemImage: "folder.badge.plus")
                        })
                    }
                }
                .fileImporter(
                    isPresented: Binding(
                        get: { adding != nil },
                        set: { _ in adding = nil }
                    ),
                    allowedContentTypes: adding?.allowedContentTypes ?? [],
                    allowsMultipleSelection: true,
                    onCompletion: importFiles
                )
                .navigationTitle("MetadataQuery Test")
            }
        }
    }
}

extension NSMetadataQueryUbiquitousExternalDocumentsTestApp {
    func importFiles(_ result: Result<[URL], Error>) {
        guard case .success(let urls) = result else {
            return
        }
        addedItems.append(
            contentsOf: urls
        )
    }
}

extension NSMetadataQueryUbiquitousExternalDocumentsTestApp {
    private enum AddMode {
        case folder
        case file

        var allowedContentTypes: [UTType] {
            switch self {
            case .folder: return [.folder]
            case .file: return [.content]
            }
        }
    }
}
