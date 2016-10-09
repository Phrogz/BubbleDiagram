import QtQuick 2.7
import QtQuick.Controls 1.4
import QtQuick.Dialogs 1.1

ApplicationWindow {
    visible: true
    width: 1200
    height: 800
    title: "Bubble Diagram"

    menuBar: MenuBar {
        Menu {
            title: "File"
            MenuItem { text:"New";   shortcut:StandardKey.New;     onTriggered:reset() }
            MenuItem { text:"Open…"; shortcut: StandardKey.Open;   onTriggered:openFile() }
            MenuSeparator { }
            MenuItem { text:"Save"; shortcut:StandardKey.Save;     onTriggered:save() }
            MenuItem { text:"Export to Image…"; shortcut:'Ctrl+E'; onTriggered:exportDialog.open() }
        }
        Menu {
            title: "Edit"
            MenuItem { text: "Undo"; shortcut: StandardKey.Undo }
            MenuSeparator { }
            MenuItem { text: "Cut"; shortcut: StandardKey.Cut }
            MenuItem { text: "Copy"; shortcut: StandardKey.Copy }
            MenuItem { text: "Paste"; shortcut: StandardKey.Paste }
            MenuSeparator { }
            MenuItem { text: "Select All"; shortcut: StandardKey.SelectAll }
        }
        Menu {
            title: "Diagram"
            MenuItem { text: "Add Room"; shortcut: "Ctrl+J"; onTriggered:grid.addRoom() }
            MenuItem { text: diagram.paused ? "Resume Layout" : "Pause Layout"; shortcut: "Ctrl+T"; onTriggered:diagram.paused = !diagram.paused }
            MenuItem { text: "Shuffle Layout"; shortcut: "Ctrl+Y"; onTriggered:diagram.shuffle() }
            MenuSeparator { }
            MenuItem { text: "Zoom Out"; shortcut: "Ctrl+-"; onTriggered:diagram.zoomOut() }
            MenuItem { text: "Zoom In";  shortcut: "Ctrl+="; onTriggered:diagram.zoomIn()  }
            MenuSeparator { }
            MenuItem { text: grid.visible ? "Hide Relationships" : "Show Relationships"; shortcut: "Ctrl+R"; onTriggered:grid.visible = !grid.visible }
        }
    }

    Image {
        id: content
        anchors.fill:parent
        Image {
            source: "qrc:/images/logo"
            width:parent.width*0.15; height:width
            opacity: 0.1
            anchors { bottom:parent.bottom; right:parent.right; margins:parent.width*0.02 }
        }

        Diagram {
            id: diagram
            anchors.fill:parent
        }

        RelationshipGrid {
            id: grid
            anchors{ bottom:parent.bottom; left:parent.left; margins:10 }
            rowHeight: 24

            Component.onCompleted: {
                roomAdded.connect(diagram.addRoom);
                relationshipChanged.connect(diagram.setRating);
            }
        }
    }


//    FileDialog {
//        id: saveDialog
//        folder: shortcuts.documents
//        selectExisting: false
//        onAccepted: grid.saveTo(fileUrl)
//    }

    Timer {
        id: defaultRooms
        running:true; interval:500;
        onTriggered: {
            grid.addRoom('My First Room',400);
            grid.addRoom('Ctrl+J for More',400);
        }
    }

    function reset(){
        diagram.reset();
        grid.reset();
    }

    function save(){
        // saveDialog.open();
        grid.saveTo();
    }

    function openFile(){
        var json = '{"rooms":[{"name":"Living Room","size":"1000"},{"name":"Dining Room","size":"500"},{"name":"Kitchen","size":"400"},{"name":"Powder Room","size":"40"},{"name":"Master Bedroom","size":"400"},{"name":"Media Room","size":"500"},{"name":"Office","size":"150"},{"name":"Master Bath","size":"60"},{"name":"Garage","size":"1200"},{"name":"Entry","size":"30"},{"name":"Deck","size":"500"},{"name":"Guest Bedroom","size":"300"},{"name":"Guest Bath","size":"300"}],"relationships":{"0,1":3,"1,2":3,"0,2":1,"2,3":3,"1,3":3,"0,4":0,"4,5":0,"0,5":3,"5,6":0,"3,6":3,"0,6":1,"6,7":1,"5,7":1,"4,7":4,"3,7":1,"2,7":1,"1,7":1,"0,7":1,"7,8":1,"4,8":1,"8,9":4,"7,9":1,"2,9":3,"1,9":3,"0,9":3,"9,10":1,"8,10":0,"7,10":1,"1,10":3,"0,10":3,"4,11":0,"11,12":4}}';
        reset();
        grid.loadFrom(JSON.parse(json));
    }

    FileDialog {
        id: exportDialog
        folder: shortcuts.documents
        selectExisting: false
        onAccepted: {
            var urlWithoutProtocol = fileUrl.toString().replace('file://','');
            if (!/[^/]+\.\w+$/.test(urlWithoutProtocol))
              urlWithoutProtocol += ".png";
            var diagramWasPaused = diagram.paused;
            diagram.paused = true;
            content.grabToImage(function(result){
                if (!result.saveToFile(urlWithoutProtocol)) console.error('Unknown error saving image to',urlWithoutProtocol);
                diagram.paused = diagramWasPaused;
            });
        }
    }
}
