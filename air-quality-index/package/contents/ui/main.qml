// SPDX-FileCopyrightText: 2026 besoeasy
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    preferredRepresentation: plasmoid.formFactor === PlasmaCore.Types.Planar ? fullRepresentation : compactRepresentation

    // ----- Settings (see contents/config/main.xml) -------------------------
    property real latitude: isNaN(Number(plasmoid.configuration.latitude)) ? 52.52 : Number(plasmoid.configuration.latitude)
    property real longitude: isNaN(Number(plasmoid.configuration.longitude)) ? 13.41 : Number(plasmoid.configuration.longitude)
    property int refreshMinutes: plasmoid.configuration.refreshMinutes || 30

    // ----- State -----------------------------------------------------------
    property int aqi: 0
    property bool hasData: false
    property string categoryText: ""
    property real pm25: 0
    property real pm10: 0
    property real ozone: 0
    property real no2: 0
    property real so2: 0
    property real co: 0
    property string lastUpdatedText: ""
    property string errorString: ""
    property bool loading: false

    // ----- Material shape scale (desktop-unit multiples, never fixed px) ---
    readonly property int cardRadius: Math.round(Kirigami.Units.gridUnit * 1.35)
    readonly property int badgeRadius: Math.round(Kirigami.Units.gridUnit * 0.65)
    readonly property int displaySize: Math.round(Kirigami.Theme.defaultFont.pointSize * 2.6)
    readonly property int hairline: Math.max(1, Math.round(Kirigami.Units.devicePixelRatio))
    // Material 3 elevation, level 1 - desktop-unit multiples, never fixed px
    readonly property int shadowBlur: Kirigami.Units.gridUnit * 3
    readonly property int shadowOffsetY: Math.round(Kirigami.Units.gridUnit * 0.3)
    readonly property int shadowBleed: Math.round(Kirigami.Units.gridUnit * 1.2)
    readonly property real shadowOpacity: 0.22

    readonly property color aqiColor: {
        if (!root.hasData) {
            return Kirigami.Theme.neutralTextColor;
        }
        if (root.aqi <= 50) {
            return Kirigami.Theme.positiveTextColor;
        }
        if (root.aqi <= 100) {
            return Kirigami.Theme.highlightColor;
        }
        return Kirigami.Theme.negativeTextColor;
    }

    toolTipMainText: root.hasData ? ("AQI " + root.aqi + " · " + root.categoryText) : "Air quality"
    toolTipSubText: root.lastUpdatedText !== "" ? ("Updated " + root.lastUpdatedText) : "Air Quality Index"

    function categoryFor(aqi: int): string {
        if (aqi <= 50) {
            return "Good";
        }
        if (aqi <= 100) {
            return "Moderate";
        }
        if (aqi <= 150) {
            return "Unhealthy for sensitive groups";
        }
        if (aqi <= 200) {
            return "Unhealthy";
        }
        if (aqi <= 300) {
            return "Very unhealthy";
        }
        return "Hazardous";
    }

    function fmt(v: real): string {
        return Number(v).toLocaleString(Qt.locale(), "f", 1);
    }

    function refresh(): void {
        if (root.loading) {
            return;
        }
        root.loading = true;
        root.errorString = "";

        var url = "https://air-quality-api.open-meteo.com/v1/air-quality"
            + "?latitude=" + root.latitude
            + "&longitude=" + root.longitude
            + "&current=us_aqi,pm10,pm2_5,ozone,nitrogen_dioxide,sulphur_dioxide,carbon_monoxide"
            + "&timezone=auto";

        var xhr = new XMLHttpRequest();
        xhr.open("GET", url);
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE) {
                return;
            }
            root.loading = false;
            if (xhr.status !== 200) {
                root.errorString = "Request failed (HTTP " + xhr.status + ")";
                return;
            }
            try {
                var data = JSON.parse(xhr.responseText);
                var cur = data ? data.current : undefined;
                if (!cur || cur.us_aqi === undefined) {
                    root.errorString = "No air-quality data returned";
                    return;
                }
                root.aqi = Math.round(Number(cur.us_aqi));
                root.hasData = true;
                root.categoryText = categoryFor(root.aqi);
                root.pm25 = Number(cur.pm2_5);
                root.pm10 = Number(cur.pm10);
                root.ozone = Number(cur.ozone);
                root.no2 = Number(cur.nitrogen_dioxide);
                root.so2 = Number(cur.sulphur_dioxide);
                root.co = Number(cur.carbon_monoxide);
                root.lastUpdatedText = new Date().toLocaleTimeString();
            } catch (e) {
                root.errorString = "Could not parse response";
            }
        };
        xhr.send();
    }

    onLatitudeChanged: refresh()
    onLongitudeChanged: refresh()

    Timer {
        id: refreshTimer
        interval: root.refreshMinutes * 60 * 1000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    // ----- Compact (panel) -------------------------------------------------
    compactRepresentation: RowLayout {
        spacing: Kirigami.Units.smallSpacing

        Kirigami.Icon {
            source: "weather-clear"
            Layout.preferredWidth: Kirigami.Units.gridUnit
            Layout.preferredHeight: Kirigami.Units.gridUnit
        }
        PlasmaComponents.Label {
            text: root.loading && !root.hasData ? "…" : (root.hasData ? String(root.aqi) : "—")
            color: root.aqiColor
            font.family: Kirigami.Theme.defaultFont.family
            font.pointSize: Kirigami.Theme.defaultFont.pointSize
            font.weight: Font.DemiBold
        }
    }

    // ----- Expanded (desktop / popup): Material card ----------------------
    fullRepresentation: ColumnLayout {
        spacing: Kirigami.Units.largeSpacing
        Layout.minimumWidth: Kirigami.Units.gridUnit * 16
        Layout.margins: Kirigami.Units.largeSpacing

        Rectangle {
            id: card
            Layout.fillWidth: true
            Layout.bottomMargin: root.shadowBleed
            implicitHeight: cardBody.implicitHeight + Kirigami.Units.largeSpacing * 2
            radius: root.cardRadius
            color: Kirigami.Theme.alternateBackgroundColor

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowBlur: root.shadowBlur
                shadowHorizontalOffset: 0
                shadowVerticalOffset: root.shadowOffsetY
                shadowColor: Kirigami.Theme.textColor
                shadowOpacity: root.shadowOpacity
            }

            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: Kirigami.Theme.highlightColor
                opacity: 0.06
            }

            ColumnLayout {
                id: cardBody
                anchors.fill: parent
                anchors.margins: Kirigami.Units.largeSpacing
                spacing: Kirigami.Units.smallSpacing

                // Header: icon badge + titles.
                RowLayout {
                    spacing: Kirigami.Units.smallSpacing
                    Layout.fillWidth: true

                    Item {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 2.2
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 2.2

                        Rectangle {
                            anchors.fill: parent
                            radius: root.badgeRadius
                            color: Kirigami.Theme.highlightColor
                            opacity: 0.28
                        }
                        Kirigami.Icon {
                            anchors.fill: parent
                            anchors.margins: Kirigami.Units.smallSpacing
                            source: "weather-clear"
                        }
                    }
                    ColumnLayout {
                        spacing: 0
                        Layout.fillWidth: true

                        PlasmaComponents.Label {
                            text: "Air Quality Index"
                            color: Kirigami.Theme.textColor
                            font.family: Kirigami.Theme.defaultFont.family
                            font.pointSize: Kirigami.Theme.defaultFont.pointSize
                            font.weight: Font.Medium
                            font.letterSpacing: 0.2
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        PlasmaComponents.Label {
                            text: (root.latitude.toFixed(2) + ", " + root.longitude.toFixed(2)) + " · Open-Meteo"
                            color: Kirigami.Theme.neutralTextColor
                            font.family: Kirigami.Theme.defaultFont.family
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: root.hairline
                    color: Kirigami.Theme.textColor
                    opacity: 0.1
                }

                // Hero readout.
                PlasmaComponents.Label {
                    text: root.loading && !root.hasData ? "Loading…" : (root.hasData ? String(root.aqi) : "—")
                    color: root.aqiColor
                    font.family: Kirigami.Theme.defaultFont.family
                    font.pointSize: root.displaySize
                    font.weight: Font.DemiBold
                    font.letterSpacing: -0.5
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                PlasmaComponents.Label {
                    text: root.hasData ? root.categoryText : "US AQI"
                    color: root.aqiColor
                    font.family: Kirigami.Theme.defaultFont.family
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize
                    font.weight: Font.Medium
                    horizontalAlignment: Text.AlignHCenter
                    Layout.fillWidth: true
                }

                // Pollutant rows.
                ColumnLayout {
                    visible: root.hasData
                    spacing: Kirigami.Units.smallSpacing
                    Layout.fillWidth: true

                    Repeater {
                        model: [
                            { "label": "PM2.5", "value": root.fmt(root.pm25) + " µg/m³" },
                            { "label": "PM10", "value": root.fmt(root.pm10) + " µg/m³" },
                            { "label": "Ozone", "value": root.fmt(root.ozone) + " µg/m³" },
                            { "label": "NO₂", "value": root.fmt(root.no2) + " µg/m³" },
                            { "label": "SO₂", "value": root.fmt(root.so2) + " µg/m³" },
                            { "label": "CO", "value": root.fmt(root.co) + " µg/m³" }
                        ]
                        delegate: RowLayout {
                            spacing: Kirigami.Units.smallSpacing
                            Layout.fillWidth: true
                            PlasmaComponents.Label {
                                text: modelData.label
                                color: Kirigami.Theme.neutralTextColor
                                font.family: Kirigami.Theme.defaultFont.family
                                font.pointSize: Kirigami.Theme.smallFont.pointSize
                                Layout.fillWidth: true
                            }
                            PlasmaComponents.Label {
                                text: modelData.value
                                color: Kirigami.Theme.textColor
                                font.family: Kirigami.Theme.defaultFont.family
                                font.pointSize: Kirigami.Theme.smallFont.pointSize
                                horizontalAlignment: Text.AlignRight
                            }
                        }
                    }
                }

                PlasmaComponents.Label {
                    visible: root.lastUpdatedText !== ""
                    text: "Updated " + root.lastUpdatedText + " · every " + root.refreshMinutes + " min"
                    color: Kirigami.Theme.neutralTextColor
                    font.family: Kirigami.Theme.defaultFont.family
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                PlasmaComponents.Label {
                    visible: root.errorString !== ""
                    text: root.errorString
                    color: Kirigami.Theme.negativeTextColor
                    font.family: Kirigami.Theme.defaultFont.family
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }
            }
        }

        PlasmaComponents.Button {
            text: root.loading ? "Refreshing…" : "Refresh now"
            enabled: !root.loading
            onClicked: root.refresh()
            Layout.fillWidth: true
        }
    }
}