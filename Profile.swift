//
//  Profile.swift
//  Which Restaurant?
//
//  Created by Adam Hodapp on 7/20/16.
//  Copyright © 2016 Adam Hodapp. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class Profile : AnyObject{
    var name : String?
    var didInitializeProperly = true
    var preferences = [String : Int]()
    
    static let preferenceTypes = ["fastFood", "fastCasual", "casualDining", "fineDining", "chinese", "italian", "indian", "japanese", "bbq", "pizza", "price"]
    init(dict : [String : NSObject]){
        if let name = dict["name"] as? String{
            self.name = name
        }
        else{
            didInitializeProperly = false
            self.name = nil
        }
        if let preferences = dict["preferences"]{
            self.preferences = preferences as! [String : Int]
        }
        else{
            for type in Profile.preferenceTypes {
                preferences[type] = 0
            }
        }
        
    }
    //Attempts to load profile, if this doens't work, then it does default name
    init(){
        let defaults = NSUserDefaults()
        name = defaults.valueForKey("name") as? String
        if let preferences = defaults.valueForKey("preferences") as? [String : Int]{
            self.preferences = preferences
        }
        else{
            didInitializeProperly = false
        }
        if name == nil{
            didInitializeProperly = false
        }
        if !didInitializeProperly{
            let name = UIDevice.currentDevice().name
            
            if name.characters.count > 9 {
                let index = name.characters.count - 9
                let range = Range<String.Index>(name.startIndex.advancedBy(index) ..<  name.startIndex.advancedBy(name.characters.count))
                if name.substringWithRange(range) == "'s iPhone"{
                    self.name = name.substringWithRange(Range<String.Index>(name.startIndex ..< name.startIndex.advancedBy(index)))
                }
                else if name == "iPhone Simulator"{
                    self.name = "Simulator"
                }
                else{
                    self.name = "Name"
                }
            }
        }
    }

    func setPreferences(preferences : [String:Int]){
        self.preferences = preferences
    }
    func getDictionary() -> [String : NSObject]{
        var dict = [String : NSObject]()
        dict["name"] = name!
        dict["preferences"] = preferences as [NSString : NSObject]
        return dict
    }
    //Saves the profile to CoreData so that it can be reloaded and teh user does not have to re-enter the data.
    func saveProfile(){
//        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
//        let managedContext = appDelegate.managedObjectContext
//        let entity =  NSEntityDescription.entityForName("UserPreferences", inManagedObjectContext:managedContext)
//        let preferences = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: managedContext)
//        for type in Profile.preferenceTypes {
//            preferences.setValue(self.preferences[type], forKey: type)
//        }
//        do {
//            try managedContext.save()
//        } catch let error as NSError  {
//            print("Could not save \(error), \(error.userInfo)")
//        }
        let defaults = NSUserDefaults()
        defaults.setObject(preferences, forKey: "preferences")
        defaults.setObject(name, forKey: "name")
    }
    
}
