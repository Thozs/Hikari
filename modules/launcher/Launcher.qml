import Quickshell
import Quickshell.Io
import QtQuick
import "../../config"
import "FuzzyMatch.js" as Fuzzy

Scope {
    id: root
    property bool open: false

    IpcHandler {
        target: "launcher"
        function toggle(): void { root.open = !root.open }
        function show(): void { root.open = true }
        function hide(): void { root.open = false }
    }

    function filteredEntries(query) {
        query = query.trim()

        if (query.startsWith(">")) {
            const cmd = query.slice(1).trim()
            if (cmd.length === 0) return []
            return [{ label: "Executar: " + cmd, kind: "command", command: cmd }]
        }

        if (query.startsWith("/")) {
            const actions = [
                { label: "Sair do Arnyx Shell", kind: "action", command: "quit" }
            ]
            const q = query.slice(1).trim().toLowerCase()
            if (q.length === 0) return actions
            return actions.filter(a => a.label.toLowerCase().includes(q))
        }

        const all = [...DesktopEntries.applications.values].filter(e => e.name)
        if (query.length === 0) {
            return all
                .sort((a, b) => a.name.localeCompare(b.name))
                .slice(0, 30)
                .map(e => ({ label: e.name, kind: "app", entry: e }))
        }

        return all
            .map(e => ({ entry: e, s: Fuzzy.score(query, e.name) }))
            .filter(r => r.s >= 0)
            .sort((a, b) => b.s - a.s)
            .slice(0, 30)
            .map(r => ({ label: r.entry.name, kind: "app", entry: r.entry }))
    }

    LazyLoader {
        active: root.open

        PanelWindow {
            id: win
            focusable: true
            color: "transparent"

            property int itemHeight: 64
            property int visibleItems: 5
            property int searchHeight: 26
            property int panelMargins: 12
            property int panelSpacing: 8

            implicitWidth: 760
            implicitHeight: panelMargins * 2
                + itemHeight * visibleItems
                + panelSpacing * 2
                + 1
                + searchHeight

            property int openMargin: 0

            anchors {
                bottom: true
            }

            exclusiveZone: 0

            margins.bottom: -win.implicitHeight

            Behavior on margins.bottom {
                NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
            }

            Component.onCompleted: margins.bottom = win.openMargin

            function activate(index) {
                const item = root.filteredEntries(search.text)[index]
                if (!item) return

                if (item.kind === "app") {
                    item.entry.execute()
                } else if (item.kind === "command") {
                    Quickshell.execDetached(["kitty", "-e", "sh", "-c", item.command])
                } else if (item.kind === "action" && item.command === "quit") {
                    Qt.quit()
                }

                root.open = false
                search.text = ""
            }

            Rectangle {
                anchors.fill: parent
                radius: 12
                bottomLeftRadius: 0
                bottomRightRadius: 0
                color: Theme.barBackground
                border.color: Theme.barOutlineVariant
                border.width: 1

                Column {
                    anchors.fill: parent
                    anchors.margins: win.panelMargins
                    spacing: win.panelSpacing

                    ListView {
                        id: resultsList
                        width: parent.width
                        height: win.itemHeight * win.visibleItems
                        clip: true
                        currentIndex: 0

                        model: ScriptModel {
                            values: root.filteredEntries(search.text)
                        }

                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            width: resultsList.width
                            height: win.itemHeight
                            color: index === resultsList.currentIndex ? Theme.surface : "transparent"
                            radius: 6

                            Row {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 14
                                spacing: 12

                                Image {
                                    width: 34
                                    height: 34
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: modelData.kind === "app" && !!modelData.entry.icon
                                    source: (modelData.kind === "app" && modelData.entry.icon)
                                        ? Quickshell.iconPath(modelData.entry.icon, "")
                                        : ""
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.label
                                    color: Theme.text
                                    font.pixelSize: 19
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onEntered: resultsList.currentIndex = index
                                onClicked: win.activate(index)
                            }
                        }
                    }

                    Rectangle { width: parent.width; height: 1; color: Theme.surface }

                    TextInput {
                        id: search
                        width: parent.width
                        height: win.searchHeight
                        color: Theme.text
                        font.pixelSize: 16
                        focus: true
                        clip: true

                        Keys.onPressed: (event) => {
                            if (event.key === Qt.Key_Escape) {
                                root.open = false
                                search.text = ""
                                event.accepted = true
                            } else if (event.key === Qt.Key_Down) {
                                resultsList.currentIndex = Math.min(resultsList.currentIndex + 1, resultsList.count - 1)
                                event.accepted = true
                            } else if (event.key === Qt.Key_Up) {
                                resultsList.currentIndex = Math.max(resultsList.currentIndex - 1, 0)
                                event.accepted = true
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                win.activate(resultsList.currentIndex)
                                event.accepted = true
                            }
                        }
                    }
                }
            }
        }
    }
}
