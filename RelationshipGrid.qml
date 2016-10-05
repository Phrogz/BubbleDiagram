import QtQuick 2.7
import QtQuick.Controls 1.4

Item {
    id: root
    signal relationshipChanged(int index1, int index2, int rating)
    property real rowHeight: 16
    property real nameWidth: 200
    property real sizeWidth: 80
    property int  defaultRating: 1
    property var  ratingNames: ['hate','neutral','like']
    property var  ørelationships: ({})
    property var  ørooms: []
    property int highlight1: -1
    property int highlight2: -1

    height: canvas.height + rowHeight

    property real labelWidth: nameWidth + sizeWidth

    function addRoom(name,size){
        var index = ørooms.length;
        var roomDetails = { name:name||'Room '+(ørooms.length+1), size:size||300, index:index };
        ørooms.push( roomDetails );
        row.createObject(canvas,roomDetails);
        ørooms = ørooms; // Force recalculation
        if (index) for (var u=index;u--;) dot.createObject(canvas,{u:u,v:index});
        canvas.requestPaint();
    }

    Component {
        id: dot
        Image {
            property int rating: defaultRating
            property int u
            property int v
            width:  rowHeight/Math.SQRT2
            height: rowHeight/Math.SQRT2
            source: "qrc:/"+ratingNames[rating]
            x: labelWidth + (v-u)*rowHeight/2 - width/2
            y: (u+v+1)*rowHeight/2 - height/2
            MouseArea {
                anchors.fill:parent
                hoverEnabled:true
                onEntered: highlight1=u, highlight2=v
                onExited:  highlight1 = highlight2 = -1
                onClicked: {
                    rating = (rating + 1) % ratingNames.length;
                    root.relationshipChanged(u,v,rating);
                }
            }
        }
    }

    Component {
        id: row
        Item {
            opacity: ~highlight1 ? (highlight1==index || highlight2==index ? 1 : 0.2) : 1
            property string name
            property int    size
            property int    index
            width: labelWidth
            height: rowHeight
            y: index*rowHeight
            TextInput {
                id: nameEditor
                anchors { left:parent.left; verticalCenter:parent.verticalCenter }
                width:nameWidth
                text:name
                font.pixelSize:rowHeight*0.7
                onEditingFinished: focus=false
                activeFocusOnTab: true
                selectByMouse: true
            }
            TextInput {
                id: sizeEditor
                anchors { right:parent.right; verticalCenter:parent.verticalCenter }
                width:sizeWidth
                text:size
                font: nameEditor.font
                horizontalAlignment:TextInput.AlignRight
                activeFocusOnTab: true
                selectByMouse: true
            }
        }
    }

    Canvas {
        id: canvas
        anchors{ top:parent.top; horizontalCenter:parent.horizontalCenter }

        property var ctx: available ? getContext('2d') : undefined
        width: nameWidth + sizeWidth + (ørooms.length/2)*rowHeight
        height: ørooms.length * rowHeight + 1

        onPaint: {
            ctx.beginPath();
            ørooms.forEach(function(room,i){
                var y    = i*rowHeight + 0.5,
                    down = (ørooms.length - i) * rowHeight/2,
                    up   = i * rowHeight/2;
                ctx.moveTo(0,y);
                ctx.lineTo(labelWidth,y);
                ctx.lineTo(labelWidth+down, y+down);
                ctx.moveTo(labelWidth,y);
                ctx.lineTo(labelWidth+up, y-up);
            });
            var y  = ørooms.length*rowHeight + 0.5,
                up = ørooms.length*rowHeight/2;
            ctx.moveTo(0,y);
            ctx.lineTo(labelWidth,y);
            ctx.lineTo(labelWidth+up, y-up);
            ctx.stroke();
        }
    }

    Button {
        text: "Add Room"
        height: rowHeight
        anchors { horizontalCenter:parent.horizontalCenter; bottom:parent.bottom }
        onClicked: addRoom()
    }

}
