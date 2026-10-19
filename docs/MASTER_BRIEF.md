# MASTER GOAL — UNSUPERVISED: ROOFTOP RIOT

Build the game described below in my selected workspace. This is an implementation goal, not a request for another proposal. Work through the milestones, create the actual assets and code, run the game, test it, inspect its presentation, and leave a playable PC build with editable source files.

I will run this as a long-running /goal with Astra Ultra selected. Use the capabilities actually available in this session. Do not assume a particular runtime, permission, integration, or installed tool merely because of the model setting.

## 01 — THE GAME WE ARE MAKING

Working title: UNSUPERVISED: ROOFTOP RIOT. This is a provisional original project identity, not a claim that the title is commercially cleared.

Create a visually striking, funny, adult-oriented 2.5D platform fighter starring recognizable 3D versions of five real people. The gameplay inspiration is the accessible movement, directional attacks, recoveries, escalating knockback, and ring-outs of a Smash-style platform fighter. The identity, characters' fictional powers, environment, UI, animations, music, and effects must be our own.

The comedy comes from ordinary-looking people performing absurdly spectacular attacks with the seriousness of world-class fighters. Keep their actual recognizable appearances and realistic body proportions. Give them expressive body language, ridiculous powers, satisfying violence, and strong individual playstyles—not oversized cartoon heads or replacement fantasy bodies.

The presentation should feel like a beautiful rooftop party that has become a catastrophically overproduced fighting tournament: sunset, city lights, a turquoise pool, dramatic silhouettes, warm architectural lighting, polished materials, reactive signage, and outrageous impact effects.

The quality priorities, in order, are:
1. Responsive, enjoyable, readable combat.
2. Convincing skeletal animation and recognizable characters.
3. Five genuinely distinct, functional movesets.
4. One excellent arena and a complete playable match loop.
5. Visual/audio polish, performance, and easy future expansion.

Do not confuse a long feature list with a good game. Make the parts work together.

## 02 — LOCKED SCOPE AND NON-GOALS

Use Godot for the game and Blender for character preparation, skeletal animation, environmental modeling, props, and asset processing. Prefer typed GDScript and Blender Python. Meshy is the source of the supplied character models, not a service you must call.

The five 3D character assets WILL ALREADY EXIST in the workspace before you start. There are NO supplied combat animations, NO finished map, and NO existing gameplay systems that you may assume are available. Rigging status is unknown until inspection.

Deliver this initial scope:
- Windows PC first; keyboard and gamepad support.
- Five selectable fighters; all unlocked immediately.
- Exactly ONE playable arena.
- Local 1v1 and 2–4-player free-for-all using the same combat systems.
- Human-versus-CPU, local human-versus-human, and mixed human/CPU matches.
- Training on the SAME arena, with hazards disabled by default.
- Three stocks, six-minute matches, damage percentages, and escalating knockback.
- Two rules presets: Party and Fair Fight. These are settings, not separate maps.
- Menus, character selection, settings, pause, results, and quick rematch.
- Actual authored and integrated skeletal animations, not just an empty animation framework.
- Editable source art, reproducible processing tools, documentation, and validation evidence.

Plan for later iOS adaptation and additional fighters. Do not implement online multiplayer, rollback networking, accounts, matchmaking, a campaign, open-world exploration, monetization, crafting, a second arena, or a mobile release in this initial goal.

Do not add a traditional health-bar mode or another unrelated ruleset. The core identity is a damage-percentage platform fighter.

## 03 — HOW YOU MUST WORK

Operate autonomously within the selected project workspace. Make reasonable design decisions without repeatedly asking me to choose colors, names, dimensions, or button bindings.

Create a short execution plan with verifiable milestones, then IMPLEMENT it. Planning is the first step, not the final deliverable. Do not stop after writing design documents, importing the models, making a graybox, or getting a capsule to move.

After each milestone:
- Run the relevant validation.
- Inspect what actually works.
- Fix failures before building further on that subsystem.
- Save an evidence snapshot and update the persistent status file.
- Continue automatically unless a genuine external blocker requires my involvement.

Use small reversible changes. Preserve user files and existing repository instructions. Do not run destructive Git commands, overwrite unrelated work, upload source photos/models to external services, purchase assets, change system-wide configuration, or publish anything.

Use installed tools first. Consult official documentation matching the actual installed versions. Do not invent APIs, pretend an integration exists, or claim that writing a script proves the script ran successfully.

Parallelize independent tasks only if supported and genuinely helpful. Keep ownership boundaries clear so multiple workers do not overwrite the same scene, asset, or script.

Keep progress updates brief and useful. Maintain persistent project state so a later session can resume without re-discovering everything. If the session ends before completion, leave the latest working build, exact unfinished acceptance criteria, and the next executable step. Do not label partial work complete.

## 04 — PREFLIGHT, WORKSPACE, AND TOOL VERIFICATION

First inspect the selected workspace, existing instructions, project files, imported assets, and version-control status. Locate the actual Godot and Blender executables. Record their versions and the available operating system, GPU/renderer information when accessible, and export-template status.

Do not assume version numbers from this prompt or another project. Do not silently upgrade working software. Use version-appropriate APIs and record commands that actually succeed.

Run a minimal Godot launch/import check and a Blender Python check. Test graphical rendering separately from headless execution; these are different capabilities.

Use the existing project layout if sensible. For a new workspace, a suitable structure is:

