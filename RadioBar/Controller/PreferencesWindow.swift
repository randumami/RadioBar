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
  
  let store = RadioStore.shared
  var workingRadios: [MyRadio] = []
  
  // Initialiserer præferencevinduet og tabelvisning, indlæser radiodata og standardværdier.
  // Sikrer at vinduet vises korrekt og at UI afspejler nuværende app-tilstand.
  override func windowDidLoad() {
    super.windowDidLoad()
    
    self.window?.center()
    self.window?.orderFrontRegardless()
    NSApp.activate(ignoringOtherApps: true)
   
    tableView.delegate = self
    tableView.dataSource = self
    tableView.target = self
    
    workingRadios = store.radios
    self.tableView.reloadData()
    getDefaultValues()
    
  }
  
  // Henter og anvender standardindstillinger (Login ved opstart og standardradio).
  // Sikrer at UI (checkbox og popup) matcher gemte værdier.
  func getDefaultValues() {
    
    // here we get default value for LoadAtStartUp
    let foundHelper = NSWorkspace.shared.runningApplications.contains {
      $0.bundleIdentifier == K.helperBundleName
    }
    loadAtStartupCheckBox.state = foundHelper ? .on : .off
    
    loadRadiosIntoPopUpMenu(withItemSelected: Defaults.standardRadio)
  }
  
  
  // Fylder popup-menuen med alle radiokanaler og markerer den valgte.
  // Gør det nemt for brugeren at vælge en standardkanal.
  func loadRadiosIntoPopUpMenu(withItemSelected: String){
    //sets the previously selected default value in the popUp menu when loading window
    
    radioToPlayWhenStartingPopUp.removeAllItems()
    radioToPlayWhenStartingPopUp.addItem(withTitle: "-")
    for radio in workingRadios {
      radioToPlayWhenStartingPopUp.addItem(withTitle: radio.radioName)
    }
    radioToPlayWhenStartingPopUp.selectItem(withTitle: withItemSelected)
    
  }
  
  
  // Indlæser en foruddefineret kanalliste fra bundle efter brugerens bekræftelse.
  // Opdaterer arbejdslisten, markerer at der er ændringer og opdaterer UI.
  @IBAction func reloadDefaultRadioChannels(_ sender: NSButton) {
    let channelsName = sender.title
    let alert = NSAlert()
    alert.messageText = NSLocalizedString("Replace channel list?", comment: "")
    alert.informativeText = NSLocalizedString("This will replace your current channels with the preset \(channelsName). You can still cancel by not pressing Save.", comment: "")
    alert.addButton(withTitle: NSLocalizedString("Replace", comment: ""))
    alert.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))
    if alert.runModal() == .alertFirstButtonReturn {
        if let url = Bundle.main.url(forResource: channelsName, withExtension: "plist"),
           let data = try? Data(contentsOf: url),
           let radios = try? PropertyListDecoder().decode([MyRadio].self, from: data) {
            workingRadios = radios
            isRadioDataChanged = true
            tableView.reloadData()
            loadRadiosIntoPopUpMenu(withItemSelected: Defaults.standardRadio)
        }
    }
  }
  
  
  // Fjerner den valgte radiokanal fra arbejdslisten og tabellen.
  // Markerer at data er ændret, så brugeren kan gemme ændringerne.
  @IBAction func removeRowFromTableView(_ sender: NSButton) {
    let row = tableView.selectedRow
    guard row >= 0 && row < workingRadios.count else { return }
    workingRadios.remove(at: row)
    tableView.beginUpdates()
    tableView.removeRows(at: IndexSet(integer: row), withAnimation: .slideRight)
    tableView.endUpdates()
    isRadioDataChanged = true
  }
  
  // Tilføjer en tom radiokanal til arbejdslisten og indsætter en række i tabellen.
  // Markerer at data er ændret, så brugeren kan gemme ændringerne.
  @IBAction func addRowToTableView(_ sender: NSButton) {
    let newIndex = workingRadios.count
    workingRadios.append(MyRadio(radioName: "", radioURL: ""))
    tableView.beginUpdates()
    tableView.insertRows(at: IndexSet(integer: newIndex), withAnimation: .effectFade)
    tableView.endUpdates()
    isRadioDataChanged = true
  }
  
  // Opdaterer radiokanalens navn i arbejdslisten baseret på den redigerede celle.
  // Sikrer at ændringer i UI straks afspejles i modellen.
  @IBAction func onEditRadioName(_ sender: NSTextField) {
    let row = tableView.row(for: sender)
    if row >= 0 && row < workingRadios.count  {
        workingRadios[row].radioName = sender.stringValue
    } else if row == workingRadios.count {
        workingRadios.append(MyRadio(radioName: sender.stringValue, radioURL: ""))
        tableView.reloadData()
    }
    isRadioDataChanged = true
  }
  
  // Opdaterer radiokanalens URL i arbejdslisten baseret på den redigerede celle.
  // Sikrer at ændringer i UI straks afspejles i modellen.
  @IBAction func onEditRadioURL(_ sender: NSTextField) {
    let row = tableView.row(for: sender)
    if row >= 0 && row < workingRadios.count {
        workingRadios[row].radioURL = sender.stringValue
    } else if row == workingRadios.count {
        workingRadios.append(MyRadio(radioName: "", radioURL: sender.stringValue))
        tableView.reloadData()
    }
    isRadioDataChanged = true
  }
  
  // Viser en simpel 'Om' dialog til brugeren.
  // Informerer om appen uden at ændre tilstand.
  @IBAction func aboutClicked(_ sender: Any) {
    let dialog = NSAlert()
    dialog.messageText = K.aboutMessageText
    if (dialog.runModal() == NSApplication.ModalResponse.OK) { return }
  }
  
  
  // Gemmer den redigerede kanalliste og den valgte standardradio til persistent storage.
  // Informerer brugeren om at ændringerne nu er aktive.
  @IBAction func saveButtonClicked(_ sender: NSButton) {
    store.update(workingRadios)
    Defaults.standardRadio = radioToPlayWhenStartingPopUp.titleOfSelectedItem ?? "-"
    isRadioDataChanged = false

    let alert = NSAlert()
    alert.messageText = NSLocalizedString("Saved", comment: "")
    alert.informativeText = NSLocalizedString("Your changes are now active.", comment: "")
    alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))
    _ = alert.runModal()
  }
  
  // Aktiverer/deaktiverer helper-app som launch item afhængigt af checkbox.
  // Giver brugeren kontrol over automatisk opstart ved login.
  @IBAction func toggleLoadAtStartup(_ sender: NSButtonCell) {
    // sets .state on checkBox based on loginItems.x.plist (in launchd folder)
    let isLoadOnStartup = sender.state == .on
    SMLoginItemSetEnabled(K.helperBundleName as CFString, isLoadOnStartup)
  }
  
  
} // MARK: -  End Class PreferencesWindow


// MARK: - Delegates for TableView
extension PreferencesWindow {
  
  func numberOfRows(in tableView: NSTableView) -> Int {
    return workingRadios.count
  }
  
  // Returnerer en celle for en tabelrække og udfylder den med navn/URL fra arbejdslisten.
  // Binder data til UI, så tabellen viser de aktuelle værdier.
  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    guard row >= 0 && row < workingRadios.count,
          let cell = tableView.makeView(withIdentifier: (tableColumn!.identifier), owner: self) as? NSTableCellView else { return nil }

    if (tableColumn?.identifier)!.rawValue == K.nameCell {
      cell.textField?.stringValue = workingRadios[row].radioName
    } else if (tableColumn?.identifier)!.rawValue == K.addressCell {
      cell.textField?.stringValue = workingRadios[row].radioURL
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

