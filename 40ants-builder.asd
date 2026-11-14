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
  :depends-on ("40ants-builder/core")
  :in-order-to ((test-op (test-op "40ants-builder-tests"))))

