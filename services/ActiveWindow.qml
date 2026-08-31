pragma Singleton
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    property string title: ""

    function requestRefresh() {
        refreshTimer.restart()
    }

    Component.onCompleted: requestRefresh()

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            const relevant = ["activewindow", "closewindow", "focusedmon", "movewindow"]
            if (relevant.some(prefix => event.name.startsWith(prefix))) {
                root.requestRefresh()
            }
        }
    }

    // debounce: varios eventos costumam chegar juntos
    Timer {
        id: refreshTimer
        interval: 80
        repeat: false
        onTriggered: proc.running = true
    }

    Process {
        id: proc
        command: ["hyprctl", "activewindow", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text)
                    root.title = (data && data.title) ? data.title : ""
                } catch (e) {
                    root.title = ""
                }
            }
        }
    }
}
