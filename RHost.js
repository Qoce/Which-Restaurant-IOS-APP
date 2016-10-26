function Party(password, name,latitude, longitude){
	this.password = password;
	this.name = name;
	this.members = new Array();
	this.latitude = latitude;
	this.longitude = longitude;
	this.addMember = function(member){
		members.add(member);
	};
}
var http = require("http");
var https = require("https");
var fs = require('fs');

var partyList = new Array();
var bodyParser = require('body-parser');
var express = require('express');
var req = require('request')
var prefrenceTypes = ["fastFood", "fastCasual", "casualDining", "fineDining", "chinese", "italian", "indian", "japanese", "bbq", "pizza", "price"]
// var options = {
//   key: fs.readFileSync('key.pem'),
//   cert: fs.readFileSync('cert.pem')
// };
var server = express();
server.use(bodyParser.json());
server.use(function(request, response) {
	var url = request.url;
	console.log(request.method);
	console.log(url);
	console.log(request.body);

	if(url.charAt(1) === 's'){
		addObjectToPartyList(request.body);
	}
	else if(url.charAt(1) === 'g'){
		latitude = url.substring(2, url.indexOf("?"));
		longitude = url.substring(url.indexOf("?") + 1, url.length);
		response.write(JSON.stringify({array: getPartiesInRange(parseFloat(latitude), parseFloat(longitude), 1)}));
	}
	else if(url.charAt(1) === 'j'){
		var body = request.body;
		var obj = body.user;

		var party = findClosePartyWithNameAndPassword(body.partyName, body.password, body.latitude, body.longitude);
		if(party !== null){
			party.members.push(obj);
			response.write(JSON.stringify(party));
			console.log("Response:");
			console.log(JSON.stringify(party));
		}
	}
	else if(url.charAt(1) === 'r'){
		var body = request.body;
		var party = findClosePartyWithNameAndPassword(body.partyName, body.password, body.latitude, body.longitude);
		if(party !== null){
			response.write(JSON.stringify(party));
			console.log("Response:");
			console.log(JSON.stringify(party));
		}
	}
	else if(url.charAt(1) === 'l'){
		var body = request.body;
		var obj = body.user;

		var party = findClosePartyWithNameAndPassword(body.partyName, body.password, body.latitude, body.longitude);
		if(party !== null){
			for (var i = 0; i < party.members.length; i++){
   				if (party.members[i].name.valueOf() === obj.name.valueOf()) {
    			  	party.members.splice(i,1);
    			 	break;
  				}
			}
			response.write(JSON.stringify(party));
			console.log("Response:");
			console.log(JSON.stringify(party));
		}
	}
	else if(url.charAt(1) === 't'){
		printPartyList();
	}
	else if(url.charAt(1) === '1'){
		var body = request.body;
		var party = findClosePartyWithNameAndPassword(body.partyName, body.password, body.latitude, body.longitude);
		party.results = body.results;
		
		response.write("Success");
	}
	else if(url.charAt(1) === 'd'){
		var body = request.body;
		var obj = body.user;

		var party = findClosePartyWithNameAndPassword(body.partyName, body.password, body.latitude, body.longitude);
		partyList.splice(party.index, 1);
	}
	if(url.charAt(1) === 'i')//Server does a google places request
	{
		var key = "AIzaSyDJNnGSF4ttzU5ITHl-GCQYZiiHgC6tT2s";
		console.log('Request reached i');
		console.log(request.body.url + '&key=' + key);
		req(request.body.url + '&key=' + key,function(error, respon, body){
			//console.log(body);
			response.write(body);
			
			response.end();
		});
	}
	else{
		response.end();
	}
});
function printPartyList(){
	console.log(JSON.stringify(partyList));
}
function addObjectToPartyList(obj){
	partyList.splice(indexOf(obj.latitude), 0, obj);
}
function indexOf(latitude){
	var endIndex = partyList.length;
	var beginIndex = 0;
	if(partyList.length === 1){
		if(partyList[0].latitude > latitude) {
			return 0;
		}
		return 1;
	}
	while(endIndex > beginIndex + 1){
		var middleIndex = Math.floor((endIndex + beginIndex) / 2);
		if(latitude > partyList[middleIndex].latitude){
			beginIndex = middleIndex;
		}
		else{
			endIndex = middleIndex;
		}
	}
	return endIndex;
}

function getPartiesInRange(latitude, longitude, range){
	var partiesInRange = new Array();
	var startIndex = indexOf(latitude - range);
	var endIndex = indexOf(latitude + range);
	for(var i = startIndex; i < endIndex; i++){
		var long = partyList[i].longitude;
		if(long > longitude - range && long < longitude + range){
			partiesInRange.push(partyList[i]);
			partyList[i].index = i;
		}
	}
	return partiesInRange;
}
function findClosePartyWithNameAndPassword(name, password, latitude, longitude){
	var partiesInRange = getPartiesInRange(latitude, longitude, 0.0001);
	var closestDistance = 1000;
	var closestParty = null;
	console.log("Length");
	console.log(partiesInRange.length);
	for(var i = 0; i < partiesInRange.length; i++){
		if(partiesInRange[i].name.valueOf() === name.valueOf() && partiesInRange[i].password.valueOf() === password.valueOf()){
			var deltaX = partiesInRange[i].latitude - latitude;
			var deltaY = partiesInRange[i].longitude - longitude;
			var distanceSquared = deltaX * deltaX + deltaY * deltaY;
			if(distanceSquared < closestDistance){
				closestDistance = distanceSquared;
				closestParty = partiesInRange[i];
			}
		}
	}
	return closestParty;
}
function createFakeData(){
    console.log('creating fake data');
    
    for(var i = 0; i < 500; i++){
        for(var j = 0; j < 500; j++){
        	var prefrences = {}
            addObjectToPartyList({longitude: Math.round((i * 360 / 500 - 180) * 10000000) / 10000000, latitude: Math.round((j * 180 / 500 - 90) * 10000000) / 10000000, name: "Johny", password: "Doritos", members: [{name: "Johny", preferences: {}}]});
        }
        if(i % 50 === 0){
        	console.log(i);
    	}
    }
}

createFakeData();
server.listen(3000);
