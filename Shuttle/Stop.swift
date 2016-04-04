//
//  Stop.swift
//  Shuttle
//
//  Created by Taylor Schmidt on 3/27/16.
//  Copyright © 2016 Taylor Schmidt. All rights reserved.
//

import Foundation
import CoreLocation

class Stop {
    var location: CLLocationCoordinate2D
    var name: String
    var stopId: String
    
    init(location loc: CLLocationCoordinate2D, name: String, stopID id: String) {
        self.location = loc
        self.name = name.toUpperCaseFirstLetters
        self.stopId = id
    }
}

extension String {
    /*
     Better for our needs than String.capitalizedString because that find the first *alpha*
     character of each word, not just the first character of each word
     "14th street".capitalizedString == "14Th Street" // the 'Th' looks weird
     "14th street".toUpperCaseFirstLetters == "14th Street" // this 'th' looks better
     */
    var toUpperCaseFirstLetters: String {
        get {
            var newCharArr: [String] = []
            let wordsArr = self.lowercaseString.componentsSeparatedByString(" ")
            for word in wordsArr {
                var wordCharArr = word.characters.map() { String($0) }
                // If empty this will crash
                if !wordCharArr.isEmpty {
                    wordCharArr[wordCharArr.startIndex] = wordCharArr.first!.uppercaseString
                    newCharArr += wordCharArr
                    newCharArr.append(" ")
                }
            }
            let newStr = newCharArr.joinWithSeparator("")
            // if empty string this will crash
            if !newStr.isEmpty {
                // truncate to get rid of
                let truncated = newStr.substringToIndex(newStr.endIndex.predecessor())
                return truncated
            } else {
                return ""
            }
            
        }
    }
}