import UIKit

/// Writes formatted text to the system clipboard.
class ClipboardWriter {
    func write(_ text: String) -> Bool {
        UIPasteboard.general.string = text
        return UIPasteboard.general.string == text
    }
}
