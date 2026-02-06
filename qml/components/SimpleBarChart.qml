import QtQuick 2.15

Canvas {
    id: chart

    property var data: []  // [{label: "", values: [v1, v2]}]
    property var colors: [Style.primary, Style.primaryLight]
    property int barWidth: 36
    property int barSpacing: 6
    property int groupSpacing: 24

    onDataChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        var ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);

        if (data.length === 0) return;

        var maxVal = 0;
        for (var i = 0; i < data.length; i++) {
            for (var j = 0; j < data[i].values.length; j++) {
                maxVal = Math.max(maxVal, data[i].values[j]);
            }
        }
        if (maxVal === 0) maxVal = 1;

        var padding = { top: 10, bottom: 40, left: 40, right: 20 };
        var chartW = width - padding.left - padding.right;
        var chartH = height - padding.top - padding.bottom;
        var numGroups = data.length;
        var barsPerGroup = data[0].values.length;
        var groupW = (barsPerGroup * barWidth) + ((barsPerGroup - 1) * barSpacing);
        var totalW = numGroups * groupW + (numGroups - 1) * groupSpacing;
        var startX = padding.left + (chartW - totalW) / 2;

        // Grid lines
        ctx.strokeStyle = "#F1F5F9";
        ctx.lineWidth = 1;
        for (var g = 0; g <= 4; g++) {
            var y = padding.top + (chartH / 4) * g;
            ctx.beginPath();
            ctx.setLineDash([4, 4]);
            ctx.moveTo(padding.left, y);
            ctx.lineTo(width - padding.right, y);
            ctx.stroke();

            // Y axis labels
            ctx.setLineDash([]);
            ctx.fillStyle = "#94A3B8";
            ctx.font = "11px sans-serif";
            ctx.textAlign = "right";
            var val = Math.round(maxVal - (maxVal / 4) * g);
            ctx.fillText(val.toString(), padding.left - 8, y + 4);
        }

        // Bars
        for (var gi = 0; gi < numGroups; gi++) {
            var groupX = startX + gi * (groupW + groupSpacing);

            for (var bi = 0; bi < barsPerGroup; bi++) {
                var barX = groupX + bi * (barWidth + barSpacing);
                var barH = (data[gi].values[bi] / maxVal) * chartH;
                var barY = padding.top + chartH - barH;

                ctx.fillStyle = colors[bi % colors.length];
                // Rounded top
                var r = 6;
                ctx.beginPath();
                ctx.moveTo(barX, barY + r);
                ctx.arcTo(barX, barY, barX + r, barY, r);
                ctx.arcTo(barX + barWidth, barY, barX + barWidth, barY + r, r);
                ctx.lineTo(barX + barWidth, padding.top + chartH);
                ctx.lineTo(barX, padding.top + chartH);
                ctx.closePath();
                ctx.fill();
            }

            // X label
            ctx.fillStyle = "#94A3B8";
            ctx.font = "11px sans-serif";
            ctx.textAlign = "center";
            ctx.fillText(data[gi].label, groupX + groupW / 2, height - 10);
        }
    }
}
