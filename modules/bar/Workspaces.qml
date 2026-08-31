import Quickshell
import Quickshell.Hyprland
import QtQuick
import "../../config"

Item {
    id: root
    property bool vertical: false
    property int cellSize: 22
    property int workspaceCount: 5

    readonly property int iconSize: Math.round(cellSize * 0.78)
    readonly property int dotSize: Math.max(4, Math.round(cellSize * 0.24))
    readonly property int cellSpacing: Math.max(3, Math.round(cellSize * 0.22))
    readonly property int trackPadding: Math.max(4, Math.round(cellSize * 0.28))

    implicitWidth: vertical ? cellSize + trackPadding * 2 : track.implicitWidth
    implicitHeight: vertical ? track.implicitHeight : cellSize + trackPadding * 2

    // Trilho de fundo - cor diferente da barra (moduleBackground/moduleBorder,
    // ja calculados via matugen a partir do wallpaper)
    Rectangle {
        id: track
        anchors.centerIn: parent
        implicitWidth: content.implicitWidth + root.trackPadding * 2
        implicitHeight: content.implicitHeight + root.trackPadding * 2
        radius: width < height ? width / 2 : height / 2
        color: Theme.barSecondary
        border.color: Theme.barOutlineVariant
        border.width: 1

        Loader {
            id: content
            anchors.centerIn: parent
            sourceComponent: root.vertical ? columnComp : rowComp
        }
    }

    Component {
        id: rowComp
        Row { spacing: root.cellSpacing; Repeater { model: root.workspaceCount; delegate: wsDelegate } }
    }
    Component {
        id: columnComp
        Column { spacing: root.cellSpacing; Repeater { model: root.workspaceCount; delegate: wsDelegate } }
    }
    Component {
        id: wsDelegate
        Rectangle {
            id: wsRect
            required property int index
            property int wsId: index + 1
            property bool active: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === wsId

            property bool hasToplevel: {
                const all = [...Hyprland.toplevels.values]
                return all.some(t => t.workspace && t.workspace.id === wsId)
            }

            property string lastAppId: WorkspaceHistory.appIdFor(wsId)

            property var desktopEntry: {
                if (!lastAppId || !hasToplevel) return null
                const heur = DesktopEntries.heuristicLookup(lastAppId)
                if (heur) return heur
                const all = [...DesktopEntries.applications.values]
                return all.find(d => d.startupWmClass &&
                    d.startupWmClass.toLowerCase() === lastAppId.toLowerCase()) || null
            }

            width: root.cellSize
            height: root.cellSize
            radius: Math.round(root.cellSize * 0.32)
            // Sem borda propria - o trilho ja da o contorno do grupo
            color: wsRect.active
                ? Theme.barAccent
                : (wsRect.hasToplevel
                    ? Qt.rgba(Theme.barOnSecondary.r, Theme.barOnSecondary.g, Theme.barOnSecondary.b, 0.22)
                    : "transparent")

            Behavior on color { ColorAnimation { duration: 120 } }

            Image {
                anchors.centerIn: parent
                width: root.iconSize
                height: root.iconSize
                visible: wsRect.desktopEntry !== null
                opacity: wsRect.active ? 1 : 0.85
                source: wsRect.desktopEntry ? Quickshell.iconPath(wsRect.desktopEntry.icon, "") : ""
            }
            // Ponto liso no lugar do numero, quando nao ha icone de app
            Rectangle {
                anchors.centerIn: parent
                visible: wsRect.desktopEntry === null
                width: root.dotSize
                height: root.dotSize
                radius: root.dotSize / 2
                color: wsRect.active ? Theme.barAccentText : Theme.barOnSecondary
                opacity: wsRect.active ? 1 : (wsRect.hasToplevel ? 0.9 : 0.55)
            }
            MouseArea {
                anchors.fill: parent
                onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = " + wsId + " })")
            }
        }
    }
}
