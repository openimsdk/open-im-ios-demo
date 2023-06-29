import Foundation

struct URLSource: Hashable {

    let url: URL

    var isPresentLocally: Bool {
        if #available(iOS 13, *) {
            return metadataCache.isEntityCached(for: url)
        } else {
            return true
        }

    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
        hasher.combine(isPresentLocally)
    }

}
