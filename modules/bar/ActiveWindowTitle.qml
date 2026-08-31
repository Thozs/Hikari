import QtQuick
import "../../config"
import "../../services"

Item {
    id: root
    required property int thickness
    property bool vertical: true
    property int maxLength: 260

    implicitWidth: root.vertical ? thickness : root.maxLength
    implicitHeight: root.vertical ? root.maxLength : thickness

    Text {
        id: label
        anchors.centerIn: parent
        anchors.verticalCenterOffset: root.vertical ? -Math.round(root.height * 0.06) : 0
        rotation: root.vertical ? 90 : 0
        text: ActiveWindow.title
        color: Theme.barText
        font.pixelSize: Math.round(root.thickness * 0.30)
        elide: Text.ElideRight
        width: root.vertical ? root.maxLength : root.width
        horizontalAlignment: Text.AlignHCenter
    }
}
