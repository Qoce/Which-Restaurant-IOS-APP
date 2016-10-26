//
//  Party.swift
//  Which Restaurant?
//
//  Created by Adam Hodapp on 7/20/16.
//  Copyright © 2016 Adam Hodapp. All rights reserved.
//

import Foundation
import CoreLocation

class Party : AnyObject{
    let name : String
    let password : String
    let location : CLLocationCoordinate2D
    var members : [Profile]
    var numMembers : Int
    var resultIDs = [[String : NSObject]]()
    
    init(dict : [String: NSObject], storeMembers : Bool){
        name = dict["name"] as! String
        password = dict["password"] as! String
        let latitude = dict["latitude"] as! Double
        let longitude = dict["longitude"] as! Double
        self.location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let members = dict["members"] as! [[String: NSObject]]
        self.members = [Profile]()
        if let resultIDs = dict["resultIDs"] as? [[String : NSObject]]{
            self.resultIDs = resultIDs
            NSLog("Yup")
        }
        if storeMembers{
            for profile in members{
                let profile = Profile(dict: profile)
                if(profile.didInitializeProperly){
                    self.members.append(profile)
                }
            }
        }
        numMembers = (dict["members"] as! [[String: NSObject]]).count
    }
    init(name : String, password : String, location : CLLocationCoordinate2D, members : [Profile]){
        self.name = name
        self.password = password
        self.location = location
        self.members = members
        self.numMembers = members.count
    }
    func getDictionary() -> [String : NSObject]{
        var dict = [String : NSObject]()
        dict["name"] = name
        dict["password"] = password
        dict["latitude"] = location.latitude
        dict["longitude"] = location.longitude
        var membersAsDicts = [[String : NSObject]]()
        for m in members{
            membersAsDicts.append(m.getDictionary())
        }
        dict["members"] = membersAsDicts
        dict["results"] = resultIDs
        return dict
    }
    func searchForRestaurant(main : Main, radius: Double, onCompletion : ([Result]) -> Void){
        var averagePreferences = [String: (Double, Double)]()
        
        for preference in Profile.preferenceTypes{
            var pValue = 0.0
            var numOpMembers = 0.0
            for user in self.members{
                pValue += Double(user.preferences[preference]!)
                if user.preferences[preference]! != 0{
                    numOpMembers += 1
                }
            }
            if numOpMembers == 0{
                averagePreferences[preference] = (0,0)
            }
            else{
                averagePreferences[preference] = (pValue / Double(numOpMembers), Double(numOpMembers) / Double(self.numMembers))
            }
        }
        var priceRange = Int(floor(averagePreferences["price"]!.0))...Int(floor(averagePreferences["price"]!.0) + 1)
        if priceRange == 4...5{
            priceRange = 3...4
        }
        else if averagePreferences["price"]!.1 == 0{
            priceRange = 1...4
        }
        let formalities = Profile.preferenceTypes[0...3] //The four types of formalities for a restaurant
        let types = Profile.preferenceTypes[4..<Profile.preferenceTypes.count - 1]
        var bestFormality : String = ""//Formality to be put in the search text
        var bestRating = (0.0, 0.01)
        var priceCounter = 1
        var keywords = [String]()
        for str in formalities{
            let average = averagePreferences[str]!
            let priceBonus = priceRange ~= priceCounter ? 0.0 : 1.0
            let rw = average.0 + log2(average.1 / bestRating.1) + priceBonus
            if rw > bestRating.0{
                bestRating = average
                bestFormality = self.convertPreferenceType(str)
            }
            priceCounter += 1
        }
        keywords.append(bestFormality)
        var topTypes = ("", "")
        var topRatings = ((0.0, 0.01), (0.0, 0.01))
        
        for str in types{
            let average = averagePreferences[str]!
            let rw = average.0 + log2(average.1 / bestRating.1)
            if rw > topRatings.0.1{
                if rw > topRatings.1.1{
                    topRatings.0 = topRatings.1
                    topRatings.1 = average
                    topTypes.0 = topTypes.1
                    topTypes.1 = self.convertPreferenceType(str)
                }
                else{
                    topRatings.0 = average
                    topTypes.0 = self.convertPreferenceType(str)
                }
            }
        }
        keywords.append(topTypes.0)
        keywords.append(topTypes.1)
        
        let radius = radius * 1609.34 //Converts miles to meters
        for str in keywords{
            do{
                let bodyStr = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=\(main.location!.coordinate.latitude),\(main.location!.coordinate.longitude)&minprice=\(priceRange.startIndex)&maxprice=\(priceRange.endIndex - 1)&opennow=true&radius=\(radius)&type=restaurant&keyword=\(str)"

                let str = "http://127.0.0.1:3000/i"
                var dict = [String: String]()
                dict["url"] = bodyStr
                let body = try NSJSONSerialization.dataWithJSONObject(dict, options: NSJSONWritingOptions.PrettyPrinted)
            
                main.makeUrlRequest(str, body: body, method: "POST"){
                    do{
                        let json = try NSJSONSerialization.JSONObjectWithData($0!, options: .AllowFragments)
                        NSLog("\(json)")
                        dispatch_async(dispatch_get_main_queue()){
                            self.addSearchResult(json as! [String : NSObject], toMax: 3, onMax: onCompletion)
                        }
                    }
                    catch{
                        NSLog("Response was inproperly JSON'D")
                    }
                }
            }
            catch{
                NSLog("Failed to create JSON object from party while creating maps request")
            }
        }
 
    }
    func convertPreferenceType(str : String) -> String{
        switch(str){
        case "fastFood":
            return "Fast_Food"
        case "fastCasual":
            return "Fast_Casual"
        case "casualDining":
            return "Casual_Dining"
        case "fineDining":
            return "Fine_Dining"
        case "bbq":
            return "Barbeque"
        default:
            return str
        }
    }
    private var searchResults = [Result]()
    private var numberOfSearches = 0
    func addSearchResult(result: [String : NSObject], toMax: Int, onMax : ([Result]) -> Void){
        let restaraunts = result["results"] as! [[String : NSObject]]
        for restaurant in restaraunts {
            var didFind = false
            for var result in searchResults{
                if result.rest["place_id"] == restaurant["place_id"]{
                    result.score = result.score + 1
                    didFind = true
                    break
                }
            }
            if !didFind{
                searchResults.append(Result(score: 1, rest: restaurant))
            }
        }
        numberOfSearches += 1
        if(numberOfSearches == toMax){
            numberOfSearches = 0
            onMax(searchResults)
            searchResults = [Result]()
        }
    }
}
struct Result{
    var score : Int!
    var rest : [String : NSObject]!
    var totalPriorityScore : Double!
    init(score : Int, rest : [String : NSObject]){
        self.score = score
        self.rest = rest
    }
    mutating func updateTotalPriorityScore(mainInstance: Main, maxDistance : Double) -> Void{
        var score : Double = Double(self.score)
        if let rating = rest["rating"] as? Double{
            score += rating
        }
        if let geometry = rest["geometry"] as? [String : NSObject]{
            if let location = geometry["location"] as? [String : NSObject]{
                if let lat = location["lat"] as? Double{
                    if let long = location["lng"] as? Double{
                        let location = CLLocation(latitude: lat, longitude: long)
                        let distance = location.distanceFromLocation(mainInstance.location!)
                        score += (maxDistance - distance) / maxDistance
                    }
                }
            }
        }
        totalPriorityScore = score
    }
}