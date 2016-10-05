import QtQuick 2.7
import QtQuick.Window 2.2

Window {
    visible: true
    width: 640
    height: 480
    title: "Bubble Diagram"

    RelationshipGrid {
        width: parent.width
        anchors{ bottom:parent.bottom; bottomMargin:10 }
        rowHeight: 32
    }
}
