import QtQuick

Item {
    id: r
    property string label: ""
    property string hint: ""
    default property alias control: holder.data
    width: parent ? parent.width : 400
    height: Math.max(52, holder.childrenRect.height + 12)

    Column {
        anchors { left: parent.left; right: holder.left; rightMargin: 16; verticalCenter: parent.verticalCenter }
        spacing: 2
        Text { width: parent.width; text: r.label; elide: Text.ElideRight
               font.family: Theme.fontFamily; font.letterSpacing: Theme.letterSpacing; font.pixelSize: Theme.px(15); color: Theme.text }
        Text { width: parent.width; text: r.hint; visible: text.length > 0; wrapMode: Text.Wrap
               font.family: Theme.fontSmall; font.letterSpacing: Theme.letterSpacing; font.pixelSize: Theme.px(12); color: Theme.textDim }
    }
    Item {
        id: holder
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        width: childrenRect.width
        height: childrenRect.height
    }
}
