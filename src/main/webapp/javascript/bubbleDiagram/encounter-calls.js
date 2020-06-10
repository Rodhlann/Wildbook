// lang  dictionary contains all language specific text. It is loaded in individuals jsp and contains
// all the necessary keys from individuals.properties with the same syntax.
var dict = {}; 
var languageTable = function(words) {
    dict = words;
}

var getIndividualIDFromEncounterToString = function(encToString) {
    // return everything between "individualID=" and the next comma after that
    console.log('encToString = %o', encToString);
    //var id = encToString.split("individualID=")[1].split(",")[0];
    var id = encToString.displayName; // since this is for display, and individualIDs are UUIDs now
    if (!id) return false;
    return id;
}

var getData = function(individualID, displayName) {
    var occurrenceObjectArray = [];
    var items = [];
    var encounterArray = [];
    var occurrenceArray = [];
    var dataObject = {};

    d3.json(wildbookGlobals.baseUrl + "/api?query="+encodeURIComponent("SELECT FROM org.ecocean.Occurrence WHERE encounters.contains(enc) && enc.individual.individualID == \"" + individualID + "\" VARIABLES org.ecocean.Encounter enc"), function(error, json) {
	if(error) {
            console.log("error")
	}
	var jsonData = json;
	for(var i=0; i < jsonData.length; i++) {
            var thisOcc = jsonData[i];
            //console.log("JsonData["+i+"] = "+JSON.stringify(thisOcc));
            var encounterSize = thisOcc.encounters.length;
            // make encounterArray, containing the individualIDs of every encounter in thisOcc;
            for(var j=0; j < encounterSize; j++) {
		//console.info('[%d] %o %o', j, thisOcc.encounters, thisOcc.encounters[j]);
		var thisEncIndID = getIndividualIDFromEncounterToString(thisOcc.encounters[j]);
		//console.log("thisEncIndID="+thisEncIndID);
		
		//var thisEncIndID = jsonData[i].encounters[j].individualID;   ///only when we fix thisOcc.encounters to be real json   :(
		//console.info('i=%d, j=%d, -> %o', i, j, thisEncIndID);
		if (!thisEncIndID || (thisEncIndID==displayName)) continue;  //unknown indiv -> false
		if(encounterArray.includes(thisEncIndID)) {
		} else {
		    encounterArray.push(thisEncIndID);
		}
            }
            occurrenceArray = occurrenceArray.concat(encounterArray);
            var occurrenceID = jsonData[i].encounters[0].occurrenceID;
            var index = encounterArray.indexOf(individualID.toString());
            if (~index) {
		encounterArray[index] = "";
            }
            var occurrenceObject = new Object();
            if(encounterArray.length > 0) {
		occurrenceObject = {occurrenceID: occurrenceID, occurringWith: encounterArray.filter(function(e){return e}).join(", ")};
            } else {
		occurrenceObject = {occurrenceID: "", occurringWith: ""};
            }
            occurrenceObjectArray.push(occurrenceObject);
            encounterArray = [];
	}

	for(var i = 0; i < occurrenceArray.length; ++i) {
            if(!dataObject[occurrenceArray[i]])
		dataObject[occurrenceArray[i]] = 0;
            ++dataObject[occurrenceArray[i]];
	}
	for (var prop in dataObject) {
            var whale = new Object();
            whale = {text:prop, count:dataObject[prop], sex: "", haplotype: ""};
            items.push(whale);	
	}
	if (items.length > 0) {
            getSexHaploData(individualID, items);
	}
	getEncounterTableData(occurrenceObjectArray, individualID);
    });
};

