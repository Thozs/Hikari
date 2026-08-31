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
                { label: "🔄 Recarregar Shell", kind: "action", command: "reload" },
                { label: "📝 Editar Configuração", kind: "action", command: "edit-config" },
                { label: "🖼️ Abrir Seletor de Wallpaper", kind: "action", command: "wallpaper" },
                { label: "📐 Trocar Posição da Barra", kind: "action", command: "cycle-bar-position" },
                { label: "📊 Mostrar Informações do Sistema", kind: "action", command: "sysinfo" },
                { label: "❌ Sair do Arnyx Shell", kind: "action", command: "quit" }
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
            property int searchHeight: 42
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
                NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
            }

            Component.onCompleted: {
                margins.bottom = win.openMargin
                search.forceActiveFocus()
            }

            function activate(index) {
                const item = root.filteredEntries(search.text)[index]
                if (!item) return

                if (item.kind === "app") {
                    item.entry.execute()
                } else if (item.kind === "command") {
                    Quickshell.execDetached(["kitty", "-e", "sh", "-c", item.command])
                } else if (item.kind === "action") {
                    if (item.command === "quit") {
                        Qt.quit()
                    } else if (item.command === "reload") {
                        Quickshell.execDetached(["sh", "-c", "quickshell kill -c arnyx-qs; sleep 0.3; quickshell -c arnyx-qs &"])
                    } else if (item.command === "edit-config") {
                        Quickshell.execDetached(["sh", "-c", "kitty -e nvim ~/.config/quickshell/arnyx-qs"])
                    } else if (item.command === "wallpaper") {
                        Quickshell.execDetached(["quickshell", "ipc", "-c", "arnyx-qs", "call", "wallpaper", "toggle"])
                    } else if (item.command === "sysinfo") {
                        Quickshell.execDetached(["kitty", "--hold", "-e", "fastfetch"])
                    } else if (item.command === "cycle-bar-position") {
                        const order = ["left", "top", "right", "bottom"]
                        const idx = order.indexOf(Settings.barPosition)
                        Settings.barPosition = order[(idx + 1) % order.length]
                    }
                }

                root.open = false
                search.text = ""
            }

            Rectangle {
                id: content
                anchors.fill: parent
                radius: 12
                bottomLeftRadius: 0
                bottomRightRadius: 0
                color: Theme.launcherBackground
                border.color: Theme.launcherListBorder
                border.width: 1

                Column {
                    anchors.fill: parent
                    anchors.margins: win.panelMargins
                    spacing: win.panelSpacing

                    // Área da lista de resultados
                    ListView {
                        id: resultsList
                        width: parent.width
                        height: win.itemHeight * win.visibleItems
                        clip: true
                        currentIndex: 0
                        focus: true

                        model: ScriptModel {
                            values: root.filteredEntries(search.text)
                        }

                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            width: resultsList.width
                            height: win.itemHeight
                            radius: 6
                            color: index === resultsList.currentIndex ? Theme.launcherSelectedBg : "transparent"
                            border.color: Theme.launcherItemBorder
                            border.width: 1

                            Row {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 14
                                anchors.right: parent.right
                                anchors.rightMargin: 14
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
                                    color: Theme.launcherText
                                    font.pixelSize: 19
                                    elide: Text.ElideRight
                                    width: parent.width - 60
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onEntered: resultsList.currentIndex = index
                                onClicked: win.activate(index)
                            }
                        }

                        // Navegação por teclado direta na lista
                        Keys.onPressed: (event) => {
                            if (event.key === Qt.Key_Down) {
                                resultsList.currentIndex = Math.min(resultsList.currentIndex + 1, resultsList.count - 1)
                                event.accepted = true
                            } else if (event.key === Qt.Key_Up) {
                                resultsList.currentIndex = Math.max(resultsList.currentIndex - 1, 0)
                                event.accepted = true
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                win.activate(resultsList.currentIndex)
                                event.accepted = true
                            } else if (event.key === Qt.Key_Escape) {
                                root.open = false
                                search.text = ""
                                event.accepted = true
                            }
                        }
                    }

                    // Separador
                    Rectangle {
                        width: parent.width
                        height: 1
                        color: Theme.launcherListBorder
                        opacity: 0.5
                    }

                    // Barra de pesquisa
                    Rectangle {
                        id: searchContainer
                        width: parent.width
                        height: win.searchHeight
                        radius: 8
                        color: Theme.launcherSearchBackground
                        border.color: Theme.launcherSearchBorder
                        border.width: 2

                        TextInput {
                            id: search
                            anchors.fill: parent
                            anchors.margins: 12
                            color: Theme.launcherText
                            font.pixelSize: 16
                            focus: true
                            clip: true
                            selectByMouse: true

                            Keys.onPressed: (event) => {
                                // Teclas de navegação vão direto para a lista
                                if (event.key === Qt.Key_Down || event.key === Qt.Key_Up) {
                                    resultsList.forceActiveFocus()
                                    resultsList.currentIndex = event.key === Qt.Key_Down ? 0 : resultsList.count - 1
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Escape) {
                                    root.open = false
                                    search.text = ""
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    if (resultsList.count > 0) {
                                        win.activate(resultsList.currentIndex)
                                    }
                                    event.accepted = true
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
