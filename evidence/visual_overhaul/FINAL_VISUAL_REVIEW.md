# Visual overhaul review

Reviewed 2026-09-28. This is an independent inspection of running-game evidence, not a visual pass inferred from automated check counts. The original brief and the later request for a drastic improvement to the graphics are the standard for this review.

## Verdict and evidence scope

The new presentation is a substantial improvement over the earlier `evidence/integration/title.png` and `four_player_scale125.png`. The older version had flat block towers, a uniform crowd row, large neon-edged HUD panels, small full-body portraits, and visually crude pool/deck materials. The current version has a coherent dusk setting, a much stronger menu composition, clear face portraits, quieter HUD treatment, recognizable terrace architecture, textured teak and stone, glass railings, and a restrained turquoise pool. This is a meaningful change in the actual game, beyond a better menu screenshot.

The first reviewed capture set still had significant visual-quality defects in its signature ability effects and one jab impact position. Both were corrected and re-inspected in fresh captures, as recorded below. No remaining important visual defect was found in the inspected final stills. This conclusion covers rendered composition and static contact readability, not unobserved motion or the exported package.

Reviewed sources:

- `presentation_final/presentation_scenarios.json`: 66 genuine 1920x1080 Forward+ captures; 137 trigger checks, zero failures. All 66 were surveyed in the eight existing contact sheets. The report explicitly records 7 ordinary gameplay camera captures and 59 closer QA frames using the same lighting and angle. The latter prove contact/material detail, not normal-gameplay framing.
- Original full-size presentation images inspected: ordinary 1v1 and its detail, Clutch neutral special, Heavy grounded stomp, Sunstruck ultimate opener, Fine Print ultimate opener, Heavy side-special lift/slam, Heavy ultimate lift/finisher, Heavy chair taunt, Deadfall recovery and plank slide, Fine Print palm/kick contacts, the shield detail, and the blood-on/flash-on heavy-impact spread. Apparent survey issues were checked against these originals before being reported.
- All 22 original full-size images in `ui_final/integration`, plus `ui_final/ui_flow.json` (56 checks, zero failures). These cover all five selections and match starts, title, settings, training, pause, results, and 1.25 UI scaling.
- `arena_v5/match_4players.png`: an actual four-player action frame at 5:52, reviewed in addition to the UI harness's four-player countdown frame. All four identities/markers and HUD panels are distinguishable in this frame.
- Old integration title and four-player HUD originals, used solely as the visual comparison baseline.
- Follow-up `jab_contact_review`: both original-size images and the report, verifying the bounded contact correction below.
- Follow-up `ability_contour_final`: all six reports were read (58 captures, 151 trigger checks, zero failures), with 16 selected images inspected at original size. These were Sunstruck/Fine Print/Deadfall warning and opener in `forward_gameplay_flash0`; Clutch/Heavy Duty/Fine Print neutral special; Heavy grounded and air-landing stomp; Sunstruck ribbon; Mobile Fine Print warning and Sunstruck opener; and Forward+ flash-on Fine Print and Sunstruck openers. This is a targeted follow-up inspection, not a claim to have visually reviewed all 58 new images.

The primary reports at review start had SHA-256 hashes `3DB3BCDCEDC4B21C2067C8634CD9DCAF06506B5C2FD74C20CD1F3B8047172991` (presentation) and `176D7E28F14320E9BF0CEFF120963AB58DE17EA4D1FE41846D29E08920EDDED5` (UI). The checked-out source commit at review start was `37ddc2ba516b56097734d68c7f842c0570c6642e`, with ongoing follow-up edits; this is not a claim that these images came from an unchanged packaged release.

## Findings and corrective work

### 1. Signature energy shapes looked unfinished in the original final capture set

Priority: important visual-polish defect. The broad opaque cyan/red rings, yellow arcs, and lavender rectangle/X in `presentation_final/f01_clutch_special_neutral.png`, `f03_heavy_duty_special_down.png`, `f02_sunstruck_ultimate_opener.png`, and `f05_fine_print_ultimate_opener.png` have uniform flat color and hard polygon joins. They read as debug geometry next to the improved environment and softer hit particles. The Heavy/Sunstruck circles also visibly continue below the front deck onto the building façade. This is easily visible in original full-size captures, not a tiny contact-sheet artifact.

Status: corrected in the inspected final follow-up frames. The ability presentation worker replaced the broad bands with soft transparent contours, narrower luminous cores, and ground-aware presentation. Initial `ability_contour_v1/ultimate` inspection showed a large improvement but Fine Print's first warning was too faint; the final revision strengthens its continuous boundary. At the ordinary 11.7 gameplay camera size, `ability_contour_final/forward_gameplay_flash0` now shows a complete, readable Fine Print warning, softer active slashes, and a clear Sunstruck perimeter without below-deck segments. Faces and player markers remain visible. The selected Mobile and flash-on counterparts preserve these qualities.

