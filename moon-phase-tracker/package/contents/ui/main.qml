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
    property int refreshMinutes: plasmoid.configuration.refreshMinutes || 5

    // ----- State -----------------------------------------------------------
    property string phaseName: "—"
    property real illumination: 0
    property real ageDays: 0
    property real daysToFull: 0
    property real daysToNew: 0
    property string lastUpdatedText: ""

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

    readonly property real cycleDays: 29.53058867

    toolTipMainText: root.phaseName + " · " + Math.round(root.illumination * 100) + "% lit"
    toolTipSubText: "Moon phase"

    function phaseIndex(frac: real): int {
        if (frac < 0.0625) {
            return 0;
        }
        if (frac < 0.1875) {
            return 1;
        }
        if (frac < 0.3125) {
            return 2;
        }
        if (frac < 0.4375) {
            return 3;
        }
        if (frac < 0.5625) {
            return 4;
        }
        if (frac < 0.6875) {
            return 5;
        }
        if (frac < 0.8125) {
            return 6;
        }
        if (frac < 0.9375) {
            return 7;
        }
        return 0;
    }

    readonly property var phaseNames: [
        "New Moon",
        "Waxing Crescent",
        "First Quarter",
        "Waxing Gibbous",
        "Full Moon",
        "Waning Gibbous",
        "Last Quarter",
        "Waning Crescent"
    ]

    function recompute(): void {
        // Reference new moon: 2000-01-06 18:14 UTC
        var ref = Date.UTC(2000, 0, 6, 18, 14, 0);
        var now = new Date();
        var days = (now.getTime() - ref) / 86400000.0;
        var frac = ((days % root.cycleDays) + root.cycleDays) % root.cycleDays / root.cycleDays;
        root.ageDays = frac * root.cycleDays;
        root.illumination = (1.0 - Math.cos(2.0 * Math.PI * frac)) / 2.0;
        root.phaseName = root.phaseNames[root.phaseIndex(frac)];
        if (frac <= 0.5) {
            root.daysToFull = (0.5 - frac) * root.cycleDays;
        } else {
            root.daysToFull = (1.5 - frac) * root.cycleDays;
        }
        var toNew = (1.0 - frac) * root.cycleDays;
        if (toNew >= root.cycleDays) {
            toNew -= root.cycleDays;
        }
        if (toNew < 0) {
            toNew += root.cycleDays;
        }
        root.daysToNew = toNew;
        root.lastUpdatedText = now.toLocaleTimeString();
    }

    onRefreshMinutesChanged: { }

    Timer {
        id: tickTimer
        interval: root.refreshMinutes * 60 * 1000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.recompute()
    }

    // ----- Compact (panel) -------------------------------------------------
    compactRepresentation: RowLayout {
        spacing: Kirigami.Units.smallSpacing

        Kirigami.Icon {
            source: "weather-clear-night"
            Layout.preferredWidth: Kirigami.Units.gridUnit
            Layout.preferredHeight: Kirigami.Units.gridUnit
        }
        PlasmaComponents.Label {
            text: Math.round(root.illumination * 100) + "%"
            color: Kirigami.Theme.textColor
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
                            source: "weather-clear-night"
                        }
                    }
                    ColumnLayout {
                        spacing: 0
                        Layout.fillWidth: true

                        PlasmaComponents.Label {
                            text: "Moon Phase"
                            color: Kirigami.Theme.textColor
                            font.family: Kirigami.Theme.defaultFont.family
                            font.pointSize: Kirigami.Theme.defaultFont.pointSize
                            font.weight: Font.Medium
                            font.letterSpacing: 0.2
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        PlasmaComponents.Label {
                            text: "Computed locally · no network"
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
                    text: Math.round(root.illumination * 100) + "%"
                    color: Kirigami.Theme.highlightColor
                    font.family: Kirigami.Theme.defaultFont.family
                    font.pointSize: root.displaySize
                    font.weight: Font.DemiBold
                    font.letterSpacing: -0.5
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                PlasmaComponents.Label {
                    text: root.phaseName
                    color: Kirigami.Theme.textColor
                    font.family: Kirigami.Theme.defaultFont.family
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize
                    font.weight: Font.Medium
                    horizontalAlignment: Text.AlignHCenter
                    Layout.fillWidth: true
                }

                // Metadata rows.
                ColumnLayout {
                    spacing: Kirigami.Units.smallSpacing
                    Layout.fillWidth: true

                    Repeater {
                        model: [
                            { "label": "Age (since new moon)", "value": root.ageDays.toFixed(1) + " days" },
                            { "label": "Days to full moon", "value": root.daysToFull.toFixed(1) + " days" },
                            { "label": "Days to new moon", "value": root.daysToNew.toFixed(1) + " days" }
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
                    text: "Updated " + root.lastUpdatedText
                    color: Kirigami.Theme.neutralTextColor
                    font.family: Kirigami.Theme.defaultFont.family
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }
        }
    }
}