var getSexHaploData = function(individualID, items) {
    d3.json(wildbookGlobals.baseUrl + "/api?query="+encodeURIComponent("SELECT FROM org.ecocean.MarkedIndividual WHERE encounters.contains(enc) && occur.encounters.contains(enc) && occur.encounters.contains(enc2) && enc2.individual.individualID == \"" + individualID + "\" VARIABLES org.ecocean.Encounter enc;org.ecocean.Encounter enc2;org.ecocean.Occurrence occur"), function(error, json) {
	if(error) {
	    console.log("error")
	}
	jsonData = json;
	for(var i=0; i < jsonData.length; i++) {
	    var result = items.filter(function(obj) {
		return obj.text === jsonData[i].individualID
	    })[0];
	    if (!result) continue;
	    result.sex = jsonData[i].sex;
	    result.haplotype = jsonData[i].localHaplotypeReflection;
	}
	makeTable(items, "#coHead", "#coBody", null);
	$('#cooccurrenceTable tr').click(function() {
            selectedWhale = ($(this).attr("class"));
            goToWhaleURL(selectedWhale);
	});
    });
};

var makeTable = function(items, tableHeadLocation, tableBodyLocation, sortOn) {
    var previousSort = null;
    refreshTable(sortOn);

    function refreshTable(sortOn) {
	console.log("Refreshing table")
	
	var keys=d3.keys(items[0]);
	if(tableHeadLocation == "#encountHead"){
	    keys.shift();
	}
	var thead = d3.select(tableHeadLocation).selectAll("th")
	    .data(keys).enter()
	    .append("th").text(function(d){
		if(d === "text") {
		    return dict['occurringWith'];
		} if (d === "occurrenceNumber"){
		    return dict['occurrenceNumber'];
		} if (d === "behavior") {
		    return dict['behavior'];
		} if(d === "alternateID") {
		    return dict['alternateID'];
		}if (d === "sex") {
		    return dict['sex'];
		} if (d === "haplotype") {
		    return dict['haplotype'];
		} if (d === "location") {
		    return dict['location'];
		} if (d === "dataTypes") {
		    return dict['dataTypes'];
		} if (d === "date") {
		    return dict['date'];
		} if(d === "occurringWith") {
		    return dict['occurringWith'];
		} if(d === "catalogNumber") {
		    //return dict['catalogNumber'];
		} if(d === "roles") {
		    return dict['roles'];
		} if(d === "relationshipWith") {
		    return dict['relationshipWith'];
		} if(d === "type") {
		    return dict['type'];
		} if(d === "socialUnit") {
		    return dict['socialUnit'];
		} if(d === "edit") {
		    return dict['edit'];
		} if(d === "remove") {
		    return dict['remove'];
		} if(d === "relationshipID") {
		    return  dict['relationshipID'];
		}
	    })
	    .on("click", function(d){
		if(tableHeadLocation != "#relationshipHead") {
		    return refreshTable(d);
		}
	    });

	console.log("ITEMS", items)
	var tr = d3.select(tableBodyLocation).selectAll("tr")
	    .data(items).enter()
	    .append("tr")
	    .attr("class", function(d){
		if(d.relationshipID !=null && d.relationshipID != 'undefined') {
		    return d.relationshipID;
		}
		return d3.values(d)[0];
	    });

	console.log("TR", tr.selectAll("td"))
	var td = tr.selectAll("td")
	    .data(function(d){
		console.log("VALUES", d3.values(d))
		if(tableHeadLocation == "#encountHead"){
	    	    var smaller = d3.values(d);
	    	    smaller.shift();
	    	    return smaller;
		}
		
		return d3.values(d);
    	    })
	    .enter().append("td")
	    .html(function(d) {
		//console.log("Dxj", d);
		//console.log("Dxk", typeof d);
		
		if(d == 'TissueSample') {
		    return "<img class='encounterImg' src='images/microscope.gif'/>";
		} 
		if(d == 'image') {
		    return "<img class='encounterImg' src='images/Crystal_Clear_filesystem_folder_image.png'/>"
		} 
		if(d == 'youtube-image') {
		    return "<img class='encounterImg' src='images/youtube.png'/>"
		} 
		if(d == 'both') {
		    return "<img class='encounterImg' src='images/microscope.gif'/><img class='encounterImg' src='images/Crystal_Clear_filesystem_folder_image.png'/>";
		}
		
		if(typeof d == "object") {
			//console.log("Dxm it's an object", typeof d);
		    if(d.length <= 2) {
		    	//console.log("Dxp it's an array");
		    	//console.log("Dxo", d);
			if(d[0] == 'edit'){
				//console.log("Dxl it's an edit", d);
			    return "XXY<button type='button' name='button' value='" + d[1] + "' class='btn btn-sm btn-block editRelationshipBtn' id='edit" + d[1] + "'>Edit</button>";
			} if(d[0] == 'remove') {
			    return "<button type='button' name='button' value='" + d[1] + "' class='btn btn-sm btn-block deleteRelationshipBtn' id='remove" + d[1] + "'>Remove</button><div class='confirmDelete' value='" + d[1] + "'><p>Are you sure you want to delete this relationship?</p><button class='btn btn-sm btn-block yesDelete' type='button' name='button' value='" +d[1]+ "'>Yes</button><button class='btn btn-sm btn-block cancelDelete' type='button' name='button' value='" + d[1] + "'>No</button></div>";
			}
			return d[0].italics() + "-" + d[1];
		    }
		    if(d.length > 2) {
			return "<a target='_blank' href='individuals.jsp?number=" + d[0] + "'>" + d[5] + "</a><br><span>" + dict['nickname'] + " : " + d[1]+ "</span><br><span>" + dict['alternateID'] + ": " + d[2] + "</span><br><span>" + dict['sex'] + ": " + d[3] + "</span><br><span>" + dict['haplotype'] +": " + d[4] + "</span>";
		    }
		}

		//console.log("Dxz",d);
		return d; 
	    });
	
	if(sortOn !== null) {
	    console.log("sorting on: "+sortOn);
	    if(sortOn != previousSort){
		tr.sort(function(a,b){return sort(a[sortOn], b[sortOn]);});
		previousSort = sortOn;
	    } else {
		tr.sort(function(a,b){return sort(b[sortOn], a[sortOn]);});
		previousSort = null;
	    }
	    td.html(function(d) {
		if(d == 'TissueSample') {
		    return "<img class='encounterImg' src='images/microscope.gif'/>";
		} 
		if(d == 'image') {
		    return "<img class='encounterImg' src='images/Crystal_Clear_filesystem_folder_image.png'/>"
		} 
		if(d == 'youtube-image') {
		    return "<img class='encounterImg' src='images/youtube.png'/>"
		} 
		if(d == 'both') {
		    return "<img class='encounterImg' src='images/microscope.gif'/><img class='encounterImg' src='images/Crystal_Clear_filesystem_folder_image.png'/>";
		}
		if(typeof d == "object") {
			//console.log("Dxm it's an object", typeof d);
		    if(d.length <= 2) {
		    	//console.log("Dxp it's an array");
		    	//console.log("Dxo", d);
			if(d[0] == 'edit'){
				//console.log("Dxl it's an edit", d);
			    return "<button type='button' name='button' value='" + d[1] + "' class='btn btn-sm btn-block editRelationshipBtn' id='edit" + d[1] + "'>Edit</button>";
			} if(d[0] == 'remove') {
			    return "<button type='button' name='button' value='" + d[1] + "' class='btn btn-sm btn-block deleteRelationshipBtn' id='remove" + d[1] + "'>Remove</button><div class='confirmDelete' value='" + d[1] + "'><p>Are you sure you want to delete this relationship?</p><button class='btn btn-sm btn-block yesDelete' type='button' name='button' value='" +d[1]+ "'>Yes</button><button class='btn btn-sm btn-block cancelDelete' type='button' name='button' value='" + d[1] + "'>No</button></div>";
			}
			return d[0].italics() + "-" + d[1];
		    }
		    if(d.length > 2) {
			return "<a target='_blank' href='individuals.jsp?number=" + d[0] + "'>" + d[5] + "</a><br><span>" + dict['nickname'] + " : " + d[1]+ "</span><br><span>" + dict['alternateID'] + ": " + d[2] + "</span><br><span>" + dict['sex'] + ": " + d[3] + "</span><br><span>" + dict['haplotype'] +": " + d[4] + "</span>";
		    }
		}
		return d;
	    });
	}
    }

    function sort(a,b) {
	if(typeof a == "string"){
	    if(a === "") {
		a = "0";
	    }if (b === "") {
		b = "0";
	    }
	    var parseA = unixCrunch(a);
	    if(parseA) {
		var whaleA = parseA;
		var whaleB = unixCrunch(b);
		return whaleA < whaleB ? 1 : whaleA == whaleB ? 0 : -1;
	    } else
		return a.localeCompare(b);
	} else if(typeof a == "number") {
	    return a > b ? 1 : a == b ? 0 : -1;
	} else if(typeof a == "boolean") {
	    return b ? 1 : a ? -1 : 0;
	}
    }
    
    function unixCrunch(date) {
	date = date.replace("-","/");
	return new Date(date).getTime()/1000;
    }
    
};

