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
          
          
//            var path = Bundle.main.bundlePath as NSString
//            for _ in 1...4 {
//                path = path.deletingLastPathComponent as NSString
//            }
//            NSWorkspace.shared.launchApplication(path as String)
        }
    
    
  }

  func applicationWillTerminate(_ aNotification: Notification) {
    // Insert code here to tear down your application
  }

  func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }


}

/*
 https://stackoverflow.com/questions/27505022/open-another-mac-app
 
 guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Terminal") else { return }

 let path = "/bin"
 let configuration = NSWorkspace.OpenConfiguration()
 configuration.arguments = [path]
 NSWorkspace.shared.openApplication(at: url,
                                    configuration: configuration,
                                    completionHandler: nil)
 
 This is just one caveat, which might not affect too many: while launchApplication() accepted a path to an executable (e.g. "MyApp.app/Contents/MacOS/MyApp"), this will result in an error (lacking privileges) with openApplication(::). You have to supply the path to the app bundle ("MyApp.app") instead.
 
 
 
 
 */
