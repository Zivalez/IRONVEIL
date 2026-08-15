# IRONVEIL — Modern Pixel Art Rendering Contract

Status: **locked visual direction** (owner decision, 2026-08-16).

## Target look

IRONVEIL is not intended to look like raw low-poly 3D. The final presentation is **modern pixel art / HD-2D-inspired 2.5D**: readable 16-bit-era pixel language combined with modern real-time rendering.

The intended visual stack is:

- Orthographic/isometric 2.5D camera.
- Pixel-art characters, creatures, pickups, foliage and small props with deliberate silhouettes and limited palettes.
- Low-poly 3D world geometry only where depth/occlusion/mechanical motion benefits from it, covered by pixel-authored or pixel-preserving textures.
- Nearest-neighbor texture filtering for pixel assets; no accidental smoothing.
- Dynamic directional/omni/spot lighting that respects the pixel aesthetic.
- Real-time shadows for player, enemies, buildings and machinery where Web/Compatibility performance permits.
- Pixel-shaped particles for dust, sparks, saw debris, steam, embers, rain and electrical effects.
- Web-compatible post-processing: pixel-grid treatment, restrained color quantization/dithering, color grading, vignette and selective glow-like treatment implemented without relying on Forward+-only compositor features.
- Crisp UI rendered separately from world pixelation. UI may use industrial schematic/gauge styling from the blueprint.

## Hybrid asset rule

Use the representation that best communicates each object:

| Object | Preferred representation |
|---|---|
| Player/NPC/enemy | Pixel-art Sprite3D / directional sprite set |
| Grass/foliage/small debris | Pixel Sprite3D / MultiMesh where useful |
| Terrain/buildings | Simple 3D geometry with pixel textures |
| Gears/shafts/wheels/saws | 3D geometry with pixel materials so mechanical rotation remains physically readable |
| Steam/sparks/dust | Particle systems with pixel textures |
| UI | Crisp Canvas UI; not world-pixelated |

## Camera and pixel stability

- Keep the current **orthographic** camera and 90-degree rotation steps.
- World art should be authored around a stable reference pixel density. Initial target: **32 world pixels per meter**, adjustable after the first representative art set exists.
- Avoid arbitrary Sprite3D scaling that produces subpixel shimmer.
- Camera movement should be quantized/smoothed in a pixel-stable way once sprite assets replace blockout meshes.

## Web / Compatibility renderer guardrail

Public Web remains the lowest common denominator. Every effect must work acceptably with Godot Compatibility rendering before being considered part of the base art direction.

Do not make the visual identity depend on Forward+-only features such as SDFGI or the Compositor. Native builds may receive optional enhancements later, but Web must preserve the same art identity.

## Phase policy

The current Phase 1 geometry is **blockout only**, not approved final graphics. It exists to prove movement, interaction, survival and mechanical automation.

Before Phase 2 Vertical Slice is considered visually presentable, replace the visible prototype primitives on the critical path with a representative modern-pixel art set covering at minimum:

1. player;
2. one enemy;
3. forest ground/foliage/trees;
4. workshop shell;
5. water wheel;
6. gearbox/belt;
7. mechanical saw;
8. resource pickups;
9. ambient particles;
10. Web-compatible world post-processing.

## Visual quality bar

A screenshot without UI should immediately read as intentional pixel art, not as "Godot primitive meshes with a pixel filter". Post-processing is enhancement, not a substitute for authored pixel assets.

## Phase 2 implementation status

Phase 2 now includes a representative authored pixel asset set for the critical route plus pixel-textured 3D world/machinery, real-time lights/shadows, manual pixel dust/steam fields and a Compatibility-safe screen shader. This establishes the rendering pipeline and visual grammar; these development assets are **not** represented as Sea-of-Stars-level final production art.
