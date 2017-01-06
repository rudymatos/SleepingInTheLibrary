//
//  ViewController.swift
//  SleepingInTheLibrary
//
//  Created by Jarrod Parkes on 11/3/15.
//  Copyright © 2015 Udacity. All rights reserved.
//

import UIKit

// MARK: - ViewController: UIViewController

class ViewController: UIViewController {
    
    // MARK: Outlets
    
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var photoTitleLabel: UILabel!
    @IBOutlet weak var grabImageButton: UIButton!
    
    // MARK: Actions
    
    @IBAction func grabNewImage(_ sender: AnyObject) {
        setUIEnabled(false)
        getImageFromFlickr()
        
    }
    
    // MARK: Configure UI
    
    private func setUIEnabled(_ enabled: Bool) {
        photoTitleLabel.isEnabled = enabled
        grabImageButton.isEnabled = enabled
        
        if enabled {
            grabImageButton.alpha = 1.0
        } else {
            grabImageButton.alpha = 0.5
        }
    }
    
    // MARK: Make Network Request
    
    private func getImageFromFlickr() {
        let methodParameters = [
            Constants.FlickrParameterKeys.Method: Constants.FlickrParameterValues.GalleryPhotosMethod,
            Constants.FlickrParameterKeys.APIKey: Constants.FlickrParameterValues.APIKey,
            Constants.FlickrParameterKeys.GalleryID: Constants.FlickrParameterValues.GalleryID,
            Constants.FlickrParameterKeys.Extras: Constants.FlickrParameterValues.MediumURL,
            Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat,
            Constants.FlickrParameterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback
        ]
        
        let urlString = Constants.Flickr.APIBaseURL + escapedParameter(parameters: methodParameters)
        print(urlString)
        let url = URL(string: urlString)
        let request = URLRequest(url: url!)
        
        DispatchQueue.global().async {
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                func displayError(_ error: String) {
                    print(error)
                    print("URL at time of error: \(url)")
                    performUIUpdatesOnMain {
                        self.setUIEnabled(true)
                    }
                }
                guard( error == nil) else{
                    displayError("There was an error with the request \(error)")
                    return
                }
                
                guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else{
                    displayError("Your request status is other than 2xx!")
                    return
                }
                
                guard let  data = data else{
                    displayError("No data return from the request")
                    return
                }
                
                let parsedResult: [String:AnyObject]!
                do{
                    parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:AnyObject]
                    guard let flickrRequestStatus = parsedResult[Constants.FlickrResponseKeys.Status], flickrRequestStatus as? String == Constants.FlickrResponseValues.OKStatus else{
                        displayError("Invalid status from FLICKR API")
                        return
                    }
                    
                    if let photosDictionary = parsedResult[Constants.FlickrResponseKeys.Photos] as? [String: AnyObject], let photoArray = photosDictionary[Constants.FlickrResponseKeys.Photo] as? [[String:AnyObject]]{
                        let randomIndex = Int(arc4random_uniform(UInt32(photoArray.count)))
                        let randomRecord = photoArray[randomIndex]
                        let title = "\(randomRecord[Constants.FlickrResponseKeys.Title]!)"
                        if let mURL = URL(string: "\(randomRecord[Constants.FlickrResponseKeys.MediumURL]!)"){
                            print("getting : \(mURL)")
                            
                            if let imageData = NSData(contentsOf: mURL) , let image = UIImage(data: imageData as Data){
                                DispatchQueue.main.async {
                                    self.photoTitleLabel.text = title
                                    self.photoImageView.image = image
                                    self.setUIEnabled(true)
                                }
                            }
                        }else{
                            DispatchQueue.main.async {
                                self.photoTitleLabel.text = "Error getting images"
                                self.setUIEnabled(true)
                            }
                        }
                        
                    }else{
                        DispatchQueue.main.async {
                            self.photoTitleLabel.text = "Error getting images"
                            self.setUIEnabled(true)
                        }
                    }
                }catch{
                    displayError("Could not use JSON data : \(data)")
                    return
                }
                
                
            }
            task.resume()
        }
    }
    
    private func escapedParameter(parameters: [String: String] )-> String{
        
        if parameters.isEmpty{
            return ""
        }else{
            var keyValuePairs = [String]()
            for(key, value) in parameters{
                let stringValue = "\(value)"
                if let escapedValue = stringValue.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed){
                    keyValuePairs.append(key + "=" + "\(escapedValue)")
                }
            }
            return "?\(keyValuePairs.joined(separator: "&"))"
        }
    }
    
}
