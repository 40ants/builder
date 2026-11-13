(uiop:define-package #:40ants-builder/dependencies
  (:use #:cl)
  (:export #:load-build-dependencies
           #:*default-slynk-modules*))
(in-package #:40ants-builder/dependencies)


(defvar *default-slynk-modules*
  (list :slynk/indentation
        :slynk/stickers
        :slynk/trace-dialog
        :slynk/package-fu
        :slynk/fancy-inspector
        :slynk/arglists)
  "Slynk contrib modules loaded into the image before the dump.

The Slynk server tries to load these modules when a client connects
and cannot do that in production, where neither Quicklisp nor the
sources are reachable. Pass NIL as SLYNK-MODULES argument of the
build function to skip them.")


(defun load-build-dependencies (system &key (slynk-modules
                                             *default-slynk-modules*))
  "Load everything which has to be present in the dumped image.

This is the Deploy library, the SYSTEM being built and the SLYNK-MODULES."
  (ql:quickload (list* :deploy
                       system
                       slynk-modules)))
