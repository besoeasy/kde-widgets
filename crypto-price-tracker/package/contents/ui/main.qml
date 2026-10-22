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

    // ----- State ---------------------------------------------------------
    property string coinId: plasmoid.configuration.coinId || "bitcoin"
    property string vsCurrency: (plasmoid.configuration.vsCurrency || "usd").toLowerCase()
    property int refreshMinutes: plasmoid.configuration.refreshMinutes || 15

    property string priceText: "—"
    property string changeText: ""
    property real changeValue: 0
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
    readonly property color changeColor: root.changeValue >= 0 ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.negativeTextColor

    toolTipMainText: coinLabel() + " " + priceText
    toolTipSubText: lastUpdatedText !== "" ? ("Updated " + lastUpdatedText) : "Crypto price"

    function coinLabel(): string {
        if (root.coinId.length === 0) {
            return "";
        }
        return root.coinId.charAt(0).toUpperCase() + root.coinId.slice(1);
    }

    function formatPrice(price: real, vs: string): string {
        return Number(price).toLocaleString(Qt.locale(), "f", 2) + " " + vs.toUpperCase();
    }

    function refresh(): void {
        if (root.loading) {
            return;
        }
        root.loading = true;
        root.errorString = "";

        var coin = root.coinId;
        var vs = root.vsCurrency;
        var url = "https://api.coingecko.com/api/v3/simple/price?ids="
            + encodeURIComponent(coin)
            + "&vs_currencies=" + encodeURIComponent(vs)
            + "&include_24hr_change=true";

        var xhr = new XMLHttpRequest();
        xhr.open("GET", url);
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE) {
                return;
            }
            root.loading = false;
            if (xhr.status === 429) {
                root.errorString = "Rate limited by CoinGecko, try again later";
                return;
            }
            if (xhr.status !== 200) {
                root.errorString = "Request failed (HTTP " + xhr.status + ")";
                return;
            }
            try {
                var data = JSON.parse(xhr.responseText);
                if (data && data.status && data.status.error_code) {
                    root.errorString = data.status.error_message || "CoinGecko error";
                    return;
                }
                var entry = data ? data[coin] : undefined;
                if (!entry) {
                    root.errorString = "Unknown coin id: " + coin;
                    return;
                }
                if (entry[vs] === undefined) {
                    root.errorString = "Unsupported currency: " + vs.toUpperCase();
                    return;
                }
                root.priceText = formatPrice(Number(entry[vs]), vs);
                var changeKey = vs + "_24h_change";
                if (entry[changeKey] !== undefined) {
                    var ch = Number(entry[changeKey]);
                    root.changeValue = ch;
                    root.changeText = (ch >= 0 ? "+" : "") + ch.toFixed(2) + "% (24h)";
                } else {
                    root.changeText = "";
                }
                root.lastUpdatedText = new Date().toLocaleTimeString();
            } catch (e) {
                root.errorString = "Could not parse response";
            }
        };
        xhr.send();
    }

    onCoinIdChanged: refresh()
    onVsCurrencyChanged: refresh()

    // Requirement: refresh every 15 minutes (configurable, defaults to 15).
    Timer {
        id: refreshTimer
        interval: root.refreshMinutes * 60 * 1000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    // ----- Compact (panel) -----------------------------------------------
    compactRepresentation: RowLayout {
        spacing: Kirigami.Units.smallSpacing

        Kirigami.Icon {
            source: "currencies"
            Layout.preferredWidth: Kirigami.Units.gridUnit
            Layout.preferredHeight: Kirigami.Units.gridUnit
        }
        PlasmaComponents.Label {
            text: root.loading && root.priceText === "—" ? "…" : root.priceText
            color: Kirigami.Theme.textColor
            font.family: Kirigami.Theme.defaultFont.family
            font.pointSize: Kirigami.Theme.defaultFont.pointSize
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
                            source: "currencies"
                        }
                    }
                    ColumnLayout {
                        spacing: 0
                        Layout.fillWidth: true

                        PlasmaComponents.Label {
                            text: root.coinLabel()
                            color: Kirigami.Theme.textColor
                            font.family: Kirigami.Theme.defaultFont.family
                            font.pointSize: Kirigami.Theme.defaultFont.pointSize
                            font.weight: Font.Medium
                            font.letterSpacing: 0.2
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        PlasmaComponents.Label {
                            text: root.vsCurrency.toUpperCase() + " · CoinGecko"
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
                    text: root.loading && root.priceText === "—" ? "Loading…" : root.priceText
                    color: Kirigami.Theme.highlightColor
                    font.family: Kirigami.Theme.defaultFont.family
                    font.pointSize: root.displaySize
                    font.weight: Font.DemiBold
                    font.letterSpacing: -0.5
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                // 24h change pill.
                Item {
                    visible: root.changeText !== ""
                    implicitWidth: changeLabel.implicitWidth + Kirigami.Units.largeSpacing
                    implicitHeight: changeLabel.implicitHeight + Kirigami.Units.smallSpacing

                    Rectangle {
                        anchors.fill: parent
                        radius: Kirigami.Units.gridUnit
                        color: root.changeColor
                        opacity: 0.28
                    }
                    PlasmaComponents.Label {
                        id: changeLabel
                        anchors.centerIn: parent
                        text: root.changeText
                        color: root.changeColor
                        font.family: Kirigami.Theme.defaultFont.family
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        font.weight: Font.DemiBold
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
