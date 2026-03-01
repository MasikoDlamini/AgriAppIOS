import Foundation

extension String {
    var htmlStripped: String {
        // Always use regex for safety
        return self.replacingOccurrences(
            of: "<[^>]+>",
            with: "",
            options: .regularExpression,
            range: nil
        )
    }
}