//
//  StatusMenuController.swift
//  RadioBar
//
//  Created by Søren Randum on 10/02/2018.
//  Copyright © 2018 Søren Randum. All rights reserved.
//

import Cocoa

var myRadioList : [MyRadio] = []


 class StatusMenuController: NSObject {
 
  @IBOutlet var statusMenu: NSMenu!
  let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
  
  var preferencesWindow = PreferencesWindow()
  var radioManager = RadioManager()
  var radioStream: Radio = Radio()
  
  override func awakeFromNib() {
    super.awakeFromNib()
    statusItem.button?.image = NSImage(named: K.menuBarIcon)
    radioManager.copyRadiosFromBundle()

    myRadioList = radioManager.loadRadios()
    radioStream.setup()
    buildRadioMenu()
  
    playDefaultRadio()
  }
  
   func playDefaultRadio(){
     guard  defaults.standardRadio != "-" else {return}
     let defaultmenu =  defaults.standardRadio

     for menu in statusMenu.items {
       if menu.title == defaultmenu {
         clickMenuItem(menuItem: statusMenu.item(withTitle: defaultmenu)!)
       }
     }
   }
   
func buildRadioMenu(){
    /// Builds the Menu.Bar drop-down menu, adds the radio channels and pref and quit menu. also sets the functions to be called when a menu i clicked
    statusItem.menu = nil
        for key in myRadioList {
          let menuItem = NSMenuItem(title: key.radioName, action: #selector(self.clickMenuItem), keyEquivalent: "" )
          statusMenu.addItem(menuItem)
        }
        
        statusMenu.addItem(NSMenuItem.separator())
        statusMenu.addItem(NSMenuItem(title: K.preferencesMenuName, action: #selector(self.PrefsClicked), keyEquivalent: ""))
        statusMenu.addItem(NSMenuItem(title: K.quitMenuName, action: #selector(self.QuitClicked), keyEquivalent: ""))
      
        statusItem.menu = statusMenu
  }
  
  
  
  @objc func clickMenuItem(menuItem: NSMenuItem) {
 
    if radioStream.isPlaying() && menuItem.state == .on
    {
      radioStream.stop()
      menuItem.state = .off
    } else {
      radioStream.stop()
      let index = myRadioList.firstIndex { $0.radioName == menuItem.title } ?? 0
      radioStream.setStation(nameOfStation: menuItem.title, URLOfStation: myRadioList[index].radioURL)
      radioStream.play()
      clerAllMenuCheckMarks(current: menuItem)
      menuItem.state = .on
    }
  }
  
  @IBAction func QuitClicked(_ sender: NSMenuItem) {
    if radioStream.isPlaying(){
      radioStream.stop()}
        
    NSApplication.shared.terminate(self)
  }
  
  @IBAction func PrefsClicked(_ sender: NSMenuItem) {
    
    preferencesWindow.showWindow(sender)
    
  }
  
  
  func clerAllMenuCheckMarks(current: NSMenuItem) {
    for menuItem in statusMenu.items {
      if menuItem.state == .on {
        menuItem.state = .off
        break
      }
    }
  }
  
}
