//
//  PartyTableViewController.swift
//  Which Restaurant?
//
//  Created by Adam Hodapp on 7/20/16.
//  Copyright © 2016 Adam Hodapp. All rights reserved.
//

import UIKit

class PartyTableViewController: UITableViewController {
    var data : [Party] = [Party]()
    var mainInstance : Main!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: .Plain, target: self, action: #selector(PartyTableViewController.exit))
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        NSLog("Count: \(data.count)")
        return data.count
    }
    func setData(data : [Party]){
        NSLog("Data Set")
        self.data = data
        NSLog("\(self.data.count)")
    }
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell : UITableViewCell?
        if let cellAttempt = tableView.dequeueReusableCellWithIdentifier("party"){
            cell = cellAttempt
        }
        else{
            cell = UITableViewCell(style: UITableViewCellStyle.Value1 , reuseIdentifier: "party")
            cell!.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
        }
        NSLog("Count: \(data.count)")
        let party = data[indexPath.row]
        cell!.textLabel!.text = "\(party.name)'s Party"
        var str = "member"
        if party.numMembers > 0{
            str = "members"
        }
        cell!.detailTextLabel!.text = "\(party.numMembers) \(str)"

        return cell!
    }
 
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var inputTextField: UITextField?
        let passwordPrompt = UIAlertController(title: "Enter Password", message: "You must enter the password to join the party", preferredStyle: UIAlertControllerStyle.Alert)
        
        passwordPrompt.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler: nil))
        passwordPrompt.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            
            self.mainInstance.join(self.data[indexPath.row], password: inputTextField!.text!){
                if($0 == nil) {
                    return
                }
                dispatch_async(dispatch_get_main_queue()) { [unowned self] in

                    let pvc = self.storyboard!.instantiateViewControllerWithIdentifier("PartyView") as! PartyViewController
                    pvc.isOwner = false
                    pvc.mainInstance = self.mainInstance
                    self.navigationController?.showViewController(pvc, sender: tableView)
                }
            }
        }))
        passwordPrompt.addTextFieldWithConfigurationHandler({(textField: UITextField!) in
            textField.placeholder = "Password"
            textField.secureTextEntry = true
            inputTextField = textField
        })
        presentViewController(passwordPrompt, animated: true, completion: nil)
    }
    func exit(){
        NSLog("O")
        self.navigationController?.navigationBarHidden = true
        self.navigationController?.popViewControllerAnimated(true)
    }
    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
