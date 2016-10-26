//
//  PartyViewController.swift
//  Which Restaurant?
//
//  Created by Adam Hodapp on 7/21/16.
//  Copyright © 2016 Adam Hodapp. All rights reserved.
//

import UIKit
import MapKit
class PartyViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var pickerLabel: UILabel!
    @IBOutlet weak var picker: UIPickerView!
    @IBOutlet weak var passwordLabel: UILabel!
    @IBOutlet weak var passwordTextBox: UITextField!
    @IBOutlet weak var publicPartyLabel: UILabel!
    @IBOutlet weak var allowJoiningButton: UIButton!
    @IBOutlet weak var findARestaurantButton: UIButton!
    @IBOutlet weak var waitingForHostLabel: UILabel!
    var mainInstance : Main?
    var timer : NSTimer?
    private var password : String{
        get{
            if let str = passwordTextBox.text{
                if str.characters.count > 2{
                    return passwordTextBox.text!
                }
            }
            passwordTextBox.text = randomAlphaNumericString(4)
            return passwordTextBox.text!
        }
    }

    var isOwner : Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateSubtitle()
        publicPartyLabel.hidden = true
        findARestaurantButton.hidden = true
        if !isOwner{
            picker.hidden = true
            pickerLabel.hidden = true
            passwordLabel.hidden = true
            passwordTextBox.hidden = true
            publicPartyLabel.hidden = true
            allowJoiningButton.hidden = true
            findARestaurantButton.hidden = true
        }
        else {
            picker.hidden = false
            picker.dataSource = self
            picker.delegate = self
            waitingForHostLabel.hidden = true
            passwordLabel.hidden = false
            passwordTextBox.hidden = false
            publicPartyLabel.hidden = true
            allowJoiningButton.hidden = false
        }
        self.navigationController?.toolbarHidden = true
        if !isOwner{
            timer = NSTimer.scheduledTimerWithTimeInterval(10.0, target: self, selector: #selector(PartyViewController.refresh), userInfo: nil, repeats: true)
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Leave", style: .Plain, target: self, action: #selector(PartyViewController.leave))
        }
        else{
             self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .Plain, target: self, action: #selector(PartyViewController.cancel))
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    func updateSubtitle(){
        if let party = mainInstance!.party{
            self.titleLabel.text = "\(party.name)'s Party"
            self.subtitleLabel.text = "Party contains \(party.numMembers) member"
            if party.numMembers > 1{
                self.subtitleLabel.text!.append("s" as Character)
            }
        }
        else if let profile = mainInstance!.userProfile{
            self.titleLabel.text = "\(profile.name!)'s Party"
            self.subtitleLabel.text = "Party is private"
        }
    }
    @IBAction func allowJoining(sender: UIButton) {
        if mainInstance != nil {
            mainInstance!.createParty(password){ errorType in
                dispatch_async(dispatch_get_main_queue()) { [unowned self] in
                    if errorType != 0 {
                        let controller = UIAlertController()
                        controller.title = "Error: No Connection"
                        if errorType == 2{
                            controller.title = "Error: Location is needed"
                        }
                        controller.addAction(UIAlertAction(title: "OK", style: .Default){ _ in})
                        self.presentViewController(controller, animated: true, completion: nil)
                        return
                    }
                    self.updateSubtitle()
                    self.passwordTextBox.userInteractionEnabled = false
                    self.allowJoiningButton.hidden = true
                    self.publicPartyLabel.hidden = false
                    self.findARestaurantButton.hidden = false
                    self.findARestaurantButton.enabled = true
                    self.timer = NSTimer.scheduledTimerWithTimeInterval(10.0, target: self, selector: #selector(PartyViewController.refresh), userInfo: nil, repeats: true)
                     self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Leave", style: .Plain, target: self, action: #selector(PartyViewController.destroy))
                }
            }
        }
        else{
            NSLog("Error: Main instnace is nil")
        }
        
    }
    @IBAction func findARestaurant(sender: UIButton) {
        self.mainInstance!.refresh(mainInstance!.party!, isHost: true){
            if !$0 {
                let controller = UIAlertController()
                controller.title = "Error: No Connection"
                controller.addAction(UIAlertAction(title: "OK", style: .Default){ _ in})
                self.presentViewController(controller, animated: true, completion: nil)
            }
            self.mainInstance!.party!.searchForRestaurant(self.mainInstance!, radius: self.getSelectedDistance()){
                var numResults = 3
                if $0.count < numResults{
                    numResults = $0.count
                }
                var bestResult = [Result!]()
                var bestScore = [Double]()
                for _ in 0..<numResults{
                    bestScore.append(-100)
                    bestResult.append(nil)
                }
                for var result in $0 {
                    result.updateTotalPriorityScore(self.mainInstance!, maxDistance: self.getSelectedDistance() * 1609.34)
                    NSLog("Score: \(result.totalPriorityScore!)")
                    var i = 0
                    for score in bestScore{
                        if result.totalPriorityScore < score{
                            if i > 0{
                                bestScore.removeFirst()
                                bestScore.insert(result.totalPriorityScore, atIndex: i - 1)
                                if bestResult.count > 0{
                                    NSLog("Count: \(i) Length \(bestResult.count)")
                                    bestResult.removeFirst()
                                    bestResult.insert(result, atIndex: i - 1)
                                }
                                else{
                                    bestResult.append(result)
                                }
                            }
                            break
                        }
                        else{
                            if i == bestScore.count - 1{
                                bestScore.append(result.totalPriorityScore)
                                bestResult.append(result)
                                bestScore.removeFirst()
                                bestResult.removeFirst()
                                break
                            }
                        }
                        i += 1
                    }
                }
                let resultView = self.storyboard!.instantiateViewControllerWithIdentifier("ResultDetails") as! ResultViewController
                var results = [(CLLocationCoordinate2D, String)]()
                NSLog("Length: \(results.count)")
                for result in bestResult{
                    if let geo = result.rest["geometry"] as? [String : NSObject]{
                        if let location = geo["location"] as? [String : NSObject]{
                            results.append((CLLocationCoordinate2D(latitude: location["lat"] as! Double, longitude: location["lng"] as! Double), result.rest["place_id"] as! String))
                                                        NSLog("result: \(results[0])")
                        }
                    }
                }
                
                for (coord, placeID) in results{
                    self.mainInstance!.party!.resultIDs.append(["ID": placeID, "lat": coord.latitude, "lng": coord.longitude])
                }
                dispatch_async(dispatch_get_main_queue()) { [unowned self] in
                    resultView.mainInstance = self.mainInstance
                    resultView.results = results
                    self.navigationController!.showViewController(resultView, sender: sender)
                }
            }
        }
    }
    
    func randomAlphaNumericString(length: Int) -> String {
        
        let allowedChars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let allowedCharsCount = UInt32(allowedChars.characters.count)
        var randomString = ""
        
        for _ in (0..<length) {
            let randomNum = Int(arc4random_uniform(allowedCharsCount))
            let newCharacter = allowedChars[allowedChars.startIndex.advancedBy(randomNum)]
            randomString += String(newCharacter)
        }
        
        return randomString
    }
    func setMain(main : Main){
        self.mainInstance = main
    }
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int{
        if component == 0{
            return 15
        }
        else{
            return 3
        }
    }
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int{
        return 2
    }
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String?{
        if component == 1{
            switch row {
            case 0:
                return "Foot"
            case 1:
                return "Bike"
            case 2:
                return "Car"
            default:
                return "Other"
            }
        }
        else{
            switch(pickerView.selectedRowInComponent(1)){
            case 0:
                if(row != 4) {
                    return "\(0.2 * Double(row + 1)) miles"
                }
                return "1 mile"
            case 1:
                if(row != 1) {
                    return "\(0.5 * Double(row + 1)) miles"
                }
                return "1 mile"
            case 2:
                if(row != 0){
                    return "\(Double(row + 1)) miles"
                }
                return "1 mile"
            default:
                return "Unset"
            }
        }
    }
    // Returns the number of miles that is selected in the picker view
    func getSelectedDistance() -> Double{
        switch(picker.selectedRowInComponent(1)){
        case 0:
            return Double(picker.selectedRowInComponent(0) + 1) * 0.2
        case 1:
            return Double(picker.selectedRowInComponent(0) + 1) * 0.5
        case 2:
            return Double(picker.selectedRowInComponent(0) + 1) * 1.0
        default:
            return -1
        }
    }
    // Updates compoments of the picekr view if the method of tansportation is selected, this prevents the 
    // Distance values from being in consistant with eachother or with the method of tansportation
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int){
        if component == 1 {
            pickerView.reloadAllComponents()
        }
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    func searchForIdealPreferences(){
        self.mainInstance!.party!.searchForRestaurant(mainInstance!, radius: getSelectedDistance()){_ in
//            let mapController = self.storyboard!.instantiateViewControllerWithIdentifier("Map") as! MapViewController
//                mapController.mainInstance = self.mainInstance!
//            let dict = json as! [String : NSObject]
//            let results = dict["results"]! as! [[String : NSObject]]
//            self.navigationController!.showViewController(mapController, sender: sender)
//            for restaurant in results{
//                let geometry = restaurant["geometry"] as! [String : NSObject]
//                let location = geometry["location"] as! [String : NSObject]
//                mapController.addMarker(restaurant["name"] as! String, withPosition: CLLocationCoordinate2D(latitude: location["lat"] as! Double, longitude: location["lng"] as! Double))
//            }
        }
    }
    override func willMoveToParentViewController(parent: UIViewController?) {
        super.willMoveToParentViewController(parent)
        if parent == nil{
            self.navigationController?.toolbarHidden = false
            stopTimer()
        }
    }
    /*
    Refreshes the party and gains new information about the number of members, for users that are not the host, this refresh will also bring them to the results view once the host decides to activate the search fetaure
    */
    func refresh(){
        self.mainInstance!.refresh(self.mainInstance!.party!, isHost: isOwner){
            if !$0 {
                let controller = UIAlertController()
                controller.title = "Error: No Connection"
                controller.addAction(UIAlertAction(title: "OK", style: .Default){ _ in})
                self.presentViewController(controller, animated: true, completion: nil)
            }
            dispatch_async(dispatch_get_main_queue()) { [unowned self] in
                self.updateSubtitle()
                if !self.isOwner && self.mainInstance!.party!.resultIDs.count > 0{
                    let resultView = self.storyboard!.instantiateViewControllerWithIdentifier("ResultDetails") as! ResultViewController
                    let resultDicts = self.mainInstance!.party!.resultIDs
                    var results = [(CLLocationCoordinate2D, String)]()
                    for item in resultDicts{
                        results.append((CLLocationCoordinate2D(latitude: item["lat"] as! Double, longitude: item["lng"] as! Double), item["ID"] as! String))
                    }
                    resultView.mainInstance = self.mainInstance
                    resultView.results = results
                    self.stopTimer()
                    self.navigationController!.showViewController(resultView, sender: nil)
                }
            }
        }
    }
    /*
    Stops the timer, if it exists
    */
    func stopTimer(){
        if timer != nil{
            timer!.invalidate()
            timer = nil
        }
    }
    /*
    Called when the host is still creating the party and presses the back button. Pretty much does nothing.
    */
    func cancel(){
        self.navigationController?.navigationBarHidden = true
        self.navigationController?.popViewControllerAnimated(true)
    }
    /*
    Called when the client is in somone elses party, and makes them leave the party.
    */
    func leave(){
        self.mainInstance!.leave(self.mainInstance!.party!)
        self.navigationController?.popViewControllerAnimated(true)
    }
    /*
    Called when the host of the party has made the party public, and presses the leave button, destroys the party
    */
    func destroy(){
        self.mainInstance?.leave(self.mainInstance!.party!, destroy: true)
        self.navigationController?.navigationBarHidden = true
        self.navigationController?.popViewControllerAnimated(true)
    }
}