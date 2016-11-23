import QtQuick 2.0
import QtQuick.Controls 1.4

Rectangle {
    id: root
    property bool open: false
    property alias scale: scaleControl.value

    anchors { top:parent.top; right:parent.right; topMargin:open ? -5 : -height; rightMargin:app.width*0.02 }
    color: '#dedede'
    border { color:'#cccccc'; width:2 }
    height:40; width:controls.width + 30
    radius: 5

    Image {
        anchors { top:parent.bottom; right:parent.right; topMargin:-2; rightMargin:app.width*0.02 }
        source:'qrc:/images/tab.png'
        transform: Rotation { origin.x:64; origin.y:16; angle:180 }
        MouseArea {
            anchors.fill:parent
            cursorShape:Qt.PointingHandCursor
            onClicked: open = !open
        }
    }

    Row {
        id: controls

        width:childrenRect.width;
        height:20; spacing:10
        anchors.centerIn:parent
        property real øsliderWidth: diagram.width/4

        Text {
            text: diagram.paused ? '▶' : '⏸';
            height:parent.height; width:height
            MouseArea {
                anchors.fill: parent
                onClicked: diagram.paused = !diagram.paused
            }
        }

        Slider {
            id: scaleControl
            height:parent.height
            width:controls.øsliderWidth
            value: 2
            minimumValue: 0.2
            maximumValue: 6
            onValueChanged: diagram.visualScale = value
        }

        Slider {
            height:parent.height
            width:controls.øsliderWidth
            value: 0.003
            minimumValue: 0.0001
            maximumValue: 0.01
            onValueChanged: diagram.springForce = value
        }

        Slider {
            height:parent.height
            width:controls.øsliderWidth
            value: 0.95
            minimumValue: 0.01
            maximumValue: 0.99
            onValueChanged: diagram.glideFactor = value
        }

        Text {
            text: '🔀'
            height:parent.height; width:height
            MouseArea {
                anchors.fill: parent
                onClicked: diagram.shuffle()
            }
        }
    }
}

