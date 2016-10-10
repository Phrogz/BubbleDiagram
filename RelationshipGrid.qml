import QtQuick 2.7
import QtQuick.Controls 1.4

Item {
    id: root
    signal relationshipChanged(int index1, int index2, int ratingIndex, var ratingValue, string ratingName)
    signal roomAdded(var room)

    property real rowHeight: 16
    property real nameWidth: 200
    property real sizeWidth: 80
    property int  defaultRating: 2
    property var  ratingNames:  ['hate','bleh','zero','like','love']
    property var  ratingValues: [-100,-50,0,1,9]
    property var  ørooms: []
    property var  ødots:  ({})
    property int highlight1: -1
    property int highlight2: -1

    height: canvas.height

    property real labelWidth: nameWidth + sizeWidth

    function addRoom(name,size){
        var index = ørooms.length;
        var r = room.createObject(canvas,{
          name: name||'Room '+(index+1),
          size: size||300,
          index:index
        });
        r.focusName();
        ørooms.push(r);
        ørooms = ørooms; //force recalculation of dependents
        roomAdded(r);
        if (index){
            for (var u=index;u--;) {
                var d = dot.createObject(canvas,{u:u,v:index});
                ødots[[u,index]] = d;
            }
        }
        canvas.requestPaint();
    }

    function setRelationship( u, v, rating ){
        ødots[[u,v]].rating = rating;
    }

    function reset(){
        ørooms.forEach(function(r){ r.destroy() });
        ørooms.length=0;
        ørooms = ørooms;
        for (var uv in ødots){
            var d = ødots[uv];
            d.visible = false;
            d.destroy();
        }
        ødots = {};
        canvas.requestPaint();
    }

    function saveTo(fileUrl){
        var json = {};
        json.rooms = ørooms.map(function(r){ return { name:r.name, size:r.size } });
        json.relationships = {};
        for (var uv in ødots) if (ødots[uv].rating!=defaultRating) json.relationships[uv]=ødots[uv].rating;
        json = JSON.stringify(json);

        // Saved filenames should have a .rooms extension
        fileUrl = (fileUrl+"").replace(/([^\/\\.]+(\.[^\/\\.]*)?$/,'$1.rooms');
        var request = new XMLHttpRequest();
        request.open("PUT", fileUrl, false);
        request.send(json);
    }

    function openFrom(fileUrl){
        var request = new XMLHttpRequest();
        request.open("GET", fileUrl, false);
        request.send(null);
        var json = request.responseText;
        try {
            var jsObject = JSON.parse(json);
            if (jsObject.rooms && jsObject.relationships){
                app.reset();
                jsObject.rooms.forEach(function(r){ addRoom(r.name,r.size) });
                for (var uv in jsObject.relationships){
                    var rating = jsObject.relationships[uv];
                    uv = uv.split(',');
                    setRelationship(uv[0],uv[1],rating);
                }
            } else console.error("Could not load",fileUrl,json);
        } catch(e){ console.log(e) }

        root.forceActiveFocus();
    }

    Component {
        id: dot
        Image {
            opacity: {
                var highlighted=true;
                if (~highlight1){
                    if (~highlight2) // over specific dot
                        highlighted = (highlight1==u && v<=highlight2) || (highlight2==v && u>=highlight1);
                    else // over specific room row
                        highlighted = highlight1==u || highlight1==v || highlight2==u || highlight2==v;
                }
                return highlighted ? 1 : 0.2;
            }
            property int rating: defaultRating
            property int u
            property int v
            width:  rowHeight/Math.SQRT2
            height: rowHeight/Math.SQRT2
            source: "qrc:/images/"+ratingNames[rating]
            x: labelWidth + (v-u)*rowHeight/2 - width/2
            y: (u+v+1)*rowHeight/2 - height/2
            MouseArea {
                anchors.fill:parent
                hoverEnabled:true
                onEntered: highlight1=u, highlight2=v
                onExited:  highlight1 = highlight2 = -1
                onClicked: {
                    root.forceActiveFocus();
                    rating = (rating + 1) % ratingNames.length;
                }
            }
            onRatingChanged: root.relationshipChanged(u,v,rating,root.ratingValues[rating],root.ratingNames[rating]);
        }
    }

    Component {
        id: room
        Item {
            opacity: ~highlight1 ? (highlight1==index || highlight2==index ? 1 : 0.2) : 1
            property alias name: nameEditor.text
            property alias size: sizeEditor.text
            property int   index

            function focusName(){
                nameEditor.forceActiveFocus();
                nameEditor.selectAll();
            }

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
                onFocusChanged: if (focus) selectAll();
                selectByMouse: true
                Rectangle { anchors.fill:parent; color:'white'; opacity:0.5; z:-1 }
            }
            TextInput {
                id: sizeEditor
                anchors { right:parent.right; verticalCenter:parent.verticalCenter }
                width:sizeWidth
                text:size
                font: nameEditor.font
                horizontalAlignment:TextInput.AlignRight
                activeFocusOnTab: true
                onFocusChanged: if (focus) selectAll();
                selectByMouse: true
                Rectangle { anchors.fill:parent; color:'white'; opacity:0.5; z:-1 }
            }
            MouseArea {
                anchors.fill:parent
                hoverEnabled:true
                onEntered:highlight1=index
                onExited: highlight1=-1
                z:-1
            }
        }
    }

    Canvas {
        id: canvas
        anchors{ top:parent.top; left:parent.left }

        property var ctx: available ? getContext('2d') : undefined
        width: nameWidth + sizeWidth + (ørooms.length/2)*rowHeight
        height: ørooms.length * rowHeight + 1

        onPaint: {
            ctx.clearRect(0,0,width,height);
            ctx.beginPath();
            for (var i=ørooms.length;i--;){
                var y    = i*rowHeight + 0.5,
                    down = (ørooms.length - i) * rowHeight/2,
                    up   = i * rowHeight/2;
                ctx.moveTo(0,y);
                ctx.lineTo(labelWidth,y);
                ctx.lineTo(labelWidth+down, y+down);
                ctx.moveTo(labelWidth,y);
                ctx.lineTo(labelWidth+up, y-up);
            }
            var y  = ørooms.length*rowHeight + 0.5,
                up = ørooms.length*rowHeight/2;
            ctx.moveTo(0,y);
            ctx.lineTo(labelWidth,y);
            ctx.lineTo(labelWidth+up, y-up);
            ctx.stroke();
        }
    }
}
