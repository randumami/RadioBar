//
//  LaunchAppDelegate.swift
//  RadioBarLaunch
//
//  Created by Soren Randum on 25/01/2022.
//  Copyright © 2022 Søren Randum. All rights reserved.
//

import Cocoa
import os.log



@main
class LaunchAppDelegate: NSObject, NSApplicationDelegate {

  
  var logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "LaunchAppDelegate")


  // Kontrollerer om hovedappen allerede kører; hvis ikke, lokaliseres og åbnes hovedappen via bundle identifier.
  // Sikrer at login-helper starter hovedappen ved login uden at åbne flere instanser og logger for fejlsøgning.
  func applicationDidFinishLaunching(_ aNotification: Notification) {
 let mainAppIdentifier = "net.systemit.RadioBar"
    
    let runningApps = NSWorkspace.shared.runningApplications
        let isRunning = runningApps.contains {
            $0.bundleIdentifier == mainAppIdentifier
        }

    logger.notice("applicationDidFinishLaunching")
    
        if !isRunning {
          
          guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: mainAppIdentifier) else { return }
          logger.notice("url er: \(url)")
          let path = Bundle.main.bundlePath
          logger.notice("path er: \(path)")
          let configuration = NSWorkspace.OpenConfiguration()
          configuration.arguments = [path]
          NSWorkspace.shared.openApplication(at: url,
                                             configuration: configuration,
                                             completionHandler: nil)
          
          logger.notice("efter NSWorkspace.shared.openApplication er kørt")

        }
    
    
  }

  func applicationWillTerminate(_ aNotification: Notification) {
    // Insert code here to tear down your application
  }

  func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }


}