incoming/                         supplied originals; preserve unchanged
source_art/characters/<id>/        editable rig/animation .blend files
source_art/stage/                  editable arena .blend files
source_art/props/                  editable ability/environment props
game/project.godot                Godot project
game/characters/                   fighter scenes and definitions
game/combat/                       moves, states, hit resolution
game/stages/rooftop_riot/           the one shipped arena
game/input/                       human, CPU, and test input providers
game/presentation/                camera, VFX, audio, HUD
game/ui/                           menus and settings
game/assets/                       processed runtime assets
tools/blender/                     inspection, rigging, animation/export scripts
tools/validation/                  reproducible checks
tests/                            automated tests and fixtures
docs/                             concise project documentation
evidence/                         screenshots, reports, logs, captures
builds/windows/                   exported playable build

Do not move supplied files merely to match this example. Reference their real locations. Keep Blender working files, source photos, tests, and development evidence out of the release package.

Initialize local version control only when appropriate. Never claim a checkpoint exists unless it actually does. Preserve Godot-generated resource identifiers required for reliable references; exclude caches, temporary renders, and unrelated binary clutter.

## 05 — INITIAL ROSTER AND ASSET MAPPING

There are five intended fighters across the four reference photographs. Use these stable IDs and descriptive labels, not guessed real names:

f01_clutch: the person in the navy/blue quarter-zip in the two-person arena photograph.
f02_sunstruck: the person wearing a yellow shirt and cap in that same photograph.
f03_heavy_duty: the central person wearing a navy Champion T-shirt and light shorts.
f04_deadfall: the person wearing a red flannel overshirt over a light shirt.
f05_fine_print: the person wearing a pale green polo and dark trousers.

Other people incidentally visible in the photographs are not additional roster members.

Treat these descriptions as reference labels. The imported 3D models are the implementation assets. Do not assume that chat images are available as files in this coding workspace. Use the model filenames, supplied manifests, and rendered contact sheets to establish the mapping. Record uncertainty rather than silently swapping people.

Their fighter names, abilities, taunts, and personas below are fictional game inventions, not claims about the actual people's personalities, occupations, behavior, or abilities.

Create an asset manifest recording each source path, source hash, fighter ID, processed output, mesh statistics, materials, texture sizes, scale, skeleton status, and processing notes. Keep originals immutable.

## 06 — CHARACTER READINESS: A MODEL IS NOT AN ANIMATION PIPELINE

Inspect every supplied asset before relying on it. Determine whether it contains a usable armature, skin weights, a suitable rest pose, separate accessories, valid materials, UVs, and any existing actions. Do not assume that a GLB contains animation or that a finished Meshy model is correctly rigged.

For each character:
- Establish upright orientation, forward direction, foot origin, and consistent approximate human scale without erasing genuine proportion differences.
- Check for fused arms/torso, merged legs, missing backfaces, problematic transparency, disconnected clothing, and distorted joints.
- Preserve recognizable facial structure, hairstyle, clothing, proportions, and material appearance.
- Normalize materials and lighting response without blindly repainting the person.
- Prepare optimized derivative meshes and texture variants non-destructively.
- Generate a simple deformation preview: shoulder raise, elbow bend, hip/knee bend, torso twist, and deep combat pose.

If a usable rig exists, preserve it and build a semantic bone mapping. If not, create a suitable humanoid armature in Blender, bind the mesh, repair weights, and validate actual deformations. Automatic weights are a starting attempt, not proof of success.

Maintain a semantic skeleton contract for root, pelvis, spine/chest, neck/head, upper/lower arms, hands, upper/lower legs, and feet. Finger, facial, and accessory bones are optional. Make retargeting explicit; do not assume shared bone names imply compatible rest poses.

Bake Blender control-rig/constraint results onto deformation bones for runtime exports as needed. Keep the editable control setup in the source .blend. Prefer explicit tested GLB exports for the runtime so the packaged game does not depend on Blender being installed.

If an asset truly cannot deform acceptably without replacement geometry, report the specific issue with an image and the smallest required correction. Continue unaffected work, but do not replace that person with a generic mannequin and call the roster complete.

## 07 — ANIMATION DELIVERABLES: CREATE THE ANIMATIONS

Animation is a core production task in this goal. Do not give me five rigid characters sliding around or static bodies that merely bob, tilt, rotate, or scale during attacks.

Author actual keyed skeletal movement in Blender. Use a reusable humanoid motion foundation, then retarget and adjust it to each character. Shared locomotion and recovery clips are acceptable after visual verification; signature attacks, specials, ultimates, stances, and personality animations must be distinct.

One editable .blend per fighter can contain multiple actions. Do not fork the entire character into separate disconnected files for idle, moving, and fighting. Maintain an export manifest describing the action names, lengths, looping behavior, and corresponding moves.

Create a complete animation vocabulary covering:
- Intro, neutral idle, movement start/stop, walk, run, turnaround, crouch.
- Jump anticipation, rising, double jump, falling, soft/hard landing.
- Shield enter/hold/exit, parry, spot dodge, rolls, aerial dodge.
- Light/heavy hit reactions, launch/tumble, knockdown, get-up, ledge catch/release.
- Three-part jab chain, directional grounded attacks, dash attack, charged heavy attacks.
- Neutral, forward, back, up, and down aerials.
- Four directional specials and each fighter's ultimate sequence.
- Grab attempt/hold/release and directional throws; corresponding victim reactions.
- Respawn, win, lose, two distinct taunts, and final-KO flourish.

Individual states may reference compatible shared clips where appropriate. Every advertised action must resolve to a real working animation. No empty clips or animation names pointing to the idle pose.

For attacks, create readable anticipation, committed contact poses, follow-through, recoil, and recovery. Use hips, shoulders, weight shifts, foot placement, and clear arcs. Feet should not skate continuously. Limbs should not pass through the torso in ordinary poses. Keep faces reasonably readable without requiring unavailable facial rigs.

