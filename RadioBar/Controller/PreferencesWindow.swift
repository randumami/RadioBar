//
//  PreferencesWindow.swift
//  QuickShell
//
//  Created by Søren Randum on 29/12/2017.
//  Copyright © 2017 Søren Randum. All rights reserved.
//

import Cocoa
import ServiceManagement

class PreferencesWindow: NSWindowController, NSTableViewDelegate, NSTableViewDataSource {
  
  override var windowNibName : NSNib.Name!
  { return "PreferencesWindow"}
  
  @IBOutlet weak var loadAtStartupCheckBox: NSButton!
  @IBOutlet weak var channelTable: NSScrollView!
  @IBOutlet weak var tableView: NSTableView!
  @IBOutlet weak var radioToPlayWhenStartingPopUp: NSPopUpButton!
  
  var isRadioDataChanged : Bool = false
  var radioManager = RadioManager()
  
  override func windowDidLoad() {
    super.windowDidLoad()
    
    self.window?.center()
    self.window?.orderFrontRegardless()
    NSApp.activate(ignoringOtherApps: true)
   
    tableView.delegate = self
    tableView.dataSource = self
    tableView.target = self
    
    tableView.reloadData()
    
    getDefaultValues()
    
  }
  
  func getDefaultValues() {
    
    // here we get default value for LoadAtStartUp
    let foundHelper = NSWorkspace.shared.runningApplications.contains {
      $0.bundleIdentifier == K.helperBundleName
    }
    loadAtStartupCheckBox.state = foundHelper ? .on : .off
    
    loadRadiosIntoPopUpMenu(withItemSelected: defaults.standardRadio)
  }
  
  
  
  func loadRadiosIntoPopUpMenu(withItemSelected: String){
    //sets the previously selected default value in the popUp menu when loading window
    
    radioToPlayWhenStartingPopUp.removeAllItems()
    radioToPlayWhenStartingPopUp.addItem(withTitle: "-")
    for radio in myRadioList {
      radioToPlayWhenStartingPopUp.addItem(withTitle: radio.radioName)
    }
    radioToPlayWhenStartingPopUp.selectItem(withTitle: withItemSelected)
    
  }
  
  
  @IBAction func reloadDefaultRadioChannels(_ sender: NSButton) {
    
    radioManager.installRadiosFromBundle(channelsToReload: sender.title)
    restartAppToLoadNewSettings()
    
  }
  
  
  @IBAction func removeRowFromTableView(_ sender: NSButton) {
    
    let row =  tableView.selectedRow
    
    if row != -1 {
      tableView.beginUpdates()
      tableView.removeRows(at: IndexSet(integer: row), withAnimation: .slideRight)
      tableView.endUpdates()
      myRadioList.remove(at: row)
      isRadioDataChanged = true
    }
  }
  
  @IBAction func addRowToTableView(_ sender: NSButton) {
    //insertRowsAtIndexes
    // tableView.insertRows(at: numberOfRows(in: tableView), withAnimation: .effectFade)
    
    tableView.beginUpdates()
    tableView.insertRows(at: IndexSet(integer: numberOfRows(in: tableView)-1), withAnimation: .effectFade)
    tableView.endUpdates()
    
    print(numberOfRows(in: tableView))
  }
  
  @IBAction func onEditRadioName(_ sender: NSTextField) {
    /// changes the value in myRadioList to the value the user put in the tableView
    let row = tableView.row(for: sender)
    if row < myRadioList.count  {
      myRadioList[row].radioName = sender.stringValue
    } else {
      myRadioList.append(MyRadio(radioName: sender.stringValue, radioURL: ""))
    }
  }
  
  @IBAction func onEditRadioURL(_ sender: NSTextField) {
    /// changes the value in myRadioList to the value the user put in the tableView
    let row = tableView.row(for: sender)
    if row < myRadioList.count {
      myRadioList[row].radioURL = sender.stringValue
    } else {
      myRadioList.append(MyRadio(radioName: "" , radioURL: sender.stringValue))
    }
  }
  
  @IBAction func aboutClicked(_ sender: Any) {
    let dialog = NSAlert()
    dialog.messageText = K.aboutMessageText
    if (dialog.runModal() == NSApplication.ModalResponse.OK) { return }
  }
  
  func restartAppToLoadNewSettings() {
    let url = URL(fileURLWithPath: Bundle.main.resourcePath!)
    let path = url.deletingLastPathComponent().deletingLastPathComponent().absoluteString
    
    let task = Process()
    task.launchPath = "/usr/bin/open"
    task.arguments = [path]
    task.launch()
    exit(0)
  }
  
  @IBAction func saveButtonClicked(_ sender: NSButton) {
    
    radioManager.write(myRadios: myRadioList)
    defaults.standardRadio = radioToPlayWhenStartingPopUp.titleOfSelectedItem ?? "-"
    
    restartAppToLoadNewSettings()
    
    
  }
  
  @IBAction func toggleLoadAtStartup(_ sender: NSButtonCell) {
    // sets .state on checkBox based on loginItems.x.plist (in launchd folder)
    let isLoadOnStartup = sender.state == .on
    SMLoginItemSetEnabled(K.helperBundleName as CFString, isLoadOnStartup)
  }
  
  
} // MARK: -  End Class PreferencesWindow


// MARK: - Delegates for TableView
extension PreferencesWindow {
  
  func numberOfRows(in tableView: NSTableView) -> Int {
    return myRadioList.count
  }
  
  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    guard let cell = tableView.makeView(withIdentifier: (tableColumn!.identifier), owner: self) as? NSTableCellView else {return nil}
    
    if (tableColumn?.identifier)!.rawValue == K.nameCell {
      cell.textField?.stringValue = myRadioList[row].radioName
    } else
    if (tableColumn?.identifier)!.rawValue == K.addressCell {
      cell.textField?.stringValue = myRadioList[row].radioURL
    }
    return cell
  }
  
  func tableView(_ tableView: NSTableView,
                 shouldEdit tableColumn: NSTableColumn?,
                 row: Int) -> Bool{
    return true
  }
  //
}

