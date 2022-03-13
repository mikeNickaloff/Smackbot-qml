import QtQuick 2.0
import "."

Item {
    property alias network: net
    Network {
        id: net
    }
    function createPathway(input, output) {
        net.createPathway(input, output)
    }
    function serialize() {
        return net.serialize()
    }
}
