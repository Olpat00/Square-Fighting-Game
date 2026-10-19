# Measured Windows performance

<!-- LIVING_ARENAS_CURRENT_BEGIN -->
## Living arenas — current four-player measurements

Ten isolated 60-second source-project cases cover all five arenas at 1920×1080 on High and Low, with four CPU fighters and authoritative 60 Hz combat. The full matrix uses a 120 FPS render cap, with VSync disabled. It measures this explicitly controlled workload and its headroom against a 16.667 ms frame budget; it is not an uncapped stress result or a device/driver fix. The ten cases recorded 41 intervals above 16.667 ms out of 71,983 render-interval samples. All outliers remain in the original matrix table; this is not a clean stable-60-FPS result across every case. Measurements apply to the Ryzen 7700X / RTX 4080 SUPER workstation; they do not certify weaker PCs, the exported build or the separate Mobile renderer. The game code retains the engine's VSync defaults; this harness deliberately disables VSync and sets its recorded render cap. Its presentation pacing is therefore a different workload from ordinary synchronized play.

CPU rendering work, GPU rendering work and frame intervals are separate measures; their percentiles must not be added. Screenshot readback occurs after measurement. The provenance receipt binds every report to unchanged current runtime, accepted fighter art and the measurement harness. Summary JSON reports, engine/native logs and companion captures are in `evidence/background_rebuild/performance/final_capped120/`; the harness does not save the raw interval series.

Combat ticks by case: The Last Resort High: 3,601, The Last Resort Low: 3,600, Lunar Reach High: 3,600, Lunar Reach Low: 3,601, Verdant Shrine High: 3,601, Verdant Shrine Low: 3,600, Abyssal Observatory High: 3,601, Abyssal Observatory Low: 3,600, Ember Foundry High: 3,600, Ember Foundry Low: 3,599.

### Completed full matrix at the recorded render rate

[Bound ten-case receipt](../evidence/background_rebuild/performance/final_capped120/profile_provenance.json). These original results remain intact, including every recorded outlier.

| Arena | Tier | Samples | Frame P95 / P99 ms | Max ms | >16.667 ms | Render CPU P95 ms | GPU P95 ms |
|---|---|---:|---:|---:|---:|---:|---:|
| The Last Resort | High | 7,200 | 9.723 / 10.559 | 28.577 | 8 | 0.590 | 2.832 |
| The Last Resort | Low | 7,191 | 10.541 / 11.977 | 69.732 | 8 | 0.801 | 2.844 |
| Lunar Reach | High | 7,200 | 10.137 / 11.127 | 21.877 | 2 | 1.646 | 3.724 |
| Lunar Reach | Low | 7,201 | 10.163 / 11.288 | 19.602 | 1 | 1.121 | 3.159 |
| Verdant Shrine | High | 7,199 | 10.414 / 11.841 | 31.749 | 4 | 0.913 | 3.787 |
| Verdant Shrine | Low | 7,200 | 9.810 / 10.721 | 27.349 | 6 | 0.420 | 3.170 |
| Abyssal Observatory | High | 7,201 | 9.974 / 10.892 | 23.385 | 5 | 0.732 | 3.013 |
| Abyssal Observatory | Low | 7,201 | 10.345 / 11.880 | 19.001 | 4 | 0.763 | 3.336 |
| Ember Foundry | High | 7,189 | 10.086 / 11.128 | 118.433 | 3 | 1.118 | 3.256 |
| Ember Foundry | Low | 7,201 | 10.073 / 10.955 | 14.801 | 0 | 0.624 | 3.156 |

### Additional isolated repeats

The following completed one-minute repeats use the same runtime inventory, accepted fighter-art report, measurement harness, render cap and VSync setting. They are additional observations, not replacements for the original ten cases. Different results do not establish an outlier cause or an overall clean performance result.

#### repeat_rooftop_low120

3 intervals above 16.667 ms out of 7,200 samples. [Bound repeat receipt](../evidence/background_rebuild/performance/repeat_rooftop_low120/profile_provenance.json). Summary JSON reports, native/engine logs and companion captures remain in `evidence/background_rebuild/performance/repeat_rooftop_low120/`; the harness does not save the raw interval series.

| Arena | Tier | Samples | Frame P95 / P99 ms | Max ms | >16.667 ms | Render CPU P95 ms | GPU P95 ms |
|---|---|---:|---:|---:|---:|---:|---:|
| The Last Resort | Low | 7,200 | 10.332 / 11.863 | 20.816 | 3 | 0.671 | 2.929 |

