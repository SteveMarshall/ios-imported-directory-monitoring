import Combine
import SwiftUI
import UniformTypeIdentifiers

@main
struct NSMetadataQueryUbiquitousExternalDocumentsTestApp: App {
    @State private var adding: AddMode? = nil
    @State private var addedItems = [URL]()

    @State private var query = NSMetadataQuery()
    @State private var fileMonitor: AnyCancellable? = nil
    @State private var foundItems = [NSMetadataItem]()

    var body: some Scene {
        WindowGroup {
            NavigationView {
                List {
                    Section("Added items") {
                        ForEach(addedItems, id: \.absoluteString) { added in
                            Text(added.lastPathComponent)
                        }
                    }

                    Section("Found items") {
                        ForEach(foundItems, id: \.fileSystemName) { found in
                            Text(found.fileSystemName)
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
        findAccessibleFiles()
    }
}

extension NSMetadataQueryUbiquitousExternalDocumentsTestApp {
    func configureUbiquityAccess(to container: String? = nil) {
        DispatchQueue.global().async {
            guard let _ = FileManager.default.url(forUbiquityContainerIdentifier: container) else {
                print("⛔️ Failed to configure iCloud container URL for: \(container ?? "nil")\n"
                        + "Make sure your iCloud is available and run again.")
                return
            }
            print("Successfully configured iCloud container?")
        }
    }

    func findAccessibleFiles() {
        configureUbiquityAccess(to: "iCloud.com.stevemarshall.AnnotateML")
        query.stop()
        fileMonitor?.cancel()

        fileMonitor = Publishers.MergeMany(
            [
                .NSMetadataQueryDidFinishGathering,
                .NSMetadataQueryDidUpdate
            ].map { NotificationCenter.default.publisher(for: $0) }
        )
            .receive(on: DispatchQueue.main)
            .sink { notification in
                query.disableUpdates()
                defer { query.enableUpdates() }

                foundItems = query.results as! [NSMetadataItem]
                print("Query posted \(notification.name.rawValue) with results: \(query.results)")
            }

        query.searchScopes = [
            NSMetadataQueryAccessibleUbiquitousExternalDocumentsScope
        ]
        query.predicate = NSPredicate(
            format: "%K LIKE %@",
            argumentArray: [NSMetadataItemFSNameKey, "*"]
        )
        query.sortDescriptors = [
            NSSortDescriptor(key: NSMetadataItemFSNameKey, ascending: true)
        ]

        if query.start() {
            print("Query started")
        } else {
            print("Query didn't start for some reason")
        }
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

extension NSMetadataItem {
    var fileSystemName: String {
        guard let fileSystemName = value(
            forAttribute: NSMetadataItemFSNameKey
        ) as? String else { return "" }

        return fileSystemName
    }
}
