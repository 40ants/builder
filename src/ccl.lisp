(uiop:define-package #:40ants-builder/ccl
  (:use #:cl)
  (:export #:install-ccl-patches
           #:deduplicate-names
           #:elide-already-imported-clauses))
(in-package #:40ants-builder/ccl)


(defun deduplicate-names (names seen)
  "Return only those names which are not in the SEEN hash-table yet,
registering every returned name."
  (loop for name in names
        unless (gethash name seen)
          collect (progn
                    (setf (gethash name seen) t)
                    name)))


(defun elide-already-imported-clauses (&key extends
                                            extends/including
                                            extends/excluding)
  "Return DEFPACKAGE clauses for a conduit package, skipping symbol
names already imported by a previous extension.

This is a copy of ORG.TFEB.CONDUIT-PACKAGES::COMPUTE-CONDUIT-CLAUSES
which elides such names: importing the same external symbol via two
:import-from clauses is tolerated by SBCL, but is a hard error on CCL
(\"Name ... is already used in a conflicting option\"). The Lisp-Stat
project defines its packages with the :extends option of the
conduit-packages DEFPACKAGE macro, and several of its extended
packages export the same symbols."
  (let ((seen (make-hash-table :test #'equal)))
    (flet ((fresh (names)
             (deduplicate-names names seen)))
      (append
       (loop for p in extends
             for externals = (fresh (loop for s being the external-symbols
                                          of (find-package p)
                                          collect (symbol-name s)))
             collect `(:import-from ,p ,@externals)
             collect `(:export ,@externals))
       (loop for (p . included) in extends/including
             for names = (fresh included)
             collect `(:import-from ,p ,@names)
             collect `(:export ,@names))
       (loop for (p . excluded) in extends/excluding
             for excluded-names = (mapcar #'string excluded)
             for included = (fresh (loop for s being the external-symbols
                                         of (find-package p)
                                         for sn = (symbol-name s)
                                         unless (member sn excluded-names
                                                        :test #'string=)
                                           collect sn))
             collect `(:import-from ,p ,@included)
             collect `(:export ,@included))))))


#+ccl
(defun %load-foreign-library-eliding-versions (name path)
  "A copy of CFFI-SYS:%LOAD-FOREIGN-LIBRARY which translates logical
pathnames into physical ones and drops the pathname version.

CCL defines the logical host home: for files inside the home
directory, and *compile-file-pathname* is a logical pathname during
compilation. The cephes.cl library computes its foreign library spec
at read time with a #. form:

  #.(merge-pathnames \"scipy-cephes/libmd.so\" *compile-file-pathname*)

so the compiled file stores #P\"home:...;scipy-cephes;libmd.so.newest\":
for a logical pathname, the default :newest version renders as a
literal \".newest\" filename suffix, and the resulting dlopen fails.
SBCL is not affected, because it renders pathnames without the
version component."
  (declare (ignore name))
  (ccl:open-shared-library
   (cffi-sys:native-namestring
    (let ((path (if (stringp path)
                    (pathname path)
                    path)))
      (make-pathname :defaults (translate-logical-pathname path)
                     :version nil)))))


(defun install-ccl-patches ()
  "Patch CFFI and conduit-packages to make Lisp-Stat and its
dependencies compile and load on CCL.

Call before the target system is quickloaded, because the patches are
used during compilation of its dependencies. On other implementations
this is a no-op."
  #+ccl
  (progn
    (setf (fdefinition 'cffi-sys:%load-foreign-library)
          #'%load-foreign-library-eliding-versions)
    (setf (fdefinition 'org.tfeb.conduit-packages::compute-conduit-clauses)
          #'elide-already-imported-clauses))
  #-ccl
  (values))
