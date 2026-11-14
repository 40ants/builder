(uiop:define-package #:40ants-builder/registry
  (:use #:cl)
  (:export #:register-local-systems))
(in-package #:40ants-builder/registry)


(defun %extend-registry-function ()
  "Return the EXTEND-REGISTRY function defined by local-deps.lisp.

The file defines the function in whatever package is current at load
time, so we look it up in *package* first, then in CL-USER."
  (or (find-symbol "EXTEND-REGISTRY" *package*)
      (find-symbol "EXTEND-REGISTRY" :cl-user)))


(defun register-local-systems (system)
  "Extend the ASDF registry with systems local to the project being built.

Projects keep a local-deps.lisp file next to their system definition
file; it defines an extend-registry function which pushes local
checkout directories onto asdf:*central-registry*. When the file is
missing, nothing is registered and the call is a no-op, because a
project may have all its dependencies on Quicklisp."
  (let ((local-deps (asdf:system-relative-pathname system
                                                   "local-deps.lisp")))
    (when (probe-file local-deps)
      (format t "Loading local systems registry: ~A~%"
              local-deps)
      (load local-deps)
      (let ((extend-registry (%extend-registry-function)))
        (unless extend-registry
          (error "File ~A does not define EXTEND-REGISTRY function."
                 local-deps))
        (funcall extend-registry)))
    (format t "Registry: ~A~%"
            asdf:*central-registry*)))
