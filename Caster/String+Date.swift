//
//  String+Date.swift
//  Caster
//
//  Created by Alex Truong on 5/1/17.
//  Copyright © 2017 Alex Truong. All rights reserved.
//

import Foundation
import UIKit

// MARK: subscription
extension String {
    
    subscript (i: Int) -> Character {
        return self[index(startIndex, offsetBy: i)]
    }
    
    subscript (r: Range<Int>) -> String {
        let start = index(startIndex, offsetBy: r.lowerBound)
        let end = index(startIndex, offsetBy: r.upperBound - r.lowerBound)
        return self[Range(start ..< end)]
    }
}

// MARK: levenshtein distance
// https://github.com/raywenderlich/swift-algorithm-club/
extension String {
    func levenshtein(toString other: String, distanceMoreThan percent: CGFloat) -> Bool {
        let selfArray = Array(self.unicodeScalars)
        let otherArray = Array(other.unicodeScalars)
        
        let m = selfArray.count
        let n = otherArray.count
        var matrix = [Int](repeating: 0, count: (m + 1) * (n + 1))
        
        // initialize matrix
        for index in 1..<(m + 1) {
            // the distance of any first string to an empty second string
            // (index, 0) = index
            matrix[index * n] = index
        }
        
        for index in 1..<(n + 1) {
            // the distance of any second string to an empty first string
            // (0, index) = index
            matrix[index] = index
        }
        
        // minimum distance
        let distance = Int(CGFloat(m) * percent)
        // current row
        var row = 0
        
        // compute Levenshtein distance
        for i in 0..<m {
            for j in 0..<n {
                // (i, j) -> i * n + j = row + j = base
                if selfArray[i] == otherArray[j] {
                    // (i + 1, j + 1) -> base + n + 1 = row + j + n + 1
                    // (i + 1, j) -> base + n = row + j + n
                    // (i, j + 1) -> base + 1 = row + j + 1
                    matrix[row + j + n + 1] = matrix[row + j]
                } else {
                    // minimum of the cost of insertion, deletion, or substitution
                    // added to the already computed costs in the corresponding cells
                    matrix[row + j + n + 1] = Swift.min(matrix[row + j], matrix[row + j + n], matrix[row + j + 1]) + 1
                }
            }
            
            row += n
        }

        return (matrix[(m + 1) * n] >= distance)
    }
}

extension String {
    func toDate() -> Date? {
        let formats = [
            "EEE, d MMM yyyy HH:mm:ss zzz",
            "EEE, d MMM yyyy HH:mm zzz"
        ]
        
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: self) {
                return date
            }
        }
        
        return nil
    }
    
    // simply trim whitespace, newline (including <p> and <br> at the start)
    func trimming() -> String? {
        // remove any p, br at the start of the string
        let string = self.replacingOccurrences(of: "^(\\s*<[/\\s]*(p|P|br)[^>]*>)*", with: "", options: .regularExpression, range: nil)
        
        // then trim again
        return string.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    
    // normalize string before convert to attributed string
    func normalize() -> String? {
        // remove all iframe
        var string = self.replacingOccurrences(of: "<[/\\s]*iframe[^>]*>", with: "", options: .regularExpression, range: nil)
        
        // remove all <hr>
        string = string.replacingOccurrences(of: "<[/\\s]*hr[^>]*>", with: "", options: .regularExpression, range: nil)
        
        // remove all H tags
        string = string.replacingOccurrences(of: "<[/\\s]*[hH][0-9][^>]*>", with: "", options: .regularExpression, range: nil)
        
        // remove all empty <p></p>
        string = string.replacingOccurrences(of: "<\\s*[pP][^>]*>\\s*<\\s*/[pP]\\s*>", with: "", options: .regularExpression, range: nil)
        
        // remove all consecutive <p> tags
        string = string.replacingOccurrences(of: "(<\\s*[pP][^>]*>\\s*)+", with: "<p>", options: .regularExpression, range: nil)

        // remove all consecutive <br> tags
        string = string.replacingOccurrences(of: "(<\\s*br[^>]*>\\s*)+", with: "<br>", options: .regularExpression, range: nil)

        // remove any p, br at the start of the string
        string = string.replacingOccurrences(of: "^(\\s*<[/\\s]*(p|P|br)[^>]*>)*", with: "", options: .regularExpression, range: nil)

        // remove any p, br at the end of the string
        string = string.replacingOccurrences(of: "(<[/\\s]*(p|P|br)[^>]*>\\s*)*$", with: "", options: .regularExpression, range: nil)
        
        // remove <img>
        string = string.replacingOccurrences(of: "<[\\s]*img[^>]*>", with: "", options: .regularExpression, range: nil)
        
        // then trim again
        return string.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // remove HTML tags and trimming whitespace/newline
    func plainText() -> String? {
        // remove html tags
        var string = self.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)

        // remove all escaped characters
        string = string.replacingOccurrences(of: "&[a-z0-9#]+;", with: "", options: .regularExpression, range: nil)
        
        // remove all new line character
        string = string.replacingOccurrences(of: "\n", with: "", options: .literal, range: nil)
        string = string.replacingOccurrences(of: "\r", with: "", options: .literal, range: nil)
        
        // remove all Zero-width non-joiner chars
        let zeroWidthNonJoiners = ["\u{200B}", "\u{200C}", "\u{200D}", "\u{FEFF}"]
        for nonJoiner in zeroWidthNonJoiners {
            string = string.replacingOccurrences(of: nonJoiner, with: "", options: .literal, range: nil)
        }
        
        return string.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // remove HTML tags and capture only meaningful a-z character
    func rawText() -> String? {
        // remove html tags
        var string = self.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
        
        // remove all escaped characters
        string = string.replacingOccurrences(of: "&[a-z0-9#]+;", with: "", options: .regularExpression, range: nil)
        
        let azAZ = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
        return String(string.characters.filter { azAZ.characters.contains($0)})
    }
    
    func attributedString() -> NSMutableAttributedString? {
        do {
            var attribute: NSMutableAttributedString?
            guard let data = data(using: .utf8) else { return nil }
            
            try attribute = NSMutableAttributedString(data: data, options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType, NSCharacterEncodingDocumentAttribute: String.Encoding.utf8.rawValue], documentAttributes: nil)
            
            return attribute
        } catch {
            return nil
        }
    }
}

extension Date {
    func toString(withFormat format: String) -> String? {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = format
        
        return formatter.string(from: self)
    }
}
