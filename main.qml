import QtQuick 2.7
import QtQuick.Controls 1.4
import QtQuick.Dialogs 1.1

ApplicationWindow {
    id: app
    visible: true
    width: 1200
    height: 800
    title: "Bubble Diagram"

    property string docLoc

    menuBar: MenuBar {
        Menu {
            title: "File"
            MenuItem { text:"New";   shortcut:StandardKey.New;  onTriggered:reset() }
            MenuItem { text:"Open…"; shortcut:StandardKey.Open; onTriggered:openDialog.open() }
            MenuSeparator { }
            MenuItem { text:"Save";  shortcut:StandardKey.Save; onTriggered: app.docLoc ? grid.saveTo(app.docLoc) : saveAsDialog.open() }
            MenuItem { text:"Save As…"; shortcut:StandardKey.SaveAs; onTriggered:saveAsDialog.open() }
            MenuItem { text:"Export to Image…"; shortcut:'Ctrl+Shift+E';   onTriggered:exportToImage() }
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
            MenuItem { text: controls.open ? "Hide Controls" : "Show Controls"; shortcut:"Ctrl+E"; onTriggered:controls.open = !controls.open }
            MenuItem { text: grid.open ? "Hide Relationships" : "Show Relationships"; shortcut: "Ctrl+R"; onTriggered:grid.open = !grid.open }
        }
    }

    Item {
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
            anchors{ bottom:parent.bottom; left:parent.left; bottomMargin:grid.open ? parent.width*0.02 : -grid.height; leftMargin:parent.width*0.02 }
            rowHeight: 24

            Component.onCompleted: {
                roomAdded.connect(diagram.addRoom);
                roomDeleted.connect(diagram.deleteRoom);
                relationshipChanged.connect(diagram.setRating);
            }
        }
    }

    AdvancedControls {
        id: controls
    }

    Timer {
        // Gross hack to add rooms initially
        id: defaultRooms
        running:true; interval:500;
        onTriggered: {
            grid.addRoom('My First Room',400);
            grid.addRoom('Ctrl+J for More',400);
        }
    }

    function reset(){
        docLoc = '';
        diagram.reset();
        grid.reset();
    }

    FileDialog {
        id: saveAsDialog
        title: "File to save as"
        nameFilters: ["Bubble Files (*.rooms)","All Files (*.*)"]
        selectedNameFilter: '*.rooms'
        selectExisting: false
        onAccepted: {
            grid.saveTo(fileUrl);
            docLoc = (fileUrl+"");
        }
    }

    FileDialog {
        id: openDialog
        title: "Select the file to load"
        selectExisting: true
        nameFilters: ["Bubble Files (*.rooms)","All Files (*.*)"]
        selectedNameFilter: '*.rooms'
        onAccepted: {
            grid.openFrom(fileUrl);
            app.docLoc = (fileUrl+"");
        }
    }

    function exportToImage(){
        var diagramWasPaused = diagram.paused;
        diagram.paused = true;
        exportDialog.open()
        diagram.paused = diagramWasPaused;
    }

    FileDialog {
        id: exportDialog
        selectExisting: false
        nameFilters: ["Portable Network Graphic (*.png)", "Other (*.png)"]
        selectedNameFilter: '*.png'
        onAccepted: {
            var imageUrl = (fileUrl+"").replace('file://','');
            if (!/[^/]+\.\w+$/.test(imageUrl)) urlWithoutProtocol += ".png";
            content.grabToImage(function(result){
                var success = result.saveToFile(imageUrl);
                if (!success) console.error('Unknown error saving image to',urlWithoutProtocol);
            });
        }
    }

    Component.onCompleted: {
        saveAsDialog.folder = openDialog.folder = exportDialog.folder = exportDialog.shortcuts.documents
    }
}
