import Foundation

class FilePresenter: NSObject {
    var onChange: ((Change) -> Void)?
    var presentedItemURL: URL?
    var presentedItemOperationQueue = OperationQueue.main

    init(with itemURL: URL, handleChanges: ((Change) -> Void)? = nil) {
        presentedItemURL = itemURL
        onChange = handleChanges
    }
}

extension FilePresenter: NSFilePresenter {
    func presentedSubitemDidAppear(at url: URL) {
        onChange?(.added(url))
    }

    func presentedSubitem(at oldURL: URL, didMoveTo newURL: URL) {
        onChange?(.moved(oldURL, newURL))
    }

    func accommodatePresentedSubitemDeletion(at url: URL) async throws {
        onChange?(.deleted(url))
    }

    func presentedSubitemDidChange(at url: URL) {
        onChange?(.changed(url))
    }
}

extension FilePresenter {
    enum Change: Identifiable {
        case added(URL)
        case deleted(URL)
        case changed(URL)
        case moved(URL, URL)

        var id: URL {
            switch self {
            case .added(let url):
                return url
            case .deleted(let url):
                return url
            case .changed(let url):
                return url
            case .moved(let url, _):
                return url
            }
        }
    }
}
