(defsystem "40ants-builder-ci"
  :author "Alexander Artemenko <svetlyak.40wt@gmail.com>"
  :license "Unlicense"
  :homepage "https://40ants.com/builder/"
  :class :package-inferred-system
  :description "Provides CI settings for 40ants-builder."
  :source-control (:git "https://github.com/40ants/builder")
  :bug-tracker "https://github.com/40ants/builder/issues"
  :pathname "src"
  :depends-on ("40ants-ci"
               "40ants-builder-ci/ci"))
