import QtQuick 2.0
import QtQuick.Controls 1.4

Row {
    property alias scale: scaleControl.value

    width:childrenRect.width;
    height:20; spacing:10
    anchors { top:parent.top; horizontalCenter:parent.horizontalCenter }

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
        width:diagram.width/5
        value: 2
        minimumValue: 0.2
        maximumValue: 6
        onValueChanged: diagram.visualScale = value
    }

    Slider {
        height:parent.height
        width:diagram.width/5
        value: 0.003
        minimumValue: 0.0001
        maximumValue: 0.01
        onValueChanged: diagram.springForce = value
    }

    Slider {
        height:parent.height
        width:diagram.width/5
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
