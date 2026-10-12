---
name: submission-check
description: Final pre-submission checklist for the FieldPulse assessment. Use when preparing to submit the repo and APKs.
---

Run through this list and report pass or fail for each item. Fix nothing silently; list what needs the user's action.

1. Both apps build in release mode:
   - `cd android-attendance && ./gradlew assembleRelease`
   - `cd flutter-camera-sync && flutter build apk --release`
2. APKs are signed and installable (not "unsigned"). One universal Flutter APK, not split per ABI.
3. APK file names: `FieldPulse-Attendance-release.apk` and `FieldPulse-CameraSync-release.apk`.
4. Root README contains every required section: title and description, architecture and main ViewModel/Cubit classes, Generative AI usage with real prompts, how to run both apps, screenshots, assumptions.
5. `PROMPTS.md` exists and contains the essential prompts. `PROMPTS.raw.md` is NOT committed.
6. Screenshots or GIFs exist in each task folder's `screenshots/` and are referenced by the README.
7. No `*.jks`, `key.properties`, `local.properties` or secrets in git history: `git log --all --stat` and `git ls-files`.
8. Mock API is clearly labeled in code and README.
9. `git status` is clean and the repo is public.
10. Reminder for the user: upload both APKs to one Drive folder, set sharing to "anyone with the link", test in a private window, reply in the original email thread with repo link and APK link.