var getEncounterTableData = function(occurrenceObjectArray, individualID) {
    var encounterData = [];
    var occurringWith = "";
    d3.json(wildbookGlobals.baseUrl + "/api/jdoql?"+encodeURIComponent("SELECT FROM org.ecocean.MarkedIndividual WHERE individualID == \"" + individualID + "\"" ), function(error, json) {
	if(error) {
            console.log("error")
	}
	jsonData = json[0];
	for(var i=0; i < jsonData.encounters.length; i++) {
    	    var occurringWith = "";
            for(var j = 0; j < occurrenceObjectArray.length; j++) {
		if (occurrenceObjectArray[j].occurrenceID == jsonData.encounters[i].occurrenceID) {
		    if(encounterData.includes(jsonData.encounters[i].occurrenceID)) {
		    } else {
			var occurringWith = occurrenceObjectArray[j].occurringWith;
			console.log(occurringWith);
		    }
		}
            }
            var dateInMilliseconds = new Date(jsonData.encounters[i].dateInMilliseconds);
            if(dateInMilliseconds > 0) {
		//console.log("Trying millis...");
		date = dateInMilliseconds.toISOString().substring(0, 10);
		if(jsonData.encounters[i].day<1){date=date.substring(0,7);}
		if(jsonData.encounters[i].month<0){date=date.substring(0,4);}
            } else if (jsonData.encounters[i].year) {
		//console.log("Tryin plaintext...");
		date = jsonData.encounters[i].year;
		if (jsonData.encounters[i].month) { date+= "-"+jsonData.encounters[i].month;}
		if (jsonData.encounters[i].day) { date+= "-"+jsonData.encounters[i].day;} 
            } else {  
		date = dict['unknown'];
            }

            if(jsonData.encounters[i].verbatimLocality) {
		var location = jsonData.encounters[i].verbatimLocality;
            } else {
		var location = "";
            }
            var catalogNumber = jsonData.encounters[i].catalogNumber;
            console.log("Here's what we are working with : "+jsonData.encounters[i]);
            if(jsonData.encounters[i].tissueSamples || jsonData.encounters[i].annotations) {
		if (jsonData.encounters[i].tissueSamples && jsonData.encounters[i].tissueSamples.length > 0 && jsonData.encounters[i].annotations.length > 0){
                    var dataTypes = "both"
		} 
		else if((jsonData.encounters[i].tissueSamples)&&(jsonData.encounters[i].tissueSamples.length > 0)) {
		    var dataTypes = jsonData.encounters[i].tissueSamples[0].type;
		} 
		else if((jsonData.encounters[i].annotations)&&(jsonData.encounters[i].annotations.length > 0)) {
		    
        	    if((jsonData.encounters[i].eventID)&&(jsonData.encounters[i].eventID.indexOf("youtube") > -1)){
        		var dataTypes = "youtube-image";
        	    }
        	    //otherwise it's just a plain old image
        	    else{
        		var dataTypes = "image";
        	    }
        	    
		}
		else {
		    var dataTypes = "";
		}
            }
            var sex = jsonData.encounters[i].sex;
            var behavior = jsonData.encounters[i].behavior;
            var alternateID = jsonData.encounters[i].alternateid;
            var encounter = new Object();
            if(occurringWith === undefined) {
		var occurringWith = "";
            }
            encounter = {catalogNumber: catalogNumber, date: date, location: location, dataTypes: dataTypes, alternateID: alternateID, sex: sex, occurringWith: occurringWith, behavior: behavior};
            encounterData.push(encounter);
	}
	makeTable(encounterData, "#encountHead", "#encountBody", "date");
	$('#encountTable tr').click(function() {
            selectedWhale = ($(this).attr("class"));
            goToEncounterURL(selectedWhale);
	});
    });
}

