import QtQuick 2.0
import "."

Item {
    property var nodes: []
    property string pathwayId
    property var responseId
    property var inputId
    function serialize() {
        console.log("serialized pathway", pathwayId, nodes, inputId, responseId)
        return {
            "type": "pathway",
            "pathwayId": pathwayId,
            "nodes": nodes,
            "responseId": responseId,
            "inputId": inputId
        }
    }
    function addNode(nodeId) {
        //        var obj = {
        //            "nodeId": nodeId,
        //            "index": nodes.length
        //        }
        nodes.push(nodeId)
    }
}
