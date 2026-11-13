(uiop:define-package #:40ants-builder/version
  (:use #:cl)
  (:import-from #:asdf
                #:component-version
                #:find-system
                #:system-source-directory)
  (:export #:pin-build-version
           #:read-changelog-version
           #:*git-commit*))
(in-package #:40ants-builder/version)


(defvar *git-commit* "unknown"
  "Git commit captured by pin-build-version before the image dump.

The binary usually runs on a host without .git and sources
(ProtectHome=read-only), so the commit has to be captured at build
time. Projects use this variable in their version flag output.")


(defun %git-commit (system)
  "Run git in SYSTEM's source directory and return HEAD's commit hash.

Returns \"unknown\" when git fails or is unavailable, so that the
build itself is not blocked by a missing repository."
  (handler-case
      (uiop:run-program (list "git"
                              "-C"
                              (namestring (system-source-directory system))
                              "rev-parse" "HEAD")
                        :output '(:string :stripped t)
                        :error-output '(:string :stripped t))
    (error (condition)
      (warn "Cannot capture git commit for ~A: ~A"
            system condition)
      "unknown")))


(defun read-changelog-version (system)
  "Return the topmost version from SYSTEM's docs/changelog.lisp or NIL.

This mirrors what the 40ants-asdf-system class does on an explicit
load-system: the first defchangelog entry defines the version. Forms
are read into a temporary package, because DEFCHANGELOG and version
symbols are not interned anywhere in the build image."
  (ignore-errors
    (let ((path (asdf:system-relative-pathname system
                                               "docs/changelog.lisp")))
      (when (probe-file path)
        (let ((*package* (make-package (gensym "CHANGELOG-PKG")
                                       :use '("CL"))))
          (unwind-protect
               (with-open-file (in path)
                 (loop for form = (read in nil :eof)
                       until (eq form :eof)
                       when (and (consp form)
                                 (string-equal (symbol-name (car form))
                                               "DEFCHANGELOG"))
                         do (let ((entry (third form)))
                              (when (and (consp entry)
                                         (symbolp (car entry)))
                                (return (symbol-name (car entry)))))))
            (delete-package *package*)))))))


(defun pin-build-version (system)
  "Capture build-time identification of SYSTEM into the image.

Stores the git commit into *git-commit* and updates the system's
component-version to VERSION+GIT.COMMIT, where the version is
taken from the system's component-version or, when it is unset, from
the topmost entry of its docs/changelog.lisp.

Called before the image dump, so that the binary's version flag
reports the state of the sources it was built from, and not of
whatever is on disk at run time. Returns the commit."
  (let* ((system (find-system system))
         (commit (%git-commit system))
         (version (or (component-version system)
                      (read-changelog-version system))))
    (setf *git-commit* commit)
    (when (and version
               (not (string= commit "unknown"))
               (not (search "+git." version)))
      (setf (component-version system)
            (format nil "~A+git.~A"
                    version
                    (subseq commit 0 (min 7 (length commit))))))
    commit))