#### repeat_ember_high120

2 intervals above 16.667 ms out of 7,190 samples. [Bound repeat receipt](../evidence/background_rebuild/performance/repeat_ember_high120/profile_provenance.json). Summary JSON reports, native/engine logs and companion captures remain in `evidence/background_rebuild/performance/repeat_ember_high120/`; the harness does not save the raw interval series.

| Arena | Tier | Samples | Frame P95 / P99 ms | Max ms | >16.667 ms | Render CPU P95 ms | GPU P95 ms |
|---|---|---:|---:|---:|---:|---:|---:|
| Ember Foundry | High | 7,190 | 9.885 / 10.799 | 111.873 | 2 | 0.914 | 3.675 |


### Preserved aborted uncapped stress run

The earlier uncapped matrix stopped during Lunar Reach High after Vulkan lost-device breadcrumbs and a native signal 11 crash; an unclean Windows restart was observed. Only the two Rooftop cases completed. The failed native log and process-failure receipt became entirely NUL bytes and cannot establish exit status. The intact engine log, partial reports and corrupt files are preserved in `evidence/background_rebuild/performance/aborted_uncapped_20261004/`, with `failure.json` recording these limitations. The root cause remains unknown. The capped matrix does not conceal, supersede or resolve that failure.

[Failure record and retained artifacts](../evidence/background_rebuild/performance/aborted_uncapped_20261004/failure.json). The failure record is not a completed performance provenance receipt; its two completed reports do not replace the full current ten-case matrix.

The living-background still and movie fixtures are visual evidence; movie capture and encoding overhead are not included in this matrix and are not performance results. Earlier platform, map and two-arena matrices below are historical workloads. The earlier Vulkan lost-device failure and reboot history remain retained; its cause was not established, and this background pass does not claim a driver fix.
<!-- LIVING_ARENAS_CURRENT_END -->

<!-- LIVING_ARENAS_HISTORY_BEGIN -->
## Historical records before the living-background upgrade

The retained notes below describe earlier build snapshots. Their screenshots, movies, runtime counts, metrics and package names are historical; current living-background acceptance is above. Any earlier heading or text calling a result current applies only to its recorded snapshot. The preceding platform runtime, docs, tools and Windows build are preserved under `evidence/background_rebuild/baseline/`. Earlier failure histories remain retained.
<!-- LIVING_ARENAS_HISTORY_END -->

<!-- PLATFORM_REFINEMENT_CURRENT_BEGIN -->
## Platform refinement — current four-player measurements

Ten isolated 60-second source-project cases cover all five arenas at 1920×1080 on High and Low, with four CPU fighters and authoritative 60 Hz combat. The ten cases recorded 1,650 intervals above 16.667 ms out of 564,786 render-interval samples. All outliers remain in the original matrix table; this is not a clean stable-60-FPS result across every case. Measurements apply to the Ryzen 7700X / RTX 4080 SUPER workstation; they do not certify weaker PCs, the exported build or the separate Mobile renderer.

CPU rendering work, GPU rendering work and frame intervals are separate measures; their percentiles must not be added. Screenshot readback occurs after measurement. The provenance receipt binds every report to unchanged current runtime, accepted fighter art and the measurement harness. Summary JSON reports, engine/native logs and companion captures are in `evidence/platform_refinement/performance/final/`; the harness does not save the raw interval series.

Combat ticks by case: The Last Resort High: 3,601, The Last Resort Low: 3,600, Lunar Reach High: 3,600, Lunar Reach Low: 3,600, Verdant Shrine High: 3,601, Verdant Shrine Low: 3,600, Abyssal Observatory High: 3,600, Abyssal Observatory Low: 3,600, Ember Foundry High: 3,600, Ember Foundry Low: 3,601.

### Original full matrix

[Bound ten-case receipt](../evidence/platform_refinement/performance/final/profile_provenance.json). These original results remain intact, including every recorded outlier.

