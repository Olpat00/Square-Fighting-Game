# Living-background upgrade delivered

The requested five-map background pass is complete and independently audited. Current runtime: 537 files, SHA-256 `F27D1FA730C48897031F76F245F4B28D50B6DFA35BC3D4C7E249666CDF1E8825`.

The Windows release is [RooftopRiot-Living-Arenas-Windows.zip](../../builds/RooftopRiot-Living-Arenas-Windows.zip), with matching editable sources under `Game File/stages/`. [Delivery](delivery.json), [final audit](final_audit.json) and [requirement audit](completion_requirements.json) bind the exact current artifacts. Five ambient previews are under `motion/<arena>/ambient.mp4`.

Current visual, motion, pause/reset, preservation, source, Windows and full-match checks pass. The ten-case performance matrix uses an explicit 120 FPS cap. Frame-pacing stalls and the earlier uncapped GPU device-loss failure remain unresolved and documented in [performance notes](../../docs/PERFORMANCE.md); no driver fix or clean stable-60-FPS claim is made. Human/controller testing and weaker-PC performance remain unverified.

Earlier interrupted checkpoint instructions are preserved separately in [RESUME_before_delivery.md](RESUME_before_delivery.md) and [progress_before_delivery.json](progress_before_delivery.json). They are historical and must not replace the completed current receipts.
