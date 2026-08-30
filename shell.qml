import Quickshell
import QtQml
import "./modules/bar"
import "./modules/launcher"
import "./modules/wallpaper"
import "./services"
import "./config"

ShellRoot {
    Component.onCompleted: Wallpaper.scanLocal()
    Binding {
        target: Theme
        property: "_wallpaperPath"
        value: Wallpaper.appliedPath
    }
    Bar {}
    Launcher {}
    WallpaperPanel {}
}
