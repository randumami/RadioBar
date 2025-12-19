//
//  StatusMenuController.swift
//  RadioBar
//
//  Created by Søren Randum on 10/02/2018.
//  Copyright © 2018 Søren Randum. All rights reserved.
//

import Cocoa


class StatusMenuController: NSObject {
 
  @IBOutlet var statusMenu: NSMenu!
  let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
  
  var preferencesWindow = PreferencesWindow()
  var radioManager = RadioManager()
  var radioStream: Radio = Radio()
  let store = RadioStore.shared
  
  // Initialiserer statusmenuen, registrerer observers og bygger menuen.
  // Indlæser radioliste og sætter radioStream op, så appen er klar ved opstart.
  override func awakeFromNib() {
    super.awakeFromNib()
    NotificationCenter.default.addObserver(self, selector: #selector(radiosDidChange(_:)), name: .radiosDidChange, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(nowPlayingDidUpdate(_:)), name: .nowPlayingDidUpdate, object: nil)
    statusItem.button?.image = NSImage(named: K.menuBarIcon)
    buildRadioMenu()
    radioManager.copyRadiosFromBundle()
    store.load()
    radioStream.setup()
  }
  
  // Afspiller den valgte standardradio ved app-start, hvis en sådan er sat.
  // Finder menuitem via navn og simulerer klik, så afspilning/markering håndteres korrekt.
  func playDefaultRadio(){
    guard  UserDefaults.standard.standardRadio != "-" else { return } // no default radio is set, so nothing will be played at startup
    
    let defaultRadioChannel = UserDefaults.standard.standardRadio
    for menu in statusMenu.items {
      if menu.title == defaultRadioChannel {
        clickMenuItem(menuItem: statusMenu.item(withTitle: defaultRadioChannel)!)
      }
    }
  }
  
  // Bygger menulinjens radiomenu dynamisk ud fra den aktuelle radioliste.
  // Tilføjer også Præferencer og Quit og binder actions til menuitems.
  func buildRadioMenu(){
    /// Builds the Menu.Bar drop-down menu, adds the radio channels and preferences and quit menu. also sets the function (clickMenuItem) to be called when a menu i clicked
    statusMenu.removeAllItems()
    statusItem.menu = nil
    for key in store.radios {
      let menuItem = NSMenuItem(title: key.radioName, action: #selector(self.clickMenuItem), keyEquivalent: "" )
      menuItem.target = self
      statusMenu.addItem(menuItem)
    }
    
    statusMenu.addItem(NSMenuItem.separator())
    let prefsItem = NSMenuItem(title: K.preferencesMenuName, action: #selector(self.PrefsClicked), keyEquivalent: "")
    prefsItem.target = self
    statusMenu.addItem(prefsItem)
    let quitItem = NSMenuItem(title: K.quitMenuName, action: #selector(self.QuitClicked), keyEquivalent: "")
    quitItem.target = self
    statusMenu.addItem(quitItem)
    
    statusItem.menu = statusMenu
  }
  
  // Starter eller stopper afspilning for den valgte radiokanal.
  // Sørger for at kun ét menuitem er markeret, og at radioStream opdateres korrekt.
  @objc func clickMenuItem(menuItem: NSMenuItem) {

    if radioStream.isPlaying() && menuItem.state == .on
    {
      radioStream.stop()
      menuItem.state = .off
    } else {
      radioStream.stop()
      let index = store.radios.firstIndex { $0.radioName == menuItem.title } ?? 0
      radioStream.setStation(nameOfStation: menuItem.title, URLOfStation: store.radios[index].radioURL)
      radioStream.play()
      clearAllMenuCheckMarks()
      menuItem.state = .on
    }
  }
  
  // Stopper afspilning om nødvendigt og afslutter appen.
  // Sikrer en pæn nedlukning uden at efterlade afspilningsressourcer.
  @IBAction func QuitClicked(_ sender: NSMenuItem) {
    if radioStream.isPlaying(){
      radioStream.stop()}
      
    NSApplication.shared.terminate(self)
  }
  
  // Åbner præferencevinduet, så brugeren kan redigere kanaler og standardindstillinger.
  // Giver hurtig adgang til konfiguration direkte fra menulinjen.
  @IBAction func PrefsClicked(_ sender: NSMenuItem) {
    
    preferencesWindow.showWindow(sender)
    
  }
  
  // Fjerner markering fra alle radio-menuitems.
  // Sikrer at kun den aktuelt afspillede kanal vises som valgt.
  func clearAllMenuCheckMarks() {
    for menuItem in statusMenu.items where menuItem.state == .on {
      menuItem.state = .off
    }
  }
  
  // Rebuilder radiomenuen når kanallisten ændres og forsøger at afspille standardradio.
  // Holder UI i sync med data og forbedrer oplevelsen ved ændringer.
  @objc private func radiosDidChange(_ notification: Notification) {
    statusMenu.removeAllItems()
    buildRadioMenu()
    playDefaultRadio()
  }
  
  // Opdaterer menuknappens tooltip med aktuel titel/kunstner.
  // Gør det let at se hvad der afspilles uden at åbne et vindue.
  @objc private func nowPlayingDidUpdate(_ notification: Notification) {
    let title = (notification.userInfo?["title"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    let artist = (notification.userInfo?["artist"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    let text: String
    if !title.isEmpty && !artist.isEmpty {
      text = "\(artist) — \(title)"
    } else if !title.isEmpty {
      text = title
    } else if !artist.isEmpty {
      text = artist
    } else {
      text = ""
    }
    statusItem.button?.toolTip = text.isEmpty ? nil : text
  }
}