Match animation timing to move timing; do not stretch every attack from the same generic punch. Standard locomotion should be in-place. Gameplay movement is controlled by the combat/movement system, not uncontrolled root motion. Any special-move displacement must be explicitly authored and collision-tested through that system.

Use AnimationPlayer/AnimationLibrary and AnimationTree or an equivalent maintainable Godot setup. The gameplay state machine owns combat state; the animation system presents it. Blending cannot delay an active hit or grant an extra cancel window.

Create repeatable contact sheets and preview captures showing idle, run, jump, a basic strike, a recovery, and each signature special on the actual character. Inspect the in-engine result after export, not only the Blender viewport.

## 08 — WORLD, MOVEMENT, AND CAMERA FOUNDATIONS

Use a 3D world and 3D fighters with gameplay confined to one plane: X horizontal, Y vertical, Z fixed for authoritative combat. The stage may have visual depth, but fighters cannot sidestep into or out of attacks.

A suitable starting implementation is CharacterBody3D for the fighter body with a separate VisualRoot and imported skeletal model. Keep gameplay facing as a sign and rotate the presentation root appropriately. Do not use negative skeleton scale as the main facing mechanism.

Build responsive acceleration, braking, turnarounds, ground jumps, short hops, double jumps, air control, fast fall, platform drop-through, ledge recovery, and controlled landing lag. Expose tuning values centrally.

Use a 60 Hz authoritative combat tick with frame-independent rendering. Initial tuning targets, not untouchable constants:
- Ground run speed approximately 7–9 stage meters per second.
- Initial jump apex approximately 3.5–4 stage meters.
- Input buffering around 6 ticks.
- Small ground-jump grace window around 4 ticks.
- Short-hop control through release timing.
- One aerial dodge and one recovery special per airtime unless a documented mechanic says otherwise.

Track supported platform, airborne resources, landing transitions, and temporary collision exceptions explicitly. Refresh aerial resources only on legitimate landing/respawn. Prevent infinite recovery resets, edge jitter, wall clipping, and uncontrolled depth drift.

Implement one-way platforms deliberately for this 3D controller. Verify the APIs available in the installed engine rather than assuming a 2D-only one-way collision property exists on a 3D node. Use tested per-fighter top-plane crossing/support logic or an equivalent robust approach. Drop-through must ignore only the intended platform temporarily, not all stage collisions.

The shared camera follows active fighters, predicts meaningful launches modestly, and smoothly adjusts framing within limits. Favor a side-on orthographic or near-orthographic presentation that makes distances readable. Never rotate the gameplay camera around the fighters during ordinary combat.

Use fixed world-space blast boundaries independent of the camera. Camera shake, zoom, and resolution changes must never change KO eligibility. Keep offscreen indicators, player markers, and safe HUD margins clear.

## 09 — COMBAT RULES AND AUTHORITATIVE HIT RESOLUTION

Use damage percentages and stocks. Damage begins at 0%; successful hits raise it. Higher damage generally produces stronger knockback. A stock is lost only when the fighter crosses a world-space blast boundary or another explicitly documented KO condition—not because a health bar reached zero.

Default match: three stocks, six minutes. At timeout, rank surviving players by stocks remaining, then lower damage percentage. Resolve an exact tie with a short clearly announced sudden-death phase involving only tied fighters on the same arena. Define and test simultaneous elimination and double-KO behavior.

Implement:
- Grounded light attacks, directional attacks, charged heavies, dash attacks, and aerials.
- Directional specials, recovery moves, grabs, and throws.
- Shield, shield resource, shield regeneration delay, shield stun, and shield break.
- Perfect-timed defensive parries with a clear short window.
- Spot dodge, ground roll, and aerial dodge with readable vulnerable recovery.
- Hitstun, hitstop, knockdown, limited directional influence, and launch tumble.
- Damage scaling or hitstun safeguards to prevent trivial infinite chains.
- Per-fighter ultimate meter and temporary passive resources.

Use an explicit MoveDefinition containing stable ID, input/context requirements, startup ticks, active windows, recovery, cancel windows, damage, knockback parameters, launch angle, hitstun, shield effects, armor/invulnerability windows, movement curves, animation ID, effects, and ownership rules.

Starting balance ranges: jabs around 5–8 startup ticks; committed heavies around 16–24; charged moves capped around 60–75 charge ticks. Tune through testing. Do not shorten moves indiscriminately until everything becomes unreadable.

Author hitboxes in authoritative fighter-local coordinates and mirror them by gameplay facing. Keep them reasonably matched to visible limbs/props. Visual bone interpolation must not determine whether a hit exists on a simulation tick.

Collect eligible contacts before resolving them so attack trades do not depend on scene-tree order. Define attack-instance IDs, target IDs, hit-group IDs, re-hit intervals, and ownership. One punch must not apply damage every overlapping frame or once per victim hurtbox. Intentional multihits require explicit data.

Use swept checks for fast projectiles/moves where necessary. Resolve shields, parries, grabs, armor, vulnerability, and clash rules in a documented order. All damage passes through one combat resolution pathway, including traps and hazards.

Separate hitstop from global pause. Specify which motion and timers freeze; preserve input buffering without causing duplicate attacks afterward. Do not casually set global time scale for every punch.

Knockback should depend on move strength, target damage, target weight, and bounded influence. Keep launch trajectories predictable and testable. Avoid random critical hits and hidden luck bonuses.

Track KO credit and assists consistently. Clear temporary buffs, stale inputs, hit registries, owned effects, captures, and recovery state on KO/reset as appropriate. Respawn above a safe point with brief visible invulnerability that ends early when the player attacks.

