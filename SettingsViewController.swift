//
//  SettingsViewController.swift
//  WhichRest
//
//  Created by Adam Hodapp on 7/26/16.
//  Copyright © 2016 Adam Hodapp. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {

    @IBOutlet weak var fastFood: UISegmentedControl!
    @IBOutlet weak var fastCasual: UISegmentedControl!
    @IBOutlet weak var casualDining: UISegmentedControl!
    @IBOutlet weak var fineDining: UISegmentedControl!
    @IBOutlet weak var chinese: UISegmentedControl!
    @IBOutlet weak var italian: UISegmentedControl!
    @IBOutlet weak var indian: UISegmentedControl!
    @IBOutlet weak var japanese: UISegmentedControl!
    @IBOutlet weak var bbq: UISegmentedControl!
    @IBOutlet weak var pizza: UISegmentedControl!
    @IBOutlet weak var price: UISegmentedControl!
    @IBOutlet weak var name: UITextField!
    var segmentedControls = [String : UISegmentedControl]()
    private var _mainInstance : Main? = nil
    var mainInstance : Main?{
        get{
            return _mainInstance
        }
        set(main){
            _mainInstance = main
            for (id, segmentedControl) in segmentedControls{
                let n = mainInstance!.userProfile!.preferences[id]! - 1
                if n == -1{
                    segmentedControl.selectedSegmentIndex = segmentedControl.numberOfSegments - 1
                }
                else{
                    segmentedControl.selectedSegmentIndex = n
                }
            }
            self.name.text = mainInstance!.userProfile!.name!
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        segmentedControls["fastFood"] = fastFood
        segmentedControls["fastCasual"] = fastCasual
        segmentedControls["casualDining"] = casualDining
        segmentedControls["fineDining"] = fineDining
        segmentedControls["chinese"] = chinese
        segmentedControls["italian"] = italian
        segmentedControls["indian"] = indian
        segmentedControls["japanese"] = japanese
        segmentedControls["bbq"] = bbq
        segmentedControls["pizza"] = pizza
        segmentedControls["price"] = price
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func saveButtonPressed(sender: NSObject) {
        var preferences = [String : Int]()
        for str in Profile.preferenceTypes{
            preferences[str] = segmentedControls[str]!.selectedSegmentIndex + 1
        }
        for (str, n) in preferences{
            if str != "price"{
                if n == 6{
                    preferences[str] = 0
                }
            }
            else{
                if n == 5{
                    preferences[str] = 0
                }
            }
        }
        if let main = mainInstance{
            main.userProfile!.setPreferences(preferences)
            main.userProfile!.name = name.text
            main.userProfile!.saveProfile()
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

}