| Arena | Tier | Samples | Frame P95 / P99 ms | Max ms | >16.667 ms | Render CPU P95 ms | GPU P95 ms |
|---|---|---:|---:|---:|---:|---:|---:|
| The Last Resort | High | 41,047 | 2.110 / 2.810 | 12.847 | 0 | 0.352 | 1.359 |
| The Last Resort | Low | 70,315 | 1.278 / 1.917 | 10.398 | 0 | 0.204 | 0.617 |
| Lunar Reach | High | 46,425 | 1.962 / 2.605 | 10.860 | 0 | 0.542 | 0.986 |
| Lunar Reach | Low | 78,002 | 1.085 / 1.759 | 10.065 | 0 | 0.363 | 0.383 |
| Verdant Shrine | High | 56,307 | 1.583 / 2.200 | 10.589 | 0 | 0.298 | 0.734 |
| Verdant Shrine | Low | 92,111 | 0.860 / 1.668 | 10.030 | 0 | 0.204 | 0.323 |
| Abyssal Observatory | High | 39,884 | 2.178 / 8.456 | 121.362 | 305 | 0.564 | 0.829 |
| Abyssal Observatory | Low | 84,772 | 1.247 / 1.906 | 5.071 | 0 | 0.273 | 0.344 |
| Ember Foundry | High | 51,248 | 1.762 / 2.463 | 7.375 | 0 | 0.425 | 1.003 |
| Ember Foundry | Low | 4,675 | 38.051 / 58.801 | 102.313 | 1345 | 1.009 | 9.442 |

### Additional isolated repeats

The following completed one-minute repeats use the same runtime inventory, accepted fighter-art report and measurement harness. They are additional observations, not replacements for the original ten cases. Different results do not establish an outlier cause or an overall clean performance result.

#### repeat_observatory

1 intervals above 16.667 ms out of 45,807 samples. [Bound repeat receipt](../evidence/platform_refinement/performance/repeat_observatory/profile_provenance.json). Summary JSON reports, native/engine logs and companion captures remain in `evidence/platform_refinement/performance/repeat_observatory/`; the harness does not save the raw interval series.

| Arena | Tier | Samples | Frame P95 / P99 ms | Max ms | >16.667 ms | Render CPU P95 ms | GPU P95 ms |
|---|---|---:|---:|---:|---:|---:|---:|
| Abyssal Observatory | High | 45,807 | 2.258 / 3.263 | 48.151 | 1 | 0.711 | 0.815 |

#### repeat_foundry

0 intervals above 16.667 ms out of 72,848 samples. [Bound repeat receipt](../evidence/platform_refinement/performance/repeat_foundry/profile_provenance.json). Summary JSON reports, native/engine logs and companion captures remain in `evidence/platform_refinement/performance/repeat_foundry/`; the harness does not save the raw interval series.

| Arena | Tier | Samples | Frame P95 / P99 ms | Max ms | >16.667 ms | Render CPU P95 ms | GPU P95 ms |
|---|---|---:|---:|---:|---:|---:|---:|
| Ember Foundry | Low | 72,848 | 1.848 / 2.863 | 6.922 | 0 | 0.337 | 0.364 |


Earlier map and two-arena matrices below are historical workloads. The earlier Vulkan lost-device failure and reboot history remain retained; its cause was not established, and this platform pass does not claim a driver fix.
<!-- PLATFORM_REFINEMENT_CURRENT_END -->

<!-- PLATFORM_REFINEMENT_HISTORY_BEGIN -->
## Historical records before the platform refinement

The retained notes below describe earlier build snapshots. Their screenshots, movies, runtime counts, metrics and package names are historical; current platform acceptance is above. The pre-platform runtime, docs, tools, Windows build and map evidence are preserved under `evidence/platform_refinement/baseline/`. Earlier failure histories remain retained.
<!-- PLATFORM_REFINEMENT_HISTORY_END -->

<!-- MAP_EXPANSION_HISTORICAL_BEGIN -->
## Historical five-arena expansion before platform refinement: recorded four-player measurements

Ten isolated 60-second cases cover all five arenas at 1920×1080 on High and Low, using four CPU fighters and the fixed 60 Hz combat loop. The ten cases contain 4 intervals above 16.667 ms out of 645,002 samples; the full table retains those outliers. These measurements apply to the Ryzen 7700X / RTX 4080 SUPER workstation; weaker-PC and current Mobile-renderer performance remain unverified.