var goToEncounterURL = function(selectedWhale) {
    window.open(wildbookGlobals.baseUrl + "/encounters/encounter.jsp?number=" + selectedWhale);
}

var goToWhaleURL = function(selectedWhale) {
    window.open(wildbookGlobals.baseUrl + "/individuals.jsp?number=" + selectedWhale);
}

var getRelationshipData = function(relationshipID) {
    d3.json(wildbookGlobals.baseUrl + "/api/org.ecocean.social.Relationship/" + relationshipID, function(error, json) {
	if(error) {
            console.log("error")
	}
	jsonData = json;
	console.log("Relationship ID in getRelationshipData: " + relationshipID);
	var type = jsonData.type;
	var individual1 = jsonData.markedIndividualName1;
	var individual2 = jsonData.markedIndividualName2;
	var role1 = jsonData.markedIndividualRole1;
	var role2 = jsonData.markedIndividualRole2;
	var descriptor1 = jsonData.markedIndividual1DirectionalDescriptor;
	var descriptor2 = jsonData.markedIndividual2DirectionalDescriptor
	var socialUnit = jsonData.relatedSocialUnitName;

	var startTime;
	var endTime;
	
	if (jsonData.startTime == "-1") {
    	    startTime = null;;
	} else {
    	    startTime = new Date(jsonData.startTime);
	}
	if (jsonData.endTime == "-1") {
    	    endTime = null;
	} else {
    	    endTime = new Date(jsonData.endTime);
	}

	var bidirectional = jsonData.bidirectional;

	$("#addRelationshipForm").show();
	$("#setRelationship").show();

	$("#individual1set").hide();
	$("#individual1").show();
	$("#individual1").val(individual1);
	$('#role1').val(role1);
	$("#descriptor1").val(descriptor1);
	$("#individual2").val(individual2);
	$("#role2").val(role2);
	$("#descriptor2").val(descriptor2);
	$("#socialUnit").val(socialUnit);
	$("#startTime").val(startTime.toISOString().substr(0,10));
	$("#endTime").val(endTime.toISOString().substr(0,10));
	$("#bidirectional").val(bidirectional);
    });
}

