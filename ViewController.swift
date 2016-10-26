//
//  ViewController.swift
//  Which Restaurant?
//
//  Created by Adam Hodapp on 7/19/16.
//  Copyright © 2016 Adam Hodapp. All rights reserved.
//

import UIKit

class ViewController: UIViewController { 
    let main = Main()
    var child : SettingsViewController? {
        get{
            return self.childViewControllers.last as? SettingsViewController
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setToolbarHidden(false, animated: false)
        child!.mainInstance = main
        self.navigationController?.navigationBarHidden = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func add(sender: UIBarButtonItem) {
        let pvc = self.storyboard!.instantiateViewControllerWithIdentifier("PartyView") as! PartyViewController
        pvc.setMain(main)
        self.navigationController?.navigationBarHidden = false
        self.navigationController!.showViewController(pvc, sender: sender)
     //   pvc.updatePartyMembers()
    }
    @IBAction func search(sender: UIBarButtonItem) {
        NSLog("Search Pressed")
        let tableController = self.storyboard!.instantiateViewControllerWithIdentifier("PartyTable") as! PartyTableViewController
        tableController.mainInstance = main
        main.search(){
            if $0 != 0{
                let controller = UIAlertController()
                controller.title = "Error: No Connection"
                if $0 == 2{
                    controller.title = "Error: Please enable GPS"
                }
                controller.addAction(UIAlertAction(title: "OK", style: .Default){ _ in})
                self.presentViewController(controller, animated: true, completion: nil)
            }
            else if($1 != nil){
                tableController.setData($1!)
                dispatch_async(dispatch_get_main_queue()) { [unowned self] in
                      self.navigationController?.navigationBarHidden = false
                    self.navigationController!.showViewController(tableController, sender: sender)
                }

            }

        }
    }

}