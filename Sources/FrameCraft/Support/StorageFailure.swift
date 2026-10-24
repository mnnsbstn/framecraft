import Foundation

enum StorageFailure {
    static func message(for error: Error) -> String {
        var current: NSError? = error as NSError
        // AVFoundation may wrap a filesystem failure. Bound traversal defensively.
        for _ in 0..<8 {
            guard let item = current else { break }
            if (item.domain == NSCocoaErrorDomain && item.code == NSFileWriteOutOfSpaceError) ||
                (item.domain == NSPOSIXErrorDomain && item.code == Int(ENOSPC)) {
                return "Nicht genügend Speicherplatz. Gib Speicher frei und versuche es erneut. Das Original und bereits gespeicherte Dateien bleiben erhalten."
            }
            current = item.userInfo[NSUnderlyingErrorKey] as? NSError
        }
        return error.localizedDescription
    }
}