The matrix contains 645,002 render-interval samples. Combat ticks by case: The Last Resort High: 3,600; The Last Resort Low: 3,600; Lunar Reach High: 3,601; Lunar Reach Low: 3,600; Verdant Shrine High: 3,600; Verdant Shrine Low: 3,600; Abyssal Observatory High: 3,600; Abyssal Observatory Low: 3,600; Ember Foundry High: 3,600; Ember Foundry Low: 3,600. Screenshot readback occurs after the measurement window; movie, export, Blender and other Godot work were stopped during profiling. Render CPU and GPU time are reported separately from frame pacing. Full reports, sample counts, callback statistics, draw counts and memory are in `evidence/map_expansion/performance/after_reboot_20261003/`; `profile_provenance.json` binds all ten cases to unchanged current source, fighter art and harness.

An earlier uncapped matrix aborted on Lunar High with Vulkan lost-device errors; NVIDIA then reported a lost GPU requiring a system reboot. That failed run is preserved in `evidence/map_expansion/performance/final_20261003/failure.json`. Its root cause was not established. The table below describes the subsequent complete run, not a demonstrated fix for that driver/device failure.

| Arena | Tier | Frame P95 / P99 ms | Max ms | >16.667 ms | Render CPU P95 ms | GPU P95 ms |
|---|---|---:|---:|---:|---:|---:|
| The Last Resort | High | 2.166 / 2.852 | 23.537 | 1 | 0.371 | 1.388 |
| The Last Resort | Low | 1.258 / 1.944 | 10.214 | 0 | 0.209 | 0.656 |
| Lunar Reach | High | 2.266 / 3.673 | 18.607 | 1 | 0.666 | 0.965 |
| Lunar Reach | Low | 1.257 / 1.930 | 12.694 | 0 | 0.408 | 0.370 |
| Verdant Shrine | High | 1.559 / 2.219 | 10.829 | 0 | 0.367 | 0.713 |
| Verdant Shrine | Low | 0.896 / 1.677 | 23.143 | 1 | 0.269 | 0.302 |
| Abyssal Observatory | High | 1.764 / 2.521 | 13.237 | 0 | 0.554 | 0.758 |
| Abyssal Observatory | Low | 1.001 / 1.893 | 9.076 | 0 | 0.280 | 0.305 |
| Ember Foundry | High | 2.723 / 3.724 | 18.203 | 1 | 0.557 | 1.013 |
| Ember Foundry | Low | 1.050 / 1.879 | 6.865 | 0 | 0.297 | 0.328 |

The table measures four-player matches. Earlier two-player figures below belong to the previous two-arena rebuild and are retained as history.
<!-- MAP_EXPANSION_HISTORICAL_END -->

## Prior two-arena rebuild: historical 1080p results

All eight isolated 60-second cases completed 3,600 combat ticks with clean exits at 1920×1080. Every four-player High/Low case stayed below the 16.667 ms frame budget in all measured samples, supporting the 60 FPS target on this workstation. Each two-player case had one isolated 31.140–41.056 ms interval; those outliers are retained below. Their cause is not established, and no zero-stutter or weaker-PC claim is made.

Final reports: `evidence/rebuild/performance/final_20261003/`. The matrix ran from 20:50:51 to 20:59:38 UTC with other game, Blender and FFmpeg work stopped. The provenance receipt passes for all eight cases and confirms unchanged source (467 runtime files), accepted art and harness throughout.

| Arena | Tier | Players | Samples | Frame P95 / P99 ms | Frame max ms | Frames >16.667 ms | Render CPU P95 ms | GPU P95 ms |
|---|---|---:|---:|---:|---:|---:|---:|---:|
| The Last Resort | High | 2 | 41,707 | 1.784 / 2.179 | 31.921 | 1 | 0.275 | 1.291 |
| The Last Resort | High | 4 | 41,957 | 1.892 / 2.436 | 10.736 | 0 | 0.305 | 1.279 |
| The Last Resort | Low | 2 | 71,061 | 0.997 / 1.325 | 31.140 | 1 | 0.163 | 0.650 |
| The Last Resort | Low | 4 | 70,754 | 1.100 / 1.654 | 9.774 | 0 | 0.192 | 0.649 |
| Lunar Reach | High | 2 | 52,016 | 1.430 / 1.796 | 41.056 | 1 | 0.408 | 0.901 |
| Lunar Reach | High | 4 | 48,761 | 1.632 / 2.153 | 9.843 | 0 | 0.513 | 0.972 |
| Lunar Reach | Low | 2 | 92,868 | 0.797 / 1.046 | 40.429 | 1 | 0.303 | 0.342 |
| Lunar Reach | Low | 4 | 79,334 | 1.019 / 1.546 | 9.471 | 0 | 0.380 | 0.372 |

