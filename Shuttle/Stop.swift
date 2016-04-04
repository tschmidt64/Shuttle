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
        self.name = name.lowercaseString.toUpperCaseFirstLetters
        self.stopId = id
    }
}

extension String {
    var toUpperCaseFirstLetters: String {
        get {
            var newCharArr: [String] = []
            let wordsArr = self.componentsSeparatedByString(" ")
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