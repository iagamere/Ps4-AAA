# ps4-builder repo

Private repository used by the PS4 Builder Android app.

- `.github/workflows/toolchain.yml` — manual, run once: builds the PS4 toolchain Docker image and pushes it to ghcr.io.
- `.github/workflows/build.yml` — runs when `incoming/*.zip` is pushed: unzips, builds with `openorbis-cmake` + `make` inside that image, publishes release `build-<run number>` (ELF + build.log, or build.log + errors.txt on failure; always status.json).
- `docker/Dockerfile` — toolchain recipe. Steps marked UNVERIFIED (libssh2, libnfs) had no documented PS4 recipe.
- `scripts/` — the steps called by build.yml (each step name starts with `[n/7]`; the app shows these names as the stage).
