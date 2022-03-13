import QtQuick 2.0
import "."

Item {
    id: bot
    property alias brain: brainObj
    Brain {
        id: brainObj
    }
    function findResponse(input) {
        return brainObj.network.findBestResponse(input)
    }
    function addPathway(input, output) {
        brainObj.createPathway(input, output)
        console.log(JSON.stringify(brainObj.network.serialize()))
    }
}
