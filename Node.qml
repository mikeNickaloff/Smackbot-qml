import QtQuick 2.0

Item {
    property var data
    property var references: []
    property var nodeId
    function serialize() {
        console.log("serialized node", nodeId, data)
        return {
            "type": "node",
            "data": data,
            "nodeId": nodeId
        }
    }
}
