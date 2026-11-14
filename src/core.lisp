(uiop:define-package #:40ants-builder/core
  (:use #:cl)
  (:nicknames #:40ants-builder)
  (:import-from #:40ants-builder/ccl
                #:install-ccl-patches)
  (:import-from #:40ants-builder/ecl
                #:install-ecl-workarounds)
  (:import-from #:40ants-builder/dependencies
                #:load-build-dependencies
                #:*default-slynk-modules*)
  (:import-from #:40ants-builder/image
                #:install-build-debugger-hook
                #:prepare-image
                #:dump-binary)
  (:import-from #:40ants-builder/registry
                #:register-local-systems)
  (:import-from #:40ants-builder/version
                #:pin-build-version
                #:*git-commit*)
  (:export #:build
           #:build-error
           #:build-error-condition
           #:pin-build-version
           #:*git-commit*
           #:*default-slynk-modules*))
(in-package #:40ants-builder/core)


(define-condition build-error (error)
  ((condition :initarg :condition
              :reader build-error-condition
              :documentation "The original serious condition reported by the pipeline."))
  (:report (lambda (build-error stream)
             (format stream "Build failed: ~A"
                     (build-error-condition build-error)))))


(defun install-implementation-workarounds ()
  "Install implementation specific workarounds.

Must run before the target system is loaded: under CCL the patches
are used during compilation of its dependencies, and under ECL the
empty \"NIL\" package makes their DEFPACKAGE forms readable."
  (install-ccl-patches)
  (install-ecl-workarounds))


(defun build (system &key (slynk-modules *default-slynk-modules*)
                          (exit t))
  "Build a standalone binary of SYSTEM and return the pinned git commit.

SYSTEM is an ASDF system designator of the program system, like
:pingvito. The pipeline is essentially a build.lisp script extracted
into a reusable library:

1. installs a debugger hook which fails the process with exit code 1
   instead of hanging in the interactive debugger;
2. extends the ASDF registry from the local-deps.lisp file in
   SYSTEM's source directory, when it is present;
3. installs implementation workarounds (the CFFI and conduit-packages
   patches on CCL, the empty \"NIL\" package on ECL);
4. quickloads Deploy, SYSTEM and SLYNK-MODULES (defaults to
   *default-slynk-modules*; pass NIL to skip them);
5. pins the build identification: the git commit goes into
   *git-commit* and the commit is appended to the ASDF version of
   SYSTEM;
6. prepares the image for the dump: renames the Clack handler package
   to its slash nickname, pushes the :deploy-console feature and
   removes the build debugger hook;
7. dumps the binary: asdf:make on SBCL and CCL, asdf:program-op on
   ECL.

On success the process exits with code 0. On failure the condition is
printed with a backtrace and the process exits with code 1. When EXIT
is NIL, build does not quit: it returns the commit on success and
signals build-error, wrapping the original condition, on failure."
  (install-build-debugger-hook)
  (handler-case
      (progn
        (register-local-systems system)
        (install-implementation-workarounds)
        (load-build-dependencies system :slynk-modules slynk-modules)
        (pin-build-version system)
        (prepare-image)
        (dump-binary system)
        (let ((commit *git-commit*))
          (when exit
            (uiop:quit 0))
          commit))
    (serious-condition (condition)
      (format *error-output* "~&BUILD FAILED: ~A~%~%" condition)
      (uiop:print-condition-backtrace condition)
      (if exit
          (uiop:quit 1)
          (error 'build-error :condition condition)))))
