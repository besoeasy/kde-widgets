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
    property string language: plasmoid.configuration.language || ""
    property int repoCount: plasmoid.configuration.count || 5
    property int refreshMinutes: plasmoid.configuration.refreshMinutes || 60

    // ----- State -----------------------------------------------------------
    property var repos: []
    property string lastUpdatedText: ""
    property string errorString: ""
    property bool loading: false

    // ----- Material shape scale (desktop-unit multiples, never fixed px) ---
    readonly property int cardRadius: Math.round(Kirigami.Units.gridUnit * 1.15)
    readonly property int badgeRadius: Math.round(Kirigami.Units.gridUnit * 0.65)
    readonly property int hairline: Math.max(1, Math.round(Kirigami.Units.devicePixelRatio))

    toolTipMainText: root.repos.length > 0 ? ("Trending: " + root.repos[0].name) : "GitHub Trending"
    toolTipSubText: lastUpdatedText !== "" ? ("Updated " + lastUpdatedText) : "Top starred repos of the week"

    function formatStars(n: int): string {
        if (n >= 1000) {
            return (n / 1000).toFixed(1) + "k";
        }
        return "" + n;
    }

    function refresh(): void {
        if (root.loading) {
            return;
        }
        root.loading = true;
        root.errorString = "";

        var d = new Date();
        d.setDate(d.getDate() - 7);
        var since = Qt.formatDate(d, "yyyy-MM-dd");
        var query = "created:>" + since;
        if (root.language !== "") {
            query += " language:" + root.language;
        }
        var url = "https://api.github.com/search/repositories?q=" + encodeURIComponent(query)
            + "&sort=stars&order=desc&per_page=" + root.repoCount;

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
                if (!data.items) {
                    root.errorString = "Unexpected response";
                    return;
                }
                var list = [];
                for (var i = 0; i < data.items.length; i++) {
                    var item = data.items[i];
                    list.push({
                        "name": item.full_name,
                        "description": item.description || "",
                        "stars": formatStars(Number(item.stargazers_count)),
                        "language": item.language || "",
                        "url": item.html_url
                    });
                }
                root.repos = list;
                root.lastUpdatedText = new Date().toLocaleTimeString();
            } catch (e) {
                root.errorString = "Could not parse response";
            }
        };
        xhr.send();
    }

    onLanguageChanged: refresh()
    onRepoCountChanged: refresh()

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
            source: "starred"
            Layout.preferredWidth: Kirigami.Units.gridUnit
            Layout.preferredHeight: Kirigami.Units.gridUnit
        }
        PlasmaComponents.Label {
            text: {
                if (root.loading && root.repos.length === 0) {
                    return "…";
                }
                if (root.repos.length === 0) {
                    return "Trending";
                }
                return root.repos[0].name + " " + root.repos[0].stars;
            }
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
                            source: "starred"
                        }
                    }
                    ColumnLayout {
                        spacing: 0
                        Layout.fillWidth: true

                        PlasmaComponents.Label {
                            text: root.language !== "" ? ("Trending · " + root.language) : "Trending on GitHub"
                            color: Kirigami.Theme.textColor
                            font.family: Kirigami.Theme.defaultFont.family
                            font.pointSize: Kirigami.Theme.defaultFont.pointSize
                            font.bold: true
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        PlasmaComponents.Label {
                            text: root.loading ? "Loading…" : "Top starred this week"
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

                Repeater {
                    model: root.repos
                    delegate: MouseArea {
                        id: rowHover
                        Layout.fillWidth: true
                        implicitHeight: row.implicitHeight + Kirigami.Units.smallSpacing * 2
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: Qt.openUrlExternally(modelData.url)

                        Rectangle {
                            anchors.fill: parent
                            radius: root.badgeRadius
                            color: Kirigami.Theme.highlightColor
                            opacity: rowHover.containsMouse ? 0.12 : 0

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: Kirigami.Units.shortDuration
                                }
                            }
                        }

                        RowLayout {
                            id: row
                            anchors.fill: parent
                            anchors.margins: Kirigami.Units.smallSpacing
                            spacing: Kirigami.Units.smallSpacing

                            // Rank badge.
                            Item {
                                Layout.preferredWidth: Kirigami.Units.gridUnit
                                Layout.preferredHeight: Kirigami.Units.gridUnit

                                Rectangle {
                                    anchors.fill: parent
                                    radius: root.badgeRadius
                                    color: Kirigami.Theme.highlightColor
                                    opacity: 0.28
                                }
                                PlasmaComponents.Label {
                                    anchors.centerIn: parent
                                    text: index + 1
                                    color: Kirigami.Theme.highlightColor
                                    font.family: Kirigami.Theme.defaultFont.family
                                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                                    font.bold: true
                                }
                            }

                            ColumnLayout {
                                spacing: 0
                                Layout.fillWidth: true

                                PlasmaComponents.Label {
                                    text: modelData.name + "  ★ " + modelData.stars
                                    color: Kirigami.Theme.textColor
                                    font.family: Kirigami.Theme.defaultFont.family
                                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                                    font.bold: true
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                                PlasmaComponents.Label {
                                    visible: modelData.description !== ""
                                    text: modelData.description
                                    color: Kirigami.Theme.neutralTextColor
                                    font.family: Kirigami.Theme.defaultFont.family
                                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                                    elide: Text.ElideRight
                                    maximumLineCount: 2
                                    wrapMode: Text.Wrap
                                    Layout.fillWidth: true
                                }
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
