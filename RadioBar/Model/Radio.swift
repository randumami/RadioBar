//
//  Radio.swift
//  RadioBar
//
//  Created by Soren Randum on 24/12/2021.
//  Copyright © 2021 Søren Randum. All rights reserved.

// based on SwiftyRadio by Eric Conner

import AVFoundation
import AppKit

open class Radio: NSObject {

  private var Player: AVPlayer?
  private var PlayerItem: AVPlayerItem!
  private var station: Station!

  private struct Station {
    var name: String = ""
    var URL: String = ""
    var description: String = ""
    var artwork: NSImage?
    var isPlaying: Bool = false
  }


  open func setup() {
    station = Station()
  }

  open func setStation(nameOfStation: String, URLOfStation: String, description: String = "", radioLogo: NSImage = NSImage()) {
    station = Station(name: nameOfStation, URL: URLOfStation, description: description, artwork: radioLogo)
    sendUserNotification()
    NotificationCenter.default.post(name: Notification.Name(rawValue: "RadioMetadataUpdated"), object: nil)
  }


  open func getDescription() -> String {
    return station.description
  }


  open func getRadioName() -> String {
    return station.name
  }

// TODO: - GetRadioArt not implemented yet!
  open func GetRadioArt() -> NSImage {
    return station.artwork!
  }


  open func isPlaying() -> Bool {
    return station.isPlaying
  }

  open func play() {
    guard station.URL != ""  else { return } //  Station has not been setup
    guard !isPlaying()       else { return} //  Station is already playing
     
        PlayerItem = AVPlayerItem(url: URL(string: station.URL)!)
        PlayerItem.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.new, context: nil)

        Player = AVPlayer(playerItem: PlayerItem)
        Player?.play()

        station.isPlaying = true
        NotificationCenter.default.post(name: Notification.Name(rawValue: "RadioPlayWasPressed"), object: nil)
  }

  open func stop() {
    guard isPlaying() else { return} // Station is already stopped
      Player?.pause()
      PlayerItem.removeObserver(self, forKeyPath: "status")
      Player = nil
      station.isPlaying = false
      station.name = ""
      station.description = ""
      station.artwork = nil
      NotificationCenter.default.post(name: Notification.Name(rawValue: "RadioStopWasPressed"), object: nil)
  }

  open func togglePlayStop() {
    if isPlaying() {
      stop()
    } else {
      play()
    }
  }

  
  open func customMetadata(_ title: String, artist: String = "") {
    station.description = title
    station.name = artist

    sendUserNotification()
    NotificationCenter.default.post(name: Notification.Name(rawValue: "RadioMetadataUpdated"), object: nil)
  }

  private func sendUserNotification() {
 
    let userNotification = NSUserNotification()
      userNotification.title = station.name
      userNotification.subtitle = station.description
      userNotification.identifier = "net.systemit.RadioBar"
      if(station.artwork != nil) {
        let image = station.artwork
        userNotification.contentImage = image
      }
      NSUserNotificationCenter.default.removeAllDeliveredNotifications()
      NSUserNotificationCenter.default.deliver(userNotification)
  }

  open func updateStationArtwork(_ image: NSImage) {
    station.artwork = image
    sendUserNotification()
  }

  override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
    /// Called when the player item status changes
    if keyPath == "status" {
      if PlayerItem.status == AVPlayerItem.Status.failed {
        stop()
        customMetadata("\(station.name) station is offline", artist: "")
        NotificationCenter.default.post(name: Notification.Name(rawValue: "RadioStationOffline"), object: nil)
      }
    }

  }
}
