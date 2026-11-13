(uiop:define-package #:40ants-builder/ecl
  (:use #:cl)
  (:export #:install-ecl-workarounds))
(in-package #:40ants-builder/ecl)


(defun install-ecl-workarounds ()
  "Prepare the image so the dependencies' DEFPACKAGE forms can be read
on ECL.

Some dependencies (metacopy, in particular) read
#.(if *load-with-contextl* '#:contextl (values)) inside DEFPACKAGE.
On SBCL, the reader inserts nothing into the list for zero values of
sharp-dot, while the ECL reader inserts NIL, which DEFPACKAGE turns
into :use of a package named \"NIL\", and ECL fails with \"There
exists no package with name NIL\". Creating an empty package with
this name makes such DEFPACKAGE forms valid. On other implementations
this is a no-op."
  #+ecl
  (unless (find-package "NIL")
    (make-package "NIL" :use '()))
  #-ecl
  (values))
