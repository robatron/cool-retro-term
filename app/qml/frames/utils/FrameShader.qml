import QtQuick 2.2
import QtGraphicalEffects 1.0

Item{
    Loader{
        anchors.fill: parent
        source: "StaticFrameShader.qml"
    }
    Loader{
        anchors.fill: parent
        z: parent.z + 1
        source: "ReflectingFrameShader.qml"
    }
}