Ultimate meter runs from 0 to 100. Award capped meter from legitimate combat, not whiffing, idle taunts, self-damage, or repeatedly farming an invulnerable target. Reset meter on losing a stock initially. Ultimate attacks must have telegraphed counterplay and may miss; they are not guaranteed zero-damage kills.

## 10 — COMMON MOVESET CONTRACT

Every fighter must implement the same discoverable input vocabulary while feeling different:
- Neutral light jab chain; up/side/down grounded light attacks.
- Neutral/side, up, and down heavy attacks with appropriate charge behavior.
- Dash attack.
- Five aerial directions: neutral, forward, back, up, down.
- Neutral, side, up, and down special.
- Grab and four directional throws.
- Shield, parry, grounded dodges, aerial dodge.
- Ultimate, two taunts, and win/KO presentation.

Use common infrastructure, not identical choreography. Give each fighter different range, weight, speed, jump rhythm, recovery risk, attack arcs, and punish windows. Keep those differences readable and documented.

For each moveset, create a compact move sheet with its actual implemented frame data, purpose, risk, and counterplay. Include two beginner-friendly example combos without promising they work at every damage percentage or against every opponent.

All fighter names and lines below are editable content. Preserve stable internal IDs when display names change.

## 11 — FIGHTER 1: CLUTCH / f01_clutch

Reference: navy quarter-zip. Archetype: accessible kinetic all-rounder. VFX: electric blue and white, compressed impact rings, short angular speed trails.

Fictional persona: the competitor who treats a rooftop argument like the final ten seconds of a championship. Relaxed guard, athletic footwork, clean combinations, slightly excessive victory celebrations.

Strengths: reliable fundamentals, flexible aerial control, understandable combos. Weaknesses: modest reach and no effortless long-range zoning.

Passive — MOMENTUM: landing different attacks in a short sequence builds up to three visible pips. Repeating the same jab or striking shields cannot farm them indefinitely. An empowered special consumes one pip for a clearly defined extra effect. Do not secretly change animation speed or move timing when pips are gained.

Neutral special — OVERTIME: a chargeable forward palm blast with short-to-medium range. More charge increases reach and commitment. A momentum pip adds a second small kinetic ring, not an unavoidable full-stage beam.

Side special — PERSONAL FOUL: a fast step-in shoulder check with visible startup and punishable recovery. The empowered version creates a small end-of-dash burst. It cannot pass through stage walls.

Up special — SECOND WIND: an angled rising uppercut with limited steering, followed by helpless fall. Empowerment improves recovery distance modestly; it does not refresh the recovery resource.

Down special — TIME OUT: a brief planted counter stance. A correctly timed incoming strike triggers a kinetic shove. Missing the timing leaves a clear vulnerable recovery. No screen-wide time freeze.

Ultimate — CLUTCH TIME: a telegraphed rush that confirms into a short multi-hit combination only if the opener connects. End with a powerful directional launch. In free-for-all, keep the action on the arena and preserve other players' visibility.

Animation identity: compact jab–cross–hook chain, scissor-like aerial kicks, sliding stop, shoulder-led heavy strike, wrist-loosening idle.

Comedy: checks an imaginary scoreboard; calls for a replay after getting launched. Final-KO flourish: an absurd sports-style victory graphic and a composed collar adjustment.

## 12 — FIGHTER 2: SUNSTRUCK / f02_sunstruck

Reference: yellow shirt and cap. Archetype: ricochet trickster and mobile zoner. VFX: gold, warm magenta, sunbursts, curved disc trails.

Fictional persona: an overconfident rooftop headliner who considers every fight part of the entertainment. Cap gestures, theatrical dodges, flashy footwork, dramatic bows.

Strengths: unusual angles, projectile routing, mobility mixups. Weaknesses: lighter weight, weaker close-range scrambles, punishable failed tricks.

Passive — ENCORE: successfully catching a returning special disc builds a visible three-step sequence. Completing it empowers the next disc. No random luck, unexplained criticals, or hidden probability.

Neutral special — HAT TRICK: throw a luminous cap-shaped disc that travels outward and returns. Cap active projectiles and enforce per-target re-hit windows. Use a generated energy prop rather than damaging the supplied head mesh to extract a hat.

Side special — VELVET ROPE: a sweeping golden ribbon strike followed by a short lateral reposition. Useful for spacing, but not a teleport through collision or a full invulnerable escape.

Up special — VIP LAUNCH: a compact burst of theatrical pyrotechnics propels the fighter upward with limited horizontal adjustment. Big readable startup effect; vulnerable descent.

Down special — MIRROR SERVICE: place one visible reflector puck that redirects the fighter's own disc at a predictable angle. It expires and can be destroyed. Reflector behavior must be clear from its orientation and preview effect.

Ultimate — THE MAIN EVENT: aim a bright stage spotlight at a visible region, show a warning marker, then deliver a short sequence of solar impacts inside that region. Opponents can leave, dodge, or punish the setup. No full-screen whiteout.

Animation identity: backhand tosses, spinning heels, exaggerated cap-tip anticipation, low evasive steps, showboating follow-through.

Comedy: bows before confirming whether anyone was hit. Final-KO flourish: a fictional VIP EXIT graphic accompanies the launch.

## 13 — FIGHTER 3: HEAVY DUTY / f03_heavy_duty

Reference: navy T-shirt and light shorts. Archetype: heavyweight grappler and close-range bruiser. VFX: steel, crimson, chunky dust, compressed shockwaves.

Fictional persona: a bouncer for an event that absolutely did not hire a bouncer. Heavy planted stance, economical movement, enormous commitment, deadpan reactions.

Strengths: throws, punishing close-range hits, survival at higher damage. Weaknesses: slower movement, large commitment windows, less forgiving recovery.

