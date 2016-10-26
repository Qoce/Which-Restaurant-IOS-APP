//
//  Main.swift
//  Which Restaurant?
//
//  Created by Adam Hodapp on 7/20/16.
//  Copyright © 2016 Adam Hodapp. All rights reserved.
//
// Google Maps API Key
// AIzaSyCASJ2p0PSJIzl_Xq_sDsoYe9fKlGtcHRM
import Foundation
import CoreLocation

class Main : NSObject, CLLocationManagerDelegate{
    let locationManager = CLLocationManager()
    var userProfile : Profile?
    var party : Party?
   // static let key = "AIzaSyCASJ2p0PSJIzl_Xq_sDsoYe9fKlGtcHRM"
    
    var location : CLLocation?{
        get{
            return locationManager.location
        }
    }
    override init() {
        super.init()
        userProfile = Profile()
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func makeUrlRequest(str : String, body : NSData?, method: String, completion : (NSData?) -> Void){
        let url = NSURL(string:str)
        let request = NSMutableURLRequest(URL:url!)
        let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
        if(body != nil){
            request.HTTPBody = body!
            request.allHTTPHeaderFields!["Content-Type"] = "application/json"
        }
        request.HTTPMethod = method
        let dataTask = session.dataTaskWithRequest(request) {
            (data : NSData?, response : NSURLResponse?, error : NSError?) -> Void in
            completion(data)
            
        }
        dataTask.resume()
    }
    func search(onCompletion : (Int, [Party]?) -> Void) -> Void{
        var partyList : [Party] = [Party]()
        if(location != nil){
            makeUrlRequest("http://localhost:3000/g\(location!.coordinate.latitude)?\(self.location!.coordinate.longitude)", body: nil, method: "GET"){
                if($0 == nil){
                    onCompletion(1, nil)
                }
                else{
                    //let string = NSString(data: $0!, encoding: NSUTF8StringEncoding)
                    do{
                        let json = try NSJSONSerialization.JSONObjectWithData($0!, options: .AllowFragments)
                        if let parties = json["array"] as? [[String: NSObject]] {
                            NSLog("Parties Length: \(parties.count)")
                            for partyDict in parties{
                                let party = Party(dict: partyDict, storeMembers: false)
                                partyList.append(party)
                            }
                            onCompletion(0, partyList)
                        }
                    }
                    catch{
                        onCompletion(1, nil)
                    }
                }
            }
        }
        else{
            onCompletion(2, nil)
        }
    }
    func createParty(password : String, onCompletion: (Int) -> Void){
        if(location != nil){
            var profiles = [Profile]()
            do{
                profiles.append(userProfile!)
                let party = Party(name: "\(userProfile!.name!)",password : password, location: location!.coordinate, members: profiles)
                NSLog("Is valid JSON? \(NSJSONSerialization.isValidJSONObject(party.getDictionary()))")

                let body = try NSJSONSerialization.dataWithJSONObject(party.getDictionary(), options: NSJSONWritingOptions.PrettyPrinted)
                makeUrlRequest("http://localhost:3000/s", body: body, method: "POST"){
                    if let data = $0{
                        let string = NSString(data: data, encoding: NSUTF8StringEncoding)
                        if(string!.isEqualToString("success")){
                            NSLog("Connection Suceeded")
                        }
                        self.party = party
                        onCompletion(0)
                    }
                    else{
                        NSLog("Error, failed to connect to server")
                        onCompletion(1)
                        
                    }
                }
            }
            catch{
                NSLog("Error in party creation")
            }
        }
        else{
            NSLog("Failed to create party beacuse the location could not be obtained.")
            onCompletion(2)
        }
    }
    func join(p : Party, password: String, onCompletion: (Party?) -> Void){
        if(location != nil){
            do{
                let user = userProfile!.getDictionary()
                var object = [String: NSObject]()
                object["latitude"] = p.location.latitude
                object["longitude"] = p.location.longitude
                object["password"] = password
                object["partyName"] = p.name
                object["user"] = user
                let body = try NSJSONSerialization.dataWithJSONObject(object, options: NSJSONWritingOptions.PrettyPrinted)
                makeUrlRequest("http://localhost:3000/j", body: body, method: "POST"){
                    if $0 == nil {
                        NSLog("No Response from server join request")
                    }
                    else{
                        do{
                            let json = try NSJSONSerialization.JSONObjectWithData($0!, options: .AllowFragments)
                            self.party = Party(dict: json as! [String : NSObject], storeMembers: false)
                            onCompletion(self.party)
                            return
                        }
                        catch{
                            NSLog("Error parsing JSON when joining party")
                        }
                    }
                    onCompletion(nil)
                }
            }
            catch{
                NSLog("Error in joining party")
            }
        }
    }
    //Creates the basics needed to ID the party, its locaiton, name, and password
    func createPartyID(p : Party) -> [String : NSObject]{
        var object = [String: NSObject]()
        object["latitude"] = p.location.latitude
        object["longitude"] = p.location.longitude
        object["password"] = p.password
        object["partyName"] = p.name
        return object
    }
    func leave(p: Party, destroy : Bool = false){
        party = nil
        do{
            let user = userProfile!.getDictionary()
            var object = createPartyID(p)
            object["user"] = user
            let body = try NSJSONSerialization.dataWithJSONObject(object, options: .PrettyPrinted)
            let c : String
            if destroy{
                c = "d"
            }
            else {
                c = "l"
            }
            makeUrlRequest("http://localhost:3000/\(c)", body: body, method: "POST"){
                if $0 == nil {
                    NSLog("No Response from server leave request")
                }
            }
        }
        catch{
            NSLog("Error creating JSON Object for leave request")
        }
    }
    func refresh(p: Party, isHost: Bool, onCompletion: (didConnect: Bool) -> Void){
        let object = createPartyID(p)
        do{
            NSLog("Is valid JSON? \(NSJSONSerialization.isValidJSONObject(object))")
            let body = try NSJSONSerialization.dataWithJSONObject(object, options: .PrettyPrinted)
            makeUrlRequest("http://localhost:3000/r", body: body, method: "POST"){
                do{
                    if $0 != nil{
                        let json = try NSJSONSerialization.JSONObjectWithData($0!, options: .AllowFragments)
                        self.party = Party(dict: json as! [String : NSObject], storeMembers: isHost)
                        onCompletion(didConnect: true)
                    }
                    else{
                        NSLog("No Responce from Server after refresh request")
                        onCompletion(didConnect: false)
                    }
                }
                catch{
                    NSLog("Error parsing JSON when joining party")
                }
            }
        }
        catch{
            NSLog("Error creating JSON Object for refresh")
        }
    }
    func updateResults(p: Party, isHost: Bool, onError: () -> Void){
        let object = createPartyID(p)
        do{
            NSLog("Is valid JSON? \(NSJSONSerialization.isValidJSONObject(object))")
            let body = try NSJSONSerialization.dataWithJSONObject(object, options: .PrettyPrinted)
            makeUrlRequest("http://localhost:3000/1", body: body, method: "POST"){didConnect in
                if didConnect == nil {
                    onError()
                }
            }
        }
        catch{
            NSLog("Error creating JSON Object for updateResults")
        }

    }
}
