import QtQuick
import M3Shapes
Item {
    id: root
    property int variant: 0
    property color color: Theme.primary
    property real turn: 0
    MaterialShape {
        anchors.fill: parent
        visible: GraphicsInfo.api !== GraphicsInfo.Software
        shape: root.variant === 0 ? MaterialShape.Cookie6Sided : root.variant === 1 ? MaterialShape.Clover4Leaf : root.variant === 2 ? MaterialShape.Sunny : MaterialShape.Flower
        color: root.color; rotation: root.turn
        animationDuration: 350
    }
    Canvas {
        id: fallback; anchors.fill: parent
        visible: GraphicsInfo.api === GraphicsInfo.Software
        rotation: root.turn
        Connections { target: root; function onColorChanged() { fallback.requestPaint() } function onVariantChanged() { fallback.requestPaint() } }
        onWidthChanged: requestPaint(); onHeightChanged: requestPaint()
        onPaint: {
            const c=getContext("2d"); c.reset();c.fillStyle=root.color;c.beginPath()
            const lobes=[6,4,12,8][root.variant % 4], depth=[0.08,0.24,0.13,0.22][root.variant % 4]
            for(let i=0;i<=240;i++){const a=i/240*Math.PI*2;const r=Math.min(width,height)*0.47*(1-depth+depth*Math.cos(lobes*a));const x=width/2+r*Math.cos(a),y=height/2+r*Math.sin(a);if(i===0)c.moveTo(x,y);else c.lineTo(x,y)}
            c.closePath();c.fill()
        }
    }
}
