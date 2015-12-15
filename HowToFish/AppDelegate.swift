//
//  AppDelegate.swift
//  HowToFish
//
//  Created by Kerr, James on 11/19/15.
//  Copyright © 2015 Columbia Sportswear Company. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        configureParse()
        checkForLocalDatabase()
        checkForInternetConnection()
        
        //Set Apperance
        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.LightContent, animated: false)
        UINavigationBar.appearance().tintColor = UIColor.whiteColor()
        UINavigationBar.appearance().barTintColor = CSC_Colors.csc_blue //UIColor(colorLiteralRed: 0.0, green: 136.0/255.0, blue: 206.0/255.0, alpha: 1.0)
        UINavigationBar.appearance().barStyle = .Black
        UINavigationBar.appearance().translucent = false
        UINavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor(), NSFontAttributeName: UIFont(name: "GerTTv1.0-Bold", size: 20.0)!]
        
        return true
    }
    
    func printFonts() {
        let fontFamilyNames = UIFont.familyNames()
        for familyName in fontFamilyNames {
            print("------------------------------")
            print("Font Family Name = [\(familyName)]")
            let names = UIFont.fontNamesForFamilyName(familyName)
            print("Font Names = [\(names)]")
        }
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func configureParse() {
        // Enable storing and querying data from Local Datastore.
        // Remove this line if you don't want to use Local Datastore features or want to use cachePolicy.
        //Parse.enableLocalDatastore()
        
        // You must register Parse subclasses before calling setApplicationID
        registerParseSubclasses()
        
        // ****************************************************************************
        // Uncomment this line if you want to enable Crash Reporting
        // ParseCrashReporting.enable()
        //
        // Uncomment and fill in with your Parse credentials:
        Parse.setApplicationId("NcOyhHNA4cTHJvRMuXTr6CfOBfuJq4iOsDuxv5iB", clientKey: "wcl68iFFA3ajCf3gKZ1AXvD4Y3sZbKtqbKgd2M8c")
        //
        // If you are using Facebook, uncomment and add your FacebookAppID to your bundle's plist as
        // described here: https://developers.facebook.com/docs/getting-started/facebook-sdk-for-ios/
        // Uncomment the line inside ParseStartProject-Bridging-Header and the following line here:
        // PFFacebookUtils.initializeFacebook()
        // ****************************************************************************
        
        PFUser.enableAutomaticUser()
        
        let defaultACL = PFACL();
        
        // If you would like all objects to be private by default, remove this line.
        defaultACL.setPublicReadAccess(true)
        
        PFACL.setDefaultACL(defaultACL, withAccessForCurrentUser:true)
    }
    
    func registerParseSubclasses() {
        MediaObject.registerSubclass()
    }

    // MARK: - Database Setup -
    
    func checkForLocalDatabase() -> Void {
        
        let useBundledDatabase = true // for development only. set to true for production
        let defaults = NSUserDefaults.standardUserDefaults()
        let localData: Bool = defaults.boolForKey("localData")
        
        // If this is not first launch and the database exists then exit the method
        guard hasLauncedOnce() == false && localData == false else {
            return
        }
        
        // If this is first launch and we are using the bundled dB, then install it
        guard (hasLauncedOnce() == true && useBundledDatabase == false) else {
            installBundledDatabase()
            return
        }
        
        // If this is first launch and there is no local dB then build from Parse
        guard hasLauncedOnce() == true && localData == true else {
            installParseDatabase()
            return
        }
        
        print("Local database found")
        return
    }
    
    
    func installBundledDatabase() -> Bool {
        print("Installing Bundled Database")
        let fileManager = NSFileManager.defaultManager()
        if let bundledDatabasePath = NSBundle.mainBundle().pathForResource("default", ofType: "realm") {
            
            let docsDir = pathForDocumentDirectory()!
            let finalPath = docsDir + "/default.realm"
            
            do {
                try fileManager.copyItemAtPath(bundledDatabasePath, toPath: finalPath)
                
                NSUserDefaults.standardUserDefaults().setBool(true, forKey: "localData")
                NSUserDefaults.standardUserDefaults().synchronize()
                
            } catch let error as NSError {
                print("Error saving bundled database to documents directory: \(error)")
            }
            return true
        }
        print("Could not find path to documents directory")
        return false
    }
    
    
    func installParseDatabase() {
        print("Building local database")
        let mb = ModelBuilder.sharedInstance
        mb.buildLocalDatabase()
    }
    
    // MARK: - Helper methods -
    
    func hasLauncedOnce() -> Bool {
        if NSUserDefaults.standardUserDefaults().boolForKey("HasLaunchedOnce") {
            print("Has launched once")
            return true
        } else {
            // This is the first launch ever
            print("First launch")
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "HasLaunchedOnce")
            NSUserDefaults.standardUserDefaults().synchronize()
            return false
        }
    }
    
    func pathForDocumentDirectory() -> String? {
        let fileManager = NSFileManager.defaultManager()
        let urls = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        if let path = urls[0].path {
            return path
        }
        return nil
    }

    
    func getVersionAndBuild() -> String {
        let version = NSBundle.mainBundle().infoDictionary?["CFBundleShortVersionString"] as! String
        let build = NSBundle.mainBundle().infoDictionary?[kCFBundleVersionKey as String] as! String
        return "version: " + version + " build: " + build
    }
    
    func checkForInternetConnection() {
        guard Reachability.isConnectedToNetwork() else {
            print("No Internet Connection")
            return
        }
        print("Internet Connection OK")
    }
    
    
    }

