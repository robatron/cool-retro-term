import QtQuick 2.2
import QtGraphicalEffects 1.0

ShaderEffect{
    property color font_color: shadersettings.font_color
    property real brightness: shadersettings.brightness * 1.5 + 0.5
    property variant cacheReflections: cacheSource

    property real screen_distorsion: shadersettings.screen_distortion * framecontainer.distortionCoefficient

    property variant lightSource: frameReflectionSource

    property real chroma_color: shadersettings.chroma_color

    blending: true

    // Cache some results to make calculations faster.
    ShaderEffect{
        id: cacheReflections
        anchors.fill: parent

        blending: false

        property variant source: framesource
        property variant normals: framesourcenormals
        property real screen_distorsion: shadersettings.screen_distortion * framecontainer.distortionCoefficient
        property real ambient_light: shadersettings.ambient_light

        property color background_color: shadersettings.background_color

        fragmentShader: "
            uniform sampler2D source;
            uniform sampler2D normals;
            uniform highp float screen_distorsion;
            uniform highp float ambient_light;
            uniform highp float qt_Opacity;
            uniform highp vec4 background_color;

            varying highp vec2 qt_TexCoord0;

            vec2 distortCoordinates(vec2 coords){
                vec2 cc = coords - vec2(0.5);
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

                float dotProd = dot(normal, light_direction);

                gl_FragColor = vec4(0.0, 0.0, txt_normal.a, dotProd);
            }"
    }

    ShaderEffectSource{
        id: cacheSource
        sourceItem: cacheReflections
        hideSource: true
        smooth: true
    }


    // Reflections using by FastBlur.
    FastBlur{
        id: frameReflectionEffect
        width: parent.width / 10.0
        height: parent.height / 10.0
        radius: 64
        source: terminal.kterminal
        smooth: false
    }

    ShaderEffectSource{
        id: frameReflectionSource
        sourceItem: frameReflectionEffect
        hideSource: true
        smooth: true
    }

    fragmentShader: "
            uniform sampler2D cacheReflections;
            uniform sampler2D lightSource;
            uniform lowp float chroma_color;
            uniform highp float qt_Opacity;
            uniform highp float screen_distorsion;

            uniform vec4 font_color;
            varying lowp float brightness;

            varying highp vec2 qt_TexCoord0;

            vec2 distortCoordinates(vec2 coords){
                vec2 cc = coords - vec2(0.5);
                float dist = dot(cc, cc) * screen_distorsion;
                return (coords + cc * (1.0 + dist) * dist);
            }

            float rgb2grey(vec3 v){
                return dot(v, vec3(0.21, 0.72, 0.04));
            }

            void main(){
                vec4 cache = texture2D(cacheReflections, qt_TexCoord0);

                float txtAlpha = cache.b;
                float dotProd = cache.a;

                vec3 realLightColor = texture2D(lightSource, qt_TexCoord0).rgb;
                float lightAlpha = texture2D(lightSource, qt_TexCoord0).a;
                vec3 lightColor = mix(font_color.rgb * rgb2grey(realLightColor), font_color.rgb * realLightColor, chroma_color) * dotProd;

                gl_FragColor = vec4(lightColor * txtAlpha, dotProd * txtAlpha * 0.2);
            }"

    onStatusChanged: if (log) console.log(log) //Print warning messages
}
