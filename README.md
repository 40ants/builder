<a id="x-2840ANTS-BUILDER-DOCS-2FINDEX-3A-40README-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

# 40ants-builder - A reusable builder of standalone binaries for Common Lisp projects

<a id="40-ants-builder-asdf-system-details"></a>

## 40ANTS-BUILDER ASDF System Details

* Description: A reusable builder of standalone binaries for Common Lisp projects.
* Licence: Unlicense
* Author: Alexander Artemenko <svetlyak.40wt@gmail.com>
* Homepage: [https://40ants.com/builder/][64f1]
* Bug tracker: [https://github.com/40ants/builder/issues][2fec]
* Source control: [GIT][af68]
* Depends on: [asdf][c15d]

[![](https://img.shields.io/badge/WARN-LLM%20GENERATED-FF6347)][f8eb]

[![](https://github-actions.40ants.com/40ants/builder/matrix.svg?only=ci.run-tests)][c4f9]

![](http://quickdocs.org/badge/40ants-builder.svg)

<a id="x-2840ANTS-BUILDER-DOCS-2FINDEX-3A-3A-40FEATURES-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

## Features

Dumping a standalone binary of a Common Lisp application requires more
than calling `asdf:make` or `ros build`. A production build needs a
prepared environment: local checkouts registered in `ASDF`,
implementation specific quirks patched, Slynk contrib modules loaded
before the dump (a Slynk client cannot load them at run time on the
production host, where neither Quicklisp nor the sources are
reachable), and the build identification captured while the sources
and `.git` are still around. This recipe usually lives in a
per-project `build.lisp` script, copied between projects, untested and
undocumented. `40ants-builder` extracts it into one reusable, tested
function: `(40ants-builder:build :my-app)`.

The library does not replace Deploy: it complements it. Your system
still declares `deploy-op` as its `:build-operation`, and Deploy
bundles foreign libraries and dumps the image. 40ants-builder takes
care of everything around that dump and finishes by calling
`asdf:make`, which performs `deploy-op`.

* **One call builds the binary.** `(40ants-builder:build :my-app)`
  runs the whole pipeline: registry setup, workarounds, dependency
  loading, version pinning, image preparation and the dump.
* **Local systems registered.** A `local-deps.lisp` file in the
  project root, when present, is loaded to push local checkout
  directories onto the `ASDF` registry.
* **Implementation quirks patched.** On `CCL` the builder fixes `CFFI`'s
  foreign library loader, which chokes on logical pathnames with a
  `:newest` version suffix, and teaches conduit-packages to elide
  duplicate defpackage imports, which Lisp-Stat requires; on `ECL` it
  creates an empty `NIL` package so the dependencies' defpackage forms
  stay readable.
* **Build identification pinned.** The git commit and the version from
  the system's `docs/changelog.lisp` are stored into the image, so
  `--version` reports what the binary was built from, even on a host
  without sources.
* **Production ready image.** Slynk contrib modules are loaded before
  the dump, the `:deploy-console` feature silences Deploy's status
  output at service startup, and the build debugger hook is removed,
  so it does not ship inside the binary.
* **Multiple implementations.** `SBCL` and `CCL` build via `asdf:make`
  (usually `deploy-op`), `ECL` builds via `asdf:program-op`, which does
  not rely on the unsupported `uiop:dump-image`.
* **Fail fast behavior.** Any build error prints the condition with a
  backtrace and exits with a non-zero code instead of hanging in the
  interactive debugger; pass `exit nil` to embed the pipeline into
  another tool and handle errors yourself.

<a id="x-2840ANTS-BUILDER-DOCS-2FINDEX-3A-3A-40INSTALLATION-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

## Installation

You can install this library from Quicklisp, but you want to receive updates quickly, then install it from Ultralisp.org:

```
(ql-dist:install-dist "http://dist.ultralisp.org/"
                      :prompt nil)
(ql:quickload :40ants-builder)
```
<a id="x-2840ANTS-BUILDER-DOCS-2FINDEX-3A-3A-40USAGE-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

## Usage

Call the build function with the name of the `ASDF` system which
describes your program. For a project which defines a `pingvito`
system with a `deploy-op` build operation, run from the project's
root:

```sh
qlot exec ros run --eval '(ql:quickload :40ants-builder)' --eval '(40ants-builder:build :pingvito)'
```
The pipeline, essentially a common `build.lisp` script extracted into
a reusable library:

1. installs a debugger hook which fails the process with exit code 1
   instead of hanging in the interactive debugger;
2. extends the `ASDF` registry from the `local-deps.lisp` file in the
   system's source directory, when it is present;
3. installs implementation workarounds: patches `CFFI`'s foreign
   library loader and conduit-packages's `DEFPACKAGE` clause
   computation on `CCL`, and creates an empty `NIL` package on `ECL`;
4. quickloads Deploy, the system being built and Slynk contrib
   modules, which otherwise would be missing in production when a
   Slynk client connects;
5. pins the build identification: the git commit goes into
   `40ants-builder:*git-commit*` and the system's `ASDF` version
   becomes `VERSION+GIT.COMMIT`;
6. prepares the image for the dump: renames the Clack handler package
   to its slash nickname, pushes the `:deploy-console` feature and
   removes the build debugger hook, so it does not get dumped into
   the image;
7. dumps the binary: asdf:make on `SBCL` and `CCL`, and
   asdf:program-op on `ECL`, which does not support
   uiop:dump-image.

On success the process exits with code 0; on failure the condition is
printed with a backtrace and the process exits with code 1.

Pass `slynk-modules nil` to skip the Slynk contribs and `exit nil` to
keep the process alive, returning the pinned commit instead of
quitting:

```lisp
(40ants-builder:build :pingvito :slynk-modules nil)
```
Note that a binary built on one operating system or architecture cannot run on
another one. Build on the target host or in an equivalent
environment, and keep the `bin/` directory with native libraries next
to the binary in the release.

<a id="x-2840ANTS-BUILDER-DOCS-2FINDEX-3A-3A-40FOR-AI-AGENTS-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

## For AI Agents

This library is written with `AI` coding agents, and it ships an agent
skill so that agents can adopt it correctly. The skill teaches how to
convert a project to build through 40ants-builder: the program system
layout, the optional `local-deps.lisp` registry file, the direct
command and the 40ants-lake `builder` slot integration, build
verification, and the retirement of an old `build.lisp` script.

Point your coding agent to the
[`SKILL.md`][0964]
file of this repository, or copy it into your project's
`.agents/skills/setup-40ants-builder/` directory. The
[AI badge][f8eb] in the `README` marks the
code as `LLM` generated.

<a id="x-2840ANTS-BUILDER-DOCS-2FINDEX-3A-3A-40API-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

## API

<a id="x-2840ANTS-BUILDER-DOCS-2FINDEX-3A-3A-4040ANTS-BUILDER-2FCCL-3FPACKAGE-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

### 40ANTS-BUILDER/CCL

<a id="x-28-23A-28-2818-29-20BASE-CHAR-20-2E-20-2240ANTS-BUILDER-2FCCL-22-29-20PACKAGE-29"></a>

#### [package](f064) `40ants-builder/ccl`

<a id="x-2840ANTS-BUILDER-DOCS-2FINDEX-3A-3A-7C-4040ANTS-BUILDER-2FCCL-3FFunctions-SECTION-7C-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

#### Functions

<a id="x-2840ANTS-BUILDER-2FCCL-3ADEDUPLICATE-NAMES-20FUNCTION-29"></a>

##### [function](70b3) `40ants-builder/ccl:deduplicate-names` names seen

Return only those names which are not in the `SEEN` hash-table yet,
registering every returned name.

<a id="x-2840ANTS-BUILDER-2FCCL-3AELIDE-ALREADY-IMPORTED-CLAUSES-20FUNCTION-29"></a>

##### [function](8e24) `40ants-builder/ccl:elide-already-imported-clauses` &key extends extends/including extends/excluding

Return `DEFPACKAGE` clauses for a conduit package, skipping symbol
names already imported by a previous extension.

This is a copy of the compute-conduit-clauses function of the
org.tfeb.conduit-packages library which elides such names: importing
the same external symbol via two :import-from clauses is tolerated by
`SBCL`, but is a hard error on `CCL` ("Name ... is already used in a
conflicting option"). The Lisp-Stat project defines its packages
with the :extends option of the conduit-packages `DEFPACKAGE` macro,
and several of its extended packages export the same symbols.

<a id="x-2840ANTS-BUILDER-2FCCL-3AINSTALL-CCL-PATCHES-20FUNCTION-29"></a>

##### [function](12fe) `40ants-builder/ccl:install-ccl-patches`

Patch `CFFI` and conduit-packages to make Lisp-Stat and its
dependencies compile and load on `CCL`.

Call before the target system is quickloaded, because the patches are
used during compilation of its dependencies. On other implementations
this is a no-op.

<a id="x-2840ANTS-BUILDER-DOCS-2FINDEX-3A-3A-4040ANTS-BUILDER-2FCORE-3FPACKAGE-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

### 40ANTS-BUILDER/CORE

<a id="x-28-23A-28-2819-29-20BASE-CHAR-20-2E-20-2240ANTS-BUILDER-2FCORE-22-29-20PACKAGE-29"></a>

#### [package](038f) `40ants-builder/core`

<a id="x-2840ANTS-BUILDER-DOCS-2FINDEX-3A-3A-7C-4040ANTS-BUILDER-2FCORE-3FClasses-SECTION-7C-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

#### Classes

<a id="x-2840ANTS-BUILDER-DOCS-2FINDEX-3A-3A-4040ANTS-BUILDER-2FCORE-24BUILD-ERROR-3FCLASS-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

##### BUILD-ERROR

<a id="x-2840ANTS-BUILDER-2FCORE-3ABUILD-ERROR-20CONDITION-29"></a>

###### [condition](fbaf) `40ants-builder/core:build-error` (error)

**Readers**

<a id="x-2840ANTS-BUILDER-2FCORE-3ABUILD-ERROR-CONDITION-20-2840ANTS-DOC-2FLOCATIVES-3AREADER-2040ANTS-BUILDER-2FCORE-3ABUILD-ERROR-29-29"></a>

###### [reader](fbaf) `40ants-builder/core:build-error-condition` (build-error) (:condition)

<a id="x-2840ANTS-BUILDER-DOCS-2FINDEX-3A-3A-7C-4040ANTS-BUILDER-2FCORE-3FFunctions-SECTION-7C-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

#### Functions

<a id="x-2840ANTS-BUILDER-2FCORE-3ABUILD-20FUNCTION-29"></a>

##### [function](a20e) `40ants-builder/core:build` system &key (slynk-modules \*default-slynk-modules\*) (exit t)

Build a standalone binary of `SYSTEM` and return the pinned git commit.

`SYSTEM` is an `ASDF` system designator of the program system, like
:pingvito. The pipeline is essentially a build.lisp script extracted
into a reusable library:

1. installs a debugger hook which fails the process with exit code 1
   instead of hanging in the interactive debugger;
2. extends the `ASDF` registry from the local-deps.lisp file in
   `SYSTEM`'s source directory, when it is present;
3. installs implementation workarounds (the `CFFI` and conduit-packages
   patches on `CCL`, the empty "`NIL`" package on `ECL`);
4. quickloads Deploy, `SYSTEM` and `SLYNK-MODULES` (defaults to
   *default-slynk-modules*; pass `NIL` to skip them);
5. pins the build identification: the git commit goes into
   *git-commit* and the commit is appended to the `ASDF` version of
   `SYSTEM`;
6. prepares the image for the dump: renames the Clack handler package
   to its slash nickname, pushes the :deploy-console feature and
   removes the build debugger hook;
7. dumps the binary: asdf:make on `SBCL` and `CCL`, asdf:program-op on
   `ECL`.

On success the process exits with code 0. On failure the condition is
printed with a backtrace and the process exits with code 1. When `EXIT`
is `NIL`, build does not quit: it returns the commit on success and
signals build-error, wrapping the original condition, on failure.

<a id="x-2840ANTS-BUILDER-2FVERSION-3APIN-BUILD-VERSION-20FUNCTION-29"></a>

##### [function](fabd) `40ants-builder/version:pin-build-version` system

Capture build-time identification of `SYSTEM` into the image.

Stores the git commit into *git-commit* and appends the commit to the
system's version, updating its component-version. The version is
taken from the system's component-version or, when it is unset, from
the topmost entry of its docs/changelog.lisp.

Called before the image dump, so that the binary's version flag
reports the state of the sources it was built from, and not of
whatever is on disk at run time. Returns the commit.

<a id="x-2840ANTS-BUILDER-DOCS-2FINDEX-3A-3A-7C-4040ANTS-BUILDER-2FCORE-3FVariables-SECTION-7C-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

#### Variables

<a id="x-2840ANTS-BUILDER-2FDEPENDENCIES-3A-2ADEFAULT-SLYNK-MODULES-2A-20-28VARIABLE-29-29"></a>

##### [variable](7a51) `40ants-builder/dependencies:*default-slynk-modules*` (:slynk/indentation :slynk/stickers :slynk/trace-dialog :slynk/package-fu
 :slynk/fancy-inspector :slynk/arglists)

Slynk contrib modules loaded into the image before the dump.

The Slynk server tries to load these modules when a client connects
and cannot do that in production, where neither Quicklisp nor the
sources are reachable. Pass `NIL` as `SLYNK-MODULES` argument of the
build function to skip them.

<a id="x-2840ANTS-BUILDER-2FVERSION-3A-2AGIT-COMMIT-2A-20-28VARIABLE-29-29"></a>

##### [variable](feed) `40ants-builder/version:*git-commit*` "unknown"

Git commit captured by pin-build-version before the image dump.

The binary usually runs on a host without .git and sources
(ProtectHome=read-only), so the commit has to be captured at build
time. Projects use this variable in their version flag output.

<a id="x-2840ANTS-BUILDER-DOCS-2FINDEX-3A-3A-4040ANTS-BUILDER-2FDEPENDENCIES-3FPACKAGE-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

### 40ANTS-BUILDER/DEPENDENCIES

<a id="x-28-23A-28-2827-29-20BASE-CHAR-20-2E-20-2240ANTS-BUILDER-2FDEPENDENCIES-22-29-20PACKAGE-29"></a>

#### [package](c7cd) `40ants-builder/dependencies`

<a id="x-2840ANTS-BUILDER-DOCS-2FINDEX-3A-3A-7C-4040ANTS-BUILDER-2FDEPENDENCIES-3FFunctions-SECTION-7C-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

#### Functions

<a id="x-2840ANTS-BUILDER-2FDEPENDENCIES-3ALOAD-BUILD-DEPENDENCIES-20FUNCTION-29"></a>

##### [function](9cac) `40ants-builder/dependencies:load-build-dependencies` system &key (slynk-modules \*default-slynk-modules\*)

Load everything which has to be present in the dumped image.

This is the Deploy library, the `SYSTEM` being built and the `SLYNK-MODULES`.

<a id="x-2840ANTS-BUILDER-DOCS-2FINDEX-3A-3A-7C-4040ANTS-BUILDER-2FDEPENDENCIES-3FVariables-SECTION-7C-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

#### Variables

<a id="x-2840ANTS-BUILDER-2FDEPENDENCIES-3A-2ADEFAULT-SLYNK-MODULES-2A-20-28VARIABLE-29-29"></a>

##### [variable](7a51) `40ants-builder/dependencies:*default-slynk-modules*` (:slynk/indentation :slynk/stickers :slynk/trace-dialog :slynk/package-fu
 :slynk/fancy-inspector :slynk/arglists)

Slynk contrib modules loaded into the image before the dump.

The Slynk server tries to load these modules when a client connects
and cannot do that in production, where neither Quicklisp nor the
sources are reachable. Pass `NIL` as `SLYNK-MODULES` argument of the
build function to skip them.

<a id="x-2840ANTS-BUILDER-DOCS-2FINDEX-3A-3A-4040ANTS-BUILDER-2FECL-3FPACKAGE-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

### 40ANTS-BUILDER/ECL

<a id="x-28-23A-28-2818-29-20BASE-CHAR-20-2E-20-2240ANTS-BUILDER-2FECL-22-29-20PACKAGE-29"></a>

#### [package](9fa7) `40ants-builder/ecl`

<a id="x-2840ANTS-BUILDER-DOCS-2FINDEX-3A-3A-7C-4040ANTS-BUILDER-2FECL-3FFunctions-SECTION-7C-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

#### Functions

<a id="x-2840ANTS-BUILDER-2FECL-3AINSTALL-ECL-WORKAROUNDS-20FUNCTION-29"></a>

##### [function](c982) `40ants-builder/ecl:install-ecl-workarounds`

Prepare the image so the dependencies' `DEFPACKAGE` forms can be read
on `ECL`.

Some dependencies (metacopy, in particular) read

<a id="if-load-with-contextl-contextl-values-inside-defpackage"></a>

###### .(if *load-with-contextl* '#:contextl (values)) inside DEFPACKAGE.

On `SBCL`, the reader inserts nothing into the list for zero values of
sharp-dot, while the `ECL` reader inserts `NIL`, which `DEFPACKAGE` turns
into :use of a package named "`NIL`", and `ECL` fails with "There
exists no package with name `NIL`". Creating an empty package with
this name makes such `DEFPACKAGE` forms valid. On other implementations
this is a no-op.

<a id="x-2840ANTS-BUILDER-DOCS-2FINDEX-3A-3A-4040ANTS-BUILDER-2FIMAGE-3FPACKAGE-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

### 40ANTS-BUILDER/IMAGE

<a id="x-28-23A-28-2820-29-20BASE-CHAR-20-2E-20-2240ANTS-BUILDER-2FIMAGE-22-29-20PACKAGE-29"></a>

#### [package](5e2c) `40ants-builder/image`

<a id="x-2840ANTS-BUILDER-DOCS-2FINDEX-3A-3A-7C-4040ANTS-BUILDER-2FIMAGE-3FFunctions-SECTION-7C-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

#### Functions

<a id="x-2840ANTS-BUILDER-2FIMAGE-3ADUMP-BINARY-20FUNCTION-29"></a>

##### [function](bdfe) `40ants-builder/image:dump-binary` system

Dump the standalone binary of `SYSTEM`.

On `SBCL` and `CCL` this is asdf:make, which performs the system's
:build-operation (deploy-op for Pingvito). `ECL` does not support
uiop:dump-image, and deploy-op relies on it, so under `ECL` the standard
asdf:program-op is used instead: the system is compiled to C and the
object files are linked into an executable with c:build-program,
using the :entry-point and :build-pathname from the system's
definition file.

<a id="x-2840ANTS-BUILDER-2FIMAGE-3AENSURE-PACKAGE-NICKNAME-20FUNCTION-29"></a>

##### [function](ace0) `40ants-builder/image:ensure-package-nickname` package-name nickname

Add `NICKNAME` to the package named `PACKAGE-NAME`.

Does nothing when the package does not exist or when a package named
`NICKNAME` is already present, because in these cases rename-package
either has nothing to do or signals a correctable error. Returns T
when the package was renamed.

<a id="x-2840ANTS-BUILDER-2FIMAGE-3AINSTALL-BUILD-DEBUGGER-HOOK-20FUNCTION-29"></a>

##### [function](edf1) `40ants-builder/image:install-build-debugger-hook`

Install a debugger hook which fails the build process immediately.

Any error during the build must exit the process with a non-zero
code, instead of leaving it hanging in the interactive debugger of
Roswell/`CCL`.

<a id="x-2840ANTS-BUILDER-2FIMAGE-3APREPARE-IMAGE-20FUNCTION-29"></a>

##### [function](1937) `40ants-builder/image:prepare-image`

Prepare the build image for the dump.

Gives the Clack Hunchentoot handler package its slash nickname:
Clack looks handlers up by a name with slashes, does not find it in
the current dist and calls ql:quickload at run time, which fails
under ProtectHome. The nickname removes the runtime load.

Then pushes the :deploy-console feature to silence Deploy's status
output at service startup ("Performing warm boot", "Loading foreign
library ..." etc.): with this feature the warm boot sets
*status-output* to `NIL`, the same way deploy-console-op does for
console applications. Build identification stays available through
the project's version flag.

Finally, removes the build-only debugger hook, so it does not get
dumped into the image: otherwise any runtime error would kill the
service with a build failure message instead of the project's own
error handling.

<a id="x-2840ANTS-BUILDER-DOCS-2FINDEX-3A-3A-4040ANTS-BUILDER-2FREGISTRY-3FPACKAGE-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

### 40ANTS-BUILDER/REGISTRY

<a id="x-28-23A-28-2823-29-20BASE-CHAR-20-2E-20-2240ANTS-BUILDER-2FREGISTRY-22-29-20PACKAGE-29"></a>

#### [package](88c7) `40ants-builder/registry`

<a id="x-2840ANTS-BUILDER-DOCS-2FINDEX-3A-3A-7C-4040ANTS-BUILDER-2FREGISTRY-3FFunctions-SECTION-7C-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

#### Functions

<a id="x-2840ANTS-BUILDER-2FREGISTRY-3AREGISTER-LOCAL-SYSTEMS-20FUNCTION-29"></a>

##### [function](4fba) `40ants-builder/registry:register-local-systems` system

Extend the `ASDF` registry with systems local to the project being built.

Projects keep a local-deps.lisp file next to their system definition
file; it defines an extend-registry function which pushes local
checkout directories onto asdf:*central-registry*. When the file is
missing, nothing is registered and the call is a no-op, because a
project may have all its dependencies on Quicklisp.

<a id="x-2840ANTS-BUILDER-DOCS-2FINDEX-3A-3A-4040ANTS-BUILDER-2FVERSION-3FPACKAGE-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

### 40ANTS-BUILDER/VERSION

<a id="x-28-23A-28-2822-29-20BASE-CHAR-20-2E-20-2240ANTS-BUILDER-2FVERSION-22-29-20PACKAGE-29"></a>

#### [package](d0a3) `40ants-builder/version`

<a id="x-2840ANTS-BUILDER-DOCS-2FINDEX-3A-3A-7C-4040ANTS-BUILDER-2FVERSION-3FFunctions-SECTION-7C-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

#### Functions

<a id="x-2840ANTS-BUILDER-2FVERSION-3APIN-BUILD-VERSION-20FUNCTION-29"></a>

##### [function](fabd) `40ants-builder/version:pin-build-version` system

Capture build-time identification of `SYSTEM` into the image.

Stores the git commit into *git-commit* and appends the commit to the
system's version, updating its component-version. The version is
taken from the system's component-version or, when it is unset, from
the topmost entry of its docs/changelog.lisp.

Called before the image dump, so that the binary's version flag
reports the state of the sources it was built from, and not of
whatever is on disk at run time. Returns the commit.

<a id="x-2840ANTS-BUILDER-2FVERSION-3AREAD-CHANGELOG-VERSION-20FUNCTION-29"></a>

##### [function](fd65) `40ants-builder/version:read-changelog-version` system

Return the topmost version from `SYSTEM`'s docs/changelog.lisp or `NIL`.

This mirrors what the 40ants-asdf-system class does on an explicit
load-system: the first changelog entry defines the version. Forms
are read into a temporary package, because the changelog macro and
version symbols are not interned anywhere in the build image.

<a id="x-2840ANTS-BUILDER-DOCS-2FINDEX-3A-3A-7C-4040ANTS-BUILDER-2FVERSION-3FVariables-SECTION-7C-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

#### Variables

<a id="x-2840ANTS-BUILDER-2FVERSION-3A-2AGIT-COMMIT-2A-20-28VARIABLE-29-29"></a>

##### [variable](feed) `40ants-builder/version:*git-commit*` "unknown"

Git commit captured by pin-build-version before the image dump.

The binary usually runs on a host without .git and sources
(ProtectHome=read-only), so the commit has to be captured at build
time. Projects use this variable in their version flag output.


[64f1]: https://40ants.com/builder/
[f8eb]: https://github.com/40ants/ai-badges
[af68]: https://github.com/40ants/builder
[c4f9]: https://github.com/40ants/builder/actions
[f064]: https://github.com/40ants/builder/blob/790ccef45da1edc93984e48427944fe79966a703/src/ccl.lisp#L1
[8e24]: https://github.com/40ants/builder/blob/790ccef45da1edc93984e48427944fe79966a703/src/ccl.lisp#L19
[12fe]: https://github.com/40ants/builder/blob/790ccef45da1edc93984e48427944fe79966a703/src/ccl.lisp#L85
[70b3]: https://github.com/40ants/builder/blob/790ccef45da1edc93984e48427944fe79966a703/src/ccl.lisp#L9
[038f]: https://github.com/40ants/builder/blob/790ccef45da1edc93984e48427944fe79966a703/src/core.lisp#L1
[fbaf]: https://github.com/40ants/builder/blob/790ccef45da1edc93984e48427944fe79966a703/src/core.lisp#L29
[a20e]: https://github.com/40ants/builder/blob/790ccef45da1edc93984e48427944fe79966a703/src/core.lisp#L48
[c7cd]: https://github.com/40ants/builder/blob/790ccef45da1edc93984e48427944fe79966a703/src/dependencies.lisp#L1
[9cac]: https://github.com/40ants/builder/blob/790ccef45da1edc93984e48427944fe79966a703/src/dependencies.lisp#L23
[7a51]: https://github.com/40ants/builder/blob/790ccef45da1edc93984e48427944fe79966a703/src/dependencies.lisp#L8
[9fa7]: https://github.com/40ants/builder/blob/790ccef45da1edc93984e48427944fe79966a703/src/ecl.lisp#L1
[c982]: https://github.com/40ants/builder/blob/790ccef45da1edc93984e48427944fe79966a703/src/ecl.lisp#L7
[5e2c]: https://github.com/40ants/builder/blob/790ccef45da1edc93984e48427944fe79966a703/src/image.lisp#L1
[edf1]: https://github.com/40ants/builder/blob/790ccef45da1edc93984e48427944fe79966a703/src/image.lisp#L10
[ace0]: https://github.com/40ants/builder/blob/790ccef45da1edc93984e48427944fe79966a703/src/image.lisp#L24
[1937]: https://github.com/40ants/builder/blob/790ccef45da1edc93984e48427944fe79966a703/src/image.lisp#L41
[bdfe]: https://github.com/40ants/builder/blob/790ccef45da1edc93984e48427944fe79966a703/src/image.lisp#L66
[88c7]: https://github.com/40ants/builder/blob/790ccef45da1edc93984e48427944fe79966a703/src/registry.lisp#L1
[4fba]: https://github.com/40ants/builder/blob/790ccef45da1edc93984e48427944fe79966a703/src/registry.lisp#L16
[d0a3]: https://github.com/40ants/builder/blob/790ccef45da1edc93984e48427944fe79966a703/src/version.lisp#L1
[feed]: https://github.com/40ants/builder/blob/790ccef45da1edc93984e48427944fe79966a703/src/version.lisp#L13
[fd65]: https://github.com/40ants/builder/blob/790ccef45da1edc93984e48427944fe79966a703/src/version.lisp#L39
[fabd]: https://github.com/40ants/builder/blob/790ccef45da1edc93984e48427944fe79966a703/src/version.lisp#L66
[0964]: https://github.com/40ants/builder/blob/master/.agents/skills/setup-40ants-builder/SKILL.md
[2fec]: https://github.com/40ants/builder/issues
[c15d]: https://quickdocs.org/asdf

* * *
###### [generated by [40ANTS-DOC](https://40ants.com/doc/)]
