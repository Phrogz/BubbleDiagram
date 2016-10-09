import QtQuick 2.0
import QtQuick.Controls 1.4
import QtQuick.Controls.Styles 1.4

import "springz.js" as Springz

Canvas {
    id: canvas
    property bool paused: false

    property real visualScale: scaleControl.value
    property var ønodeByIndex // FIXME: index will not be unique once deletion is allowed
    property var øspringz
    property var øcenter
    property var ctx: available ? getContext('2d') : undefined

    onVisualScaleChanged: fitToCanvas()
    onWidthChanged:  fitToCanvas()
    onHeightChanged: fitToCanvas()

    Row {
        width:childrenRect.width;
        height:20; spacing:10
        anchors { top:parent.top; horizontalCenter:parent.horizontalCenter }

        Button {
            text: paused ? '▶' : '⏸';
            height:parent.height; width:height
            onClicked: paused = !paused
            style: ButtonStyle { background: Rectangle { color:'transparent' } }
        }

        Slider {
            id: scaleControl
            height:parent.height
            width:canvas.width/5
            value: 2
            minimumValue: 0.2
            maximumValue: 6
        }

        Slider {
            height:parent.height
            width:canvas.width/5
            value: 0.003
            minimumValue: 0.0001
            maximumValue: 0.01
            onValueChanged: øspringz && (øspringz.scale=value)
        }

        Slider {
            height:parent.height
            width:canvas.width/5
            value: 0.95
            minimumValue: 0.01
            maximumValue: 0.99
            onValueChanged: øspringz && (øspringz.glide=value)
        }

        Button {
            text: '🔀'
            height:parent.height; width:height
            onClicked: shuffle()
            style: ButtonStyle { background: Rectangle { color:'transparent' } }
        }
    }

    Timer {
        interval:20; running:!paused; repeat:true
        onTriggered: {
            øspringz.simulate();
            fitToCanvas();
        }
    }

    Component.onCompleted: reset()

    function reset(){
        ønodeByIndex = {};
        øspringz = new Springz.Collection({masses:true, scale:0.003, glide:0.95});
        øcenter = øspringz.node({locked:true,radius:40,force:0.2});
    }

    function addRoom(room){
        var node = øspringz.node({ obj:room, radius:Math.sqrt(room.size), x:(Math.random()-0.5)*100, y:(Math.random()-0.5)*100 });
        ønodeByIndex[room.index] = node;
        room.sizeChanged.connect(function(){
            node.radius = Math.sqrt(room.size) * scale;
            requestPaint();
        });
        room.nameChanged.connect(requestPaint);
        if (øcenter) øspringz.connect(node,øcenter,{force:0.2});
        requestPaint();
    }

    function setRating(index1,index2,rating,ratingValue,ratingName){
        var n1 = ønodeByIndex[index1],
            n2 = ønodeByIndex[index2];

        if (!n1 || !n2) return;
        if (ratingValue==0) øspringz.disconnect(n1,n2);
        else                øspringz.connect(n1,n2,{force:ratingValue});
        requestPaint();
    }

    function fitToCanvas(){
        if (!øspringz) return;
        øspringz.fitWithin( width/2/visualScale, height/2/visualScale );
        requestPaint();
    }

    function zoomIn(){
        scaleControl.value *= 1.5;
    }

    function zoomOut(){
        scaleControl.value /= 1.5;
    }

    onPaint: {
        ctx.reset();
        ctx.clearRect(0,0,width,height);
        if (!øspringz) return;

        ctx.translate(width/2,height/2);
        ctx.scale(visualScale,visualScale);
        ctx.textAlign = 'center';
        ctx.textBaseline = 'middle';
        ctx.font = (14/visualScale).toFixed(2)+"pt sans-serif";
        ctx.lineWidth = 1/visualScale;
        øspringz.connections.forEach(drawConnection);
        ctx.strokeStyle = 'black';
        øspringz.nodes
            .sort(function(n1,n2){ return (n2.radius-n1.radius) || (n1.id-n2.id) })
            .forEach(drawNode);
    }

    function drawNode(node){
        if (!node.obj) return;
        ctx.beginPath();
        ctx.arc(node.x,node.y,node.radius,0,Math.PI*2);
        ctx.fillStyle = 'lightgray';
        ctx.fill();
        ctx.stroke();
        ctx.fillStyle = 'black';
        if (node.obj.name) fillTextMultiLine(ctx,node.obj.name,node.x,node.y);
    }

    function drawConnection(c){
        if (!c.node1.obj || !c.node2.obj) return;
        ctx.beginPath();
        ctx.moveTo(c.node1.x,c.node1.y);
        ctx.lineTo(c.node2.x,c.node2.y);
        ctx.strokeStyle = (c.force < 0) ? 'rgba(255,0,0,0.1)' : 'green';
        ctx.stroke();
    }

    function fillTextMultiLine(ctx, text, x, y) {
      var lineHeight = ctx.measureText("M").width * 1.2;
      var lines = text.split(" ");
      for (var i=0; i<lines.length; ++i)
        ctx.fillText(lines[i], x, y - (lines.length-1)*lineHeight/2 + lineHeight*i );
    }

    function shuffle(){
        øspringz.nodes.forEach(function(n){
            if (n==øcenter) return;
            n.x = (Math.random()-0.5) * width/visualScale;
            n.y = (Math.random()-0.5) * height/visualScale;
        })
    }
}
