import QtQuick 2.0
import QtQuick.Controls 1.4

import "springz.js" as Springz

Canvas {
    id: canvas
    property bool paused: false
    property real visualScale: 1
    property real springForce: 0.003
    property real glideFactor: 0.95

    property var ønodeById
    property var øspringz
    property var øcenter
    property var ctx: available ? getContext('2d') : undefined
    property var øoverNode
    property var ødragOffset

    signal hoverNode(int nodeId)

    onVisualScaleChanged: fitToCanvas()
    onSpringForceChanged: if (øspringz) øspringz.scale = springForce
    onGlideFactorChanged: if (øspringz) øspringz.glide = glideFactor
    onWidthChanged:  fitToCanvas()
    onHeightChanged: fitToCanvas()

    Timer {
        interval:1000/30; running:!paused; repeat:true
        onTriggered: {
            øspringz.simulate();
            fitToCanvas();
        }
    }

    Component.onCompleted: reset()

    MouseArea {
        property real canX
        property real canY
        anchors.fill: parent
        hoverEnabled: true
        onPositionChanged: {
            canX = (mouseX - canvas.width/2)  / visualScale;
            canY = (mouseY - canvas.height/2) / visualScale;
            if (ødragOffset){
                øoverNode.x = ødragOffset.x + canX;
                øoverNode.y = ødragOffset.y + canY;
            } else øoverNode = øspringz.nodeAt(canX, canY);
            if (paused) requestPaint();
        }
        onPressed: {
            if (øoverNode){
                øoverNode.locked = true;
                ødragOffset = { x:øoverNode.x-canX, y:øoverNode.y-canY };
            }
            if (paused) requestPaint();
        }
        onDoubleClicked: {
            if (øoverNode) øoverNode.locked = false;
            if (paused) requestPaint();
        }
        onReleased: ødragOffset = null;
    }

    function reset(){
        ønodeById = {};
        øspringz = new Springz.Collection({masses:true, scale:springForce, glide:glideFactor});
        øcenter = øspringz.node({locked:true,radius:40,force:0.2});
    }

    function addRoom(room){
        var node = øspringz.node({ obj:room, radius:Math.sqrt(room.size), x:(Math.random()-0.5)*100, y:(Math.random()-0.5)*100 });
        ønodeById[room.rId] = node;
        room.sizeChanged.connect(function(){
            node.radius = Math.sqrt(room.size) * scale;
            requestPaint();
        });
        room.nameChanged.connect(requestPaint);
        if (øcenter) øspringz.connect(node,øcenter,{force:0.2});
        requestPaint();
    }

    function deleteRoom(room){
        øspringz.removeNode(ønodeById[room.rId]);
        requestPaint();
    }

    function setRating(id1,id2,rating,ratingValue,ratingName){
        var n1 = ønodeById[id1],
            n2 = ønodeById[id2];

        if (!n1 || !n2) return;
        if (ratingValue===0) øspringz.disconnect(n1,n2);
        else                 øspringz.connect(n1,n2,{force:ratingValue});
        requestPaint();
    }

    function fitToCanvas(){
        if (!øspringz) return;
        øspringz.fitWithin( width/2/visualScale, height/2/visualScale );
        requestPaint();
    }

    function zoomIn(){
        controls.scale *= 1.5;
    }

    function zoomOut(){
        controls.scale /= 1.5;
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
        øspringz.nodes
            .sort(function(n1,n2){ return (n2.radius-n1.radius) || (n1.id-n2.id) })
            .forEach(drawNode);
    }

    function drawNode(node){
        if (!node.obj) return;
        ctx.beginPath();
        ctx.arc(node.x,node.y,node.radius,0,Math.PI*2);
        ctx.fillStyle = (node==øoverNode) ? 'white' : 'lightgray';
        ctx.fill();
        ctx.strokeStyle = node.locked ? 'red' : 'black';
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
            if (n==øcenter || n.locked) return;
            n.x = (Math.random()-0.5) * width/visualScale;
            n.y = (Math.random()-0.5) * height/visualScale;
        })
    }
}