The final Clutch/Heavy neutral rings have a soft narrow rim and clear center instead of opaque bands. Heavy's grounded and air-landing shockwaves now lie on the floor plane, resolving the façade overlap. Sunstruck's ribbon uses tapering curved traces instead of a broad hard strip. These changes resolve the concrete visual defects found in this review. No additional actionable defect was found in the 16 selected final images. The separate implementation/tests establish gameplay behavior; this inspection establishes the visible improvement.

Final report SHA-256 hashes for the ordinary-camera ability comparison are `0698172341884448ADDC3FD0AFD2EB025B51B1A071DDE5787A236159CCECBC9B` (Forward+ flash-off), `7D92DFBC3CE4B70008ED426C25A0DA2EEF874BA9C6A8230FEE762111E9CE8F51` (Forward+ flash-on), and `7B5C7AE4E6433EDEFF09717BA85B6969AD5040749F436CB5A6DEBA617CC6BF36` (Mobile flash-off).

### 2. Clutch's first jab impact was visibly below the striking hand

Priority: bounded contact-polish correction. `presentation_final/match_1v1_action_detail.png` shows the jab reaching the collar/face area while the blue impact originates near the waist. JSON confirms the real `jab1` resolves at tick 14 with an effect origin at local `(0.66, 1.12)`. The effect is visibly about 80–90 pixels below contact in the close QA frame. This is less conspicuous in normal framing, but it weakens the impact.

With root authorization, this review changed only `f01_clutch.gd`'s optional presentation `impact_offset` for `jab1` to `(0.78, 1.50)`. The new point is 0.3985m from the unchanged hit center, inside the existing 0.41m hit radius. Startup, active/recovery windows, damage, hit radius, and hit offset are unchanged. The resolver collects collision using the original hit geometry; the optional offset supplies the visual contact position.

Verified corrected in `jab_contact_review/match_1v1_action.png` and its detail, both inspected at original size. The burst now sits at the upper torso immediately beneath the contacting hand, instead of the waist, while preserving the face and body silhouette. The focused graphical command exited 0 with 8 trigger checks, zero failures, two fresh captures, and no reported engine errors/warnings. Recorded hit tick remains 14 and damage remains 3.5; all recorded fighter-state snapshots are identical to the original fixture. Only the effect origin changes to world `(0.355, 1.50, 0)`.

## What holds up visually

- All five portraits present recognizable supplied faces/clothes with consistent lighting and readable crops. Heavy Duty's armor and Sunstruck's tropical clothes follow the user's confirmed mapping. No replacement body or portrait substitution was observed.
- In the inspected close poses, limbs remain attached and proportions credible. Heavy's lift puts the hands near the victim's waist/torso; the chair taunt visibly seats the pelvis on the chair. Fine Print's palm trace begins near the hand, and Deadfall's planted foot meets the plank. No severe exploded skinning or missing-texture defect was found in this reviewed set.
- New transparent shields preserve faces and body silhouettes from both opposing facings. Small hit bursts reinforce contact without obscuring the entire exchange. The blood/flash combinations were surveyed, but still images do not establish comfort over time or audio/visual rhythm.
- The arena's functional platform fronts are clear against the background pool. Stone, timber, glass and the more compact bar create a coherent venue. The former wall of flat city boxes and repeated crowd line are gone.
- HUD percentages, portraits, stock dots, meters, and four player colors remain readable. The four-player action frame shows a busy encounter without HUD overlap. Training tips fit their panel at 1.25 scale. Title, selection, pause and results have consistent typography and button hierarchy.
- Scaled settings/results/selection screenshots show deliberate scroll positions that reveal final controls while clipping earlier content at the top. The UI report explicitly verifies those controls remain reachable; this is not reported as inaccessible content based on one scrolled frame.

## Remaining limits of this review

The façade and small crowd figures are intentionally simple and are less detailed than the photographic sky/city backdrop. Their silhouettes and material response still look stylized at close QA zoom; they do not prevent play or undermine the major improvement. Continuous animation blending, foot sliding, temporal shimmer, effect timing, live four-player chaos, controller feel, performance, and audio quality cannot be certified from these stills. Static action poses are evidence of rendered poses, not proof that every animation transition is convincing. Root's live/native checks, gameplay capture and performance runs remain separate requirements. No claim about the exported Windows package is made here.
