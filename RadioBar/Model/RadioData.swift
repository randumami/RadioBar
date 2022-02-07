//
//  RadioData.swift
//  RadioBar
//
//  Created by Soren Randum on 22/01/2022.
//  Copyright © 2022 Søren Randum. All rights reserved.
//

import Foundation


struct MyRadio: Codable, Equatable {
  var radioName : String
  var radioURL : String
  
  
  static func == (lhs: MyRadio, rhs: MyRadio) -> Bool {
    return lhs.radioName == rhs.radioName && lhs.radioURL == rhs.radioURL
  }
  
}

struct defaults {
  
  static var standardRadio  :String {
    get {
      UserDefaults.standard.string(forKey: "standardRadio") ?? "-"
    }
    
    set {
      UserDefaults.standard.setValue(newValue , forKey: "standardRadio")
    }
  }
}
