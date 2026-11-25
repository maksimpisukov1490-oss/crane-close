import QtQuick
import QtQuick3D
import "facets.js" as Facets

// 3D-журавлик, собранный из плоских бумажных граней.
// На лицевые грани проецируется скриншот окна, изнанка чёрная.
Node {
    id: crane

    property string shotUrl: ""
    // 0 — грани собраны в точку, 1 — журавлик раскрыт
    property real bloom: 1

    readonly property int count: Facets.facets.length

    function centroid(f) {
        let x = 0, y = 0;
        for (let i = 0; i < f.pts.length; i++) {
            x += f.pts[i][0];
            y += f.pts[i][1];
        }
        return [x / f.pts.length, y / f.pts.length, f.z];
    }

    function smooth(x) {
        const t = Math.max(0, Math.min(1, x));
        return t * t * (3 - 2 * t);
    }

    function bloomFor(index) {
        const delay = (index % 7) * 0.035;
        const p = smooth((bloom - delay) / (1 - delay));
        return p;
    }

    function easeOutBack(v) {
        const c1 = 1.70158;
        const c3 = c1 + 1;
        const x = Math.max(0, Math.min(1, v));
        return 1 + c3 * Math.pow(x - 1, 3) + c1 * Math.pow(x - 1, 2);
    }

    Repeater3D {
        model: crane.count

        Node {
            id: facetNode

            required property int index

            readonly property var f: Facets.facets[index]
            readonly property var c: crane.centroid(f)
            readonly property real p: crane.bloomFor(index)

            position: Qt.vector3d(c[0] * p,
                                  c[1] * p,
                                  c[2] * p + Math.sin(Math.PI * p) * (26 + (index % 4) * 9))
            readonly property real sc: 0.10 + 0.90 * crane.easeOutBack(Math.min(1, p * 1.1))
            scale: Qt.vector3d(sc, sc, sc)
            eulerRotation: Qt.vector3d((1 - p) * 8 * ((index % 3) - 1),
                                       (1 - p) * 10 * ((index % 2) ? 1 : -1),
                                       (1 - p) * 24 * ((index % 2) ? 1 : -1))

            CraneFacet {
                points: facetNode.f.pts.map(pt => [pt[0] - facetNode.c[0],
                                                   pt[1] - facetNode.c[1],
                                                   facetNode.f.z - facetNode.c[2]])
                uvs: facetNode.f.uvs
                shade: facetNode.f.shade
                shotUrl: crane.shotUrl
            }
        }
    }
}