Passive — COMMITMENT: specified heavy-attack windows can absorb one qualifying light hit without interruption. Damage still applies. Grabs and sufficiently strong attacks defeat this armor. Show a brief armor flash; never make it permanent.

Neutral special — COMPLAINT DEPARTMENT: a short-range thunderous clap. Strong shield pressure and a compact shockwave, but obvious windup and no long-range projectile spam.

Side special — PLEASE REMAIN SEATED: a committed short rush into a command grab. On connection, perform a brief lift-and-slam. On whiff, leave substantial recovery. Define cancellation, victim release, interruption, and simultaneous-grab rules.

Up special — CARRY-ON: a forceful rising clothesline with limited lateral travel. Powerful near the body, but its recovery distance remains a deliberate weakness.

Down special — FLOOR INSPECTION: stomp when grounded; commit to a downward elbow drop when airborne. A landing shockwave spreads a short distance. Missing the stage is a real risk, not a free automatic rescue.

Ultimate — FOLDED LIKE FURNITURE: a telegraphed grab leads to an absurd wrestling-style slam onto a conjured folding-chair platform. Use authored attacker/victim animation and controlled motion, then launch the victim. The prop is temporary and must clean up reliably.

Animation identity: body hooks, shove-heavy jabs, heel plants, broad grabs, belly-first aerial tackle, exaggerated impact settling.

Comedy: unfolds a chair during a taunt and sits for a moment. Final-KO flourish: looks disappointed in the broken furniture rather than excited about winning.

## 14 — FIGHTER 4: DEADFALL / f04_deadfall

Reference: red flannel over a light shirt. Archetype: setup-oriented scrapper and trap controller. VFX: forest green, amber, bark fragments, rope arcs.

Fictional persona: someone who insists everything is a simple weekend project while constructing wildly unsafe combat equipment. Loose stance, improvised tools, sudden technical movement.

Strengths: stage control, layered setups, trap conversions. Weaknesses: setup time, weaker immediate pressure, destructible tools.

Passive — FIELDCRAFT: landing an armed trap grants one visible Quick Fix charge. The next side or up special can consume it for a modest movement improvement. No stacking into unlimited recovery or permanent speed.

Neutral special — SPLINTER SERVICE: send a small rolling log-like energy construct across the platform. It can be jumped over and has a finite life. It obeys terrain rules and does not invisibly damage fighters on another platform.

Side special — SHORTCUT: a low sliding rush on a conjured plank, ending in a rising strike. Good for surprising movement, but punishable if blocked. Collides correctly with solid stage geometry.

Up special — BRANCH OFFICE: swing from a briefly conjured overhead branch using a predetermined, collision-aware recovery arc. This is not a general-purpose grappling simulation. The branch is presentation, not a new permanent platform.

Down special — TRIP HAZARD: deploy a clearly visible, briefly arming tripline. Maximum two active traps; oldest expires when replaced. Opponents can destroy or avoid them. Define ownership, damage, trigger limits, and cleanup on stock loss.

Ultimate — QUESTIONABLE LANDSCAPING: mark a diagonal impact zone and bring down an absurd oversized tree construct. Strong launch on the main hit, smaller debris effects afterward. The warning must communicate the actual dangerous region.

Animation identity: backhand swings, low sweeps, scrappy elbow chains, quick tool placement, loose-to-explosive weight shifts.

Comedy: checks a tiny imaginary instruction sheet after summoning the tree. Final-KO flourish: a deadpan THAT WAS LOAD-BEARING sign appears briefly.

## 15 — FIGHTER 5: FINE PRINT / f05_fine_print

Reference: pale green polo and dark trousers. Archetype: precise counter-striker and spacing specialist. VFX: violet/white, fine rectangular traces, crisp geometric impact marks.

Fictional persona: a perfectly polite administrator of unnecessarily violent consequences. Upright posture, clean steps, controlled kicks, minimal wasted movement.

Strengths: counterplay, spacing, punishing predictable attacks. Weaknesses: demanding timing, limited crowd control, vulnerable missed counters.

Passive — CITATIONS: precise special hits and successful parries place up to three visible marks on an opponent, with expiry and per-target limits. A designated heavy or ultimate consumes marks for a bounded bonus. Marks are never invisible permanent debuffs.

Neutral special — POINT TAKEN: a narrow, extending palm-thrust energy strike. Excellent at a specific distance, poor when carelessly thrown at point-blank range. A clean outer-range hit grants a mark.

Side special — HOSTILE TAKEOVER: a measured advancing heel kick with a follow-up only on a confirmed hit. Shielding or dodging the opener creates a punish opportunity.

Up special — CORPORATE LADDER: ascend through three precise kicks with translucent step effects. The steps are non-colliding presentation, not permanent additional platforms.

Down special — OBJECTION: a short precision counter window, narrower but more rewarding than ordinary shield defense. Failure has real recovery. Its timing must be learnable and visually consistent.

Ultimate — TERMS AND CONDITIONS: telegraph a bounded geometric strike zone, then deliver a rapid sequence of precise attacks. Existing marks improve the final launch within a cap. Catching someone requires the opener; the entire arena is not automatically captured.

Animation identity: controlled straight punches, snapping kicks, composed backsteps, tidy guard, tiny sleeve adjustment after a successful counter.

Comedy: produces an imaginary clipboard during a taunt. Final-KO flourish: a large DENIED stamp and an almost apologetic nod.

## 16 — THE ONE ARENA: THE LAST RESORT

Build a single signature rooftop venue above a fictional city. It is a luxury party terrace surrounding a purpose-built fighting deck, not a generic floating gray platform.

