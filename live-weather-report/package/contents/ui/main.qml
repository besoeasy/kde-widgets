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
    property string units: plasmoid.configuration.units || "celsius"
    property int refreshMinutes: plasmoid.configuration.refreshMinutes || 30

    // ----- State -----------------------------------------------------------
    property string tempText: "—"
    property string conditionText: ""
    property string iconName: "weather-clear"
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

    toolTipMainText: conditionText !== "" ? (tempText + " · " + conditionText) : tempText
    toolTipSubText: lastUpdatedText !== "" ? ("Updated " + lastUpdatedText) : "Weather"

    // WMO weather-code mapping for the Open-Meteo forecast API.
    function conditionFor(code: int): var {
        if (code === 0) {
            return ["Clear sky", "weather-clear"];
        }
        if (code === 1) {
            return ["Mainly clear", "weather-few-clouds"];
        }
        if (code === 2) {
            return ["Partly cloudy", "weather-clouds"];
        }
        if (code === 3) {
            return ["Overcast", "weather-clouds"];
        }
        if (code === 45 || code === 48) {
            return ["Fog", "weather-fog"];
        }
        if (code >= 51 && code <= 57) {
            return ["Drizzle", "weather-showers"];
        }
        if ((code >= 61 && code <= 67) || (code >= 80 && code <= 82)) {
            return ["Rain", "weather-rain"];
        }
        if ((code >= 71 && code <= 77) || code === 85 || code === 86) {
            return ["Snow", "weather-snow"];
        }
        if (code >= 95) {
            return ["Thunderstorm", "weather-storm"];
        }
        return ["", "weather-clear"];
    }

    function refresh(): void {
        if (root.loading) {
            return;
        }
        root.loading = true;
        root.errorString = "";

        var unitParam = root.units === "fahrenheit" ? "fahrenheit" : "celsius";
        var url = "https://api.open-meteo.com/v1/forecast?latitude=" + root.latitude
            + "&longitude=" + root.longitude
            + "&current=temperature_2m,weather_code"
            + "&temperature_unit=" + unitParam
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
                if (!data.current || data.current.temperature_2m === undefined) {
                    root.errorString = "Unexpected response";
                    return;
                }
                var unit = unitParam === "fahrenheit" ? "°F" : "°C";
                root.tempText = Math.round(Number(data.current.temperature_2m)) + unit;
                var info = conditionFor(Number(data.current.weather_code));
                root.conditionText = info[0];
                root.iconName = info[1];
                root.lastUpdatedText = new Date().toLocaleTimeString();
            } catch (e) {
                root.errorString = "Could not parse response";
            }
        };
        xhr.send();
    }

    onLatitudeChanged: refresh()
    onLongitudeChanged: refresh()
    onUnitsChanged: refresh()

    // Requirement: refresh every 30 minutes (configurable, defaults to 30).
    Timer {
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
            source: root.iconName
            Layout.preferredWidth: Kirigami.Units.gridUnit
            Layout.preferredHeight: Kirigami.Units.gridUnit
        }
        PlasmaComponents.Label {
            text: root.loading && root.tempText === "—" ? "…" : root.tempText
            color: Kirigami.Theme.textColor
            font.family: Kirigami.Theme.defaultFont.family
            font.pointSize: Kirigami.Theme.defaultFont.pointSize
        }
    }

    // ----- Expanded (desktop / popup): Material card -----------------------
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
            // Real Material surface: distinct from the desktop background so
            // the card reads as an object rather than a flat wash.
            color: Kirigami.Theme.alternateBackgroundColor

            // Material 3 level-1 elevation.
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowBlur: root.shadowBlur
                shadowHorizontalOffset: 0
                shadowVerticalOffset: root.shadowOffsetY
                shadowColor: Kirigami.Theme.textColor
                shadowOpacity: root.shadowOpacity
            }

            // Tonal surface tint (Material You dynamic colour over the card).
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
                            source: root.iconName
                        }
                    }
                    ColumnLayout {
                        spacing: 0
                        Layout.fillWidth: true

                        PlasmaComponents.Label {
                            text: root.conditionText !== "" ? root.conditionText : "Weather"
                            color: Kirigami.Theme.textColor
                            font.family: Kirigami.Theme.defaultFont.family
                            font.pointSize: Kirigami.Theme.defaultFont.pointSize
                            font.weight: Font.Medium
                            font.letterSpacing: 0.2
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        PlasmaComponents.Label {
                            text: "Open-Meteo · live"
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
                    text: root.loading && root.tempText === "—" ? "Loading…" : root.tempText
                    color: Kirigami.Theme.highlightColor
                    font.family: Kirigami.Theme.defaultFont.family
                    font.pointSize: root.displaySize
                    font.weight: Font.DemiBold
                    font.letterSpacing: -0.5
                    elide: Text.ElideRight
                    Layout.fillWidth: true
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
