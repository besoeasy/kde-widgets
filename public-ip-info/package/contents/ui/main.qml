// SPDX-FileCopyrightText: 2026 besoeasy
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    preferredRepresentation: compactRepresentation

    // ----- Settings (see contents/config/main.xml) -------------------------
    property int refreshMinutes: plasmoid.configuration.refreshMinutes || 60

    // ----- State -----------------------------------------------------------
    property string ipText: "—"
    property string cityText: ""
    property string countryText: ""
    property string lastUpdatedText: ""
    property string errorString: ""
    property bool loading: false

    // ----- Material shape scale (desktop-unit multiples, never fixed px) ---
    readonly property int cardRadius: Math.round(Kirigami.Units.gridUnit * 1.15)
    readonly property int badgeRadius: Math.round(Kirigami.Units.gridUnit * 0.65)
    readonly property int displaySize: Math.round(Kirigami.Theme.defaultFont.pointSize * 2.6)
    readonly property int hairline: Math.max(1, Math.round(Kirigami.Units.devicePixelRatio))

    toolTipMainText: ipText
    toolTipSubText: cityText !== "" ? cityText : "IP & Location"

    function refresh(): void {
        if (root.loading) {
            return;
        }
        root.loading = true;
        root.errorString = "";

        var xhr = new XMLHttpRequest();
        xhr.open("GET", "https://ipinfo.io/json");
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
                if (!data.ip) {
                    root.errorString = "Unexpected response";
                    return;
                }
                root.ipText = data.ip;
                var place = data.city || "";
                if (data.region) {
                    place = place !== "" ? (place + ", " + data.region) : data.region;
                }
                root.cityText = place;
                root.countryText = data.country || "";
                root.lastUpdatedText = new Date().toLocaleTimeString();
            } catch (e) {
                root.errorString = "Could not parse response";
            }
        };
        xhr.send();
    }

    // Requirement: refresh every 60 minutes (configurable, defaults to 60).
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
            source: "network-wired"
            Layout.preferredWidth: Kirigami.Units.gridUnit
            Layout.preferredHeight: Kirigami.Units.gridUnit
        }
        PlasmaComponents.Label {
            text: root.loading && root.ipText === "—" ? "…" : root.ipText
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
            Layout.fillWidth: true
            implicitHeight: cardBody.implicitHeight + Kirigami.Units.largeSpacing * 2
            radius: root.cardRadius
            color: Kirigami.Theme.backgroundColor

            // Material tonal wash over the card surface.
            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: Kirigami.Theme.highlightColor
                opacity: 0.18
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
                            source: "network-wired"
                        }
                    }
                    ColumnLayout {
                        spacing: 0
                        Layout.fillWidth: true

                        PlasmaComponents.Label {
                            text: "IP Address"
                            color: Kirigami.Theme.textColor
                            font.family: Kirigami.Theme.defaultFont.family
                            font.pointSize: Kirigami.Theme.defaultFont.pointSize
                            font.bold: true
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        PlasmaComponents.Label {
                            text: root.countryText !== "" ? root.countryText : "Public address"
                            color: Kirigami.Theme.neutralTextColor
                            font.family: Kirigami.Theme.defaultFont.family
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    // Country pill.
                    Item {
                        visible: root.countryText !== ""
                        implicitWidth: countryLabel.implicitWidth + Kirigami.Units.largeSpacing
                        implicitHeight: countryLabel.implicitHeight + Kirigami.Units.smallSpacing

                        Rectangle {
                            anchors.fill: parent
                            radius: Kirigami.Units.gridUnit
                            color: Kirigami.Theme.highlightColor
                            opacity: 0.28
                        }
                        PlasmaComponents.Label {
                            id: countryLabel
                            anchors.centerIn: parent
                            text: root.countryText
                            color: Kirigami.Theme.highlightColor
                            font.family: Kirigami.Theme.defaultFont.family
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                            font.bold: true
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
                    text: root.loading && root.ipText === "—" ? "Loading…" : root.ipText
                    color: Kirigami.Theme.highlightColor
                    font.family: Kirigami.Theme.defaultFont.family
                    font.pointSize: root.displaySize
                    font.bold: true
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                PlasmaComponents.Label {
                    visible: root.cityText !== ""
                    text: root.cityText
                    color: Kirigami.Theme.textColor
                    font.family: Kirigami.Theme.defaultFont.family
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize
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
