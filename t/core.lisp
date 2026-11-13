(uiop:define-package #:40ants-builder-tests/core
  (:use #:cl #:rove)
  (:import-from #:40ants-builder/ccl
                #:deduplicate-names
                #:elide-already-imported-clauses)
  (:import-from #:40ants-builder/image
                #:ensure-package-nickname)
  (:import-from #:40ants-builder/version
                #:pin-build-version
                #:read-changelog-version
                #:*git-commit*)
  (:import-from #:40ants-builder/dependencies
                #:*default-slynk-modules*)
  (:import-from #:40ants-builder/registry
                #:register-local-systems))
(in-package #:40ants-builder-tests/core)


(defvar *fixture-counter* 0)


(defun %tmp-directory ()
  (uiop:ensure-directory-pathname
   (or (uiop:getenv-pathname "TMPDIR" :want-directory t)
       #p"/tmp/")))


(defun %make-fixture-directory ()
  (ensure-directories-exist
   (uiop:merge-pathnames*
    (format nil "40ants-builder-tests/~A-~A/"
            (incf *fixture-counter*)
            (get-universal-time))
    (%tmp-directory))))


(defun %delete-fixture-directory (directory)
  (uiop:delete-directory-tree
   directory
   :validate (lambda (path)
               (search "40ANTS-BUILDER-TESTS"
                       (namestring path)))
   :if-does-not-exist :ignore))


(defun %remove-fake-registry-entry ()
  (setf asdf:*central-registry*
        (remove #p"/40ants-builder-tests/fake-registry-entry/"
                asdf:*central-registry*
                :test #'uiop:pathname-equal))
  (let ((symbol (or (find-symbol "EXTEND-REGISTRY" :cl-user)
                    (find-symbol "EXTEND-REGISTRY" *package*))))
    (when (and symbol
               (fboundp symbol))
      (fmakunbound symbol))))


(defun %write-local-deps (directory)
  (let ((path (uiop:merge-pathnames* "roswell/local-deps.lisp"
                                     directory)))
    (ensure-directories-exist path)
    (with-open-file (out path
                         :direction :output
                         :if-exists :supersede)
      (format out "(in-package :cl-user)~%")
      (format out "(defun extend-registry ()~%")
      (format out "  (pushnew #p\"/40ants-builder-tests/fake-registry-entry/\"~%")
      (format out "           asdf:*central-registry*~%")
      (format out "           :test #'uiop:pathname-equal))~%"))))


(defun %write-fake-asd (directory name)
  (with-open-file (out (uiop:merge-pathnames* (format nil "~A.asd" name)
                                              directory)
                       :direction :output
                       :if-exists :supersede)
    (format out "(defsystem ~S)~%" name)))


(deftest deduplicate-names-keeps-first-occurrence
  (let ((seen (make-hash-table :test #'equal)))
    (ok (equal (deduplicate-names (list "a" "b" "a" "c" "b") seen)
               (list "a" "b" "c")))
    ;; Already seen names are filtered out on subsequent calls too:
    (ok (equal (deduplicate-names (list "a" "d") seen)
               (list "d")))))


(deftest conduit-clauses-elide-duplicate-imports
  (let ((package-a (make-package "40ANTS-BUILDER-TESTS/CONDUIT-A" :use '()))
        (package-b (make-package "40ANTS-BUILDER-TESTS/CONDUIT-B" :use '())))
    (unwind-protect
         (progn
           (export (list (intern "DELETE-NTH" package-a)) package-a)
           (export (list (intern "DELETE-NTH" package-b)) package-b)
           (let* ((clauses (elide-already-imported-clauses
                            :extends (list (package-name package-a)
                                           (package-name package-b))))
                  (imported (loop for clause in clauses
                                  when (eq (first clause) :import-from)
                                    append (cddr clause)))
                  (exported (loop for clause in clauses
                                  when (eq (first clause) :export)
                                    append (rest clause))))
             ;; Both packages export DELETE-NTH, but the name must be
             ;; imported only once, because CCL treats the duplicate
             ;; :import-from as a hard error:
             (ok (= (count "DELETE-NTH" imported :test #'string=)
                    1))
             ;; And the symbol remains re-exported by the conduit:
             (ok (= (count "DELETE-NTH" exported :test #'string=)
                    1))))
      (delete-package package-a)
      (delete-package package-b))))


(deftest conduit-clauses-export-all-externals
  (let ((package-a (make-package "40ANTS-BUILDER-TESTS/CONDUIT-C" :use '())))
    (unwind-protect
         (progn
           (export (list (intern "FOO" package-a)
                         (intern "BAR" package-a))
                   package-a)
           (let* ((clauses (elide-already-imported-clauses
                            :extends (list (package-name package-a))))
                  (exported (loop for clause in clauses
                                  when (eq (first clause) :export)
                                    append (rest clause))))
             (ok (equal (sort (copy-list exported) #'string<)
                        (list "BAR" "FOO")))))
      (delete-package package-a))))


(deftest ensure-package-nickname-adds-a-nickname
  (let ((package (make-package "40ANTS-BUILDER-TESTS/DUMMY" :use '())))
    (unwind-protect
         (progn
           (ok (ensure-package-nickname "40ANTS-BUILDER-TESTS/DUMMY"
                                        "40ANTS-BUILDER-TESTS/DUMMY-NICK"))
           (ok (eq (find-package "40ANTS-BUILDER-TESTS/DUMMY-NICK")
                   package))
           ;; The second call is a no-op, not an error:
           (ok (null (ensure-package-nickname "40ANTS-BUILDER-TESTS/DUMMY"
                                              "40ANTS-BUILDER-TESTS/DUMMY-NICK"))))
      (delete-package package))))


(deftest ensure-package-nickname-ignores-unknown-package
  (ok (null (ensure-package-nickname "40ANTS-BUILDER-TESTS/NO-SUCH-PACKAGE"
                                     "40ANTS-BUILDER-TESTS/NO-SUCH-NICKNAME"))))


(deftest ensure-package-nickname-does-not-clash-with-existing-name
  (let ((package (make-package "40ANTS-BUILDER-TESTS/DUMMY-2" :use '()))
        (occupant (make-package "40ANTS-BUILDER-TESTS/DUMMY-2-NICK" :use '())))
    (unwind-protect
         (progn
           ;; A package with the nickname's name is already present,
           ;; rename-package would signal a correctable error here:
           (ok (null (ensure-package-nickname "40ANTS-BUILDER-TESTS/DUMMY-2"
                                              "40ANTS-BUILDER-TESTS/DUMMY-2-NICK")))
           (ok (eq (find-package "40ANTS-BUILDER-TESTS/DUMMY-2-NICK")
                   occupant))
           ;; The nickname was not attached to the dummy package:
           (ok (null (member "40ANTS-BUILDER-TESTS/DUMMY-2-NICK"
                             (package-nicknames package)
                             :test #'string=))))
      (delete-package occupant)
      (delete-package package))))


(deftest read-changelog-version-returns-topmost-entry
  ;; The builder documents itself: the topmost entry of its own
  ;; docs/changelog.lisp defines its version.
  (ok (equal (read-changelog-version :40ants-builder)
             "0.1.0")))


(deftest pin-build-version-captures-commit-and-pins-version
  (let* ((system (asdf:find-system :40ants-builder))
         (old-version (asdf:component-version system))
         (old-commit *git-commit*))
    (unwind-protect
         (let ((commit (pin-build-version :40ants-builder)))
           (ok (and (stringp commit)
                    (not (string= commit "unknown"))))
           (ok (= (length commit) 40))
           (ok (string= *git-commit* commit))
           (let* ((base-version (or old-version
                                    (read-changelog-version :40ants-builder)))
                  (expected (format nil "~A+git.~A"
                                    base-version
                                    (subseq commit 0 7))))
             (ok (string= (asdf:component-version system)
                          expected))))
      (setf (asdf:component-version system) old-version)
      (setf *git-commit* old-commit))))


(deftest pin-build-version-is-idempotent
  ;; Repeated call in the same image must not append the commit to
  ;; the already pinned version:
  (let* ((system (asdf:find-system :40ants-builder))
         (old-version (asdf:component-version system))
         (old-commit *git-commit*))
    (unwind-protect
         (progn
           (pin-build-version :40ants-builder)
           (let ((first-version (asdf:component-version system)))
             (pin-build-version :40ants-builder)
             (ok (string= (asdf:component-version system)
                          first-version))))
      (setf (asdf:component-version system) old-version)
      (setf *git-commit* old-commit))))


(deftest register-local-systems-loads-local-deps-and-extends-registry
  (let ((directory (%make-fixture-directory)))
    (unwind-protect
         (let ((fake-system "40ants-builder-tests-fake-target"))
           (%write-local-deps directory)
           (%write-fake-asd directory fake-system)
           (pushnew directory
                    asdf:*central-registry*
                    :test #'uiop:pathname-equal)
           (unwind-protect
                (progn
                  (register-local-systems fake-system)
                  (ok (member #p"/40ants-builder-tests/fake-registry-entry/"
                              asdf:*central-registry*
                              :test #'uiop:pathname-equal)))
             (setf asdf:*central-registry*
                   (remove directory
                           asdf:*central-registry*
                           :test #'uiop:pathname-equal))
             (asdf:clear-system fake-system)))
      (%remove-fake-registry-entry)
      (%delete-fixture-directory directory))))


(deftest register-local-systems-tolerates-missing-local-deps
  (let ((directory (%make-fixture-directory)))
    (unwind-protect
         (let ((fake-system "40ants-builder-tests-fake-empty")
               (before (length asdf:*central-registry*)))
           (%write-fake-asd directory fake-system)
           (pushnew directory
                    asdf:*central-registry*
                    :test #'uiop:pathname-equal)
           (unwind-protect
                (progn
                  (register-local-systems fake-system)
                  (ok (= (length asdf:*central-registry*)
                         before)))
             (setf asdf:*central-registry*
                   (remove directory
                           asdf:*central-registry*
                           :test #'uiop:pathname-equal))
             (asdf:clear-system fake-system)))
      (%delete-fixture-directory directory))))


(deftest default-slynk-modules-include-contribs
  (ok (member :slynk/indentation *default-slynk-modules*))
  (ok (member :slynk/fancy-inspector *default-slynk-modules*))
  (ok (member :slynk/arglists *default-slynk-modules*)))
