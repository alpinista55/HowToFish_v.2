//
//  HttpDownloader.swift
//  HowToFish
//
//  Created by Kerr, James on 11/20/15.
//  Copyright © 2015 Columbia Sportswear Company. All rights reserved.
//

import Foundation

class HttpDownloader {
    
    var expectedContentLength = 0
    var buffer:NSMutableData = NSMutableData()
    var destinationUrl : NSURL?

    
    class func loadFileSync(url: NSURL, completion:(path:String, error:NSError!) -> Void) {
        let documentsUrl =  NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first as NSURL!
        let destinationUrl = documentsUrl.URLByAppendingPathComponent(url.lastPathComponent!)
        if NSFileManager().fileExistsAtPath(destinationUrl.path!) {
            print("file already exists [\(destinationUrl.path!)]")
            completion(path: destinationUrl.path!, error:nil)
        } else if let dataFromURL = NSData(contentsOfURL: url){
            if dataFromURL.writeToURL(destinationUrl, atomically: true) {
                print("file saved [\(destinationUrl.path!)]")
                completion(path: destinationUrl.path!, error:nil)
            } else {
                print("error saving file")
                let error = NSError(domain:"Error saving file", code:1001, userInfo:nil)
                completion(path: destinationUrl.path!, error:error)
            }
        } else {
            let error = NSError(domain:"Error downloading file", code:1002, userInfo:nil)
            completion(path: destinationUrl.path!, error:error)
        }
    }
    
    class func loadFileAsync(url: NSURL, sessionDelegate: NSURLSessionDelegate, completion:(path:String, error:NSError!) -> Void) {
        let documentsUrl =  NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first as NSURL!
        let destinationUrl = documentsUrl.URLByAppendingPathComponent(url.lastPathComponent!)
        if NSFileManager().fileExistsAtPath(destinationUrl.path!) {
            print("file already exists [\(destinationUrl.path!)]")
            completion(path: destinationUrl.path!, error:nil)
        } else {
            let sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
            let manqueue = NSOperationQueue.mainQueue()
            let session = NSURLSession(configuration: sessionConfig, delegate: sessionDelegate, delegateQueue: manqueue)
            let request = NSMutableURLRequest(URL: url)
            request.HTTPMethod = "GET"
            let task = session.dataTaskWithRequest(request, completionHandler: { (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
                if (error == nil) {
                    if let response = response as? NSHTTPURLResponse {
                        print("response=\(response)")
                        if response.statusCode == 200 {
                            if data!.writeToURL(destinationUrl, atomically: true) {
                                print("file saved [\(destinationUrl.path!)]")
                                completion(path: destinationUrl.path!, error:error)
                            } else {
                                print("error saving file")
                                let error = NSError(domain:"Error saving file", code:1001, userInfo:nil)
                                completion(path: destinationUrl.path!, error:error)
                            }
                        }
                    }
                }
                else {
                    print("Failure: \(error!.localizedDescription)");
                    completion(path: destinationUrl.path!, error:error)
                }
            })
            task.resume()
        }
    }
    
    class func loadFileAsyncWithDelegate(url: NSURL, sessionDelegate: NSURLSessionDelegate, completion:(destinationURL: NSURL, error: NSError!) -> Void) {
        let documentsUrl =  NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first as NSURL!
        if let destinationUrl = documentsUrl.URLByAppendingPathComponent(url.lastPathComponent!) as NSURL!{
            if NSFileManager().fileExistsAtPath(destinationUrl.path!) {
                print("file already exists [\(destinationUrl.path!)]")
                completion(destinationURL: destinationUrl, error:nil)
            } else {
                let sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
                //let manqueue = NSOperationQueue.mainQueue()
                let session = NSURLSession(configuration: sessionConfig, delegate: sessionDelegate, delegateQueue: nil)
                let request = NSMutableURLRequest(URL: url)
                request.HTTPMethod = "GET"
                let task = session.dataTaskWithRequest(request)
                task.resume()
            }
        }
    }

}