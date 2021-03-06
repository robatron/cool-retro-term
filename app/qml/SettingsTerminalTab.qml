/*******************************************************************************
* Copyright (c) 2013 "Filippo Scognamiglio"
* https://github.com/Swordfish90/cool-retro-term
*
* This file is part of cool-retro-term.
*
* cool-retro-term is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program.  If not, see <http://www.gnu.org/licenses/>.
*******************************************************************************/

import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Layouts 1.1

Tab{
    ColumnLayout{
        anchors.fill: parent
        GroupBox{
            title: qsTr("Rasterization Mode")
            Layout.fillWidth: true
            ComboBox {
                id: rasterizationBox
                property string selectedElement: model[currentIndex]
                anchors.fill: parent
                model: [qsTr("Default"), qsTr("Scanlines"), qsTr("Pixels")]
                currentIndex: appSettings.rasterization
                onCurrentIndexChanged: {
                    appSettings.rasterization = currentIndex
                }
            }
        }
        GroupBox{
            title: qsTr("Font") + " (" + rasterizationBox.selectedElement + ")"
            Layout.fillWidth: true
            GridLayout{
                anchors.fill: parent
                columns: 2
                Text{ text: qsTr("Name") }
                ComboBox{
                    id: fontChanger
                    Layout.fillWidth: true
                    model: appSettings.fontlist
                    onActivated: {
                        var name = appSettings.fontlist.get(index).name;
                        appSettings.fontNames[appSettings.rasterization] = name;
                        appSettings.handleFontChanged();
                    }
                    function updateIndex(){
                        var name = appSettings.fontNames[appSettings.rasterization];
                        var index = appSettings.getIndexByName(name);
                        if (index !== undefined)
                            currentIndex = index;
                    }
                    Connections{
                        target: appSettings
                        onRasterizationChanged: fontChanger.updateIndex();
                    }
                    Component.onCompleted: updateIndex();
                }
                Text{ text: qsTr("Scaling") }
                RowLayout{
                    Layout.fillWidth: true
                    Slider{
                        Layout.fillWidth: true
                        id: fontScalingChanger
                        onValueChanged: if(enabled) appSettings.fontScaling = value
                        stepSize: 0.05
                        enabled: false // Another trick to fix initial bad behavior.
                        Component.onCompleted: {
                            minimumValue = 0.5;
                            maximumValue = 2.5;
                            value = appSettings.fontScaling;
                            enabled = true;
                        }
                        Connections{
                            target: appSettings
                            onFontScalingChanged: fontScalingChanger.value = appSettings.fontScaling;
                        }
                    }
                    Text{
                        text: Math.round(fontScalingChanger.value * 100) + "%"
                    }
                }
                Text{ text: qsTr("Font Width") }
                RowLayout{
                    Layout.fillWidth: true
                    Slider{
                        Layout.fillWidth: true
                        id: widthChanger
                        onValueChanged: appSettings.fontWidth = value;
                        value: appSettings.fontWidth
                        stepSize: 0.05
                        Component.onCompleted: {
                            // This is needed to avoid unnecessary chnaged events.
                            minimumValue = 0.5;
                            maximumValue = 1.5;
                        }
                    }
                    Text{
                        text: Math.round(widthChanger.value * 100) + "%"
                    }
                }
            }
        }
        GroupBox{
            title: qsTr("Colors")
            Layout.fillWidth: true
            ColumnLayout{
                anchors.fill: parent
                RowLayout{
                    Layout.fillWidth: true
                    ColorButton{
                        name: qsTr("Font")
                        height: 50
                        Layout.fillWidth: true
                        onColorSelected: appSettings._font_color = color;
                        button_color: appSettings._font_color
                    }
                    ColorButton{
                        name: qsTr("Background")
                        height: 50
                        Layout.fillWidth: true
                        onColorSelected: appSettings._background_color = color;
                        button_color: appSettings._background_color
                    }
                }
                ColumnLayout{
                    Layout.fillWidth: true
                    CheckableSlider{
                        name: qsTr("Chroma Color")
                        onNewValue: appSettings.chroma_color = newValue
                        value: appSettings.chroma_color
                    }
                    CheckableSlider{
                        name: qsTr("Saturation Color")
                        onNewValue: appSettings.saturation_color = newValue
                        value: appSettings.saturation_color
                        enabled: appSettings.chroma_color !== 0
                    }
                }
            }
        }
    }
}
