import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import "../../config"

Scope {
    id: root
    property string hours: "00"
    property string minutes: "00"
    property bool vertical: Settings.barPosition === "left" || Settings.barPosition === "right"

    Process {
        id: dateProc
        command: ["date", "+%H:%M"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = this.text.trim().split(":")
                root.hours = parts[0]
                root.minutes = parts[1]
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: dateProc.running = true
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: panel
            required property var modelData
            screen: modelData
            color: "transparent"

            readonly property int thickness: Math.round(Math.max(
                Settings.barThicknessMin,
                Math.min(Settings.barThicknessMax, screen.height * Settings.barThicknessRatio)
            ))
            readonly property int pillRadius: thickness / 2
            readonly property int lengthInset: Math.round(
                (root.vertical ? screen.height : screen.width) * Settings.barVerticalInsetRatio
            )

            implicitWidth: root.vertical ? thickness : 0
            implicitHeight: root.vertical ? 0 : thickness

            anchors {
                top: Settings.barPosition === "top" || root.vertical
                bottom: Settings.barPosition === "bottom" || root.vertical
                left: Settings.barPosition === "left" || !root.vertical
                right: Settings.barPosition === "right" || !root.vertical
            }

            margins {
                left: Settings.barPosition === "left" ? Settings.barMargin : (!root.vertical ? panel.lengthInset : 0)
                right: Settings.barPosition === "right" ? Settings.barMargin : (!root.vertical ? panel.lengthInset : 0)
                top: Settings.barPosition === "top" ? Settings.barMargin : (root.vertical ? panel.lengthInset : 0)
                bottom: Settings.barPosition === "bottom" ? Settings.barMargin : (root.vertical ? panel.lengthInset : 0)
            }

            // ============================================================
            // LAYOUT VERTICAL (barra na esquerda/direita)
            // ============================================================
            Item {
                id: verticalLayout
                anchors.fill: parent
                visible: root.vertical

                // Grupo do topo: LauncherButton + Workspaces
                // Preenche do topo (com inset) até o centro
                Rectangle {
                    id: topGroupBg
                    anchors {
                        top: parent.top
                        topMargin: panel.lengthInset
                        horizontalCenter: parent.horizontalCenter
                        bottom: parent.verticalCenter
                    }
                    width: Math.max(
                        Math.round(panel.thickness * 0.6) + 16,
                        Math.round(panel.thickness * 0.55) * 5 + 8 * 4 + 24
                    )
                    radius: panel.pillRadius
                    color: Theme.moduleBackground
                    border.color: Theme.moduleBorder
                    border.width: 1

                    Column {
                        anchors.centerIn: parent
                        spacing: 6

                        LauncherButton {
                            anchors.horizontalCenter: parent.horizontalCenter
                            thickness: panel.thickness
                        }

                        Workspaces {
                            anchors.horizontalCenter: parent.horizontalCenter
                            vertical: true
                            cellSize: Math.round(panel.thickness * 0.55)
                        }
                    }
                }

                // Grupo de baixo: AudioIndicator + Relógio
                // Preenche do centro até a base (com inset)
                Rectangle {
                    id: bottomGroupBg
                    anchors {
                        top: parent.verticalCenter
                        bottom: parent.bottom
                        bottomMargin: panel.lengthInset
                        horizontalCenter: parent.horizontalCenter
                    }
                    width: Math.max(
                        Math.round(panel.thickness * 0.6) + 16,
                        Math.round(panel.thickness * 0.40) * 2 + 20
                    )
                    radius: panel.pillRadius
                    color: Theme.moduleBackground
                    border.color: Theme.moduleBorder
                    border.width: 1

                    Column {
                        anchors.centerIn: parent
                        spacing: 6

                        AudioIndicator {
                            anchors.horizontalCenter: parent.horizontalCenter
                            thickness: panel.thickness
                            vertical: true
                            screenRef: panel.screen
                            barPosition: Settings.barPosition
                            barMargin: Settings.barMargin
                            edgeInset: panel.lengthInset
                        }

                        Column {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 2
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: root.hours
                                color: Theme.barText
                                font.pixelSize: Math.round(panel.thickness * 0.34)
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: root.minutes
                                color: Theme.barText
                                font.pixelSize: Math.round(panel.thickness * 0.34)
                            }
                        }
                    }
                }
            }

            // ============================================================
            // LAYOUT HORIZONTAL (barra no topo/base)
            // ============================================================
            Item {
                id: horizontalLayout
                anchors.fill: parent
                visible: !root.vertical

                // Grupo da esquerda: LauncherButton + Workspaces
                Rectangle {
                    id: leftGroupBg
                    anchors {
                        left: parent.left
                        leftMargin: panel.lengthInset
                        verticalCenter: parent.verticalCenter
                        right: parent.horizontalCenter
                    }
                    height: Math.max(
                        Math.round(panel.thickness * 0.6) + 16,
                        Math.round(panel.thickness * 0.55) + 16
                    )
                    radius: panel.pillRadius
                    color: Theme.moduleBackground
                    border.color: Theme.moduleBorder
                    border.width: 1

                    Row {
                        anchors.centerIn: parent
                        spacing: 6

                        LauncherButton {
                            anchors.verticalCenter: parent.verticalCenter
                            thickness: panel.thickness
                        }

                        Workspaces {
                            anchors.verticalCenter: parent.verticalCenter
                            vertical: false
                            cellSize: Math.round(panel.thickness * 0.55)
                        }
                    }
                }

                // Grupo da direita: AudioIndicator + Relógio
                Rectangle {
                    id: rightGroupBg
                    anchors {
                        right: parent.right
                        rightMargin: panel.lengthInset
                        verticalCenter: parent.verticalCenter
                        left: parent.horizontalCenter
                    }
                    height: Math.max(
                        Math.round(panel.thickness * 0.6) + 16,
                        Math.round(panel.thickness * 0.40) + 16
                    )
                    radius: panel.pillRadius
                    color: Theme.moduleBackground
                    border.color: Theme.moduleBorder
                    border.width: 1

                    Row {
                        anchors.centerIn: parent
                        spacing: 6

                        AudioIndicator {
                            anchors.verticalCenter: parent.verticalCenter
                            thickness: panel.thickness
                            vertical: false
                            screenRef: panel.screen
                            barPosition: Settings.barPosition
                            barMargin: Settings.barMargin
                            edgeInset: panel.lengthInset
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.hours + ":" + root.minutes
                            color: Theme.barText
                            font.pixelSize: Math.round(panel.thickness * 0.40)
                        }
                    }
                }
            }
        }
    }
}
