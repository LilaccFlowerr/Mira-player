import QtQuick
Canvas {
    id: icon
    property string name: "music"
    property color color: Theme.text
    implicitWidth: 22; implicitHeight: 22
    onNameChanged: requestPaint()
    onColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onPaint: {
        const c = getContext("2d"); c.reset(); c.scale(width / 24, height / 24)
        c.strokeStyle = color; c.fillStyle = color; c.lineWidth = 1.8; c.lineCap = "round"; c.lineJoin = "round"
        function line(points) { c.beginPath(); c.moveTo(points[0],points[1]); for(let i=2;i<points.length;i+=2)c.lineTo(points[i],points[i+1]); c.stroke() }
        function circle(x,y,r,fill) { c.beginPath(); c.arc(x,y,r,0,Math.PI*2); fill?c.fill():c.stroke() }
        switch(name) {
        case "home": line([3,11,12,3,21,11]);line([5,10,5,21,10,21,10,15,14,15,14,21,19,21,19,10]);break
        case "search": circle(10.5,10.5,6.5,false);line([15.5,15.5,21,21]);break
        case "library": line([4,4,4,20]);line([9,4,9,20]);line([14,5,18,4,22,19,18,20,14,5]);break
        case "heart": c.beginPath();c.moveTo(12,21);c.bezierCurveTo(-6,10,4,-2,12,7);c.bezierCurveTo(20,-2,30,10,12,21);c.stroke();break
        case "play": c.beginPath();c.moveTo(8,4);c.lineTo(20,12);c.lineTo(8,20);c.closePath();c.fill();break
        case "pause": c.fillRect(6,5,4,14);c.fillRect(14,5,4,14);break
        case "next": c.beginPath();c.moveTo(5,5);c.lineTo(16,12);c.lineTo(5,19);c.closePath();c.fill();line([19,5,19,19]);break
        case "previous": c.beginPath();c.moveTo(19,5);c.lineTo(8,12);c.lineTo(19,19);c.closePath();c.fill();line([5,5,5,19]);break
        case "arrow": line([5,12,19,12]);line([13,6,19,12,13,18]);break
        case "back": line([15,5,8,12,15,19]);break
        case "plus": line([12,5,12,19]);line([5,12,19,12]);break
        case "check": line([5,12,10,17,20,6]);break
        case "close": line([6,6,18,18]);line([18,6,6,18]);break
        case "external": line([14,4,21,4,21,11]);line([21,4,11,14]);line([10,5,4,5,4,20,19,20,19,14]);break
        case "device": line([3,4,21,4,21,16,3,16,3,4]);line([12,16,12,21]);line([8,21,16,21]);break
        case "volume": line([4,10,8,10,13,5,13,19,8,14,4,14,4,10]);c.beginPath();c.arc(13,12,7,-0.85,0.85);c.stroke();break
        case "refresh": c.beginPath();c.arc(12,12,8,0.5,5.4);c.stroke();line([19,3,19,8,14,8]);break
        case "sun": circle(12,12,4,false);for(let i=0;i<8;i++){let a=i*Math.PI/4;line([12+8*Math.cos(a),12+8*Math.sin(a),12+10*Math.cos(a),12+10*Math.sin(a)])}break
        case "moon": c.beginPath();c.arc(12,12,9,-1.2,1.8);c.bezierCurveTo(0,20,0,4,11,3);c.bezierCurveTo(5,12,14,17,20,9);c.stroke();break
        case "settings": circle(12,12,4,false);for(let i=0;i<8;i++){let a=i*Math.PI/4;line([12+8*Math.cos(a),12+8*Math.sin(a),12+10*Math.cos(a),12+10*Math.sin(a)])}circle(12,12,8,false);break
        case "timer": circle(12,13,8,false);line([9,2,15,2]);line([12,8,12,13,15,15]);break
        case "grid": for(let x=4;x<18;x+=10)for(let y=4;y<18;y+=10)c.strokeRect(x,y,6,6);break
        case "list": for(let y=6;y<=18;y+=6){circle(4,y,1,true);line([9,y,21,y])}break
        case "more": circle(5,12,1.5,true);circle(12,12,1.5,true);circle(19,12,1.5,true);break
        case "shuffle": line([3,7,7,7,15,17,21,17]);line([18,14,21,17,18,20]);line([3,17,7,17,9.5,14]);line([12.5,10,15,7,21,7]);line([18,4,21,7,18,10]);break
        case "repeat": line([4,12,4,8,6,6,20,6]);line([17,3,20,6,17,9]);line([20,12,20,16,18,18,4,18]);line([7,15,4,18,7,21]);break
        case "repeatOne": line([4,12,4,8,6,6,20,6]);line([17,3,20,6,17,9]);line([20,12,20,16,18,18,4,18]);line([7,15,4,18,7,21]);line([10.5,10.5,12,9.5,12,14.5]);break
        case "mute": line([4,10,8,10,13,5,13,19,8,14,4,14,4,10]);line([16,9,22,15]);line([22,9,16,15]);break
        case "bars": c.fillRect(4.5,10,3,10);c.fillRect(10.5,4,3,16);c.fillRect(16.5,13,3,7);break
        default: line([9,17,9,5,19,3,19,15]);circle(6,18,3,true);circle(16,16,3,true)
        }
    }
}
