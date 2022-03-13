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
        Rectangle {
            border.color: "black"
            width: parent.width
            height: 150
            id: inputBox
            TextInput {

                id: input
                anchors.centerIn: inputBox
                onTextChanged: {
                    response.text = bot.findResponse(input.text)
                    if (response.text == "I dont know") {

                        output.enabled = true
                    }
                }
                text: "Enter your message here"
                onFocusChanged: {
                    if (input.focus == true) {
                        if (input.text == "Enter your message here") {
                            input.text = ""
                        }
                    }
                }
            }
        }
        Rectangle {
            border.color: "black"
            width: parent.width
            height: 150
            anchors.top: inputBox.bottom
            id: outputBox
            TextInput {
                id: output
                width: parent.width
                height: outputBox.height * 0.95
                anchors.centerIn: outputBox
                text: "Enter your response here"
                onTextChanged: {
                    if (output.text.length > 0) {
                        addButton.enabled = true
                    } else {
                        addButton.enabled = false
                    }
                }
                onFocusChanged: {
                    if (output.focus == true) {
                        if (output.text == "Enter your response here") {
                            output.text = ""
                        }
                    }
                }
            }
        }
        Text {
            id: response
            text: "none"
            width: parent.width
            height: 150
            anchors.top: outputBox.bottom
        }
        Rectangle {
            border.color: "black"
            width: parent.width
            height: 50
            id: buttonBox
            anchors.top: response.bottom

            Button {
                id: addButton
                text: "Add"
                onClicked: {
                    bot.addPathway(input.text, output.text)
                    input.text = ""
                    output.text = ""
                    input.focus = true
                }
                anchors.centerIn: ButtonBox
            }
            Button {
                id: guessButton
                text: "Guess"
                onClicked: {
                    response.text = bot.findResponse(input.text)
                }
                anchors.centerIn: buttonBox
                anchors.left: addButton.right
            }
        }
        Component.onCompleted: {

        }
    }
}
