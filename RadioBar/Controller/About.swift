//
//  About.swift
//  RadioBar
//
//  Created by Søren Randum on 21/09/2021.
//  Copyright © 2021 Søren Randum. All rights reserved.
//

import Cocoa

class About: NSWindowController {

  convenience init() {
        self.init(windowNibName: "AboutWindow")
    }
  
  
    override func windowDidLoad() {
        super.windowDidLoad()
        print("i aboutwindow")
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
      self.window?.center()
      self.window?.makeKeyAndOrderFront(nil)
      NSApp.activate(ignoringOtherApps: true)
    }
    
}
