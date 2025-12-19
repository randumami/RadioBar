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

  // Returnerer sti til appens Application Support mappe.
  // Bruges som base for at gemme og læse radiolisten persistente filer.
  private var appSupportURL: URL {
    let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    return base.appendingPathComponent("net.systemit.RadioBar", isDirectory: true)
  }

  // Sti til den persistente radioliste (radios.plist) i appens supportmappe.
  // Centraliserer placeringen for nem adgang flere steder i koden.
  private var radioURL: URL {
    return appSupportURL.appendingPathComponent("radios.plist")
  }

  // Legacy-sti for radiolisten fra tidligere versioner (uden undermappe).
  // Bruges til migration så eksisterende brugere bevarer deres kanaler.
  private var legacyRadioURL: URL {
    let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    return base.appendingPathComponent("radios.plist")
  }

  // Sørger for at Application Support mappen eksisterer (opretter hvis nødvendigt).
  // Forhindrer fejl ved læsning/skrivning af filer senere.
  private func ensureAppSupportDirectory() throws {
    try FileManager.default.createDirectory(at: appSupportURL, withIntermediateDirectories: true)
  }

  // Migrerer radiolisten fra legacy-placering hvis ny fil ikke findes, men gammel gør.
  // Giver en gnidningsfri opgradering uden at miste brugerdata.
  private func migrateLegacyIfNeeded() {
    // If new file doesn't exist but legacy does, move it
    let fm = FileManager.default
    if !fm.fileExists(atPath: radioURL.path), fm.fileExists(atPath: legacyRadioURL.path) {
      do {
        try ensureAppSupportDirectory()
        try fm.moveItem(at: legacyRadioURL, to: radioURL)
      } catch {
        // If migration fails, we ignore and let normal load fall back
      }
    }
  }

  // Læser radiolisten fra disk og returnerer den, eller en fallback ved fejl.
  // Sikrer at appen altid har en gyldig liste at vise/arbejde med.
  func loadRadios() -> [MyRadio] {
    do {
      try ensureAppSupportDirectory()
      migrateLegacyIfNeeded()
      let data = try Data(contentsOf: radioURL)
      return try PropertyListDecoder().decode([MyRadio].self, from: data)
    } catch {
      return [MyRadio(radioName: "No Radios", radioURL: "")]
    }
  }

  // Skriver den givne radioliste til disk atomisk.
  // Bevarer brugerens ændringer og minimerer risiko for korruption.
  func write(myRadios: [MyRadio]) {
    do {
      try ensureAppSupportDirectory()
      let data = try PropertyListEncoder().encode(myRadios)
      try data.write(to: radioURL, options: .atomic)
    } catch {
      // Optionally log error
    }
  }

  // Kopierer en default radioliste fra bundle ved første kørsel (hvis ingen fil findes).
  // Giver nye brugere en fornuftig startkonfiguration.
  func copyRadiosFromBundle() {
    guard let url = Bundle.main.url(forResource: "DR", withExtension: "plist") else { return }
    do {
      try ensureAppSupportDirectory()
      let fm = FileManager.default
      if !fm.fileExists(atPath: radioURL.path) {
        let data = try Data(contentsOf: url)
        try data.write(to: radioURL, options: .atomic)
      }
    } catch {
      // Optionally log error
    }
  }

  // Overskriver radiolisten med en foruddefineret liste fra bundle.
  // Bruges når brugeren ønsker at erstatte nuværende kanaler med et preset.
  func installRadiosFromBundle(channelsToReload: String) {
    guard let url = Bundle.main.url(forResource: channelsToReload, withExtension: "plist") else { return }
    do {
      try ensureAppSupportDirectory()
      let data = try Data(contentsOf: url)
      try data.write(to: radioURL, options: .atomic)
    } catch {
      // Optionally log error
    }
  }
}

