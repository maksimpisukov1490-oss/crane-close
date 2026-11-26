import QtQuick
import QtQuick3D

// 3D-эффект закрытия окна: лист со скриншотом и его трёхмерное превращение.
Node {
    id: fx

    property string effect: "fade"
    property string path: ""
    property real t: 0
    property real ww: 0
    property real wh: 0
    property real cx: 0
    property real cy: 0
    property real hold: 0.22

    readonly property real dur: {
        switch (effect) {
        case "fade": return 1.50;
        case "cube": return 1.60;
        case "doors": return 1.70;
        case "flip": return 1.60;
        case "vortex": return 1.60;
        default: return 1.60;
        }
    }
    readonly property real q: {
        const x = Math.max(0, Math.min(1, (t - hold) / (dur - hold - 0.05)));
        return x < 0.5 ? 2 * x * x : 1 - Math.pow(-2 * x + 2, 2) / 2;
    }

    position: Qt.vector3d(cx, cy, 0)
    visible: effect !== "origami" && t < dur + 0.05

    readonly property string src: "file://" + path
    readonly property real W: ww / 100
    readonly property real H: wh / 100

    Texture {
        id: texFull
        source: fx.src
    }
    Texture {
        id: texLeft
        source: fx.src
        scaleU: 0.5
        positionU: 0
    }
    Texture {
        id: texRight
        source: fx.src
        scaleU: 0.5
        positionU: 0.5
    }

    // ---------- Fade ----------
    Model {
        visible: fx.effect === "fade"
        source: "#Rectangle"
        scale: Qt.vector3d(fx.W, fx.H, 1)
        materials: PrincipledMaterial {
            lighting: PrincipledMaterial.NoLighting
            alphaMode: PrincipledMaterial.Blend
            baseColorMap: texFull
            baseColor: Qt.rgba(1, 1, 1, 1 - fx.q)
        }
    }

    // ---------- Cube ----------
    Node {
        visible: fx.effect === "cube"
        eulerRotation: Qt.vector3d(0, -90 * fx.q, 0)

        Model {
            source: "#Rectangle"
            scale: Qt.vector3d(fx.W, fx.H, 1)
            materials: PrincipledMaterial {
                lighting: PrincipledMaterial.NoLighting
                baseColorMap: texFull
            }
        }

        // боковая грань куба
        Model {
            source: "#Rectangle"
            position: Qt.vector3d(fx.ww / 2, 0, -fx.ww * 0.3)
            scale: Qt.vector3d(fx.ww * 0.6 / 100, fx.H, 1)
            eulerRotation: Qt.vector3d(0, 90, 0)
            materials: PrincipledMaterial {
                lighting: PrincipledMaterial.NoLighting
                cullMode: Material.NoCulling
                baseColor: "#101014"
            }
        }
    }

    // ---------- Doors ----------
    Node {
        visible: fx.effect === "doors"

        Node {
            position: Qt.vector3d(-fx.ww / 2, 0, 0)
            eulerRotation: Qt.vector3d(0, 100 * fx.q, 0)

            Model {
                position: Qt.vector3d(fx.ww / 4, 0, 0)
                source: "#Rectangle"
                scale: Qt.vector3d(fx.W / 2, fx.H, 1)
                materials: PrincipledMaterial {
                    lighting: PrincipledMaterial.NoLighting
                    baseColorMap: texLeft
                }
            }
            Model {
                position: Qt.vector3d(fx.ww / 4, 0, -0.7)
                source: "#Rectangle"
                scale: Qt.vector3d(fx.W / 2, fx.H, 1)
                materials: PrincipledMaterial {
                    lighting: PrincipledMaterial.NoLighting
                    cullMode: Material.NoCulling
                    baseColor: "#0E0E12"
                }
            }
        }

        Node {
            position: Qt.vector3d(fx.ww / 2, 0, 0)
            eulerRotation: Qt.vector3d(0, -100 * fx.q, 0)

            Model {
                position: Qt.vector3d(-fx.ww / 4, 0, 0)
                source: "#Rectangle"
                scale: Qt.vector3d(fx.W / 2, fx.H, 1)
                materials: PrincipledMaterial {
                    lighting: PrincipledMaterial.NoLighting
                    baseColorMap: texRight
                }
            }
            Model {
                position: Qt.vector3d(-fx.ww / 4, 0, -0.7)
                source: "#Rectangle"
                scale: Qt.vector3d(fx.W / 2, fx.H, 1)
                materials: PrincipledMaterial {
                    lighting: PrincipledMaterial.NoLighting
                    cullMode: Material.NoCulling
                    baseColor: "#0E0E12"
                }
            }
        }
    }

    // ---------- Flip ----------
    Node {
        visible: fx.effect === "flip"
        eulerRotation: Qt.vector3d(-92 * fx.q, 0, 0)

        Model {
            source: "#Rectangle"
            scale: Qt.vector3d(fx.W, fx.H, 1)
            materials: PrincipledMaterial {
                lighting: PrincipledMaterial.NoLighting
                baseColorMap: texFull
            }
        }
        Model {
            position: Qt.vector3d(0, 0, -0.7)
            source: "#Rectangle"
            scale: Qt.vector3d(fx.W, fx.H, 1)
            materials: PrincipledMaterial {
                lighting: PrincipledMaterial.NoLighting
                cullMode: Material.NoCulling
                baseColor: "#0E0E12"
            }
        }
    }

    // ---------- Vortex ----------
    Node {
        visible: fx.effect === "vortex"
        position: Qt.vector3d(0, 0, -320 * fx.q)
        eulerRotation: Qt.vector3d(0, 0, 540 * fx.q)
        scale: {
            const s = Math.max(0.02, 1 - 0.98 * fx.q);
            return Qt.vector3d(s, s, s);
        }

        Model {
            source: "#Rectangle"
            scale: Qt.vector3d(fx.W, fx.H, 1)
            materials: PrincipledMaterial {
                lighting: PrincipledMaterial.NoLighting
                alphaMode: PrincipledMaterial.Blend
                baseColorMap: texFull
                baseColor: Qt.rgba(1, 1, 1, 1 - fx.q)
            }
        }
    }
}
