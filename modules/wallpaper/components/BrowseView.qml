import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../../config" as ConfigModule
import "../../../services"

Item {
    id: browseView

    readonly property var c: ConfigModule.Theme
    readonly property string fontDisplay: "Noto Serif"
    readonly property string fontBody:    "Noto Sans"
    readonly property int rowItemWidth: 370

    signal wallpaperSelected(string wallpaperId)

    property string downloadingId: ""
    property int tabIndex: 0
    property var localResults: []
    property int localPage: 1
    readonly property int localPageSize: 24
    readonly property int localLastPage: Math.max(1, Math.ceil(browseView.localResults.length / browseView.localPageSize))
    readonly property var localPagedResults: browseView.localResults.slice(
        (browseView.localPage - 1) * browseView.localPageSize,
        browseView.localPage * browseView.localPageSize
    )

    property bool selectMode: false
    property var selectedPaths: []
    property real _savedLocalScrollY: 0

    readonly property string countLabel: {
        if (browseView.tabIndex === 0) return Wallpaper.currentResults.length + " nesta página"
        if (browseView.tabIndex === 1) return browseView.localResults.length + " imagens"
        if (browseView.tabIndex === 2) {
            return groupsBrowser.activeGroupName === ""
                ? groupsBrowser.groupNamesList.length + " grupos"
                : groupsBrowser.activeGroupFiles.length + " imagens"
        }
        return ""
    }

    // ---- estrela / grupos ----
    property var _pendingStarGroups: []
    property bool _pendingToggleSingle: false
    property string starDownloadingId: ""

    function onStarClicked(kind, payload) {
        const names = Groups.groupNames()
        if (names.length === 1) {
            browseView.applyStarDirect(kind, payload, names[0])
            return
        }
        starPicker.openFor(kind, payload)
    }

    function applyStarDirect(kind, payload, groupName) {
        if (kind === "local") {
            if (Groups.groupsForFile(payload.name).indexOf(groupName) !== -1)
                Groups.removeFromGroup(groupName, payload.name)
            else
                Groups.addToGroup(groupName, payload.name)
        } else {
            browseView._pendingStarGroups = [groupName]
            browseView._pendingToggleSingle = true
            browseView.starDownloadingId = payload.id
            Wallpaper.downloadOriginal(payload)
        }
    }

    function onStarPickerConfirmed(selected) {
        if (starPicker.kind === "local") {
            const filename = starPicker.payload.name
            const before = Groups.groupsForFile(filename)
            for (const g of Groups.groupNames()) {
                const isChecked = selected.indexOf(g) !== -1
                const wasIn = before.indexOf(g) !== -1
                if (isChecked && !wasIn) Groups.addToGroup(g, filename)
                else if (!isChecked && wasIn) Groups.removeFromGroup(g, filename)
            }
        } else {
            browseView._pendingStarGroups = selected
            browseView._pendingToggleSingle = false
            browseView.starDownloadingId = starPicker.payload.id
            Wallpaper.downloadOriginal(starPicker.payload)
        }
    }

    function isPathSelected(path) {
        return browseView.selectedPaths.indexOf(path) !== -1
    }
    function toggleSelectPath(path) {
        const idx = browseView.selectedPaths.indexOf(path)
        const arr = browseView.selectedPaths.slice()
        if (idx === -1)
            arr.push(path)
        else
            arr.splice(idx, 1)
        browseView.selectedPaths = arr
    }
    function deleteSelected() {
        browseView._savedLocalScrollY = localGrid.contentX
        Wallpaper.deleteLocalPaths(browseView.selectedPaths)
        browseView.selectedPaths = []
        browseView.selectMode = false
    }
    function deleteSinglePath(path) {
        browseView._savedLocalScrollY = localGrid.contentX
        Wallpaper.deleteLocalPaths([path])
    }

    function updateLocalFilter(resetPage) {
        const q = searchField.text.trim().toLowerCase()
        if (q.length === 0) {
            browseView.localResults = Wallpaper.localList
        } else {
            browseView.localResults = Wallpaper.localList.filter(function (w) {
                return w.name.toLowerCase().indexOf(q) !== -1
            })
        }
        if (resetPage) {
            browseView.localPage = 1
        } else {
            browseView.localPage = Math.max(1, Math.min(browseView.localPage, browseView.localLastPage))
        }
    }

    function localNextPage() {
        if (browseView.localPage < browseView.localLastPage)
            browseView.localPage++
    }

    function localPreviousPage() {
        if (browseView.localPage > 1)
            browseView.localPage--
    }

    function goToPage(page) {
        const maxPage = browseView.tabIndex === 0 ? Wallpaper.lastPage : browseView.localLastPage
        const target = Math.max(1, Math.min(page, maxPage))
        if (browseView.tabIndex === 0) {
            if (!Wallpaper.fetching)
                Wallpaper.search(searchField.text.trim(), target)
        } else {
            browseView.localPage = target
        }
    }

    function switchTab(idx) {
        if (browseView.tabIndex === idx)
            return
        browseView.tabIndex = idx
        searchField.text = ""
        if (idx !== 1) {
            browseView.selectMode = false
            browseView.selectedPaths = []
        }
        if (idx === 0) {
            if (Wallpaper.currentResults.length === 0)
                Wallpaper.search("", 1)
        } else if (idx === 1) {
            browseView.updateLocalFilter(true)
        }
        // idx === 2 (Grupos): GroupsBrowser calcula tudo via bindings reativas
    }

    Component.onCompleted: {
        if (Wallpaper.currentResults.length === 0)
            Wallpaper.search("", 1)
        browseView.updateLocalFilter(true)
    }

    Connections {
        target: Wallpaper
        function onWallpaperApplied(path) {
            browseView.downloadingId = ""
        }
        function onLocalListChanged() {
            if (browseView.tabIndex === 1) {
                browseView.updateLocalFilter(false)
                Qt.callLater(function () {
                    localGrid.contentX = browseView._savedLocalScrollY
                })
            }
        }
        function onOriginalReady(wallpaperId, filename) {
            if (browseView._pendingToggleSingle) {
                const g = browseView._pendingStarGroups[0]
                if (Groups.groupsForFile(filename).indexOf(g) !== -1)
                    Groups.removeFromGroup(g, filename)
                else
                    Groups.addToGroup(g, filename)
            } else if (browseView._pendingStarGroups.length > 0) {
                browseView._pendingStarGroups.forEach(function (g) { Groups.addToGroup(g, filename) })
            }
            browseView._pendingStarGroups = []
            browseView._pendingToggleSingle = false
            browseView.starDownloadingId = ""
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.fillWidth: true
            height: 56
            color: c.surfaceLow
            topLeftRadius: 16
            topRightRadius: 16
            z: 2

            Rectangle {
                anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                height: 1
                color: c.outlineVariant
                opacity: 0.5
            }

            RowLayout {
                anchors { fill: parent; leftMargin: 16; rightMargin: 12 }
                spacing: 10

                Text {
                    text: "🖼️ Wallpapers"
                    font.family: browseView.fontDisplay
                    font.pixelSize: 21
                    color: c.text
                }

                Row {
                    id: tabsRow
                    spacing: 6

                    Rectangle {
                        width: tabWallLabel.implicitWidth + 18
                        height: 26
                        radius: 13
                        color: browseView.tabIndex === 0 ? c.accent : c.surface
                        Behavior on color { ColorAnimation { duration: 150 } }

                        Text {
                            id: tabWallLabel
                            anchors.centerIn: parent
                            text: "Wallhaven"
                            font.family: browseView.fontBody
                            font.pixelSize: 13
                            color: browseView.tabIndex === 0 ? c.accentText : c.textMuted
                        }
                        MouseArea { anchors.fill: parent; onClicked: browseView.switchTab(0) }
                    }

                    Rectangle {
                        width: tabLocalLabel.implicitWidth + 18
                        height: 26
                        radius: 13
                        color: browseView.tabIndex === 1 ? c.accent : c.surface
                        Behavior on color { ColorAnimation { duration: 150 } }

                        Text {
                            id: tabLocalLabel
                            anchors.centerIn: parent
                            text: "Minha Pasta"
                            font.family: browseView.fontBody
                            font.pixelSize: 13
                            color: browseView.tabIndex === 1 ? c.accentText : c.textMuted
                        }
                        MouseArea { anchors.fill: parent; onClicked: browseView.switchTab(1) }
                    }

                    Rectangle {
                        width: tabGroupsLabel.implicitWidth + 18
                        height: 26
                        radius: 13
                        color: browseView.tabIndex === 2 ? c.accent : c.surface
                        Behavior on color { ColorAnimation { duration: 150 } }

                        Text {
                            id: tabGroupsLabel
                            anchors.centerIn: parent
                            text: "Grupos"
                            font.family: browseView.fontBody
                            font.pixelSize: 13
                            color: browseView.tabIndex === 2 ? c.accentText : c.textMuted
                        }
                        MouseArea { anchors.fill: parent; onClicked: browseView.switchTab(2) }
                    }
                }

                Rectangle {
                    id: selectModeToggle
                    visible: browseView.tabIndex === 1
                    width: selectModeLabel.implicitWidth + 18
                    height: 26
                    radius: 13
                    color: browseView.selectMode ? c.danger : c.surface

                    Text {
                        id: selectModeLabel
                        anchors.centerIn: parent
                        text: browseView.selectMode ? "Cancelar" : "Selecionar"
                        font.family: browseView.fontBody
                        font.pixelSize: 13
                        color: browseView.selectMode ? c.accentText : c.textMuted
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            browseView.selectMode = !browseView.selectMode
                            if (!browseView.selectMode)
                                browseView.selectedPaths = []
                        }
                    }
                }

                Rectangle {
                    id: searchBar
                    Layout.fillWidth: true
                    height: 32
                    radius: 16
                    color: c.surface
                    border.color: searchField.activeFocus ? c.accent : c.outlineVariant
                    border.width: searchField.activeFocus ? 1.5 : 1
                    Behavior on border.width { NumberAnimation { duration: 120 } }
                    visible: browseView.tabIndex !== 2

                    TextInput {
                        id: searchField
                        anchors {
                            verticalCenter: parent.verticalCenter
                            left: parent.left; right: clearBtn.left
                            leftMargin: 14; rightMargin: 6
                        }
                        color: c.text
                        font.family: browseView.fontBody
                        font.pixelSize: 15
                        clip: true
                        onTextChanged: {
                            if (browseView.tabIndex === 0)
                                searchDebounce.restart()
                            else
                                browseView.updateLocalFilter(true)
                        }
                        Keys.onEscapePressed: {
                            text = ""
                            if (browseView.tabIndex === 0)
                                Wallpaper.search("", 1)
                            else
                                browseView.updateLocalFilter(true)
                        }
                    }

                    Text {
                        anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: 14 }
                        text: browseView.tabIndex === 0 ? "Search tags…" : "Filtrar arquivos…"
                        color: c.textMuted
                        font.family: browseView.fontBody
                        font.pixelSize: 15
                        visible: searchField.text.length === 0
                        opacity: 0.6
                    }

                    Item {
                        id: clearBtn
                        anchors { right: parent.right; verticalCenter: parent.verticalCenter; rightMargin: 8 }
                        width: 20; height: 20
                        visible: searchField.text.length > 0
                        opacity: visible ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 100 } }

                        Rectangle { anchors.centerIn: parent; width: 16; height: 16; radius: 8; color: c.surfaceHighest }
                        Text { anchors.centerIn: parent; text: "✕"; color: c.textMuted; font.pixelSize: 11; font.bold: true }
                        MouseArea { anchors.fill: parent; onClicked: searchField.text = "" }
                    }
                }

                Timer {
                    id: searchDebounce
                    interval: 400
                    onTriggered: Wallpaper.search(searchField.text.trim(), 1)
                }

                Rectangle {
                    width: countLabelText.implicitWidth + 16
                    height: 24
                    radius: 12
                    color: c.surfaceHigh
                    visible: browseView.countLabel.length > 0

                    Text {
                        id: countLabelText
                        anchors.centerIn: parent
                        text: browseView.countLabel
                        font.family: browseView.fontBody
                        font.pixelSize: 13
                        color: c.textMuted
                    }
                }
            }
        }

        Rectangle {
            id: sortChipsBar
            Layout.fillWidth: true
            height: 40
            color: c.surfaceLow
            clip: true
            visible: browseView.tabIndex === 0

            Rectangle {
                anchors { top: parent.top; left: parent.left; right: parent.right }
                height: 1
                color: c.outlineVariant
                opacity: 0.25
            }

            ListView {
                id: sortList
                anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                orientation: ListView.Horizontal
                spacing: 7
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                model: ListModel {
                    ListElement { label: "Relevance"; value: "relevance" }
                    ListElement { label: "Toplist";   value: "toplist"   }
                    ListElement { label: "Latest";    value: "date_added"}
                    ListElement { label: "Random";    value: "random"    }
                    ListElement { label: "Views";     value: "views"     }
                }

                delegate: Item {
                    width: chip.implicitWidth + 24
                    height: sortList.height

                    Rectangle {
                        id: chip
                        anchors.centerIn: parent
                        implicitWidth: chipLabel.implicitWidth + 24
                        height: 26
                        radius: 13
                        color: Wallpaper.sorting === value ? c.accent : c.surface
                        Behavior on color { ColorAnimation { duration: 180 } }

                        Text {
                            id: chipLabel
                            anchors.centerIn: parent
                            text: label
                            font.family: browseView.fontBody
                            font.pixelSize: 13
                            color: Wallpaper.sorting === value ? c.accentText : c.textMuted
                            Behavior on color { ColorAnimation { duration: 180 } }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            Wallpaper.sorting = value
                            Wallpaper.search(searchField.text.trim(), 1)
                        }
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Rectangle {
                anchors.fill: parent
                color: c.background
                visible: browseView.tabIndex === 0 && Wallpaper.fetching && Wallpaper.currentResults.length === 0
                z: 10

                Row {
                    anchors.centerIn: parent
                    spacing: 10
                    Rectangle {
                        width: 22; height: 22; radius: 11
                        color: "transparent"
                        border.color: c.accent
                        border.width: 2
                        RotationAnimator on rotation {
                            from: 0; to: 360; duration: 800
                            loops: Animation.Infinite
                            running: parent.visible
                            easing.type: Easing.Linear
                        }
                    }
                    Text {
                        text: "loading"
                        color: c.textMuted
                        font.family: browseView.fontBody
                        font.pixelSize: 14
                        opacity: 0.7
                    }
                }
            }

            Rectangle {
                anchors.fill: parent
                color: c.background
                visible: browseView.tabIndex === 0 && Wallpaper.lastError.length > 0 && !Wallpaper.fetching && Wallpaper.currentResults.length === 0
                z: 9

                Text {
                    anchors.centerIn: parent
                    text: "⚠ " + Wallpaper.lastError
                    color: c.textMuted
                    font.pixelSize: 14
                    font.family: browseView.fontBody
                    wrapMode: Text.Wrap
                    width: 300
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            Rectangle {
                anchors.fill: parent
                color: c.background
                visible: browseView.tabIndex === 1 && browseView.localResults.length === 0
                z: 9

                Text {
                    anchors.centerIn: parent
                    text: searchField.text.trim().length > 0 ? "Nada encontrado" : "Nenhum wallpaper salvo ainda"
                    color: c.textMuted
                    font.pixelSize: 14
                    font.family: browseView.fontBody
                }
            }

            ListView {
                id: wallGrid
                anchors.fill: parent
                anchors.margins: 10
                orientation: ListView.Horizontal
                spacing: 10
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                visible: browseView.tabIndex === 0
                model: Wallpaper.currentResults

                ScrollBar.horizontal: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    contentItem: Rectangle { implicitHeight: 3; color: c.accent; opacity: 0.45; radius: 2 }
                }

                WheelHandler {
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    onWheel: (event) => {
                        wallGrid.contentX = Math.max(0, Math.min(wallGrid.contentWidth - wallGrid.width, wallGrid.contentX - event.angleDelta.y))
                    }
                }

                delegate: Item {
                    id: wallCell
                    width: browseView.rowItemWidth
                    height: wallGrid.height

                    readonly property var wallpaperData: modelData
                    readonly property bool hovered: cardHover.hovered
                    readonly property bool wallFavorited: Wallpaper.localList.some(function (w) {
                        return w.name.indexOf("wallhaven_" + wallCell.wallpaperData.id + ".") === 0
                            && Groups.groupsForFile(w.name).length > 0
                    })

                    readonly property var resOptions: {
                        var opts = [{ label: "Original", width: 0, height: 0 }]
                        var seen = {}
                        for (var i = 0; i < Monitors.list.length; i++) {
                            var m = Monitors.list[i]
                            var key = m.width + "x" + m.height
                            if (!seen[key]) {
                                seen[key] = true
                                opts.push({ label: m.name, width: m.width, height: m.height })
                            }
                        }
                        return opts
                    }

                    Rectangle {
                        id: card
                        anchors { top: parent.top; horizontalCenter: parent.horizontalCenter; topMargin: 5 }
                        width: parent.width - 10
                        height: Math.min(parent.height - 10, width * 9 / 16)
                        radius: 14
                        color: c.surface
                        clip: true

                        transform: [
                            Translate {
                                y: wallCell.hovered ? -4 : 0
                                Behavior on y { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                            },
                            Scale {
                                origin.x: card.width / 2
                                origin.y: card.height / 2
                                xScale: cardArea.pressed ? 0.97 : 1.0
                                yScale: cardArea.pressed ? 0.97 : 1.0
                                Behavior on xScale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                                Behavior on yScale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                            }
                        ]

                        Image {
                            id: thumbImg
                            anchors.fill: parent
                            source: Wallpaper.getThumbnailUrl(modelData, "large")
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                            opacity: status === Image.Ready ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 300 } }

                            Rectangle {
                                anchors.fill: parent
                                color: c.surfaceHigh
                                visible: thumbImg.status !== Image.Ready
                                Text { anchors.centerIn: parent; text: "◫"; font.pixelSize: 31; color: c.outline; opacity: 0.25 }
                            }

                            Rectangle {
                                visible: modelData.resolution !== undefined
                                anchors { top: parent.top; right: parent.right; topMargin: 6; rightMargin: 6 }
                                height: 16
                                radius: 8
                                width: resText.implicitWidth + 10
                                color: Qt.rgba(0, 0, 0, 0.7)

                                Text {
                                    id: resText
                                    anchors.centerIn: parent
                                    text: modelData.resolution || ""
                                    font.family: browseView.fontBody
                                    font.pixelSize: 10
                                    font.bold: true
                                    color: c.accent
                                }
                            }
                        }

                        Rectangle {
                            id: starBtn
                            z: 6
                            anchors { top: parent.top; left: parent.left; margins: 6 }
                            width: 20; height: 20; radius: 10
                            color: Qt.rgba(0, 0, 0, 0.55)
                            opacity: (wallCell.hovered || wallCell.wallFavorited) ? 1 : 0
                            visible: opacity > 0.01
                            Behavior on opacity { NumberAnimation { duration: 140 } }

                            Text {
                                anchors.centerIn: parent
                                text: wallCell.wallFavorited ? "★" : "☆"
                                color: wallCell.wallFavorited ? c.accent : "white"
                                font.pixelSize: 14
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: browseView.onStarClicked("wallhaven", wallCell.wallpaperData)
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: 14
                            color: Qt.rgba(0, 0, 0, 0.55)
                            visible: browseView.downloadingId === modelData.id

                            Text {
                                anchors.centerIn: parent
                                text: "aplicando…"
                                color: "white"
                                font.family: browseView.fontBody
                                font.pixelSize: 13
                            }
                        }

                        Rectangle {
                            id: resPanel
                            z: 5
                            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                            height: Math.min(resPanelColumn.implicitHeight + 12, card.height * 0.7)
                            color: Qt.rgba(0, 0, 0, 0.72)
                            opacity: wallCell.hovered ? 1 : 0
                            visible: opacity > 0.01
                            Behavior on opacity { NumberAnimation { duration: 140 } }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.NoButton
                            }

                            Column {
                                id: resPanelColumn
                                anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 6 }
                                spacing: 3

                                Flow {
                                    width: resPanelColumn.width
                                    spacing: 3

                                    Repeater {
                                        model: wallCell.resOptions
                                        delegate: Rectangle {
                                            height: 16
                                            radius: 5
                                            width: optLabel.implicitWidth + 10
                                            color: optArea.containsMouse ? c.accent : Qt.rgba(255, 255, 255, 0.12)

                                            Text {
                                                id: optLabel
                                                anchors.centerIn: parent
                                                text: modelData.width > 0 ? (modelData.width + "×" + modelData.height) : modelData.label
                                                font.family: browseView.fontBody
                                                font.pixelSize: 10
                                                color: "white"
                                            }

                                            MouseArea {
                                                id: optArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                onClicked: {
                                                    browseView.downloadingId = wallCell.wallpaperData.id
                                                    if (modelData.width > 0)
                                                        Wallpaper.downloadAndApply(wallCell.wallpaperData, modelData.width, modelData.height, 1)
                                                    else
                                                        Wallpaper.downloadAndApply(wallCell.wallpaperData, 0, 0, 1)
                                                    browseView.wallpaperSelected(wallCell.wallpaperData.id)
                                                }
                                            }
                                        }
                                    }
                                }

                                Rectangle {
                                    width: resPanelColumn.width
                                    height: 16
                                    radius: 5
                                    color: moreOptArea.containsMouse ? Qt.rgba(255, 255, 255, 0.18) : "transparent"

                                    Text {
                                        anchors.centerIn: parent
                                        text: "☰ mais resoluções"
                                        font.family: browseView.fontBody
                                        font.pixelSize: 10
                                        color: c.textMuted
                                    }

                                    MouseArea {
                                        id: moreOptArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: {
                                            resolutionOverlay.wallpaper = wallCell.wallpaperData
                                            resolutionOverlay.open = true
                                        }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: 14
                            color: c.accent
                            opacity: cardArea.pressed ? 0.16 : (cardHover.hovered && !wallCell.hovered ? 0.07 : 0)
                            Behavior on opacity { NumberAnimation { duration: 130 } }
                        }

                        MouseArea {
                            id: cardArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                browseView.downloadingId = modelData.id
                                Wallpaper.downloadAndApply(modelData, 0, 0, 1)
                                browseView.wallpaperSelected(modelData.id)
                            }
                        }
                        HoverHandler {
                            id: cardHover
                            target: card
                        }
                    }
                }
            }

            ListView {
                id: localGrid
                anchors.fill: parent
                anchors.margins: 10
                orientation: ListView.Horizontal
                spacing: 10
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                visible: browseView.tabIndex === 1
                model: browseView.localPagedResults

                ScrollBar.horizontal: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    contentItem: Rectangle { implicitHeight: 3; color: c.accent; opacity: 0.45; radius: 2 }
                }

                WheelHandler {
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    onWheel: (event) => {
                        localGrid.contentX = Math.max(0, Math.min(localGrid.contentWidth - localGrid.width, localGrid.contentX - event.angleDelta.y))
                    }
                }

                delegate: Item {
                    id: localCell
                    width: browseView.rowItemWidth
                    height: localGrid.height
                    readonly property bool localFavorited: Groups.groupsForFile(modelData.name).length > 0

                    Rectangle {
                        id: localCard
                        anchors { top: parent.top; horizontalCenter: parent.horizontalCenter; topMargin: 26 }
                        width: parent.width - 10
                        height: Math.min(parent.height - 10, width * 9 / 16)
                        radius: 14
                        color: c.surface
                        clip: true

                        Image {
                            id: localThumbImg
                            anchors.fill: parent
                            source: "file://" + modelData.path
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                            sourceSize.width: localCard.width
                            sourceSize.height: localCard.height
                            opacity: status === Image.Ready ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 300 } }

                            Rectangle {
                                anchors.fill: parent
                                color: c.surfaceHigh
                                visible: localThumbImg.status !== Image.Ready
                                Text { anchors.centerIn: parent; text: "◫"; font.pixelSize: 31; color: c.outline; opacity: 0.25 }
                            }

                            Rectangle {
                                anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                                height: 20
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0) }
                                    GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.65) }
                                }
                                Text {
                                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom; leftMargin: 8; rightMargin: 8; bottomMargin: 3 }
                                    text: modelData.name
                                    color: "white"
                                    font.family: browseView.fontBody
                                    font.pixelSize: 11
                                    elide: Text.ElideMiddle
                                }
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: 14
                            color: c.accent
                            opacity: localCardArea.pressed ? 0.16 : (localCardArea.containsMouse ? 0.07 : 0)
                            Behavior on opacity { NumberAnimation { duration: 130 } }
                        }

                        transform: Scale {
                            origin.x: localCard.width / 2
                            origin.y: localCard.height / 2
                            xScale: localCardArea.pressed ? 0.97 : 1.0
                            yScale: localCardArea.pressed ? 0.97 : 1.0
                            Behavior on xScale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                            Behavior on yScale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                        }

                        MouseArea {
                            id: localCardArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                if (browseView.selectMode) {
                                    browseView.toggleSelectPath(modelData.path)
                                } else {
                                    Wallpaper.applyPath(modelData.path)
                                    browseView.wallpaperSelected(modelData.path)
                                }
                            }
                        }

                        Rectangle {
                            id: selectCheck
                            visible: browseView.selectMode
                            z: 10
                            anchors { top: parent.top; left: parent.left; margins: 6 }
                            width: 20; height: 20; radius: 10
                            color: browseView.isPathSelected(modelData.path) ? c.accent : Qt.rgba(0, 0, 0, 0.55)
                            border.color: "white"
                            border.width: 1
                            Text {
                                anchors.centerIn: parent
                                visible: browseView.isPathSelected(modelData.path)
                                text: "✓"
                                color: "white"
                                font.pixelSize: 14
                                font.bold: true
                            }
                        }

                        Rectangle {
                            id: localStarBtn
                            visible: !browseView.selectMode && (localCardArea.containsMouse || localCell.localFavorited)
                            z: 10
                            anchors { top: parent.top; left: parent.left; margins: 6 }
                            width: 20; height: 20; radius: 10
                            color: Qt.rgba(0, 0, 0, 0.65)
                            Text {
                                anchors.centerIn: parent
                                text: localCell.localFavorited ? "★" : "☆"
                                color: localCell.localFavorited ? c.accent : "white"
                                font.pixelSize: 14
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: browseView.onStarClicked("local", modelData)
                            }
                        }

                        Rectangle {
                            id: activeBadge
                            visible: !localCardArea.containsMouse && modelData.path === Wallpaper.appliedPath
                            z: 10
                            anchors { top: parent.top; right: parent.right; margins: 6 }
                            height: 18
                            radius: 9
                            width: activeLabel.implicitWidth + 14
                            color: c.accent
                            Text {
                                id: activeLabel
                                anchors.centerIn: parent
                                text: "Ativo"
                                color: c.accentText
                                font.family: browseView.fontBody
                                font.pixelSize: 11
                                font.bold: true
                            }
                        }

                        Rectangle {
                            id: deleteBtn
                            visible: !browseView.selectMode && localCardArea.containsMouse
                            z: 10
                            anchors { top: parent.top; right: parent.right; margins: 6 }
                            width: 20; height: 20; radius: 10
                            color: Qt.rgba(0, 0, 0, 0.65)
                            Text { anchors.centerIn: parent; text: "✕"; color: "white"; font.pixelSize: 13; font.bold: true }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: browseView.deleteSinglePath(modelData.path)
                            }
                        }
                    }
                }
            }

            GroupsBrowser {
                id: groupsBrowser
                anchors.fill: parent
                visible: browseView.tabIndex === 2
                rowItemWidth: browseView.rowItemWidth
                onWallpaperSelected: function (path) { browseView.wallpaperSelected(path) }
            }

            Rectangle {
                id: pagerBar
                anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                height: 44
                color: c.surfaceLow
                bottomLeftRadius: 0
                bottomRightRadius: 0
                visible: browseView.tabIndex === 0 || browseView.localLastPage > 1 || (browseView.selectMode && browseView.tabIndex === 1)

                readonly property int curPage: browseView.tabIndex === 0 ? Wallpaper.currentPage : browseView.localPage
                readonly property int lastPg: browseView.tabIndex === 0 ? Wallpaper.lastPage : browseView.localLastPage
                readonly property bool busy: browseView.tabIndex === 0 ? Wallpaper.fetching : false
                readonly property bool showSelectionBar: browseView.selectMode && browseView.tabIndex === 1

                Rectangle {
                    anchors { top: parent.top; left: parent.left; right: parent.right }
                    height: 1
                    color: c.outlineVariant
                    opacity: 0.3
                }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 16

                    Rectangle {
                        width: 30; height: 30; radius: 15
                        color: pagerBar.curPage > 1 ? c.surface : c.surfaceLow
                        opacity: pagerBar.curPage > 1 && !pagerBar.busy ? 1 : 0.35
                        Text { anchors.centerIn: parent; text: "‹"; font.pixelSize: 19; color: c.text }
                        MouseArea {
                            anchors.fill: parent
                            enabled: pagerBar.curPage > 1 && !pagerBar.busy
                            onClicked: browseView.tabIndex === 0 ? Wallpaper.previousPage() : browseView.localPreviousPage()
                        }
                    }

                    Text {
                        text: "Página " + pagerBar.curPage + " de " + pagerBar.lastPg
                        color: c.textMuted
                        font.pixelSize: 14
                    }

                    Rectangle {
                        width: 30; height: 30; radius: 15
                        color: pagerBar.curPage < pagerBar.lastPg ? c.surface : c.surfaceLow
                        opacity: pagerBar.curPage < pagerBar.lastPg && !pagerBar.busy ? 1 : 0.35
                        Text { anchors.centerIn: parent; text: "›"; font.pixelSize: 19; color: c.text }
                        MouseArea {
                            anchors.fill: parent
                            enabled: pagerBar.curPage < pagerBar.lastPg && !pagerBar.busy
                            onClicked: browseView.tabIndex === 0 ? Wallpaper.nextPage() : browseView.localNextPage()
                        }
                    }
                }

                RowLayout {
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter; rightMargin: 14 }
                    spacing: 8
                    visible: pagerBar.showSelectionBar

                    Text {
                        text: browseView.selectedPaths.length + " sel."
                        color: c.textMuted
                        font.family: browseView.fontBody
                        font.pixelSize: 14
                    }

                    Rectangle {
                        width: 120; height: 28; radius: 14
                        color: browseView.selectedPaths.length > 0 ? c.danger : c.surface
                        opacity: browseView.selectedPaths.length > 0 ? 1 : 0.5
                        Text {
                            anchors.centerIn: parent
                            text: "Apagar selecionados"
                            font.family: browseView.fontBody
                            font.pixelSize: 12
                            font.bold: true
                            color: c.accentText
                        }
                        MouseArea {
                            anchors.fill: parent
                            enabled: browseView.selectedPaths.length > 0
                            onClicked: browseView.deleteSelected()
                        }
                    }
                }
            }
        }
    }

    ResolutionOverlay {
        id: resolutionOverlay
    }

    StarPicker {
        id: starPicker
        onConfirmed: function (selected) { browseView.onStarPickerConfirmed(selected) }
    }
}