Art direction: late golden hour drifting subtly toward blue hour; turquoise pool water behind the combat plane; amber architectural lighting; dark stone, brushed metal, warm wood, glass, palms, sculptural lights, skyline silhouettes, distant traffic, and a dramatic sky. Use the scale contrast between ordinary people and the city below.

Starting gameplay blockout, adjustable after movement tests:
- Main deck approximately 18 meters wide, centered on X, floor top at Y=0.
- Two side upper platforms approximately 4.5 meters wide at X=-5 and X=5, Y around 3.6.
- One narrower central upper platform around Y=5.5.
- Four clear initial spawn positions on the main deck.
- Outer ledges with readable recovery space below and to the sides.
- Blast boundaries initially around X=+/-18, lower Y=-8, upper Y=16; tune alongside launch strength and camera framing.

All platforms share the same gameplay depth. Background pool decks, railings, stairs, furniture, and city geometry are visual depth, not misleading walkable lanes.

Build the arena in Blender with deliberate architecture, bevels, coherent material scale, modular trim, lighting fixtures, and modeled focal props. Avoid a random pile of cubes with bloom. Keep collision meshes simple and separate from decorative geometry.

Party preset:
- The center platform moves slowly along a predictable vertical service-lift path.
- Two clearly marked edge pyrotechnic vents occasionally pulse with modest damage/launch.
- Hazards announce themselves visually and audibly at least about one second ahead.
- A seeded event schedule makes tests reproducible.
- Decorative furniture and small signs can break into pooled cosmetic fragments.
- Background lights, screens, and crowd silhouettes react to major hits and KOs.

Fair Fight preset:
- The same arena, geometry, lighting, and visual identity.
- Center platform held at a fixed documented position.
- Damaging hazards disabled.
- Cosmetic background events remain restrained.
- No randomized gameplay-affecting surprises.

Keep the main floor intact. Do not destroy the only safe surface, hide attacks behind debris, launch players with unannounced hazards, or make the scenery more important than the fighters. Destruction is curated prop breakup, not an expensive general-purpose fracture simulation.

Use subtle environmental progression, not a real-time day/night simulation. Maintain consistent fighter lighting and attack readability throughout the match. Background crowds may be efficient original silhouettes/instanced assets; do not depend on generating more realistic people.

Exactly one shipped playable stage. Internal test fixtures are permitted but must not appear as extra selectable maps.

## 17 — VISUAL FEEL, MATURE COMEDY, AND FINISHERS

Aim for premium stylized realism: believable materials and proportions with deliberately exaggerated action. Preserve the supplied people's recognizable appearances. Do not apply a harsh cartoon shader, permanently obscure faces, or turn everyone into the same armored superhero.

Create clear visual layers: readable fighters, visible attack effects, quieter stage, atmospheric background. Use rim lighting, controlled emission, contact shadows, restrained bloom, and contrast. Effects should reinforce an attack's shape and timing.

Use small hitstop on light hits, stronger punctuation on heavy launches, directional impact bursts, brief camera impulse, restrained trails, controller rumble, and clear shield/parry effects. Avoid constant full-screen shake, chromatic aberration, motion blur, flashing, or camera cuts.

Adult-oriented tone: stylized blood splashes, exaggerated ragdoll-like KO motion, optional profanity in fictional written barks, absurd overkill, and comic disrespect. Keep the presentation clearly fictional. Do not create realistic torture, anatomically detailed dismemberment of the supplied people, hateful jokes, sexual humiliation, or invented allegations about their real lives.

Treat M-rated as a content target, not an official rating already obtained. Include independent settings for blood, profanity, flash intensity, shake, and rumble. Blood-off must preserve impact readability with alternate effects.

Separate an ultimate from a finisher. Ultimates are real, counterable gameplay moves. Finishers are short presentation flourishes after a confirmed decisive KO, not a second combat mode, repeated QTE, or mandatory ten-second interruption.

In 1v1, the final match-winning KO may receive a brief dramatic angle after the result is authoritative. In a free-for-all that is still active, use compact effects and maintain the shared camera. Never hide other players while two characters perform a cinematic.

If physical ragdoll is reliable and affordable, use it after KO. Otherwise author a convincing skeletal tumble. In either case, visual bodies and debris cannot change authoritative combat collisions or the match result.

## 18 — INPUT, LOCAL MULTIPLAYER, AND CPU OPPONENTS

Create an input abstraction that produces per-player action snapshots. Gameplay consumes those snapshots without knowing whether they came from keyboard, gamepad, CPU, or a test runner. A future touch provider should be addable without rewriting combat.

Suggested default actions: move, aim direction, jump, light, heavy, special, defend/dodge, grab, ultimate, taunt, pause. Choose sensible keyboard/gamepad defaults, expose remapping, and show them in-game. Do not require complicated motion inputs.

Support keyboard plus controllers, multiple controllers, controller connection/disconnection, player-slot assignment, and no input leakage between players. One keyboard profile is sufficient initially; do not advertise robust four-player shared-keyboard support without actually testing its limitations.

Create CPU opponents now, not merely empty AI hooks. They should approach, space, attack, shield occasionally, recover, avoid obvious hazards, use their signature mechanic, and try to return to the stage instead of walking off forever.

Use a stage-aware navigation/action graph or equivalent platform-fighter reasoning—not ground-only navigation that ignores jumps and recovery. Easy/Normal/Hard should differ in reaction delay, decision quality, and mistakes, not hidden damage/health bonuses or impossible knowledge of future inputs.

All CPU actions must flow through the same input rules as human actions. Keep seeds controllable for tests. Include a CPU-vs-CPU demonstration mode within the normal setup flow.

## 19 — UI, TRAINING, AUDIO, AND MATCH FLOW

