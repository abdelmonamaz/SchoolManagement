import QtQuick

Canvas {
    id: chart

    property var data: []  // [{label: "", value: number}]
    property color lineColor: Style.primary
    property color fillColor: Style.primary

    onDataChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        var ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);

        if (data.length < 2) return;

        var maxVal = 0;
        for (var i = 0; i < data.length; i++) {
            maxVal = Math.max(maxVal, data[i].value);
        }
        if (maxVal === 0) maxVal = 1;

        var padding = { top: 10, bottom: 30, left: 10, right: 10 };
        var chartW = width - padding.left - padding.right;
        var chartH = height - padding.top - padding.bottom;

        var points = [];
        for (var j = 0; j < data.length; j++) {
            var px = padding.left + (j / (data.length - 1)) * chartW;
            var py = padding.top + chartH - (data[j].value / maxVal) * chartH;
            points.push({x: px, y: py});
        }

        // Gradient fill
        var gradient = ctx.createLinearGradient(0, padding.top, 0, height - padding.bottom);
        gradient.addColorStop(0, Qt.rgba(fillColor.r, fillColor.g, fillColor.b, 0.12));
        gradient.addColorStop(1, Qt.rgba(fillColor.r, fillColor.g, fillColor.b, 0.0));

        ctx.beginPath();
        ctx.moveTo(points[0].x, points[0].y);
        for (var k = 1; k < points.length; k++) {
            var xc = (points[k - 1].x + points[k].x) / 2;
            var yc = (points[k - 1].y + points[k].y) / 2;
            ctx.quadraticCurveTo(points[k - 1].x, points[k - 1].y, xc, yc);
        }
        ctx.quadraticCurveTo(points[points.length - 1].x, points[points.length - 1].y,
                             points[points.length - 1].x, points[points.length - 1].y);
        ctx.lineTo(points[points.length - 1].x, height - padding.bottom);
        ctx.lineTo(points[0].x, height - padding.bottom);
        ctx.closePath();
        ctx.fillStyle = gradient;
        ctx.fill();

        // Line
        ctx.beginPath();
        ctx.moveTo(points[0].x, points[0].y);
        for (var m = 1; m < points.length; m++) {
            var xc2 = (points[m - 1].x + points[m].x) / 2;
            var yc2 = (points[m - 1].y + points[m].y) / 2;
            ctx.quadraticCurveTo(points[m - 1].x, points[m - 1].y, xc2, yc2);
        }
        ctx.quadraticCurveTo(points[points.length - 1].x, points[points.length - 1].y,
                             points[points.length - 1].x, points[points.length - 1].y);
        ctx.strokeStyle = lineColor;
        ctx.lineWidth = 3;
        ctx.stroke();

        // X labels
        ctx.fillStyle = Style.textSecondary;
        ctx.font = "11px sans-serif";
        ctx.textAlign = "center";
        for (var n = 0; n < data.length; n++) {
            var lx = padding.left + (n / (data.length - 1)) * chartW;
            ctx.fillText(data[n].label, lx, height - 6);
        }
    }
}
