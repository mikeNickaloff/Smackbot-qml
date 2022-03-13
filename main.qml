import QtQuick 2.0
import QtQuick.Controls 2.0
import "."

Window {
    width: 640
    height: 480
    visible: true
    title: qsTr("Hello World")
    Bot {
        id: bot
    }
    Item {
        id: rootItem
        anchors.fill: parent

        TextInput {
            id: input
            width: parent.width
            height: 150
        }
        TextInput {
            id: output
            width: parent.width
            height: 150
            anchors.top: input.bottom
        }
        Text {
            id: response
            text: "none"
            width: parent.width
            height: 150
            anchors.top: output.bottom
        }
        Button {
            id: addButton
            text: "Add"
            onClicked: {
                bot.addPathway(input.text, output.text)
                input.text = ""
                output.text = ""
                input.focus = true
            }
            anchors.top: response.bottom
        }
        Button {
            text: "Guess"
            onClicked: {
                response.text = bot.findResponse(input.text)
            }
            anchors.top: response.bottom
            anchors.left: addButton.right
        }
        Component.onCompleted: {

        }
    }
}
