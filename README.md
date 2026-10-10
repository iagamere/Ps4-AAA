# ps4-builder repo

Private repository used by the PS4 Builder Android app.

- `.github/workflows/toolchain.yml` — manual, run once: builds the **OpenOrbis** toolchain image (`ps4-toolchain`) and pushes it to ghcr.io.
- `.github/workflows/toolchain-payload.yml` — manual, run once: builds the **ps4-payload-dev/sdk** image (`ps4-payload-toolchain`) and pushes it to ghcr.io.
- `.github/workflows/build.yml` — runs when `incoming/*.zip` is pushed: unzips, picks the image from `toolchain.txt`, configures + builds inside it, publishes release `build-<run number>` (ELF + build.log, or build.log + errors.txt on failure; always status.json).
- `docker/Dockerfile` — OpenOrbis recipe. Steps marked UNVERIFIED (libssh2, libnfs) had no documented PS4 recipe.
- `docker/Dockerfile.payload` + `docker/payload-deps.sh` — ps4-payload-dev/sdk recipe (SDK zip + zlib, openlibm, openssl, json-c, libpsl, curl, libssh2, libsmb2, libnfs).
- `scripts/` — the steps called by build.yml (each step name starts with `[n/7]`; the app shows these names as the stage).

## Choosing the toolchain per project

Put a file named `toolchain.txt` in the project root (next to `CMakeLists.txt`) inside the zip:

| content | image | configure |
|---|---|---|
| `openorbis` (default when the file is missing or empty) | `ps4-toolchain` | `openorbis-cmake ..` |
| `payload-sdk` | `ps4-payload-toolchain` | `orbis-cmake ..` (`$CMAKE` from `orbis.sh`) |

Any other value fails the build with an error message. If the matching image was never built the pull step tells you which workflow to run.