All requested fighters remained alive for every sample, and no case completed a round or rematched during sampling. There are 498,458 frame samples in total, including 240,806 four-player samples. The four two-player outliers were not screenshot or movie costs: readback happens after the sample window. Callback monitors also retain their raw maxima, but no synchronized spike trace was recorded, so those values cannot identify the cause.

Low reduced measured scene/effect/texture costs as well as GPU time. Four-player resource peaks and callback P95 values are:

| Arena / tier | Peak draws | Peak primitives | Peak reported VRAM MiB | Physics callback P95 ms | Process callback P95 ms |
|---|---:|---:|---:|---:|---:|
| The Last Resort / High | 281 | 473,080 | 756.4 | 3.861 | 1.786 |
| The Last Resort / Low | 233 | 419,963 | 535.4 | 3.718 | 1.469 |
| Lunar Reach / High | 1,144 | 2,837,721 | 513.7 | 3.917 | 1.962 |
| Lunar Reach / Low | 875 | 335,799 | 322.5 | 3.771 | 1.649 |

These measurements cover this hardware and these match configurations. They do not establish every fighter pairing, cold shader caches, Mobile-renderer performance or weaker PCs.

### Hardware and measurement method

Hardware: AMD Ryzen 7 7700X (8 cores/16 threads), 15.2 GiB system RAM, NVIDIA GeForce RTX 4080 SUPER, Windows 11 Home 10.0.26200. `evidence/rebuild/performance_hardware.json` records the workstation inventory; each graphical result also records its actual GPU and renderer. The game uses Godot 4.7.2 Vulkan Forward+ for this matrix. Mobile remains a separate Windows renderer option, without a current performance certification.

`tools/validation/profile_rebuild.ps1` runs eight cases: The Last Resort and Lunar Reach, each at High and Low with two and four Normal CPUs. Two-player cases use Clutch/Heavy Duty; four-player cases add Urban Sentinel/Midnight Gentleman. Each run uses the actual main scene, Party platforms/hazards and normal effects/audio at 1920×1080. Combat advances at 60 Hz while V-sync and the render cap are disabled to measure headroom. Three seconds of warmup precede a 60-second sample window. Finished rounds automatically rematch so the sample cannot silently become a results-screen benchmark, although none finished during this matrix.

Frame pacing is measured as monotonic intervals between process-frame callbacks. Viewport CPU and GPU rendering use Godot's measured-render-time API. Process and physics monitors are also recorded. These are separate, partly overlapping measurements and must not be summed. The report includes sample counts, mean/P95/P99/max, samples exceeding 16.667 ms, active-fighter sample distribution, combat ticks, completed matches and peak draw/primitive/VRAM figures. A four-player setup can temporarily have fewer surviving fighters before rematch; its distribution remains visible in the raw report.

No screenshots, movie recording or encoding run inside the measurement window. The single resolution-evidence capture is taken after sampling. Profiling runs separately from Blender and other game processes. The runner rejects unsuccessful exits, logged problems, stale output, wrong case/resolution, missing GPU timing or insufficient combat advancement. `profile_provenance.json` binds every case report to hashes of the runtime inventory, accepted art report and measurement harness, verifying that none changed during the matrix. The package tool checks these bindings against the exported build before delivery.

```powershell
& ./tools/validation/profile_rebuild.ps1 -Seconds 60
```

The same harness can target the preserved baseline with `-Project` and a distinct `-Output`. Results obtained with this method should be compared with that baseline, not directly with the older callback-only profiles below. Hardware, drivers, cold shader caches, other fighter combinations and weaker PCs limit extrapolation even if the measured machine meets the target.

### Preserved baseline measured with the current method

Both High/four-player baseline runs completed 60 seconds and 3,600 combat ticks at 1920×1080 with clean exits. Reports: `evidence/rebuild/baseline/performance_current_method/`. They used the same workstation, profiler, slot configuration and stage preset as the rebuild matrix. Gameplay changes mean CPU decisions and match trajectories are not identical workloads.

| Arena | Samples | Frame P95 / P99 ms | Frame max ms | Frames >16.667 ms | Render CPU P95 ms | GPU P95 ms | Peak draws | Peak primitives |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| The Last Resort | 39,667 | 2.056 / 2.504 | 14.516 | 0 | 0.308 | 1.455 | 255 | 458,417 |
| Lunar Reach | 34,331 | 2.275 / 2.570 | 5.267 | 0 | 0.623 | 1.727 | 1,113 | 2,275,592 |

