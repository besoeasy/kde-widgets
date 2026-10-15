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
    property bool use24Hour: plasmoid.configuration.use24Hour !== undefined ? plasmoid.configuration.use24Hour : true
    property bool showSeconds: plasmoid.configuration.showSeconds !== undefined ? plasmoid.configuration.showSeconds : true
    property bool showDate: plasmoid.configuration.showDate !== undefined ? plasmoid.configuration.showDate : true

    // ----- State -----------------------------------------------------------
    property string timeText: "--:--"
    property string dateText: ""

    // ----- Material shape scale (desktop-unit multiples, never fixed px) ---
    readonly property int cardRadius: Math.round(Kirigami.Units.gridUnit * 1.15)
    readonly property int badgeRadius: Math.round(Kirigami.Units.gridUnit * 0.65)
    readonly property int displaySize: Math.round(Kirigami.Theme.defaultFont.pointSize * 2.6)
    readonly property int hairline: Math.max(1, Math.round(Kirigami.Units.devicePixelRatio))

    toolTipMainText: timeText
    toolTipSubText: dateText !== "" ? dateText : "Clock"

    function timeFormat(): string {
        if (root.use24Hour) {
            return root.showSeconds ? "HH:mm:ss" : "HH:mm";
        }
        return root.showSeconds ? "h:mm:ss AP" : "h:mm AP";
    }

    function tick(): void {
        var now = new Date();
        root.timeText = Qt.formatTime(now, timeFormat());
        root.dateText = Qt.formatDate(now, Qt.DefaultLocaleLongDate);
    }

    onUse24HourChanged: tick()
    onShowSecondsChanged: tick()
    onShowDateChanged: tick()

    // Requirement: the clock ticks every second.
    Timer {
        interval: 1000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.tick()
    }

    // ----- Compact (panel) -------------------------------------------------
    compactRepresentation: RowLayout {
        spacing: Kirigami.Units.smallSpacing

        Kirigami.Icon {
            source: "clock"
            Layout.preferredWidth: Kirigami.Units.gridUnit
            Layout.preferredHeight: Kirigami.Units.gridUnit
        }
        PlasmaComponents.Label {
            text: root.timeText
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
                opacity: 0.11
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
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 2
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 2

                        Rectangle {
                            anchors.fill: parent
                            radius: root.badgeRadius
                            color: Kirigami.Theme.highlightColor
                            opacity: 0.15
                        }
                        Kirigami.Icon {
                            anchors.fill: parent
                            anchors.margins: Kirigami.Units.smallSpacing
                            source: "clock"
                        }
                    }
                    ColumnLayout {
                        spacing: 0
                        Layout.fillWidth: true

                        PlasmaComponents.Label {
                            text: root.showDate && root.dateText !== "" ? root.dateText : "Clock"
                            color: Kirigami.Theme.textColor
                            font.family: Kirigami.Theme.defaultFont.family
                            font.pointSize: Kirigami.Theme.defaultFont.pointSize
                            font.bold: true
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        PlasmaComponents.Label {
                            text: (root.use24Hour ? "24-hour" : "12-hour") + " · live"
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
                    text: root.timeText
                    color: Kirigami.Theme.textColor
                    font.family: Kirigami.Theme.defaultFont.family
                    font.pointSize: root.displaySize
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                PlasmaComponents.Label {
                    text: "updates every second"
                    color: Kirigami.Theme.neutralTextColor
                    font.family: Kirigami.Theme.defaultFont.family
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    horizontalAlignment: Text.AlignHCenter
                    Layout.fillWidth: true
                }
            }
        }
    }
}
