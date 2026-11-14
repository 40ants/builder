(uiop:define-package #:40ants-builder-docs/index
  (:use #:cl)
  (:import-from #:pythonic-string-reader
                #:pythonic-string-syntax)
  #+quicklisp
  (:import-from #:quicklisp)
  (:import-from #:named-readtables
                #:in-readtable)
  (:import-from #:40ants-doc
                #:defsection
                #:defsection-copy)
  (:import-from #:40ants-builder-docs/changelog
                #:@changelog)
  (:import-from #:docs-config
                #:docs-config)
  (:import-from #:40ants-doc/autodoc
                #:defautodoc)
  (:export #:@index
           #:@readme
           #:@changelog))
(in-package #:40ants-builder-docs/index)

(in-readtable pythonic-string-syntax)


(defmethod docs-config ((system (eql (asdf:find-system "40ants-builder-docs"))))
  ;; 40ANTS-DOC-THEME-40ANTS system will bring
  ;; as dependency a full 40ANTS-DOC but we don't want
  ;; unnecessary dependencies here:
  #+quicklisp
  (ql:quickload "40ants-doc-theme-40ants")
  #-quicklisp
  (asdf:load-system "40ants-doc-theme-40ants")
  
  (list :theme
        (find-symbol "40ANTS-THEME"
                     (find-package "40ANTS-DOC-THEME-40ANTS")))
  )


(defsection @index (:title "40ants-builder - A reusable builder of standalone binaries for Common Lisp projects"
                                   :ignore-words ("JSON"
                                   "HTTP"
                                   "TODO"
                                   "Unlicense"
                                   "REPL"
                                   "ASDF"
                                   "40A"
                                   "API"
                                   "AI"
                                   "CLI"
                                   "LLM"
                                   "README"
                                   "SBCL"
                                   "CCL"
                                   "ECL"
                                   "CFFI"
                                   "GIT"))
  (40ants-builder system)
  "
[![WARN-LLM GENERATED](https://img.shields.io/badge/WARN-LLM%20GENERATED-FF6347)](https://github.com/40ants/ai-badges)

[![](https://github-actions.40ants.com/40ants/builder/matrix.svg?only=ci.run-tests)](https://github.com/40ants/builder/actions)

![Quicklisp](http://quickdocs.org/badge/40ants-builder.svg)
"
  (@features section)
  (@installation section)
  (@usage section)
  (@for-ai-agents section)
  (@api section))


(defsection-copy @readme @index)


(defsection @features (:title "Features")
  """
Dumping a standalone binary of a Common Lisp application requires more
than calling `asdf:make` or `ros build`. A production build needs a
prepared environment: local checkouts registered in ASDF,
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

- **One call builds the binary.** `(40ants-builder:build :my-app)`
  runs the whole pipeline: registry setup, workarounds, dependency
  loading, version pinning, image preparation and the dump.
- **Local systems registered.** A `local-deps.lisp` file in the
  project root, when present, is loaded to push local checkout
  directories onto the ASDF registry.
- **Implementation quirks patched.** On CCL the builder fixes CFFI's
  foreign library loader, which chokes on logical pathnames with a
  `:newest` version suffix, and teaches conduit-packages to elide
  duplicate defpackage imports, which Lisp-Stat requires; on ECL it
  creates an empty `NIL` package so the dependencies' defpackage forms
  stay readable.
- **Build identification pinned.** The git commit and the version from
  the system's `docs/changelog.lisp` are stored into the image, so
  `--version` reports what the binary was built from, even on a host
  without sources.
- **Production ready image.** Slynk contrib modules are loaded before
  the dump, the `:deploy-console` feature silences Deploy's status
  output at service startup, and the build debugger hook is removed,
  so it does not ship inside the binary.
- **Multiple implementations.** SBCL and CCL build via `asdf:make`
  (usually `deploy-op`), ECL builds via `asdf:program-op`, which does
  not rely on the unsupported `uiop:dump-image`.
- **Fail fast behavior.** Any build error prints the condition with a
  backtrace and exits with a non-zero code instead of hanging in the
  interactive debugger; pass `exit nil` to embed the pipeline into
  another tool and handle errors yourself.
""")


(defsection @installation (:title "Installation")
  """
You can install this library from Quicklisp, but you want to receive updates quickly, then install it from Ultralisp.org:

```
(ql-dist:install-dist "http://dist.ultralisp.org/"
                      :prompt nil)
(ql:quickload :40ants-builder)
```
""")


(defsection @usage (:title "Usage")
  """
Call the build function with the name of the ASDF system which
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
2. extends the ASDF registry from the `local-deps.lisp` file in the
   system's source directory, when it is present;
3. installs implementation workarounds: patches CFFI's foreign
   library loader and conduit-packages's DEFPACKAGE clause
   computation on CCL, and creates an empty `NIL` package on ECL;
4. quickloads Deploy, the system being built and Slynk contrib
   modules, which otherwise would be missing in production when a
   Slynk client connects;
5. pins the build identification: the git commit goes into
   `40ants-builder:*git-commit*` and the system's ASDF version
   becomes `VERSION+GIT.COMMIT`;
6. prepares the image for the dump: renames the Clack handler package
   to its slash nickname, pushes the `:deploy-console` feature and
   removes the build debugger hook, so it does not get dumped into
   the image;
7. dumps the binary: asdf:make on SBCL and CCL, and
   asdf:program-op on ECL, which does not support
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
""")


(defsection @for-ai-agents (:title "For AI Agents")
  """
This library is written with AI coding agents, and it ships an agent
skill so that agents can adopt it correctly. The skill teaches how to
convert a project to build through 40ants-builder: the program system
layout, the optional `local-deps.lisp` registry file, the direct
command and the 40ants-lake `builder` slot integration, build
verification, and the retirement of an old `build.lisp` script.

Point your coding agent to the
[`SKILL.md`](https://github.com/40ants/builder/blob/master/.agents/skills/setup-40ants-builder/SKILL.md)
file of this repository, or copy it into your project's
`.agents/skills/setup-40ants-builder/` directory. The
[AI badge](https://github.com/40ants/ai-badges) in the README marks the
code as LLM generated.
""")


(defautodoc @api (:system "40ants-builder"
                  :ignore-words ("NIL")))
