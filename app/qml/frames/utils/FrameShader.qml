import QtQuick 2.2
import QtGraphicalEffects 1.0

ShaderEffect{
    property variant source: framesource
    property variant normals: framesourcenormals

    property real screen_distorsion: appSettings.screen_distortion
    property size curvature_coefficients: Qt.size(width / mainShader.width, height / mainShader.height)

    property real ambient_light: appSettings.ambient_light
    property color font_color: appSettings.font_color
    property color background_color: appSettings.background_color
    property real brightness: appSettings.brightness * 1.5 + 0.5

    property bool frameReflections: appSettings.frameReflections
    property variant lightSource: reflectionEffectSourceLoader.item

    property real chroma_color: appSettings.chroma_color

    Loader{
        id: reflectionEffectLoader
        width: parent.width * 0.33
        height: parent.height * 0.33
        active: frameReflections

        sourceComponent: FastBlur{
            id: frameReflectionEffect
            radius: 128
            source: terminal.kterminal
            smooth: false
        }
    }

    Loader{
        id: reflectionEffectSourceLoader
        active: frameReflections
        sourceComponent: ShaderEffectSource{
            id: frameReflectionSource
            sourceItem: reflectionEffectLoader.item
            hideSource: true
            smooth: true
            visible: false
        }
    }

    blending: true

    fragmentShader: "
                            uniform sampler2D source;
                            uniform sampler2D normals;
                            uniform highp float screen_distorsion;
                            uniform highp float ambient_light;
                            uniform highp float qt_Opacity;
                            uniform lowp float chroma_color;

                            uniform highp vec2 curvature_coefficients;" +

                            (frameReflections ?
                                "uniform sampler2D lightSource;" : "") + "

                            uniform vec4 font_color;
                            uniform vec4 background_color;
                            varying lowp float brightness;

                            varying highp vec2 qt_TexCoord0;

                            vec2 distortCoordinates(vec2 coords){
                                vec2 cc = (coords - vec2(0.5)) * curvature_coefficients;
                                float dist = dot(cc, cc) * screen_distorsion;
                                return (coords + cc * (1.0 + dist) * dist);
                            }

                            float rgb2grey(vec3 v){
                                return dot(v, vec3(0.21, 0.72, 0.04));
                            }

                            void main(){
                                vec2 coords = distortCoordinates(qt_TexCoord0);
                                vec4 txt_color = texture2D(source, coords);
                                vec4 txt_normal = texture2D(normals, coords);
                                vec3 normal = normalize(txt_normal.rgb * 2.0 - 1.0);
                                vec3 light_direction = normalize(vec3(0.5, 0.5, 0.0) - vec3(qt_TexCoord0, 0.0));

                                float dotProd = dot(normal, light_direction);" +

                                (frameReflections ? "
                                    vec3 realLightColor = texture2D(lightSource, coords).rgb;
                                    float screenLight = rgb2grey(realLightColor);
                                    float clampedDotProd = clamp(dotProd, 0.05, 1.0);
                                    float diffuseReflection = clamp(screenLight * 1.5 * clampedDotProd, 0.0, 0.35);
                                    float reflectionAlpha = mix(1.0, 0.90, dotProd);
                                    vec3 lightColor = mix(font_color.rgb * screenLight, font_color.rgb * realLightColor, chroma_color);"
                                : "
                                    float diffuseReflection = 0.0;
                                    float reflectionAlpha = 1.0;
                                    vec3 lightColor = font_color.rgb;") + "


                                vec3 back_color = background_color.rgb * (0.2 + 0.5 * dotProd);
                                vec3 front_color = lightColor * (0.05 + diffuseReflection);

                                vec4 dark_color = vec4((back_color + front_color) * txt_normal.a, txt_normal.a * reflectionAlpha);
                                gl_FragColor = mix(dark_color, txt_color, ambient_light);
                            }"

    onStatusChanged: if (log) console.log(log) //Print warning messages
}
