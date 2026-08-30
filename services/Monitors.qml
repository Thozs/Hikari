pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
    id: root

    property var list: []

    function refresh() {
        var out = []
        var mons = Hyprland.monitors.values
        for (var i = 0; i < mons.length; i++) {
            var m = mons[i]
            out.push({
                name: m.name,
                width: m.width,
                height: m.height,
                scale: m.scale,
                focused: m.focused
            })
        }
        list = out
    }

    Component.onCompleted: refresh()
}
