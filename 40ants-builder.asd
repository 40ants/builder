#-asdf3.1 (error "40ants-builder requires ASDF 3.1 because for lower versions pathname does not work for package-inferred systems.")
(defsystem "40ants-builder"
  :description "A reusable builder of standalone binaries for Common Lisp projects."
  :author "Alexander Artemenko <svetlyak.40wt@gmail.com>"
  :license "Unlicense"
  :homepage "https://40ants.com/builder/"
  :source-control (:git "https://github.com/40ants/builder")
  :bug-tracker "https://github.com/40ants/builder/issues"
  :class :40ants-asdf-system
  :defsystem-depends-on ("40ants-asdf-system")
  :pathname "src"
  :depends-on ("40ants-builder/core"
               ;; CFFI and conduit-packages get patched on CCL,
               ;; see the 40ants-builder/ccl module:
               #+ccl "cffi"
               #+ccl "org.tfeb.conduit-packages")
  :in-order-to ((test-op (test-op "40ants-builder-tests"))))


#+ccl
(progn
  (asdf:register-system-packages "cffi" '("CFFI-SYS"))
  (asdf:register-system-packages "org.tfeb.conduit-packages"
                                 '("ORG.TFEB.CONDUIT-PACKAGES")))
