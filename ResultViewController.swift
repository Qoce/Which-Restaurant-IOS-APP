//
//  ResultViewController.swift
//  WhichRest
//
//  Created by Adam Hodapp on 8/8/16.
//  Copyright © 2016 Adam Hodapp. All rights reserved.
//

import UIKit
import MapKit
import GoogleMaps

class ResultViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var websiteLabel: UILabel!
    @IBOutlet weak var phoneNumberLabel: UILabel!
    @IBOutlet weak var imageLabel: UIImageView!
    @IBOutlet weak var previous: UIBarButtonItem!
    @IBOutlet weak var next: UIBarButtonItem!
    
    //Results, includes the location of each of hte reuslts for sending them to the mapView, and also the Identifiers of the results to allow it to make detailRequests
    private var _results : [(CLLocationCoordinate2D, String)]!
    var results : [(CLLocationCoordinate2D, String)]!{
        get{
            return _results
        }
        set(results){
            _results = results
            let client = GMSPlacesClient.sharedClient()
            for result in results{
                var firstPart : (CLLocationCoordinate2D, GMSPlace)?
                var secondPart : UIImage?
                client.lookUpPlaceID(result.1){ (place : GMSPlace?, error : NSError?) -> Void in
                    if place != nil{
                        if secondPart != nil{
                            self.data.append((result.0, place!, secondPart!))
                            if self.hasLoaded{
                                self.updateData(0)
                            }
                        }
                        else{
                            firstPart = (result.0, place!)
                        }
                    }
                    
                }
                self.loadFirstPhotoForPlace(result.1){
                    if firstPart != nil{
                        self.data.append((firstPart!.0, firstPart!.1, $0))
                        if self.hasLoaded{
                            self.updateData(0)
                        }
                    }
                    else{
                        secondPart = $0
                    }
                }
            }
        }
    }
    var mainInstance : Main!
    private var data = [(CLLocationCoordinate2D, GMSPlace, UIImage?)]()
    private var resultShown = 0
    private var hasLoaded = false
    override func viewDidLoad() {
        super.viewDidLoad()
        hasLoaded = true
        if data.count > 0 {
            updateData(0)
        }
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back to Prefences", style: .Plain, target: self, action: #selector(ResultViewController.exit))
        self.navigationController?.toolbarHidden = false
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func updateData(result : Int){
        resultShown = result
        self.titleLabel.text = data[result].1.name
        self.addressLabel.text = data[result].1.formattedAddress!
        if let website = data[result].1.website{
            self.websiteLabel.text = website.absoluteString
        }
        self.phoneNumberLabel.text = data[result].1.phoneNumber!
        self.previous.enabled = result != 0
        self.next.enabled = result != data.count - 1
        self.imageLabel.image = data[result].2

    }
    @IBAction func showDirections(sender: UIButton) {
        let mapView = self.storyboard!.instantiateViewControllerWithIdentifier("Map") as!   MapViewController
        mapView.mainInstance = self.mainInstance
        mapView.drawDirectionLine(mainInstance.location!, destination: CLLocation(latitude: data[resultShown].0.latitude, longitude: data[resultShown].0.longitude))
        mapView.addMarker(data[resultShown].1.name, withTitle: "Destination", withPosition: data[resultShown].0)
        self.navigationController!.showViewController(mapView, sender: sender)
    }
    @IBAction func showAllResults(sender: UIButton) {
        let mapView = self.storyboard!.instantiateViewControllerWithIdentifier("Map") as!   MapViewController
        mapView.mainInstance = self.mainInstance
        for (location, result, _) in data{
              mapView.addMarker(result.name, withPosition: location)
        }
        self.navigationController!.showViewController(mapView, sender: sender)
    }
    @IBAction func next(sender: UIBarButtonItem) {
        self.updateData(resultShown + 1)
    }
    @IBAction func previous(sender: UIBarButtonItem) {
        self.updateData(resultShown - 1)
    }
    func loadFirstPhotoForPlace(placeID: String, onCompletion : (UIImage?) -> Void) {
        GMSPlacesClient.sharedClient().lookUpPhotosForPlaceID(placeID) { (photos, error) -> Void in
            if let error = error {
                // TODO: handle the error.
                print("Error: \(error.description)")
            } else {
                if let firstPhoto = photos?.results.first {
                    self.loadImageForMetadata(firstPhoto){
                        onCompletion($0)
                    }
                }
            }
        }
    }
    
    func loadImageForMetadata(photoMetadata: GMSPlacePhotoMetadata, onCompletion : (UIImage?) -> Void){
        GMSPlacesClient.sharedClient().loadPlacePhoto(photoMetadata, constrainedToSize: self.imageLabel.bounds.size, scale: self.imageLabel.window!.screen.scale) { (photo, error) -> Void in
                if let error = error {
                    print("Error: \(error.description)")
                } else {
                    onCompletion(photo)
                    //self.attributionTextView.attributedText = photoMetadata.attributions;
                }
        }
    }
    /*
     * Exits all the way back to the root view controller.  The user will not be able to acces the informaiton
     * in this view again.  Might add a warning dialog in the future
     */
    func exit(){
        self.navigationController?.navigationBarHidden = true
        self.navigationController?.popToRootViewControllerAnimated(true)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

