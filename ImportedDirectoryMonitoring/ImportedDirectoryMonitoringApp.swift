import Combine
import SwiftUI
import UniformTypeIdentifiers

@main
struct ImportedDirectoryMonitoringApp: App {
    @Environment(\.scenePhase) private var scenePhase

    @State private var importing: Importing? = nil
    @State private var importedItems = [URL]()

    @State private var query = NSMetadataQuery()
    @State private var fileMonitor: AnyCancellable? = nil
    @State private var foundItems = [NSMetadataItem]()

    @State private var rootURL: URL? = nil

    @State private var filePresenters = [FilePresenter]()
    @State private var observedChanges = [FilePresenter.Change]()

    var body: some Scene {
        WindowGroup {
            NavigationView {
                List {
                    Section("Imported items") {
                        ForEach(importedItems, id: \.absoluteString) { imported in
                            Text(imported.lastPathComponent)
                        }
                    }

                    Section("Found \(foundItems.count) items from NSMetadataQuery") {
                        ForEach(foundItems, id: \.fileSystemName) { found in
                            Text(found.fileSystemName)
                        }
                    }

                    Section("Observed changes from FilePresenter") {
                        ForEach(observedChanges) { change in
                            Text(change.description)
                        }
                    }
                }
                .toolbar {
                    Menu {
                        Button(action: addFile, label: {
                            Label("Add file", systemImage: "doc.badge.plus")
                        })
                        Button(action: { importing = .file }, label: {
                            Label("Import file", systemImage: "arrow.down.doc")
                        })
                        Button(action: { importing = .folder }, label: {
                            Label("Import folder", systemImage: "square.and.arrow.down")
                        })
                    } label: {
                        Label("Add item", systemImage: "plus")
                    }
                }
                .fileImporter(
                    isPresented: Binding(
                        get: { importing != nil },
                        set: { _ in importing = nil }
                    ),
                    allowedContentTypes: importing?.allowedContentTypes ?? [],
                    allowsMultipleSelection: true,
                    onCompletion: importFiles
                )
                .navigationTitle("MetadataQuery Test")
                .onChange(of: scenePhase) { newPhase in
                    filePresenters.forEach(NSFileCoordinator.removeFilePresenter(_:))

                    guard newPhase == .active else { return }

                    configureUbiquityAccess(
                        to: "iCloud.com.stevemarshall.Sample",
                        then: findAccessibleFiles
                    )
                    filePresenters.forEach(NSFileCoordinator.addFilePresenter(_:))
                }
                .onChange(of: importedItems) { importedItems in
                    filePresenters.forEach(NSFileCoordinator.removeFilePresenter(_:))

                    filePresenters = importedItems.map { importedItem in
                        FilePresenter(with: importedItem) {
                            observedChanges.append($0)
                        }
                    }
                }
                .onChange(of: scenePhase) { newPhase in
                    guard newPhase == .background else { return }

                }
            }
        }
    }
}

extension ImportedDirectoryMonitoringApp {
    func importFiles(_ result: Result<[URL], Error>) {
        guard case .success(let urls) = result else {
            return
        }
        importedItems.append(
            contentsOf: urls
        )
    }
}

extension ImportedDirectoryMonitoringApp {
    func configureUbiquityAccess(
        to container: String? = nil,
        then access: (() -> Void)?
    ) {
        // This shouldn't be on the main thread because it can apparently take some time
        DispatchQueue.global().async {
            guard let url = FileManager.default.url(
                forUbiquityContainerIdentifier: container
            ) else {
                print("⛔️ Failed to configure iCloud container URL for: \(container ?? "nil")\n"
                        + "Make sure your iCloud is available and run again.")
                return
            }

            print("Successfully configured iCloud container")
            rootURL = url
            access.map { DispatchQueue.main.async(execute: $0) }
        }
    }
}

extension ImportedDirectoryMonitoringApp {
    func addFile() {
        guard let fileURL = rootURL?.appendingPathComponent(
            UUID().uuidString,
            isDirectory: false
        ) else { return }

        NSFileCoordinator().coordinate(writingItemAt: fileURL, options: .forReplacing, error: nil) { newURL in
            FileManager.default.createFile(atPath: newURL.path, contents: nil)
        }
    }
}

extension ImportedDirectoryMonitoringApp {
    func findAccessibleFiles() {
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
                print("Query posted \(notification.name.rawValue) with \(foundItems.count) results: \(query.results)")
            }

        query.searchScopes = [
            NSMetadataQueryAccessibleUbiquitousExternalDocumentsScope,
            rootURL as Any
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

extension ImportedDirectoryMonitoringApp {
    private enum Importing {
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

private extension FilePresenter.Change {
    var description: String {
        switch self {
        case .added(let url):
            return "Added \(url)"
        case .deleted(let url):
            return "Deleted \(url)"
        case .changed(let url):
            return "Changed \(url)"
        case .moved(let old, let new):
            return "Moved \(old) to \(new)"
        }
    }
}
