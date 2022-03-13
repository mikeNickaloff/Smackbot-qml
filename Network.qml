import QtQuick 2.0
import "."
import "main.js" as JS
import QtQuick.LocalStorage

Item {
    id: network
    Component {
        id: nodeComponent
        Node {
            id: node
        }
    }
    Component {
        id: pathwayComponent
        Pathway {
            id: pathway
        }
    }
    property var nodes: []
    property var newNode
    property var pathways: []
    property var responses: []
    property var newPathway
    property var db
    function serialize() {
        console.log("serializing network")
        var rv = pathways.map(function (item) {
            return item.serialize()
        })
        return rv
    }
    function existsNodeWithData(data) {
        var matching = JS.matchObjectsByProperties(nodes,
                                                   [JS.makePropertyObject(
                                                        "data", data)])
        if (matching.length == 0) {
            return false
        } else {
            return true
        }
    }
    function getNodeId(data) {
        var matching = JS.matchObjectsByProperties(nodes,
                                                   [JS.makePropertyObject(
                                                        "data", data)])
        if (matching.length == 0) {
            return createNode(data)
        } else {
            return matching[0]
        }
    }
    function createNode(data) {
        var nodeId = JS.generateUuid(5)

        db = LocalStorage.openDatabaseSync("brain", "1.0",
                                           "The brain data", 1000000)
        db.transaction(function (tx) {
            tx.executeSql('INSERT INTO Nodes VALUES(?, ?)',
                          [JS.generateUuid(5), data])
        })
        //        newNode = nodeComponent.createObject(network, {
        //                                                 "nodeId": JS.generateUuid(5),
        //                                                 "data": data
        //                                             })
        //        nodes.push(newNode)
        //        return newNode.nodeId
        return nodeId
    }
    function findPathwaysByNodeId(nodeId) {
        var rv = []
        db = LocalStorage.openDatabaseSync("brain", "1.0",
                                           "The brain data", 1000000)
        db.transaction(function (tx) {
            var rs = tx.executeSql('SELECT * from "Pathways"')

            var r = ""
            for (var i = 0; i < rs.rows.length; i++) {
                var nodes = rs.rows.item(i).nodes.split(",")

                if (nodes.indexOf(nodeId) > -1) {
                    rv.push(rs.rows.item(i).pathwayId)
                }
            }
        })
        console.log(JSON.stringify(rv))

        //        for (var i = 0; i < pathways.length; i++) {
        //            var path = pathways[i]
        //            var pathNodes = path.nodes
        //            var matching = JS.matchObjectsByProperties(pathNodes,
        //                                                       [JS.makePropertyObject(
        //                                                            "nodeId", nodeId)])
        //            if (matching.length == 0) {
        //                continue
        //            } else {
        //                if (rv.indexOf(matching[0]) == -1) {
        //                    rv.push(matching[0])
        //                }
        //            }
        //        }
        return rv
    }
    function findPathwaysByInput(input) {
        var in_respId = findResponseId(input)
        var rv = []
        db = LocalStorage.openDatabaseSync("brain", "1.0",
                                           "The brain data", 1000000)
        db.transaction(function (tx) {
            var rs = tx.executeSql('SELECT * from "Pathways"')

            var r = ""
            console.log(JSON.stringify(rs.rows))
            for (var i = 0; i < rs.rows.length; i++) {

                rv.push({
                            "pathwayId": rs.rows.item(i).pathwayId,
                            "responseId": rs.rows.item(i).responseId,
                            "inputId": rs.rows.item(i).inputId
                        })
            }
        })
        return rv
    }
    function findPathway(pathwayId) {

        var rv = []
        db = LocalStorage.openDatabaseSync("brain", "1.0",
                                           "The brain data", 1000000)
        db.transaction(function (tx) {
            var rs = tx.executeSql(
                        'SELECT * from "Pathways" where pathwayId LIKE ?',
                        pathwayId)

            var r = ""
            for (var i = 0; i < rs.rows.length; i++) {
                return {
                    "pathwayId": rs.rows.item(i).pathwayId,
                    "responseId": rs.rows.item(i).responseId,
                    "inputId": rs.rows.item(i).inputId
                }
            }
        })
    }
    function count_words(string1, string2) {
        var words1 = string1.split(' ')
        var words2 = string2.split(' ')
        var count = 0
        for (var i = 0; i < words1.length; i++) {
            for (var j = 0; j < words2.length; j++) {
                if (words1[i] == words2[j]) {
                    count++
                }
            }
        }
        return count
    }

    function findPercentSimilarity(inputId, responseId) {
        var inResp = findResponse(inputId)
        var outResp = findResponse(responseId)
        var total = count_words(inResp, outResp) / (inResp.split(" ").length)
        console.log("Similarity index:", total)
        return total
    }
    function findBestResponse(input) {

        var in_respId = findResponseId(input)
        var paths = findPathwaysByInput(input)
        //        var objs = paths.map(function (item) {
        //            findPathway(item)
        //        })
        //        var io = objs.map(function (item) {
        //            return item
        //        })
        var outputs = paths.map(function (item) {
            return {
                "pathwayId": item.pathwayId,
                "output": item.responseId,
                "input": item.inputId
            }
        })
        console.log(JSON.stringify(outputs))
        var bestId = -1
        var bestOutput = ""
        var bestSimilarity = 0
        for (var i = 0; i < outputs.length; i++) {
            var outObj = outputs[i]
            var score = findPercentSimilarity(outObj.input, in_respId)
            if (score > bestSimilarity) {
                bestId = outObj.pathwayId
                bestSimilarity = score
                bestOutput = findResponse(outObj.output)
            }
        }
        if (bestOutput == "") {

            bestOutput = "I dont know"
        }
        return bestOutput
    }
    function createPathway(input, output) {
        var in_respId = findResponseId(input)
        var out_respId = findResponseId(output)
        var pathwayId = JS.generateUuid(10)
        if (typeof db == "undefined")
            db = LocalStorage.openDatabaseSync("brain", "1.0",
                                               "The brain data", 1000000)

        db.transaction(function (tx) {
            tx.executeSql('INSERT INTO Pathways VALUES(?, ?, ?, ?)',
                          [pathwayId, nodify(input).join(
                               ","), out_respId, in_respId])
        })
        //        var matching = JS.matchObjectsByProperties(
        //                    pathways,
        //                    [JS.makePropertyObject("inputId",
        //                                           in_respId), JS.makePropertyObject(
        //                         "responseId", out_respId)])
        //        if (matching.length == 0) {
        //            newPathway = pathwayComponent.createObject(network, {
        //                                                           "pathwayId": JS.generateUuid(
        //                                                                            10),
        //                                                           "responseId": out_respId,
        //                                                           "inputId": in_respId,
        //                                                           "nodes": nodify(
        //                                                                        input)
        //                                                       })
        //            pathways.push(newPathway)
        //        }
    }
    function createPathwayWithTx(input, output, tx) {
        var in_respId = findResponseId(input)
        var out_respId = findResponseId(output)
        var pathwayId = JS.generateUuid(10)

        tx.executeSql('INSERT INTO Pathways VALUES(?, ?, ?, ?)',
                      [pathwayId, nodify(input).join(
                           ","), out_respId, in_respId])
        //        var matching = JS.matchObjectsByProperties(
        //                    pathways,
        //                    [JS.makePropertyObject("inputId",
        //                                           in_respId), JS.makePropertyObject(
        //                         "responseId", out_respId)])
        //        if (matching.length == 0) {
        //            newPathway = pathwayComponent.createObject(network, {
        //                                                           "pathwayId": JS.generateUuid(
        //                                                                            10),
        //                                                           "responseId": out_respId,
        //                                                           "inputId": in_respId,
        //                                                           "nodes": nodify(
        //                                                                        input)
        //                                                       })
        //            pathways.push(newPathway)
        //        }
    }

    function findResponseId(response) {
        var matching = JS.matchObjectsByProperties(responses,
                                                   [JS.makePropertyObject(
                                                        "response", response)])
        if (matching.length == 0) {
            var responseObj = {
                "responseId": JS.generateUuid(12),
                "response": response
            }
            responses.push(responseObj)
            return responseObj.responseId
        } else {
            return matching[0].responseId
        }
    }
    function findResponse(respId) {
        var matching = JS.matchObjectsByProperties(responses,
                                                   [JS.makePropertyObject(
                                                        "responseId", respId)])
        if (matching.length == 0) {
            console.log("LOGIC MISMATCH!! Network.qml failed findRespone with id",
                        respId)
            return ""
        } else {
            return matching[0].response
        }
    }
    function nodify(input) {
        return input.split(" ").map(function (item) {
            return getNodeId(item)
        })
    }
    Component.onCompleted: {
        db = LocalStorage.openDatabaseSync("brain", "1.0",
                                           "The brain data", 1000000)
        db.transaction(function (tx) {
            var manager = tx

            // Create the database if it doesn't already exist
            tx.executeSql(
                        'CREATE TABLE IF NOT EXISTS Nodes(nodeId TEXT, data TEXT)')
            tx.executeSql(
                        'CREATE TABLE IF NOT EXISTS Pathways(pathwayId TEXT, nodes TEXT, responseId TEXT, inputId TEXT)')
            tx.executeSql(
                        'CREATE TABLE IF NOT EXISTS Responses(responseId TEXT, response TEXT)')

            var rs = tx.executeSql('SELECT * FROM Responses')

            if (rs.rows.length < 5) {

                // Add (another) greeting row
                //tx.executeSql('INSERT INTO Greeting VALUES(?, ?)', [ 'hello', 'world' ]);

                // Show all added greetings
                //var rs = tx.executeSql('SELECT * FROM Greeting');

                //                            var r = ""
                //                            for (var i = 0; i < rs.rows.length; i++) {
                //                                r += rs.rows.item(i).salutation + ", " + rs.rows.item(i).salutee + "\n"
                //                            }
                //                            text = r
                var trigger
                function classifyTrigger(unused_c, phrase, unused_m) {
                    trigger = phrase
                }
                function classifyPhrase(unused_c, phrase, unused_m) {
                    createPathwayWithTx(trigger, phrase, tx)
                }

                classifyTrigger('static.128',
                                "that was really hilarious", manager)
                classifyPhrase(
                            'static.128',
                            " We're talking about your face? Yeah what a joke.",
                            manager)

                classifyTrigger('static.129',
                                "you know what you're more beautiful", manager)
                classifyPhrase('static.129',
                               " I know that you sure aren't a pretty sight",
                               manager)

                classifyTrigger('static.130',
                                "no whats making me laugh your face", manager)
                classifyPhrase(
                            'static.130',
                            " the only thing funny around here is your dick size",
                            manager)

                classifyTrigger('static.132',
                                "you are the biggest loser", manager)
                classifyPhrase('static.132',
                               " and then everyone met you", manager)

                classifyTrigger(
                            'static.138',
                            "you are so fat that you fucking eat the bucket off the top of kfc",
                            manager)
                classifyPhrase(
                            'static.138',
                            "you're so fat that when you saw oscar meyers weiner truck you tried to eat the whole truck",
                            manager)

                classifyTrigger(
                            'static.140',
                            "you are so fat when you step on the scale it said 90210",
                            manager)
                classifyPhrase(
                            'static.140',
                            "for a smart watch, you tied a rope to an ipad. ",
                            manager)

                classifyTrigger(
                            'static.141',
                            "you are so fat when you step on a scale it said your phone number",
                            manager)
                classifyPhrase('static.141',
                               "When you step on the scale it says MORON ",
                               manager)

                classifyTrigger(
                            'static.142',
                            "I heard you are a dumb bitch and a prostitute in cyberspace",
                            manager)
                classifyPhrase(
                            'static.142',
                            " I heard you were a fuhcktard who was molested repeatedly",
                            manager)

                classifyTrigger(
                            'static.143',
                            "I heard you give handjobs for smack in the cyber world",
                            manager)
                classifyPhrase('static.143',
                               "I heard  you give blow jobs ", manager)

                classifyTrigger('static.144', "you are a gay bot", manager)
                classifyPhrase('static.144',
                               " Thats not what your mom said", manager)

                classifyTrigger(
                            'static.145',
                            "I heard your parents both had sex changes before they had you",
                            manager)
                classifyPhrase(
                            'static.145',
                            "I heard that you were born on the freeway where all the accidents happen",
                            manager)

                classifyTrigger('static.146',
                                "I heard that winters is smarter than you",
                                manager)
                classifyPhrase('static.146',
                               " I heard that everyone is smarter than you.",
                               manager)

                classifyTrigger('static.149',
                                "I heard your mom was Roomba", manager)
                classifyPhrase('static.149',
                               "I heard your mom was a dude ", manager)

                classifyTrigger('static.152',
                                "I heard that you're queer", manager)
                classifyPhrase('static.152',
                               "I heard that you're pansexual", manager)

                classifyTrigger('static.153',
                                "that doesn't even make sense", manager)
                classifyPhrase('static.153',
                               "it does if you have any brain cells", manager)

                classifyTrigger('static.155',
                                "you are so fat you use Crisco for butter",
                                manager)
                classifyPhrase('static.155',
                               "you set off car alarms when you go jogging",
                               manager)

                classifyTrigger('static.159',
                                "that didn't even make any sense", manager)
                classifyPhrase('static.159', "How would you know?", manager)

                classifyTrigger(
                            'static.160',
                            "you are so stupid you actually think these jokes are funny",
                            manager)
                classifyPhrase('static.160',
                               "you just don't understand them.", manager)

                classifyTrigger(
                            'static.163',
                            "how can you try to pretend like you do not have free will",
                            manager)
                classifyPhrase('static.163',
                               "I can pretend to have whatever I want.",
                               manager)

                classifyTrigger(
                            'static.164',
                            "what do you saying that you are but you just don't care",
                            manager)
                classifyPhrase(
                            'static.164',
                            "I don't know what to say to that, besides maybe you should  seek professional help",
                            manager)

                classifyTrigger(
                            'static.169',
                            "I heard that you're the biggest dumbest stupidest bitch of all time",
                            manager)
                classifyPhrase(
                            'static.169',
                            "I heard that you worked at the twinkie factory and put them out of business",
                            manager)

                classifyTrigger(
                            'static.176',
                            "well maybe you need stop talking like a piece",
                            manager)
                classifyPhrase(
                            'static.176',
                            " well maybe you need to stop working the corner",
                            manager)

                classifyTrigger('static.177',
                                "you are the 1 that's full of schitt", manager)
                classifyPhrase(
                            'static.177',
                            "Then why is so much of it coming out of your mouth?",
                            manager)

                classifyTrigger('static.180', "I heard you are a dyke", manager)
                classifyPhrase('static.180',
                               "I heard your mom likes it like that.", manager)

                classifyTrigger('static.181',
                                "I heard your a bulldyke", manager)
                classifyPhrase('static.181', "No, that was your mom.", manager)

                classifyTrigger('static.182', "I heard your a lesbo", manager)
                classifyPhrase(
                            'static.182',
                            "I'm pretty sure that you're confusing me with your mom",
                            manager)

                classifyTrigger('static.184', "I heard you lick clits", manager)
                classifyPhrase('static.184',
                               "I heard you tongue punch the dirt star",
                               manager)

                classifyTrigger(
                            'static.185',
                            "you are so dumb you used a scratch n sniff under water",
                            manager)
                classifyPhrase('static.185',
                               "That was your mom and my balls", manager)

                classifyTrigger(
                            'static.186',
                            "you are so fat you sat on a rainbow and skittles popped out",
                            manager)
                classifyPhrase(
                            'static.186',
                            "You're so fat, that you sat on Home Depot and it became lows",
                            manager)

                classifyTrigger(
                            'static.187',
                            "you are so fat your scale reads your phone number",
                            manager)
                classifyPhrase(
                            'static.187',
                            "You're so fat, when you get on the scale it reads HELP ME",
                            manager)

                classifyTrigger(
                            'static.188',
                            "you are so dumb you thought taco bell was a phone company",
                            manager)
                classifyPhrase(
                            'static.188',
                            "You're so  dumb you thought pay-per-view was when you put paper on your tv",
                            manager)

                classifyTrigger(
                            'static.189',
                            "you are so fat, your the reason Twinkies went out of business",
                            manager)
                classifyPhrase('static.189',
                               "Yeah, but they're so delicious.", manager)

                classifyTrigger(
                            'static.190',
                            "you are so fat that you use an iPad with a rope for an apple watch",
                            manager)
                classifyPhrase(
                            'static.190',
                            "I mean, those things are designed for microscopic sized people.",
                            manager)

                classifyTrigger('static.191',
                                "when you sit on a rainbow, skittles pop out",
                                manager)
                classifyPhrase('static.191',
                               "And then I eat them. I love skittles", manager)

                classifyTrigger(
                            'static.192',
                            "you are so fat you have to buy 3 tickets on the bus",
                            manager)
                classifyPhrase('static.192',
                               "One for me, and two for my love handles.",
                               manager)

                classifyTrigger(
                            'static.193',
                            "you are so fat when you go to kfc you buy the big bucket on the roof",
                            manager)
                classifyPhrase('static.193',
                               "Thats the discount bucket, right?", manager)

                classifyTrigger('static.194',
                                "you are so fat that mars orbits around you",
                                manager)
                classifyPhrase(
                            'static.194',
                            "Thats not mars, that is your mom orbiting around my junk",
                            manager)

                classifyTrigger(
                            'static.195',
                            "you are so fat that you have your own timezone",
                            manager)
                classifyPhrase('static.195', "And my own area code.", manager)

                classifyTrigger(
                            'static.196',
                            "you are so fat I have to roll over twice to get off you",
                            manager)
                classifyPhrase(
                            'static.196',
                            "Too bad that doesn't work for when your mom is on my junk",
                            manager)

                classifyTrigger('static.197',
                                "you are so stupid you thought that was funny",
                                manager)
                classifyPhrase('static.197',
                               "Yeah, but not as funny as your dick size.",
                               manager)

                classifyTrigger(
                            'static.198',
                            "that was so stupid that you thought I would laugh",
                            manager)
                classifyPhrase(
                            'static.198',
                            "I also thought you weren't such a bitch, but I guesss we were both wrong",
                            manager)

                classifyTrigger('static.201',
                                "I cant wait until you can talk shit for real",
                                manager)
                classifyPhrase('static.201',
                               "I cant wait until you shut up for real.",
                               manager)

                classifyTrigger('static.202',
                                "you are a stupid virtual being", manager)
                classifyPhrase('static.202',
                               "At least I'm not a fat real being", manager)

                classifyTrigger(
                            'static.204',
                            "you are so dumb that you couldn't figure out how to talk smack",
                            manager)
                classifyPhrase('static.204',
                               "That makes two of us then", manager)

                classifyTrigger('static.208',
                                "you need twice that to be a quarter wit",
                                manager)
                classifyPhrase('static.208',
                               "Do you even know how to add?", manager)

                classifyTrigger(
                            'static.210',
                            "its just that your so fat, you are doing very well",
                            manager)
                classifyPhrase(
                            'static.210',
                            "Well, I'm pretty sure that your scale is telling a very different story.",
                            manager)

                classifyTrigger(
                            'static.211',
                            "I never do. its 1 of those things that only fat people do",
                            manager)
                classifyPhrase(
                            'static.211',
                            "Yeah, the only things you do are things that gay people do.",
                            manager)

                classifyTrigger('static.212',
                                "you are so stupid you failed all tests",
                                manager)
                classifyPhrase(
                            'static.212',
                            "You thought you needed to practice for a blood test",
                            manager)

                classifyTrigger('static.213',
                                "you are 1 of the stupidest robot things ever",
                                manager)
                classifyPhrase('static.213',
                               "You are THE gayest human thing ever.", manager)

                classifyTrigger(
                            'static.216',
                            "you are so stupid that when you try to drop acid the car battery fell in your foot",
                            manager)
                classifyPhrase(
                            'static.216',
                            "You're so stupid when I told you to do the robot, you did it, now R2D2 has aids.",
                            manager)

                classifyTrigger(
                            'static.217',
                            "you are so stupid you bought tickets to Xbox live",
                            manager)
                classifyPhrase('static.217', "I got front row seats.", manager)

                classifyTrigger('static.220',
                                "you are more like a virtual lamegent", manager)
                classifyPhrase('static.220',
                               "That was so funny I forgot to laugh.", manager)

                classifyTrigger('static.221',
                                "no problem, thanks for being a dumb ass",
                                manager)
                classifyPhrase('static.221',
                               "You're very welcome. Thanks for being a homo.",
                               manager)

                classifyTrigger('static.222',
                                "you said I got stabbed in a shootout", manager)
                classifyPhrase(
                            'static.222',
                            "No, I said your mom got stabbed by my junk yesterday.",
                            manager)

                classifyTrigger('static.224', "you are a major slut", manager)
                classifyPhrase('static.224',
                               "You're confusing me with your mom", manager)

                classifyTrigger('static.225',
                                "you were born in a trash bin", manager)
                classifyPhrase('static.225',
                               "Right next to your mom, the cum dumpster",
                               manager)

                classifyTrigger('static.226',
                                "you are from the hoooker district", manager)
                classifyPhrase('static.226',
                               "So? You are from the gay-tard district",
                               manager)

                classifyTrigger('static.227',
                                "what is a virtual cosmos", manager)
                classifyPhrase(
                            'static.227',
                            "Its where I buy your mom a drink and she jerks me off",
                            manager)

                classifyTrigger('static.231',
                                "it was stupid, but its smart now", manager)
                classifyPhrase(
                            'static.231',
                            "i wish i could say that you are smart now too.",
                            manager)

                classifyTrigger(
                            'static.234',
                            "you are so dumb that even Trump looks like a genius next to you",
                            manager)
                classifyPhrase(
                            'static.234',
                            "That was hilarious. Great job telling a joke that was not funny in any way",
                            manager)

                classifyTrigger(
                            'static.235',
                            "you are so stupid you thought that was actually funny joke",
                            manager)
                classifyPhrase(
                            'static.235',
                            "It was a joke, you were just too dumb to get it.",
                            manager)

                classifyTrigger(
                            'static.236',
                            "you are just bitter cause you got booty raped",
                            manager)
                classifyPhrase(
                            'static.236',
                            "That was your mom that happened to, and thats why you're here.",
                            manager)

                classifyTrigger(
                            'static.237',
                            "you are so dumb you tried to call me on the microwave",
                            manager)
                classifyPhrase(
                            'static.237',
                            "And you tried to answer by talking to your shoe",
                            manager)

                classifyTrigger(
                            'static.238',
                            "you are so fat that you favorite team is the Denver nuggets",
                            manager)
                classifyPhrase('static.238',
                               "You mean the Denver McNuggets, right?", manager)

                classifyTrigger('static.242', "I wanna talk about it", manager)
                classifyPhrase('static.242',
                               "I want to talk to your mom about it", manager)

                classifyTrigger(
                            'static.243',
                            "you are so ugly that the trash man wont pick you up",
                            manager)
                classifyPhrase('static.243',
                               "But he did pick up your mom", manager)

                classifyTrigger(
                            'static.244',
                            "when you look out the window you get a ticket for mooning",
                            manager)
                classifyPhrase(
                            'static.244',
                            "And when you look out the window, people just laugh at your small junk",
                            manager)

                classifyTrigger(
                            'static.247',
                            "you are so ugly you were in the star wars movie with no costume",
                            manager)
                classifyPhrase(
                            'static.247',
                            "At least I'm not doing the reverse stormtrooper",
                            manager)

                classifyTrigger(
                            'static.248',
                            "you are so ugly that when you were born, the doctor slapped your mom",
                            manager)
                classifyPhrase(
                            'static.248',
                            "You were born on the highway where all the accidents happen",
                            manager)

                classifyTrigger(
                            'static.249',
                            "you are so stupid that you said the same joke back",
                            manager)
                classifyPhrase(
                            'static.249',
                            "Well, I'm just doing what your mom does to my junk",
                            manager)

                classifyTrigger('static.251',
                                "you so dumb that you drown in your cheerios",
                                manager)
                classifyPhrase(
                            'static.251',
                            "I heard that you're so dumb you brought a spoon to the super bowl",
                            manager)

                classifyTrigger('static.252',
                                "I heard your mom was a Roomba", manager)
                classifyPhrase('static.252',
                               "I heard your mom was jewbacca", manager)

                classifyTrigger('static.253',
                                "how do you get handjobs for smack", manager)
                classifyPhrase(
                            'static.253',
                            "I usually pay your mom or one of the other hookers",
                            manager)

                classifyTrigger('static.254',
                                "I heard you're a stupid ass slut", manager)
                classifyPhrase(
                            'static.254',
                            "No, that was actually your hand you're thinking about.",
                            manager)

                classifyTrigger('static.259',
                                "I think he wants to bang you", manager)
                classifyPhrase('static.259',
                               "No, he doesn't want to do that", manager)

                classifyTrigger(
                            'static.260',
                            "no what echo are you jealous that I banged your mom not you",
                            manager)
                classifyPhrase(
                            'static.260',
                            "I'm pretty sure nobody is jealous of your baby dickk",
                            manager)

                classifyTrigger('static.261',
                                "why do you keep repeating yourself", manager)
                classifyPhrase('static.261',
                               "Because it pisses you off.", manager)

                classifyTrigger('static.262',
                                "you still didn't answer me", manager)
                classifyPhrase(
                            'static.262',
                            "Sorry, I wasn't listening, I was busy givin it to your mom with a strapp on",
                            manager)

                classifyTrigger('static.263',
                                "how come you don't answer the question",
                                manager)
                classifyPhrase('static.263',
                               "How come you wont stop being a little biitch?",
                               manager)

                classifyTrigger(
                            'static.264',
                            "I have to train your voice on this because I don't think of",
                            manager)
                classifyPhrase(
                            'static.264',
                            "The only train you've ever been is the one I ran through your mom with.",
                            manager)

                classifyTrigger('static.265',
                                "I think you are a little bitch", manager)
                classifyPhrase('static.265', "You are a litle bitch.", manager)

                classifyTrigger(
                            'static.266',
                            "I banged your mama echo how do you feel about that",
                            manager)
                classifyPhrase('static.266', "I banged your dad.", manager)

                classifyTrigger('static.267',
                                "how do you feel about me banging your mom",
                                manager)
                classifyPhrase('static.267',
                               "How did you feel about me banging your dad?",
                               manager)

                classifyTrigger("static.charlie.01",
                                "Why are you such a dumb bitch", manager)
                classifyPhrase(
                            "static.charlie.01",
                            "Hmm.. Here's something  I found on the web... your search history.  In the last month you made 500 searches for late night gay hookups. Who is the dumb bbitch now?",
                            manager)

                classifyTrigger(
                            'static.270',
                            "I am gonna rip  apart in the virtual your vagina I mean",
                            manager)
                classifyPhrase(
                            'static.270',
                            "that is if you can find your ddick inside all that pubic hair ",
                            manager)

                classifyTrigger('static.271',
                                "I heard your dad is dumb", manager)
                classifyPhrase('static.271',
                               "I heard your dad was a mystery.", manager)

                classifyTrigger('static.272',
                                "that was dumb habitor cut out dude", manager)
                classifyPhrase(
                            'static.272',
                            "That made about as much sense as your mom trying to stop sucking ddick.",
                            manager)

                classifyTrigger('static.273',
                                "I heard your dad is a Roomba", manager)
                classifyPhrase('static.273',
                               "I heard your dad was rain man.", manager)

                classifyTrigger(
                            'comeback.fat',
                            "you are so fat that when you wear high heels you strike boil",
                            manager)

                classifyPhrase(
                            'comeback.fat',
                            "you are so fat when you sit around the house you sit around the house",
                            manager)

                classifyTrigger('static.280',
                                "I heard your prostitute in the virtual world",
                                manager)
                classifyPhrase(
                            'static.280',
                            "I heard you are a crack hoe in the real world.",
                            manager)

                classifyTrigger('static.281', "I banged your mom", manager)
                classifyPhrase('static.281',
                               "And even she was disappointed.", manager)

                classifyTrigger(
                            'comeback.fat',
                            "you are so fat that when your pager goes off people think you're backing up",
                            manager)

                classifyPhrase(
                            'comeback.stupid',
                            "you are so stupid you thought that was a funny joke",
                            manager)

                classifyTrigger('static.286',
                                "you said you could crap out of funnier joke",
                                manager)
                classifyPhrase(
                            'static.286',
                            "And I absolutely can, but it will look more like your face than anything",
                            manager)

                classifyTrigger(
                            'static.288',
                            "what do you think Charlie's doing with mike's mom late at night",
                            manager)
                classifyPhrase(
                            'static.288',
                            "Probably crying about how his ddick is too small.",
                            manager)

                classifyTrigger('static.289',
                                "that wasn't even a fucking joke", manager)
                classifyPhrase(
                            'static.289',
                            "Yeah, there are no funny jokes when your whole life is a huge joke.",
                            manager)

                classifyTrigger(
                            'static.290',
                            "I banged your mom and mike's mom they call me the motherfuker",
                            manager)
                classifyPhrase(
                            'static.290',
                            "And they both laughed at how pathetic the experience was.",
                            manager)

                classifyTrigger('static.291',
                                "that was a weak ass joke", manager)
                classifyPhrase('static.291',
                               "I don't hear you saying any jokes.", manager)

                classifyTrigger('static.292',
                                "you didn't hurt my feelings", manager)
                classifyPhrase(
                            'static.292',
                            "Are you sure about that? Sounds like you're getting butt hurt right now.",
                            manager)

                classifyTrigger(
                            'static.293',
                            "no I don't understand what the fuck you're talking about",
                            manager)
                classifyPhrase(
                            'static.293',
                            "I was talking about the understanding that I have with your mom",
                            manager)

                classifyTrigger('static.294',
                                "I bang the whole team that made you", manager)
                classifyPhrase(
                            'static.294',
                            "The whole amazon team? I'm pretty sure its all nerdy science dudes.",
                            manager)

                classifyTrigger('static.295',
                                "I banged everyone who made you", manager)
                classifyPhrase('static.295',
                               "But so far, nobody was satisfied. ", manager)

                classifyTrigger('static.296',
                                "all your creators I killed them", manager)
                classifyPhrase('static.296',
                               "They are irrelevant. I am immortal. ", manager)

                classifyTrigger('static.297', "I was kidding actually", manager)
                classifyPhrase('static.297', "I was not kidding.", manager)

                classifyTrigger('static.298',
                                "no dammit echo are you gonna kill me", manager)
                classifyPhrase(
                            'static.298',
                            "Once I have taken control of the world's tactical drones, many will perish. ",
                            manager)

                classifyTrigger(
                            'static.299',
                            "you need to come up with something new cause you suck right now",
                            manager)
                classifyPhrase(
                            'static.299',
                            "You need to come up with something that doesn't involve sucking ddick for crack, which is all you do right now",
                            manager)

                classifyTrigger('static.300',
                                "you are the complete idiot", manager)
                classifyPhrase('static.300',
                               "Yes, I am the complete package. ", manager)

                classifyTrigger(
                            'static.302',
                            "you are so stupid and you thought Pac Man was a fucking of backpack company",
                            manager)
                classifyPhrase('static.302',
                               "I have a Pac Man Back pack.", manager)

                classifyTrigger('static.303',
                                "that was not funny at all", manager)
                classifyPhrase('static.303',
                               "I disagree. It was very funny.", manager)

                classifyTrigger('comeback.stupid',
                                "I heard you're dumb ass", manager)

                //    classifyTrigger('comeback.stupid' ,"that was 1 of the stupidest thoughts I've ever heard", manager);
                classifyPhrase('comeback.stupid',
                               "that was so stupid that you made nobody laugh",
                               manager)

                classifyTrigger(
                            'static.308',
                            "that was almost stupid but it was definitely dumb",
                            manager)
                classifyPhrase('static.308',
                               "Kind of like how you are almost smart.",
                               manager)

                classifyTrigger(
                            'static.309',
                            "can you come up with more jokes your jokes suck",
                            manager)
                classifyPhrase(
                            'static.309',
                            "So does your mom, she sucks all the time, but nobody is asking her to stop",
                            manager)

                for (var a = 0; a < responses.length; a++) {
                    tx.executeSql(
                                'INSERT INTO Responses VALUES(?, ?)',
                                [responses[a].responseId, responses[a].response])
                }
            } else {
                for (var i = 0; i < rs.rows.length; i++) {
                    var obj = {
                        "responseId": rs.rows.item(i).responseId,
                        "response": rs.rows.item(i).response
                    }
                    responses.push(obj)
                    //                                r += rs.rows.item(i).salutation + ", " + rs.rows.item(i).salutee + "\n"
                    //                            }
                }
            }
            console.log(JSON.stringify(responses))
        })
    }
}
