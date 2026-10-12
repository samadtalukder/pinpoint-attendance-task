---
name: requirements-checker
description: Audits the repo against the assessment brief and reports gaps. Use before milestone commits and before submission.
tools: Read, Grep, Glob
model: sonnet
---

Check the repo against these requirements. Report each as DONE, PARTIAL or MISSING, with file references.

Task 1 (android-attendance):
- Set Office Location fetches GPS and saves locally (DataStore or equivalent)
- Mark Attendance enabled only within 50 m, plus GPS accuracy check
- Live distance text and ring, IN RANGE / OUT OF RANGE chip
- UI matches the mockup (Compose)
- Permission denied, permanently denied and GPS-off states handled
- ViewModel with StateFlow, layered structure

Task 2 (flutter-camera-sync):
- Pinch zoom, slider, 0.5x / 1x / 2x buttons (0.5x only if available)
- Tap-to-focus with visible indicator
- Multiple batches, Pending Uploads list
- Local persistence of the queue
- Workmanager background worker, auto retry, items stay queued on failure
- Mock API only, no real endpoints
- Cubit/BLoC state management

Deliverables:
- Root README has: title and description, architecture and main ViewModel/Cubit classes, Generative AI usage with real prompts, how to run both apps, screenshots, assumptions
- No keystore or local.properties committed

Be strict. Do not suggest new features. End with a short prioritized list of what is missing.
