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
                                   "CLI"
                                   "SBCL"
                                   "CCL"
                                   "ECL"
                                   "CFFI"
                                   "GIT"))
  (40ants-builder system)
  "
[![](https://github-actions.40ants.com/40ants/builder/matrix.svg?only=ci.run-tests)](https://github.com/40ants/builder/actions)

![Quicklisp](http://quickdocs.org/badge/40ants-builder.svg)
"
  (@installation section)
  (@usage section)
  (@api section))


(defsection-copy @readme @index)


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
2. extends the ASDF registry from the system's
   `roswell/local-deps.lisp`, when the file is present;
3. installs implementation workarounds: patches CFFI's foreign
   library loader and conduit-packages's DEFPACKAGE clause
   computation on CCL, and creates an empty `NIL` package on ECL;
4. quickloads Deploy, the system being built and Slynk contrib
   modules, which otherwise would be missing in production when a
   Slynk client connects;
5. pins the build identification: the git commit goes into
   `40ants-builder:*git-commit*` and the system's ASDF version
   becomes `<version>+git.<commit>`;
6. prepares the image for the dump: renames the Clack handler package
   to its slash nickname, pushes the `:deploy-console` feature and
   removes the build debugger hook, so it does not get dumped into
   the image;
7. dumps the binary: `asdf:make` on SBCL and CCL, and
   `asdf:program-op` on ECL, which does not support
   `uiop:dump-image`.

On success the process exits with code 0; on failure the condition is
printed with a backtrace and the process exits with code 1.

Pass `slynk-modules nil` to skip the Slynk contribs and `exit nil` to
keep the process alive, returning the pinned commit instead of
quitting:

```lisp
(40ants-builder:build :pingvito :slynk-modules nil)
```

Note that a binary built on one OS or architecture cannot run on
another one. Build on the target host or in an equivalent
environment, and keep the `bin/` directory with native libraries next
to the binary in the release.
""")


(defautodoc @api (:system "40ants-builder"
                  :ignore-words ("NIL")))
