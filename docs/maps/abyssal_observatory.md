# Abyssal Observatory

An art-deco marine observatory below the ocean: a pale marble fighting gallery, cobalt enamel, warm brass ribs, a panoramic clear window, layered reef ruins and a distant humpback. Live 3D manta rays, moon jellyfish and silver shoals drift between the gallery and the distant artwork. The palette separates warm, readable fighters and pale ledges from the deep blue sea.

The main deck is 19.2 meters wide. Two 3.6 meter side balconies sit at ±5.8 meters and height 4.2; a 4.2 meter central lift sits at height 2.5. Party mode animates the lift and activates the inherited telegraphed edge hazards, presented as pressure-release water jets. Decorative architecture and sea life have no collision.

Editable foreground and midground art is local procedural geometry in `Game File/stages/abyssal_observatory/abyssal_stage.gd`, with adjacent custom shaders. The generated distant matte is `Game File/assets/arenas/abyssal_observatory/backdrop.png`; the shared `ArenaBackdrop` helper frames it behind the 3D scene. No supplied original asset is modified. Marble caustics, water shafts, pressure effects and every live animal motion derive from the authoritative stage tick, so they stop when the match pauses. The distant humpback and far reefs are part of the static matte, not animated geometry.

Low quality removes coral detail, extra jellyfish, sun shafts, gallery practical lights and sun shadows; reduces the two small shoals from 14 to 5 fish each; and replaces caustic marble with a simple cached material. Switching back to High restores the same scene. The collision layout is identical at either setting. The open space below the fighting gallery reveals the ocean chasm and recovery routes.

The window frame, columns, reef and all sea life remain behind the fight. There is no transparent glass mesh over the fighters. Fighter-only warm fill and a cool rim preserve costume readability without lighting the background to equal contrast.