var resetForm = function($form, markedIndividual) {
    $("#addRelationshipForm").show();

    $form.show();
    $form.find('input:text, select').val('');

    $("#type option:selected").prop("selected", false);
    $("#type option:first").prop("selected", "selected");
    $("#role1 option:selected").prop("selected", false);
    $("#role1 option:first").prop("selected", "selected");
    $("#role2 option:selected").prop("selected", false);
    $("#role2 option:first").prop("selected", "selected");

    $("#individual1").val('');
    $("#individual1").val(markedIndividual);
    $("#individual1").hide();
    $("#individual1set").show();
}

var getRelationshipTableData = function(individualID) {
    d3.json(wildbookGlobals.baseUrl + "/api/jdoql?"+encodeURIComponent("SELECT FROM org.ecocean.social.Relationship WHERE (this.markedIndividualName1 == \"" + individualID + "\" || this.markedIndividualName2 == \"" + individualID + "\")"), function(error, json) {
	if(error) {
	    console.log("error")
	}
	var relationshipArray = [];
	let jsonData = json;
	for(var i = 0; i < jsonData.length; i++) {
	    var relationshipID = jsonData[i]._id;
	    var startTime = jsonData[i].startTime;
	    var endTime = jsonData[i].endTime;
	    if (startTime == "-1") {
		startTime = "Start Time";
	    } 
	    if (endTime == "-1") {
		endTime = "End Time";
	    }
	    
	    if(jsonData[i].markedIndividualName1 != individualID) {
		var whaleID = jsonData[i].markedIndividualName1;
		var markedIndividual = jsonData[i].markedIndividualName2;
		var relationshipWithRole = jsonData[i].markedIndividualRole1;
		var markedIndividualRole = jsonData[i].markedIndividualRole2;
	    }
	    if(jsonData[i].markedIndividualName2 != individualID) {
		var whaleID = jsonData[i].markedIndividualName2;
		var markedIndividual = jsonData[i].markedIndividualName1;
		var markedIndividualRole = jsonData[i].markedIndividualRole1;
		var relationshipWithRole = jsonData[i].markedIndividualRole2;
	    }
	    var relatedSocialUnitName = jsonData[i].relatedSocialUnitName;
	    var type = jsonData[i].type;
	    var relationship = new Object();
	    relationship = {"roles": [markedIndividualRole, relationshipWithRole], "relationshipWith": [whaleID], "type": type, "socialUnit": relatedSocialUnitName, "edit": ["edit", relationshipID], "remove": ["remove", relationshipID]};
	    relationshipArray.push(relationship);
	}
	getIndividualData(relationshipArray);
    });
}

