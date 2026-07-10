import SwiftUI
import Foundation

extension Text {
    init(localized key: String) {
        self.init(LocalizedStringKey(key))
    }
}

extension String {
    var localizedUI: String {
        NSLocalizedString(self, comment: "")
    }

    func localizedUI(with arguments: CVarArg...) -> String {
        String(format: NSLocalizedString(self, comment: ""), arguments: arguments)
    }
}
