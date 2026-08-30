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
    readonly property int fontSize: Math.round(cellSize * 0.5)
    readonly property int cellSpacing: Math.max(3, Math.round(cellSize * 0.22))

    implicitWidth: vertical ? cellSize : content.implicitWidth
    implicitHeight: vertical ? content.implicitHeight : cellSize
    Loader {
        id: content
        anchors.centerIn: parent
        sourceComponent: root.vertical ? columnComp : rowComp
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
            color: wsRect.active
                ? Theme.text
                : (wsRect.hasToplevel
                    ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.16)
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
            Text {
                anchors.centerIn: parent
                visible: wsRect.desktopEntry === null
                text: wsId
                color: wsRect.active ? Theme.background : Theme.text
                opacity: wsRect.active ? 1 : (wsRect.hasToplevel ? 0.85 : 0.35)
                font.pixelSize: root.fontSize
            }
            MouseArea {
                anchors.fill: parent
                onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = " + wsId + " })")
            }
        }
    }
}
