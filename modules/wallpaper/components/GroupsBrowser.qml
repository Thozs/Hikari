import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../../config" as ConfigModule
import "../../../services"

Item {
    id: gb

    readonly property var c: ConfigModule.Theme
    readonly property string fontBody: "Noto Sans"
    property int rowItemWidth: 370

    signal wallpaperSelected(string path)

    // ---- navegacao ----
    property string activeGroupName: ""
    property int groupPage: 1
    readonly property int groupPageSize: 24

    readonly property var groupNamesList: Groups.groupNames()

    readonly property var activeGroupFiles: {
        if (gb.activeGroupName === "") return []
        const names = Groups.contentsOf(gb.activeGroupName)
        const byName = {}
        for (const w of Wallpaper.localList) byName[w.name] = w
        const out = []
        for (const n of names) if (byName[n]) out.push(byName[n])
        return out
    }
    readonly property int groupLastPage: Math.max(1, Math.ceil(gb.activeGroupFiles.length / gb.groupPageSize))
    readonly property var groupPagedFiles: gb.activeGroupFiles.slice(
        (gb.groupPage - 1) * gb.groupPageSize, gb.groupPage * gb.groupPageSize)

    function enterGroup(name) {
        gb.activeGroupName = name
        gb.groupPage = 1
        gb.selectMode = false
        gb.selectedNames = []
    }
    function exitGroup() {
        gb.activeGroupName = ""
        gb.selectMode = false
        gb.selectedNames = []
        gb.targetPickerMode = ""
    }
    function nextGroupPage() { if (gb.groupPage < gb.groupLastPage) gb.groupPage++ }
    function prevGroupPage() { if (gb.groupPage > 1) gb.groupPage-- }

    // ---- selecao (dentro de um grupo) ----
    property bool selectMode: false
    property var selectedNames: []

    function isNameSelected(n) { return gb.selectedNames.indexOf(n) !== -1 }
    function toggleSelectName(n) {
        const idx = gb.selectedNames.indexOf(n)
        const arr = gb.selectedNames.slice()
        if (idx === -1) arr.push(n); else arr.splice(idx, 1)
        gb.selectedNames = arr
    }

    // ---- criar / renomear grupo (barra de prompt) ----
    property string promptMode: ""   // "", "create", "rename"
    property string promptTarget: ""
    property string promptText: ""

    function openCreatePrompt() { gb.promptMode = "create"; gb.promptTarget = ""; gb.promptText = "" }
    function openRenamePrompt(name) { gb.promptMode = "rename"; gb.promptTarget = name; gb.promptText = name }
    function closePrompt() { gb.promptMode = ""; gb.promptTarget = ""; gb.promptText = "" }
    function confirmPrompt() {
        const text = gb.promptText.trim()
        if (text.length > 0) {
            if (gb.promptMode === "create") Groups.createGroup(text)
            else if (gb.promptMode === "rename") Groups.renameGroup(gb.promptTarget, text)
        }
        gb.closePrompt()
    }

    // ---- mesclar grupos ----
    property bool mergeMode: false
    property var mergeSelected: []
    property string mergeNameText: ""

    function toggleMergeMode() {
        gb.mergeMode = !gb.mergeMode
        gb.mergeSelected = []
        gb.mergeNameText = ""
    }
    function toggleMergeSelect(name) {
        const idx = gb.mergeSelected.indexOf(name)
        const arr = gb.mergeSelected.slice()
        if (idx === -1) {
            arr.push(name)
        } else {
            arr.splice(idx, 1)
        }
        gb.mergeSelected = arr
        if (gb.mergeNameText.length === 0 && arr.length > 0) gb.mergeNameText = arr[0]
    }
    function confirmMerge() {
        const name = gb.mergeNameText.trim()
        if (gb.mergeSelected.length >= 2 && name.length > 0) {
            Groups.mergeGroups(gb.mergeSelected.slice(), name)
        }
        gb.toggleMergeMode()
    }

    // ---- mover / copiar (dentro de um grupo) ----
    property string targetPickerMode: ""   // "", "move", "copy"

    function openTargetPicker(mode) { gb.targetPickerMode = mode }
    function closeTargetPicker() { gb.targetPickerMode = "" }
    function chooseTarget(name) {
        const files = gb.selectedNames.slice()
        if (gb.targetPickerMode === "move") {
            Groups.moveFiles(gb.activeGroupName, name, files)
        } else if (gb.targetPickerMode === "copy") {
            Groups.copyFiles(name, files)
        }
        gb.selectedNames = []
        gb.selectMode = false
        gb.closeTargetPicker()
    }
    function removeSelectedFromGroup() {
        Groups.removeManyFromGroup(gb.activeGroupName, gb.selectedNames.slice())
        gb.selectedNames = []
        gb.selectMode = false
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ---- barra de ferramentas ----
        Rectangle {
            Layout.fillWidth: true
            height: 48
            color: c.surfaceLow
            clip: true

            Rectangle {
                anchors { top: parent.top; left: parent.left; right: parent.right }
                height: 1
                color: c.outlineVariant
                opacity: 0.25
            }

            // lista de grupos: criar + mesclar
            RowLayout {
                anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                spacing: 10
                visible: gb.activeGroupName === "" && gb.promptMode === "" && !gb.mergeMode

                Rectangle {
                    width: 28; height: 28; radius: 14
                    color: c.surfaceHigh
                    Text { anchors.centerIn: parent; text: "+"; color: c.text; font.pixelSize: 19 }
                    MouseArea { anchors.fill: parent; onClicked: gb.openCreatePrompt() }
                }
                Text {
                    text: "novo grupo"
                    color: c.textMuted
                    font.family: gb.fontBody
                    font.pixelSize: 14
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    visible: gb.groupNamesList.length >= 2
                    width: mergeLabel.implicitWidth + 20
                    height: 28
                    radius: 14
                    color: c.surface
                    border.color: c.outlineVariant
                    border.width: 1
                    Text {
                        id: mergeLabel
                        anchors.centerIn: parent
                        text: "Mesclar grupos"
                        font.family: gb.fontBody
                        font.pixelSize: 14
                        color: c.textMuted
                    }
                    MouseArea { anchors.fill: parent; onClicked: gb.toggleMergeMode() }
                }
            }

            // dentro de um grupo: voltar + nome + selecionar
            RowLayout {
                anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                spacing: 10
                visible: gb.activeGroupName !== "" && gb.promptMode === "" && !gb.mergeMode

                Rectangle {
                    width: backLabel.implicitWidth + 20; height: 28; radius: 14
                    color: c.surface
                    Text { id: backLabel; anchors.centerIn: parent; text: "‹ Voltar"; font.family: gb.fontBody; font.pixelSize: 14; color: c.text }
                    MouseArea { anchors.fill: parent; onClicked: gb.exitGroup() }
                }

                Text {
                    Layout.fillWidth: true
                    text: gb.activeGroupName
                    color: c.text
                    font.family: gb.fontBody
                    font.pixelSize: 16
                    font.bold: true
                    elide: Text.ElideRight
                }

                Rectangle {
                    width: selLabel.implicitWidth + 20; height: 28; radius: 14
                    color: gb.selectMode ? c.danger : c.surface
                    Text {
                        id: selLabel
                        anchors.centerIn: parent
                        text: gb.selectMode ? "Cancelar" : "Selecionar"
                        font.family: gb.fontBody
                        font.pixelSize: 14
                        color: gb.selectMode ? c.accentText : c.textMuted
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            gb.selectMode = !gb.selectMode
                            if (!gb.selectMode) gb.selectedNames = []
                        }
                    }
                }
            }

            // barra de criar/renomear grupo
            RowLayout {
                anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                spacing: 8
                visible: gb.promptMode !== ""

                Text {
                    text: gb.promptMode === "create" ? "Nome do grupo:" : "Renomear para:"
                    color: c.textMuted
                    font.family: gb.fontBody
                    font.pixelSize: 14
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 30
                    radius: 8
                    color: c.surface
                    border.color: promptField.activeFocus ? c.accent : c.outlineVariant
                    border.width: 1

                    TextInput {
                        id: promptField
                        anchors { fill: parent; margins: 7 }
                        color: c.text
                        font.family: gb.fontBody
                        font.pixelSize: 15
                        clip: true
                        text: gb.promptText
                        onTextChanged: gb.promptText = text
                        Keys.onReturnPressed: gb.confirmPrompt()
                        Keys.onEscapePressed: gb.closePrompt()
                        Component.onCompleted: forceActiveFocus()
                    }
                }

                Rectangle {
                    width: 60; height: 28; radius: 8
                    color: c.accent
                    Text { anchors.centerIn: parent; text: "OK"; color: c.accentText; font.family: gb.fontBody; font.pixelSize: 14; font.bold: true }
                    MouseArea { anchors.fill: parent; onClicked: gb.confirmPrompt() }
                }
                Rectangle {
                    width: 28; height: 28; radius: 8
                    color: c.surfaceHigh
                    Text { anchors.centerIn: parent; text: "✕"; color: c.textMuted; font.pixelSize: 13 }
                    MouseArea { anchors.fill: parent; onClicked: gb.closePrompt() }
                }
            }

            // barra de mesclagem
            RowLayout {
                anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                spacing: 8
                visible: gb.mergeMode

                Text {
                    text: gb.mergeSelected.length + " selecionados"
                    color: c.textMuted
                    font.family: gb.fontBody
                    font.pixelSize: 14
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 30
                    radius: 8
                    color: c.surface
                    border.color: mergeNameField.activeFocus ? c.accent : c.outlineVariant
                    border.width: 1
                    visible: gb.mergeSelected.length >= 2

                    TextInput {
                        id: mergeNameField
                        anchors { fill: parent; margins: 7 }
                        color: c.text
                        font.family: gb.fontBody
                        font.pixelSize: 15
                        clip: true
                        text: gb.mergeNameText
                        onTextChanged: gb.mergeNameText = text
                        Keys.onReturnPressed: gb.confirmMerge()
                    }
                }

                Rectangle {
                    visible: gb.mergeSelected.length >= 2
                    width: 80; height: 28; radius: 8
                    color: c.accent
                    Text { anchors.centerIn: parent; text: "Mesclar"; color: c.accentText; font.family: gb.fontBody; font.pixelSize: 14; font.bold: true }
                    MouseArea { anchors.fill: parent; onClicked: gb.confirmMerge() }
                }
                Rectangle {
                    width: 28; height: 28; radius: 8
                    color: c.surfaceHigh
                    Text { anchors.centerIn: parent; text: "✕"; color: c.textMuted; font.pixelSize: 13 }
                    MouseArea { anchors.fill: parent; onClicked: gb.toggleMergeMode() }
                }
            }
        }

        // ---- corpo ----
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // vazio: nenhum grupo
            Rectangle {
                anchors.fill: parent
                color: c.background
                visible: gb.activeGroupName === "" && gb.groupNamesList.length === 0
                z: 9
                Column {
                    anchors.centerIn: parent
                    spacing: 10
                    Text { text: "★"; font.pixelSize: 35; opacity: 0.4; anchors.horizontalCenter: parent.horizontalCenter }
                    Text {
                        text: "Nenhum grupo criado ainda"
                        color: c.textMuted
                        font.family: gb.fontBody
                        font.pixelSize: 15
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }

            // vazio: grupo sem wallpapers
            Rectangle {
                anchors.fill: parent
                color: c.background
                visible: gb.activeGroupName !== "" && gb.activeGroupFiles.length === 0
                z: 9
                Column {
                    anchors.centerIn: parent
                    spacing: 10
                    Text { text: "☆"; font.pixelSize: 35; opacity: 0.4; anchors.horizontalCenter: parent.horizontalCenter }
                    Text {
                        text: "Grupo vazio — favorite wallpapers pela estrela"
                        color: c.textMuted
                        font.family: gb.fontBody
                        font.pixelSize: 15
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }

            // linha: lista de grupos
            ListView {
                id: groupsGrid
                anchors.fill: parent
                anchors.margins: 10
                orientation: ListView.Horizontal
                spacing: 10
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                visible: gb.activeGroupName === ""
                model: gb.groupNamesList

                ScrollBar.horizontal: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    contentItem: Rectangle { implicitHeight: 3; color: c.accent; opacity: 0.45; radius: 2 }
                }

                WheelHandler {
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    onWheel: (event) => {
                        groupsGrid.contentX = Math.max(0, Math.min(groupsGrid.contentWidth - groupsGrid.width, groupsGrid.contentX - event.angleDelta.y))
                    }
                }

                delegate: Item {
                    id: groupCell
                    width: gb.rowItemWidth
                    height: groupsGrid.height
                    readonly property string groupName: modelData
                    readonly property var fileNames: Groups.contentsOf(groupCell.groupName)
                    readonly property var firstFile: {
                        const byName = {}
                        for (const w of Wallpaper.localList) byName[w.name] = w
                        for (const n of groupCell.fileNames) if (byName[n]) return byName[n]
                        return null
                    }
                    readonly property bool isMergeSelected: gb.mergeSelected.indexOf(groupCell.groupName) !== -1

                    Rectangle {
                        id: groupCard
                        anchors { top: parent.top; horizontalCenter: parent.horizontalCenter; topMargin: 0 }
                        width: parent.width - 10
                        height: Math.min(parent.height - 10, width * 9 / 16)
                        radius: 12
                        color: c.surface
                        clip: true

                        Image {
                            anchors.fill: parent
                            visible: groupCell.firstFile !== null
                            source: groupCell.firstFile ? ("file://" + groupCell.firstFile.path) : ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                        }

                        Rectangle {
                            anchors.fill: parent
                            visible: groupCell.firstFile === null
                            color: c.surfaceHigh
                            Text { anchors.centerIn: parent; text: "📁"; font.pixelSize: 31; opacity: 0.4 }
                        }

                        Rectangle {
                            anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                            height: 30
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0) }
                                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.7) }
                            }
                            Column {
                                anchors { left: parent.left; right: parent.right; bottom: parent.bottom; leftMargin: 8; rightMargin: 8; bottomMargin: 3 }
                                Text {
                                    text: groupCell.groupName
                                    color: "white"
                                    font.family: gb.fontBody
                                    font.pixelSize: 13
                                    font.bold: true
                                    elide: Text.ElideMiddle
                                    width: parent.width
                                }
                                Text {
                                    text: groupCell.fileNames.length + " wallpapers"
                                    color: "white"
                                    font.family: gb.fontBody
                                    font.pixelSize: 11
                                    opacity: 0.8
                                }
                            }
                        }

                        Rectangle {
                            visible: gb.mergeMode && groupCell.isMergeSelected
                            anchors.fill: parent
                            radius: 12
                            color: c.accent
                            opacity: 0.35
                        }

                        Rectangle {
                            visible: gb.mergeMode
                            z: 10
                            anchors { top: parent.top; left: parent.left; margins: 6 }
                            width: 20; height: 20; radius: 10
                            color: groupCell.isMergeSelected ? c.accent : Qt.rgba(0, 0, 0, 0.55)
                            border.color: "white"
                            border.width: 1
                            Text {
                                anchors.centerIn: parent
                                visible: groupCell.isMergeSelected
                                text: "✓"
                                color: "white"
                                font.pixelSize: 14
                                font.bold: true
                            }
                        }

                        Rectangle {
                            id: renameBtn
                            visible: !gb.mergeMode && cardHoverArea.containsMouse
                            z: 10
                            anchors { top: parent.top; left: parent.left; margins: 6 }
                            width: 20; height: 20; radius: 10
                            color: Qt.rgba(0, 0, 0, 0.65)
                            Text { anchors.centerIn: parent; text: "✎"; color: "white"; font.pixelSize: 13 }
                            MouseArea { anchors.fill: parent; onClicked: gb.openRenamePrompt(groupCell.groupName) }
                        }

                        Rectangle {
                            id: deleteGroupBtn
                            visible: !gb.mergeMode && cardHoverArea.containsMouse
                            z: 10
                            anchors { top: parent.top; right: parent.right; margins: 6 }
                            width: 20; height: 20; radius: 10
                            color: Qt.rgba(0, 0, 0, 0.65)
                            Text { anchors.centerIn: parent; text: "✕"; color: "white"; font.pixelSize: 13; font.bold: true }
                            MouseArea { anchors.fill: parent; onClicked: Groups.deleteGroup(groupCell.groupName) }
                        }

                        MouseArea {
                            id: cardHoverArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                if (gb.mergeMode) gb.toggleMergeSelect(groupCell.groupName)
                                else gb.enterGroup(groupCell.groupName)
                            }
                        }
                    }
                }
            }

            // linha: conteudo de um grupo
            ListView {
                id: groupContentGrid
                anchors.fill: parent
                anchors.margins: 10
                orientation: ListView.Horizontal
                spacing: 10
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                visible: gb.activeGroupName !== ""
                model: gb.groupPagedFiles

                ScrollBar.horizontal: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    contentItem: Rectangle { implicitHeight: 3; color: c.accent; opacity: 0.45; radius: 2 }
                }

                WheelHandler {
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    onWheel: (event) => {
                        groupContentGrid.contentX = Math.max(0, Math.min(groupContentGrid.contentWidth - groupContentGrid.width, groupContentGrid.contentX - event.angleDelta.y))
                    }
                }

                delegate: Item {
                    width: gb.rowItemWidth
                    height: groupContentGrid.height

                    Rectangle {
                        id: fileCard
                        anchors { top: parent.top; horizontalCenter: parent.horizontalCenter; topMargin: 0 }
                        width: parent.width - 10
                        height: Math.min(parent.height - 10, width * 9 / 16)
                        radius: 12
                        color: c.surface
                        clip: true

                        Image {
                            anchors.fill: parent
                            source: "file://" + modelData.path
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
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
                                font.family: gb.fontBody
                                font.pixelSize: 12
                                elide: Text.ElideMiddle
                            }
                        }

                        Rectangle {
                            id: fileSelectCheck
                            visible: gb.selectMode
                            z: 10
                            anchors { top: parent.top; left: parent.left; margins: 6 }
                            width: 20; height: 20; radius: 10
                            color: gb.isNameSelected(modelData.name) ? c.accent : Qt.rgba(0, 0, 0, 0.55)
                            border.color: "white"
                            border.width: 1
                            Text {
                                anchors.centerIn: parent
                                visible: gb.isNameSelected(modelData.name)
                                text: "✓"
                                color: "white"
                                font.pixelSize: 14
                                font.bold: true
                            }
                        }

                        Rectangle {
                            visible: !gb.selectMode && fileCardArea.containsMouse
                            z: 10
                            anchors { top: parent.top; right: parent.right; margins: 6 }
                            width: 20; height: 20; radius: 10
                            color: Qt.rgba(0, 0, 0, 0.65)
                            Text { anchors.centerIn: parent; text: "✕"; color: "white"; font.pixelSize: 13; font.bold: true }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: Groups.removeFromGroup(gb.activeGroupName, modelData.name)
                            }
                        }

                        MouseArea {
                            id: fileCardArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                if (gb.selectMode) {
                                    gb.toggleSelectName(modelData.name)
                                } else {
                                    Wallpaper.applyPath(modelData.path)
                                    gb.wallpaperSelected(modelData.path)
                                }
                            }
                        }
                    }
                }
            }

            // paginacao / barra de selecao do grupo
            Rectangle {
                id: groupPager
                anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                height: 50
                color: c.surfaceLow
                bottomLeftRadius: 16
                bottomRightRadius: 16
                visible: gb.activeGroupName !== "" && (gb.groupLastPage > 1 || gb.selectMode)

                Rectangle {
                    anchors { top: parent.top; left: parent.left; right: parent.right }
                    height: 1
                    color: c.outlineVariant
                    opacity: 0.3
                }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 20
                    visible: !gb.selectMode

                    Rectangle {
                        width: 34; height: 34; radius: 17
                        color: gb.groupPage > 1 ? c.surface : c.surfaceLow
                        opacity: gb.groupPage > 1 ? 1 : 0.35
                        Text { anchors.centerIn: parent; text: "‹"; font.pixelSize: 21; color: c.text }
                        MouseArea { anchors.fill: parent; enabled: gb.groupPage > 1; onClicked: gb.prevGroupPage() }
                    }
                    Text {
                        text: "Página " + gb.groupPage + " de " + gb.groupLastPage
                        color: c.textMuted
                        font.pixelSize: 15
                    }
                    Rectangle {
                        width: 34; height: 34; radius: 17
                        color: gb.groupPage < gb.groupLastPage ? c.surface : c.surfaceLow
                        opacity: gb.groupPage < gb.groupLastPage ? 1 : 0.35
                        Text { anchors.centerIn: parent; text: "›"; font.pixelSize: 21; color: c.text }
                        MouseArea { anchors.fill: parent; enabled: gb.groupPage < gb.groupLastPage; onClicked: gb.nextGroupPage() }
                    }
                }

                RowLayout {
                    anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 14; rightMargin: 14 }
                    spacing: 8
                    visible: gb.selectMode

                    Text {
                        text: gb.selectedNames.length + " sel."
                        color: c.textMuted
                        font.family: gb.fontBody
                        font.pixelSize: 14
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        width: 90; height: 30; radius: 15
                        color: gb.selectedNames.length > 0 ? c.danger : c.surface
                        opacity: gb.selectedNames.length > 0 ? 1 : 0.5
                        Text { anchors.centerIn: parent; text: "Remover"; font.family: gb.fontBody; font.pixelSize: 13; font.bold: true; color: c.accentText }
                        MouseArea { anchors.fill: parent; enabled: gb.selectedNames.length > 0; onClicked: gb.removeSelectedFromGroup() }
                    }
                    Rectangle {
                        width: 80; height: 30; radius: 15
                        color: gb.selectedNames.length > 0 ? c.surfaceHigh : c.surface
                        opacity: gb.selectedNames.length > 0 ? 1 : 0.5
                        Text { anchors.centerIn: parent; text: "Mover"; font.family: gb.fontBody; font.pixelSize: 13; color: c.text }
                        MouseArea { anchors.fill: parent; enabled: gb.selectedNames.length > 0; onClicked: gb.openTargetPicker("move") }
                    }
                    Rectangle {
                        width: 80; height: 30; radius: 15
                        color: gb.selectedNames.length > 0 ? c.surfaceHigh : c.surface
                        opacity: gb.selectedNames.length > 0 ? 1 : 0.5
                        Text { anchors.centerIn: parent; text: "Copiar"; font.family: gb.fontBody; font.pixelSize: 13; color: c.text }
                        MouseArea { anchors.fill: parent; enabled: gb.selectedNames.length > 0; onClicked: gb.openTargetPicker("copy") }
                    }
                }
            }
        }
    }

    // ---- overlay: escolher grupo destino (mover/copiar) ----
    Item {
        anchors.fill: parent
        visible: gb.targetPickerMode !== ""
        z: 997

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.6)
            MouseArea { anchors.fill: parent; onClicked: gb.closeTargetPicker() }
        }

        Rectangle {
            anchors.centerIn: parent
            width: Math.min(parent.width - 60, 300)
            height: Math.min(parent.height - 100, 320)
            radius: 16
            color: c.surfaceLow
            border.color: c.outlineVariant
            border.width: 1

            MouseArea { anchors.fill: parent; onClicked: {} }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 8

                Text {
                    text: gb.targetPickerMode === "move" ? "Mover para…" : "Copiar para…"
                    color: c.text
                    font.family: gb.fontBody
                    font.pixelSize: 16
                    font.bold: true
                }

                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 4
                    model: gb.groupNamesList.filter(function (n) { return n !== gb.activeGroupName })

                    delegate: Rectangle {
                        width: ListView.view.width
                        height: 32
                        radius: 8
                        color: targetArea.containsMouse ? c.surface : "transparent"
                        Text {
                            anchors { fill: parent; margins: 8 }
                            text: modelData
                            color: c.text
                            font.family: gb.fontBody
                            font.pixelSize: 15
                            verticalAlignment: Text.AlignVCenter
                        }
                        MouseArea { id: targetArea; anchors.fill: parent; hoverEnabled: true; onClicked: gb.chooseTarget(modelData) }
                    }
                }
            }
        }
    }
}