Build a coherent, attractive UI, not a debug panel disguised as a menu. Use bold readable typography, restrained transitions, original iconography, and a consistent warm/cool rooftop palette.

Flow: title screen → local match setup/character selection → match → results → rematch or selection. Since there is one map, do not force an empty stage-select screen. Show the arena card and Party/Fair Fight option inside setup.

Character selection should display model-derived portraits or live previews, readable names, archetypes, player/device assignment, CPU difficulty, a concise unique-mechanic description, and Ready status. Allow mirror matches; distinguish identical fighters with player markers and tasteful effect/outline variations rather than repainting their faces.

HUD: portrait, name, player marker, damage percentage, stocks, ultimate meter, and a compact character-specific resource indicator. Show timer, pause state, KO feedback, and clear match results. Hide irrelevant clutter.

Training uses the same arena and supports reset positions, reset damage, a stationary/defending/jumping dummy, input display, optional hitbox overlay, and move tips. Development-only frame stepping and combat logs may live behind a debug toggle.

Settings: master/music/effects volume, graphics preset, resolution/window mode where supported, input remapping, shake, flashes, rumble, blood, profanity, and UI scale. Save locally with safe defaults and graceful recovery from missing or corrupt settings.

Audio is part of the deliverable, not only empty event names. Use original procedurally created sounds or clearly licensed local assets for punches, heavy hits, launches, shield, parry, jumps, landings, menu actions, meter-ready, hazards, KOs, and atmosphere. Provide a modest original musical/ambient bed if feasible. Avoid clipping, excessive repetitive noise, and silent combat.

Keep an asset license/provenance record. Do not scrape commercial game sounds or music. Do not clone the real people's voices. Use written fictional barks and optional non-identifying vocal efforts unless supplied authorized recordings exist.

## 20 — CODE AND DATA ARCHITECTURE

Keep the architecture modular but proportionate to one game. Do not spend the goal building a general-purpose engine, plugin marketplace, or elaborate framework instead of the fighting game.

Useful responsibilities:
- FighterDefinition: ID, display content, scene, stats, moveset, mechanic component, portrait, palette, animation profile.
- MoveDefinition: authoritative timing, hit data, movement, cancels, effects, animation mapping.
- FighterState: per-instance mutable combat/movement/resource state.
- CombatResolver: contact collection, defenses, damage, stun, knockback, ownership.
- InputProvider: human, CPU, and scripted/test implementations.
- Ability components: reusable projectiles, counters, traps, grabs, charge, timed zones, character-specific logic where necessary.
- MatchManager: setup, stocks, timer, respawn, KO attribution, tiebreaks, results, cleanup.
- StageController: geometry references, spawn/ledge/platform metadata, hazard preset, event seed.
- Presentation systems: animation, camera, VFX, audio, HUD.
- RosterRegistry: discover and validate content without hardcoding five fighters throughout the game.

Prefer typed Resources and small well-named scripts. Do not build one enormous fighter script with hundreds of branches on fighter name. Unique mechanics may use focused components; data-driven does not mean forcing every behavior into an unreadable universal interpreter.

Shared definitions are immutable at runtime. Damage, meters, counters, cooldowns, marks, targets, and action state belong to each fighter instance. Mirror matches must not share mutable resources accidentally.

Use structured signals/events for presentation. Avoid stringly typed event chaos and deep scene-path assumptions. Validate required nodes, resources, animation names, sockets, and move IDs during import/startup with actionable messages.

Keep randomness seeded and gameplay decisions isolated from visuals. Do not claim Godot physics or this architecture is automatically deterministic across platforms, rollback-ready, or network-ready. Future online play would require its own design and validation.

Adding a sixth fighter must require a new content folder/definition, asset mapping, animations/moves, and any genuinely new mechanic component—not edits across menus, match code, damage resolution, and camera logic.

## 21 — PERFORMANCE AND FUTURE iOS ADAPTATION

Target a stable 60 FPS on the available development PC at 1080p with four fighters and Party effects. Measure and report actual hardware, resolution, renderer, frame timing, and conditions. A target is not an achieved result until measured; do not invent mobile performance figures.

Use an appropriate desktop renderer after hardware verification. Forward+ may be used for the high PC presentation, but build a separately testable Mobile-renderer profile early. Do not assume every effect transfers unchanged or that switching renderers is always a seamless runtime toggle. Make restart requirements explicit where applicable.

Keep the core look supported by good models, materials, composition, baked/static lighting where suitable, and efficient effects. Advanced reflections/fog may enhance the PC profile but must not be required to see attacks or understand the arena.

Budget and measure skinned geometry, materials/draw calls, texture memory, real-time shadow lights, transparency, particles, decals, and debris. Use LODs and lower texture tiers on derivative assets without damaging facial recognition or skinning. Validate rather than blindly decimating every mesh to an arbitrary number.

Pool frequently spawned projectiles/effects where beneficial, cap simultaneous effects, clean up timers/signals, and check repeated rematches for memory/resource growth. Avoid uncontrolled real-time destruction, dense simulated crowds, or permanent decals.

For future iOS: preserve input abstraction, adaptable UI/safe areas, scalable effects and textures, and no desktop-only gameplay dependency. Document what remains: touch UX, device profiling, thermal/memory testing, export/signing, platform requirements, and distribution review.

Do not claim iOS is shipped or validated by a Windows build. Verify current Godot platform documentation when documenting export requirements; actual iOS export/device work needs the appropriate macOS/Xcode environment and device access.

## 22 — VALIDATION AND EVIDENCE

Create a reproducible validation workflow and run it. A successful parse is not the same as a successful game; a headless pass is not proof of visual quality; screenshots alone are not proof that combat works.

