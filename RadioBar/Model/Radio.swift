//
//  Radio.swift
//  RadioBar
//
//  Created by Soren Randum on 24/12/2021.
//  Copyright © 2021 Søren Randum. All rights reserved.

// based on SwiftyRadio by Eric Conner

import AVFoundation
import AppKit
import UserNotifications

open class Radio: NSObject, AVPlayerItemMetadataOutputPushDelegate {
  
  private var Player: AVPlayer?
  private var PlayerItem: AVPlayerItem!
  private var station: Station!
  private var statusObservation: NSKeyValueObservation?
  private var metadataOutput: AVPlayerItemMetadataOutput?
  
  private struct Station {
    var stationName: String = ""
    var URL: String = ""
    var description: String = ""
    var artwork: NSImage?
    var isPlaying: Bool = false
  }
  
  
  open func setup() {
    station = Station()
  }
  
  // Sætter den aktuelle station (navn, URL, beskrivelse og logo).
  // Poster en notifikation så UI kan opdatere Now Playing, og sender også en brugernotifikation for at informere brugeren.
  open func setStation(nameOfStation: String, URLOfStation: String, description: String = "", radioLogo: NSImage = NSImage()) {
    station = Station(stationName: nameOfStation, URL: URLOfStation, description: description, artwork: radioLogo)
    sendUserNotification()
    NotificationCenter.default.post(name: .nowPlayingDidUpdate, object: nil, userInfo: ["title": station.description, "artist": station.stationName])
  }
  
  
  open func getDescription() -> String {
    return station.description
  }
  
  
  open func getRadioName() -> String {
    return station.stationName
  }
  
  // TODO: - GetRadioArt not implemented yet!
  open func GetRadioArt() -> NSImage {
    return station.artwork ?? NSImage()
  }
  
  
  open func isPlaying() -> Bool {
    return station.isPlaying
  }
  
  // Starter afspilning af den valgte station ved at oprette en AVPlayerItem og AVPlayer.
  // Observerer status og metadata for at kunne reagere på fejl og opdatere titel/kunstner (Now Playing).
  open func play() {
    guard station.URL != ""  else { return } //  Station has not been setup
    guard !isPlaying() else { return}        //  Station is already playing
    
    guard let url = URL(string: station.URL) else { return }
    PlayerItem = AVPlayerItem(url: url)
    
    // Observe HLS/ICY timed metadata via AVPlayerItemMetadataOutput
    let output = AVPlayerItemMetadataOutput(identifiers: nil)
    output.setDelegate(self, queue: .main)
    PlayerItem.add(output)
    self.metadataOutput = output

    statusObservation = PlayerItem.observe(\.status, options: [.new]) { [weak self] item, _ in
      guard let self = self else { return }
      if item.status == .failed {
        self.stop()
        self.customMetadata("\(self.station.stationName) station is offline", artist: "")
      }
    }
    
    Player = AVPlayer(playerItem: PlayerItem)
    Player?.play()
    
    station.isPlaying = true
  }
  
  // Stopper afspilningen, rydder observers/outputs og nulstiller stationstilstand og metadata.
  // Poster en Now Playing-notifikation med tom titel/kunstner for at rydde UI-tilstand.
  open func stop() {
    guard isPlaying() else { return} // Station is already stopped
    Player?.pause()
    if let output = metadataOutput {
      PlayerItem?.remove(output)
    }
    metadataOutput = nil
    statusObservation = nil
    Player = nil
    station.isPlaying = false
    station.stationName = ""
    station.description = ""
    station.artwork = nil
    NotificationCenter.default.post(name: .nowPlayingDidUpdate, object: nil, userInfo: ["title": "", "artist": ""])
  }
  
  // Skifter mellem at afspille og stoppe afhængigt af nuværende tilstand.
  // Giver en enkel kontrol fra UI uden at kende den aktuelle afspilningsstatus.
  open func togglePlayStop() {
    if isPlaying() {
      stop()
    } else {
      play()
    }
  }
  
  
  // Opdaterer lokal metadata (titel/kunstner) for den nuværende stream.
  // Sender brugernotifikation og poster Now Playing, så menulinje/tooltip m.m. opdateres.
  open func customMetadata(_ title: String, artist: String = "") {
    station.description = title
    station.stationName = artist
    
    sendUserNotification()
    NotificationCenter.default.post(name: .nowPlayingDidUpdate, object: nil, userInfo: ["title": title, "artist": artist])
  }
  
  // Parser metadata-elementer (ID3/ICY) for at udlede titel og kunstner.
  // Falder tilbage til StreamTitle-formatet og opdaterer kun, hvis vi finder relevante værdier.
  private func handleMetadataItems(_ items: [AVMetadataItem]?) {
    guard let items = items, !items.isEmpty else { return }

    var title: String = ""
    var artist: String = ""

    // Try common keys first (title/artist)
    for item in items {
      if let key = item.commonKey?.rawValue.lowercased() {
        if key == "title", let value = item.value as? String, !value.isEmpty {
          title = value
        } else if key == "artist", let value = item.value as? String, !value.isEmpty {
          artist = value
        }
      }
    }

    // If still empty, try ICY StreamTitle inside extra attributes or value
    if title.isEmpty && artist.isEmpty {
      for item in items {
        if let keySpace = item.keySpace?.rawValue.lowercased(),
           (keySpace.contains("icy") || keySpace.contains("id3")) {
          if let stringValue = item.stringValue, !stringValue.isEmpty {
            // Typical format: "Artist - Title"
            let parts = stringValue.components(separatedBy: " - ")
            if parts.count >= 2 {
              artist = parts[0]
              title = parts[1...].joined(separator: " - ")
            } else {
              title = stringValue
            }
          }
          if let extra = item.extraAttributes, let streamTitleAny = extra[.info], let streamTitle = streamTitleAny as? String, !streamTitle.isEmpty {
            let parts = streamTitle.components(separatedBy: " - ")
            if parts.count >= 2 {
              artist = parts[0]
              title = parts[1...].joined(separator: " - ")
            } else {
              title = streamTitle
            }
          }
        }
      }
    }

    // Update if we have at least one piece of info
    if !title.isEmpty || !artist.isEmpty {
      self.customMetadata(title, artist: artist)
    }
  }
  
  // Modtager tidsbestemt metadata fra afspilleren og videresender til parseren.
  // Sikrer at nye titel/kunstner-oplysninger løbende afspejles i appens tilstand.
  public func metadataOutput(_ output: AVPlayerItemMetadataOutput,
                             didOutputTimedMetadataGroups groups: [AVTimedMetadataGroup],
                             from track: AVPlayerItemTrack?) {
    for group in groups {
      handleMetadataItems(group.items)
    }
  }
  
  // Beder om tilladelse (hvis nødvendigt) og leverer en lokal notifikation med nuværende station og titel.
  // Hjælper brugeren med at se hvad der afspilles, også uden for appen.
  private func sendUserNotification() {
    requestNotificationAuthIfNeeded()
    let content = UNMutableNotificationContent()
    content.title = station.stationName
    content.subtitle = station.description
    let request = UNNotificationRequest(identifier: "net.systemit.RadioBar.nowPlaying", content: content, trigger: nil)
    UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
  }
  
  private func requestNotificationAuthIfNeeded() {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
  }
  
  // Opdaterer artwork for den nuværende station.
  // Sender en brugernotifikation så ændringen er synlig for brugeren.
  open func updateStationArtwork(_ image: NSImage) {
    station.artwork = image
    sendUserNotification()
  }
  
}
