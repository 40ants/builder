(uiop:define-package #:40ants-builder-docs/changelog
  (:use #:cl)
  (:import-from #:40ants-doc/changelog
                #:defchangelog))
(in-package #:40ants-builder-docs/changelog)


(defchangelog (:ignore-words ("SBCL"
                              "CCL"
                              "ECL"
                              "ASDF"
                              "REPL"
                              "CFFI"
                              "CLI"))
  (0.2.0 2026-11-14
         "* The builder loads `local-deps.lisp` from the project root to
            register local systems, instead of `roswell/local-deps.lisp`.
          * Fixed compilation on CCL when CFFI or conduit-packages are not
            loaded yet: the ccl module resolves their symbols at run time and
            `install-ccl-patches` quickloads both libraries before installing
            the patches, so the module no longer references their packages at
            read time.")
  (0.1.0 2026-11-13
         "* Initial version. Extracted from the pingvito project's build.lisp
            script. Supports SBCL, CCL and ECL, pins the git commit and the
            changelog version into the dumped image, and bundles the Deploy
            runtime together with Slynk contribs."))
