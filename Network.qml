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

                createPathway("Hello smackbot", "Hello loser")
                createPathway("You are not very bright",
                              "You are about as sharp as a  spoon")

                createPathway("how are you doing",
                              "i was doing great before you started talking")

                createPathway("do you ever talk with female bots?",
                              "i am a female bot")

                createPathway("have you spoken with a spambot",
                              "whenever a cool one comes around")

                createPathway("can i hang out with you", "hell no")

                createPathway("who are you?", "i am smackbot")

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
