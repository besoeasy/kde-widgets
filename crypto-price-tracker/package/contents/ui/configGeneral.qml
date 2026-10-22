// SPDX-FileCopyrightText: 2026 besoeasy
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.plasma.plasmoid

KCM.SimpleKCM {
    property alias cfg_coinId: coinIdField.text
    property alias cfg_vsCurrency: vsCurrencyField.text
    property alias cfg_refreshMinutes: refreshSpinBox.value

    Kirigami.FormLayout {
        QQC2.TextField {
            id: coinIdField
            Kirigami.FormData.label: i18n("CoinGecko coin id:")
            placeholderText: i18n("bitcoin, ethereum, solana…")
        }

        QQC2.TextField {
            id: vsCurrencyField
            Kirigami.FormData.label: i18n("Fiat currency:")
            placeholderText: i18n("usd, eur, gbp…")
        }

        QQC2.SpinBox {
            id: refreshSpinBox
            Kirigami.FormData.label: i18n("Refresh interval (minutes):")
            from: 1
            to: 1440
        }
    }
}
