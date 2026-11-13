(defsystem "40ants-builder-docs"
  :author "Alexander Artemenko <svetlyak.40wt@gmail.com>"
  :license "Unlicense"
  :homepage "https://40ants.com/builder/"
  :class :package-inferred-system
  :description "Provides documentation for 40ants-builder."
  :source-control (:git "https://github.com/40ants/builder")
  :bug-tracker "https://github.com/40ants/builder/issues"
  :pathname "docs"
  :depends-on ("40ants-builder"
               "40ants-builder-docs/index"))