Four fighters were alive for 90.1% of rooftop samples and 90.5% of lunar samples; the remaining samples had three surviving fighters. These are baseline measurements, not results for the rebuilt assets.

Against that baseline, High/four-player frame P99 changes from 2.504 to 2.436 ms on The Last Resort and from 2.570 to 2.153 ms on Lunar Reach. GPU P95 changes from 1.455 to 1.279 ms and 1.727 to 0.972 ms respectively. The rebuilt cases retain four surviving fighters throughout, while the baseline cases include some three-survivor samples. This comparison describes the observed runs and does not isolate any one art, rendering or gameplay change.

## Historical September 28 profile

These measurements predate
scene revision 3's additional hotel/pavilion geometry, finer maps and lighting.
That September graphics pass used brief frozen previews at the user's request;
four-fighter and Mobile performance were not reprofiled. Do not attribute the
numbers below to the October rebuild or the September revision 3 package.

Measured 2026-09-28. Hardware: AMD Ryzen 7 7700X 8-Core Processor, 15.2 GiB system RAM, NVIDIA GeForce RTX 4080 SUPER; Microsoft Windows 11 Home 10.0.26200. Godot 4.7.2, Vulkan 1.4.341. Hardware evidence: `evidence/preflight/performance_hardware.json`.

Each run advances 3,600 authoritative ticks at 60 Hz with four seeded Normal CPUs (Clutch, Sunstruck, Heavy Duty, Deadfall), Party lift/pyro, damage effects, blood, High graphics and normal game audio. V-sync and the render cap are disabled to measure headroom. Other game/Blender processes are stopped. Frame samples cover the run after a two-second wall-clock warmup; they are unsmoothed monotonic microsecond intervals between process callbacks, not engine-adjusted simulation deltas or GPU-only timestamps. Fine Print's separate ability/rendered cases are in the full-five visual review.

Both the window and captured image measure **1920×1080**; the logical UI viewport is 1600×900. Godot's texture-size query reports 2304×1296 while the actual retrieved image is 1920×1080. Both raw values are retained. This API discrepancy is not silently treated as proof of an internal GPU allocation size.

| Renderer | Samples | Mean ms | P95 ms | P99 ms | Raw max ms | >16.667 ms: all / excluding capture | Peak draws | Peak primitives | Peak reported VRAM MiB |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Forward+ | 48,496 | 1.223 | 1.663 | 2.012 | 13.729 | 0 / 0 | 233 | 398,076 | 839.2 |
| Mobile | 93,591 | 0.634 | 0.929 | 1.447 | 13.621 | 0 / 0 | 153 | 397,782 | 586.5 |

- Forward+: 61.308s wall time, 48,688 total rendered frames, 99 resolved contacts and 6 KOs. 0 over-budget sample(s) were unrelated to screenshot capture. See `evidence/performance_forward.json`.
- Mobile: 61.325s wall time, 94,216 total rendered frames, 88 resolved contacts and 5 KOs. 0 over-budget sample(s) were unrelated to screenshot capture. See `evidence/performance_mobile.json`.

Readback is validation overhead, not a player feature. The summary includes every measured frame; capture-tagged spikes are disclosed rather than silently dropped. Sample sums agree with their monotonic sampling-window durations to within 0.1 ms. No sampled frame exceeded the 16.667 ms target in either run. These runs do not establish performance on weaker PCs, iOS devices, every possible match, or cold driver-cache conditions. The Mobile run is a Windows renderer compatibility/performance check, not phone validation.

Earlier runs with a mid-match screenshot are retained as `performance_*_midcapture.json`; superseded engine-delta measurements are `performance_*_engine_delta.json`. An early Mobile attempt exited without a complete report and was rejected by the runner. The wall-time reports above describe the graphics build before scene revision 3.

Reproduce with `tools/validation/profile_windows.ps1` (optional `-Profiles forward` or `-Profiles mobile`), then run this Python script. The runner rejects logged errors/warnings, stale output, wrong renderer/resolution and too few samples. It requests an early screenshot; the report tags its cost if loading delays place it outside warmup. `Launch-Mobile.cmd` selects Mobile in a new game process. No renderer switch is promised inside a running match.