var getIndividualData = function(relationshipArray) {
    var relationshipTableData = [];
    for(var i=0; i < relationshipArray.length; i++) {
	d3.json(wildbookGlobals.baseUrl + "/api/org.ecocean.MarkedIndividual/" + relationshipArray[i].relationshipWith[0], function(error, json) {
	    if(error) {
		console.log("error")
	    }
	    //console.log("json: "+JSON.stringify(json));
	    let jsonData = json;
	    var individualInfo = relationshipArray.filter(function(obj) {
		return obj.relationshipWith[0] === jsonData.individualID;
	    })[0];
	    console.log(individualInfo.relationshipWith);
	    individualInfo.relationshipWith[1] = jsonData.nickName;
	    individualInfo.relationshipWith[2] = jsonData.alternateid;
	    individualInfo.relationshipWith[3] = jsonData.sex;
	    individualInfo.relationshipWith[4] = jsonData.localHaplotypeReflection;
	    individualInfo.relationshipWith[5] = jsonData.displayName;
	    relationshipTableData.push(individualInfo);

	    if(relationshipTableData.length == relationshipArray.length) {
		for(var j = 0; j < relationshipArray.length; j++) {
		    if(relationshipArray[j].relationshipWith.length == 1) {
			relationshipArray[j].relationshipWith[1] = jsonData.nickName;
			relationshipArray[j].relationshipWith[2] = jsonData.alternateid;
			relationshipArray[j].relationshipWith[3] = jsonData.sex;
			relationshipArray[j].relationshipWith[4] = jsonData.localHaplotypeReflection;
			relationshipArray[j].relationshipWith[5] = jsonData.displayName;
		    }
		}
		makeTable(relationshipArray, "#relationshipHead", "#relationshipBody", "text");
	    }
	});
    }
}
