//
//  RadioManager.swift
//  RadioBar
//
//  Created by Soren Randum on 24/12/2021.
//  Copyright © 2021 Søren Randum. All rights reserved.
//
// /Users/soren/Library/Containers/net.systemit.RadioBar/Data/Library/Application%20Support
import Foundation


struct RadioManager {


  private var radioURL: URL {
    let documents = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    return documents.appendingPathComponent("radios.plist")
  }
  
  func loadRadios() -> [MyRadio] {
    let decoder = PropertyListDecoder()
    guard let data = try? Data.init(contentsOf: radioURL),
          let radios = try? decoder.decode([MyRadio].self, from: data)
    else {  return [MyRadio(radioName: "No Radios", radioURL: "")] }
    return radios
  }
  
  func write(myRadios: [MyRadio]) {
    
    let encoder = PropertyListEncoder()
    if let data = try? encoder.encode(myRadios) {
      if FileManager.default.fileExists(atPath: radioURL.path) {
        try? data.write(to: radioURL)
      } else {
        FileManager.default.createFile(atPath: radioURL.path, contents: data, attributes: nil)
      }
    }
  }
  
  
  func copyRadiosFromBundle() {
    guard let path = Bundle.main.path(forResource: "DR", ofType: "plist") else {return }
    if let data = FileManager.default.contents(atPath: path),
       FileManager.default.fileExists(atPath: radioURL.path) == false {
      FileManager.default.createFile(atPath: radioURL.path, contents: data, attributes: nil)
    }
  }
  
  func installRadiosFromBundle(channelsToReload: String) {
    guard let path = Bundle.main.path(forResource: channelsToReload, ofType: "plist") else {return }
    if let data = FileManager.default.contents(atPath: path) {
      FileManager.default.createFile(atPath: radioURL.path, contents: data, attributes: nil)
    }
  }
 
  
}

