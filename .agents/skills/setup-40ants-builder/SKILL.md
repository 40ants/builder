---
name: setup-40ants-builder
description: Use when converting a Common Lisp project to build its standalone binary with the 40ants-builder library, when asked to "build with 40ants-builder", "replace build.lisp", "set up lake build", or when creating a new project that should produce a Deploy binary.
---

# Setting Up 40ants-builder for a Project

## Overview

40ants-builder dumps a standalone binary of an ASDF system. One call —
`(40ants-builder:build :<system>)` — registers the project's local
systems, applies implementation quirks (CCL, ECL), loads Deploy, the
system and Slynk contribs, pins the git commit and the changelog
version into the image, and dumps the binary via Deploy into `bin/`.

Two invocation modes:

- **Direct**: a Roswell command run inside the project's Qlot
  environment.
- **`lake build`**: via a 40ants-lake `app` definition with the
  `:builder t` slot. This mode adds release staging and `lake to-prod`
  installs.

## Conversion Steps

1. **Ensure a program system exists.** The build target is an ASDF
   system that represents the binary:

   ```lisp
   #-asdf3.1 (error "<name> requires ASDF 3.1")
   (defsystem "<name>"
     :defsystem-depends-on (:deploy)
     :build-operation "deploy-op"
     :build-pathname "<name>"
     :entry-point "<package>::<entry-function>"
     :depends-on ("the-library-system"))
   ```

   If the project only has a library system, create a thin program
   system wrapping it. On CCL, `uiop:argv` is empty, so the entry
   point should receive `argv` explicitly if the app parses flags.

2. **Add `local-deps.lisp` (optional).** Place it in the project root
   only when some dependencies are local checkouts which must be
   visible to ASDF:

   ```lisp
   (in-package :cl-user)

   (defun extend-registry ()
     (loop for dep-dir in (directory
                           (merge-pathnames uiop:*wild-directory*
                                             #p"libs/"))
           do (pushnew dep-dir
                       asdf:*central-registry*
                       :test #'uiop:pathname-equal)))
   ```

   The builder loads this file and calls `extend-registry`. If all
   dependencies are on Quicklisp, skip the file — the build proceeds
   without it.

3. **Choose the invocation mode.**

   Direct command (works in any project with Qlot):

   ```bash
   qlot exec ros -L sbcl-bin/<pinned-version> run -- --non-interactive \
     --eval '(ql:quickload :40ants-builder)' \
     --eval '(40ants-builder:build :<system>)'
   ```

   For CCL builds omit `--non-interactive`: the flag is SBCL specific
   and CCL rejects it. The builder quits the process explicitly both on
   success and failure, so nothing hangs.

   Via 40ants-lake (recommended for services): add an app to the
   `Lakefile`:

   ```lisp
   (defapps
       (app "<name>"
            :builder t
            :lisp "sbcl-bin/<pinned-version>"
            :release-paths '(("bin" . "bin/"))))
   ```

   Then `lake build` builds the binary and `lake to-prod` installs it.

4. **Make 40ants-builder resolvable.** The library must be loadable in
   the project's Qlot environment:

   - preferred: install from Ultralisp once published;
   - a local checkout works when its `.asd` files are symlinked into
     `~/.roswell/lisp/quicklisp/local-projects/<dir>/`. Symlink the
     `.asd` files, not the whole checkout directory: quicklisp scans
     local projects recursively and a full-directory symlink drags the
     checkout's `.qlot` dependencies into the Roswell environment.

5. **Build and verify.**

   ```bash
   lake build        # or the direct command
   file bin/<name>
   bin/<name> --version   # prints version+commit, implementation, commit hash
   bin/<name> --help      # must exit 0
   ```

   The artifact is `bin/<name>` plus `bin/*.so` — native libraries load
   relative to the executable, so `bin/` travels as a whole directory
   in the release. Delete a stale `bin/<name>` before rebuilding if
   ASDF skips `deploy-op` because the output is newer than the inputs.

6. **Retire the old build script.** Rename `build.lisp` to
   `build-old.lisp` (keep for comparison) or delete it, then update
   every mention of the old command in `run-tests.sh`, CI workflows,
   docs and agent skills. Check the old script for project specific
   steps the builder does not cover: extra Quicklisp systems to load
   belong in the project's system dependencies or `local-deps.lisp`
   side effects, while `slynk-modules` and image preparation are
   already handled.

7. **Update documentation and changelog.** Describe the new build
   command in the project docs, and record the switch in the
   changelog.

## Common Mistakes

| Mistake | Correct action |
|---|---|
| Building on macOS and shipping the binary to Linux | Build on the target OS/architecture; binaries are not portable |
| Committing `bin/` into git | `bin/` is a build artifact; keep it ignored, ship it in the release only |
| Putting `local-deps.lisp` into `roswell/` | The builder looks for it in the project root only |
| Writing `extend-registry` without `(in-package :cl-user)` | The file is loaded in whatever package is current; pin the package explicitly |
| Expecting a meaningful version with no changelog | Keep versions in `docs/changelog.lisp` as a `defchangelog` form; the builder reads its first entry |
| Editing the old build.lisp instead of the Lakefile | Build behavior now lives in the system's ASDF file and the `local-deps.lisp`; the script is retired |

## Related

- Library docs: `40ants-builder` system documentation,
  https://40ants.com/builder/
- The builder complements Deploy: Deploy bundles foreign libraries and
  dumps the image; the builder prepares the image and orchestrates the
  build. See the Features section of the library docs.