Cover at minimum:
- Asset import, correct fighter mapping, all required animation mappings, and missing-resource checks.
- Both facing directions; jumps, short hops, double jumps, fast fall, ledges, moving platforms, and drop-through.
- Startup/active/recovery boundaries and cancel-window correctness.
- One-hit-per-target behavior, intended multihits, simultaneous trades, sweeps, armor, shields, parries, grabs, and interruption cleanup.
- Damage/weight/knockback relationships and bounded influence.
- Air-resource limits; no infinite recoveries, permanent invulnerability, or animation lockups.
- Correct ultimate costs and passive-resource limits; no farming by idle actions.
- All five fighters' specials, ultimates, traps/projectiles, and distinctive mechanics.
- Mirror matches with independent state.
- Stocks, KO credit, simultaneous KO, timeout, sudden death, respawn, match end, and rematch.
- Input isolation, pause/resume, settings persistence, and controller loss behavior.
- Party versus Fair Fight: damaging hazards truly disabled in the latter.
- Despawning/reset cleanup of projectiles, marks, captures, traps, props, and effects.
- Similar authoritative behavior under different rendering frame rates at the same combat tick rate, without claiming untested cross-platform determinism.

Use scripted scenario tests and a seeded action-fuzz/soak harness where useful. Run each distinct fighter pairing and mirror match through basic smoke coverage. Add four-CPU stress matches, repeated rematches, and deliberate offstage recovery scenarios. Record seeds and failures so bugs are reproducible.

Perform actual graphical play checks where available: main menu, character select, each character in normal light, 1v1 action, four-player action, high-damage launch, each ultimate, and results. Inspect for clipping, awkward skinning, missing effects, unreadable HUD, texture failures, and excessive camera movement.

Save genuine screenshots and short captures when tools allow. Do not substitute concept art, unrelated reference renders, or doctored UI mockups for running-game evidence. If visual inspection or a hardware test cannot be performed, label that validation incomplete instead of claiming it passed.

## 23 — MILESTONES WITH REAL EXIT CRITERIA

Milestone 0 — Preflight and source protection.
Exit: installed tools verified; workspace safe; five assets inventoried/mapped; rig readiness documented; execution plan written. Then continue.

Milestone 1 — Actual-character vertical slice.
Exit: one supplied character has a working rig, real locomotion and attack animation, plane-constrained movement, camera, one opponent instance, functional hit/launch/stock/respawn loop, and a playable blockout of the eventual arena. No unrelated test-map art production.

Milestone 2 — Combat foundation and first complete fighter.
Exit: Clutch is fully playable with directional moves, defenses, grabs, all specials, ultimate, passive, and animation coverage. Training controls and CPU basics work. Core timing/ownership/reset tests pass.

Milestone 3 — Full five-person roster.
Exit: all five supplied people are mapped correctly, animated, selectable, and playable; their unique systems work; mirror matches are independent; previews and move sheets reflect real implementation. Do not call five reskinned copies a completed roster.

Milestone 4 — Signature arena and local match loop.
Exit: the one arena has finished architecture, materials, lighting, hazards/settings, camera framing, and recognizable identity. 1v1 and 2–4-player matches with human/CPU slots reach valid results and rematch cleanly.

Milestone 5 — Presentation and usability.
Exit: polished menus/HUD, readable VFX, audio, personality animations, mature-content toggles, settings, training, and safe final-KO presentation are integrated. Capture and inspect normal gameplay, not only ideal closeups.

Milestone 6 — Stability, optimization, and handoff.
Exit: regressions fixed; stress/rematch tests run; desktop performance measured; lower graphics profile checked; release export tested when tooling permits; source and content-addition workflow documented.

Keep working automatically between milestones. Pause only for a genuine dependency/access/asset blocker, a risky action needing approval, or an actual session limit. A self-created visual-review checkpoint does not mean stop and wait for me after every small step.

## 24 — DELIVERABLES AND DEFINITION OF DONE

Leave:
1. The working Godot project with all required source and runtime assets.
2. A runnable Windows build when export templates/tools are available, with launch instructions verified against the actual files.
3. Editable Blender source files for character rigs/actions, the arena, and authored props.
4. Reproducible inspection, processing/export, and validation scripts.
5. Asset manifest, implemented move data, animation coverage report, test results, performance report, and real visual evidence.
6. Concise README plus architecture, controls, adding-a-fighter, asset pipeline, known issues, and future-iOS notes.
7. A persistent STATUS.md identifying completed work, unresolved issues, latest working checkpoint, and exact next steps.

Prove roster extensibility with a development-only template/registration test without adding a sixth selectable placeholder fighter to the shipped roster.

The game is complete for this goal only when I can launch it, select any of the five actual characters, fight a CPU or local players on the one finished arena, use the different abilities, see properly animated attacks, lose/win stocks, finish a match, rematch, change settings, and return to the menu without the normal flow breaking.

No T-posed fighters as a finished feature. No fake animation completion. No beautiful menu concealing broken combat. No generic arena hidden behind cinematic screenshots. No silent replacement of missing work with TODOs. No performance claims without measurements.

If a required item is blocked, state exactly which item, what was attempted, what evidence exists, and the smallest next action needed. Deliver the working remainder honestly without redefining the original goal.

Final handoff should be concise: build/project locations, how to launch, controls, what is verified, remaining blockers, and evidence locations. Do not dump thousands of lines of code into the final chat instead of saving the project.

BEGIN NOW: inspect the workspace and supplied character assets, verify Godot and Blender, preserve the originals, write the executable milestone plan, and start building the actual game. Make it responsive, beautiful, ridiculous, and genuinely fun to play.