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
    property int focusMinutes: plasmoid.configuration.focusMinutes || 25
    property int breakMinutes: plasmoid.configuration.breakMinutes || 5

    // ----- State -----------------------------------------------------------
    property string phase: "focus" // "focus" or "break"
    property int remainingSeconds: 0
    property bool running: false
    property int phaseTotal: (root.phase === "focus" ? root.focusMinutes : root.breakMinutes) * 60

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
    readonly property color phaseColor: root.phase === "focus" ? Kirigami.Theme.highlightColor : Kirigami.Theme.positiveTextColor

    toolTipMainText: phaseLabel() + " " + formatted()
    toolTipSubText: root.running ? "Running" : "Paused"

    function phaseLabel(): string {
        return root.phase === "focus" ? "Focus" : "Break";
    }

    function formatted(): string {
        var m = Math.floor(root.remainingSeconds / 60);
        var s = root.remainingSeconds % 60;
        return (m < 10 ? "0" + m : "" + m) + ":" + (s < 10 ? "0" + s : "" + s);
    }

    function start(): void {
        root.running = true;
    }

    function pause(): void {
        root.running = false;
    }

    function reset(): void {
        root.running = false;
        root.phase = "focus";
        root.remainingSeconds = root.focusMinutes * 60;
    }

    function skip(): void {
        if (root.phase === "focus") {
            root.phase = "break";
            root.remainingSeconds = root.breakMinutes * 60;
        } else {
            root.phase = "focus";
            root.remainingSeconds = root.focusMinutes * 60;
        }
    }

    onFocusMinutesChanged: reset()
    onBreakMinutesChanged: reset()

    Component.onCompleted: reset()

    // Requirement: the countdown ticks every second while running.
    Timer {
        interval: 1000
        repeat: true
        running: root.running
        onTriggered: {
            if (root.remainingSeconds > 0) {
                root.remainingSeconds -= 1;
            }
            if (root.remainingSeconds === 0) {
                root.skip();
            }
        }
    }

    // ----- Compact (panel) -------------------------------------------------
    compactRepresentation: RowLayout {
        spacing: Kirigami.Units.smallSpacing

        Kirigami.Icon {
            source: "chronometer"
            Layout.preferredWidth: Kirigami.Units.gridUnit
            Layout.preferredHeight: Kirigami.Units.gridUnit
        }
        PlasmaComponents.Label {
            text: phaseLabel() + " " + formatted()
            color: root.phase === "focus" ? Kirigami.Theme.textColor : Kirigami.Theme.positiveTextColor
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
                            source: "chronometer"
                        }
                    }
                    ColumnLayout {
                        spacing: 0
                        Layout.fillWidth: true

                        PlasmaComponents.Label {
                            text: phaseLabel()
                            color: Kirigami.Theme.textColor
                            font.family: Kirigami.Theme.defaultFont.family
                            font.pointSize: Kirigami.Theme.defaultFont.pointSize
                            font.weight: Font.Medium
                            font.letterSpacing: 0.2
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        PlasmaComponents.Label {
                            text: root.focusMinutes + " min focus · " + root.breakMinutes + " min break"
                            color: Kirigami.Theme.neutralTextColor
                            font.family: Kirigami.Theme.defaultFont.family
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    // Phase pill.
                    Item {
                        implicitWidth: phaseLabel.implicitWidth + Kirigami.Units.largeSpacing
                        implicitHeight: phaseLabel.implicitHeight + Kirigami.Units.smallSpacing

                        Rectangle {
                            anchors.fill: parent
                            radius: Kirigami.Units.gridUnit
                            color: root.phaseColor
                            opacity: 0.28
                        }
                        PlasmaComponents.Label {
                            id: phaseLabel
                            anchors.centerIn: parent
                            text: root.running ? "Running" : "Paused"
                            color: root.phaseColor
                            font.family: Kirigami.Theme.defaultFont.family
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                            font.weight: Font.DemiBold
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
                    text: formatted()
                    color: Kirigami.Theme.highlightColor
                    font.family: Kirigami.Theme.defaultFont.family
                    font.pointSize: root.displaySize
                    font.weight: Font.DemiBold
                    font.letterSpacing: -0.5
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                // Phase progress.
                PlasmaComponents.ProgressBar {
                    from: 0
                    to: root.phaseTotal
                    value: root.phaseTotal - root.remainingSeconds
                    Layout.fillWidth: true
                }
            }
        }

        PlasmaComponents.Button {
            text: root.running ? "Pause" : "Start"
            onClicked: root.running ? root.pause() : root.start()
            Layout.fillWidth: true
        }
        RowLayout {
            spacing: Kirigami.Units.smallSpacing
            Layout.fillWidth: true

            PlasmaComponents.Button {
                text: "Reset"
                onClicked: root.reset()
                Layout.fillWidth: true
            }
            PlasmaComponents.Button {
                text: "Skip"
                onClicked: root.skip()
                Layout.fillWidth: true
            }
        }
    }
}
