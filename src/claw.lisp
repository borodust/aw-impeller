(claw:defwrapper (:aw-impeller
                  (:system :aw-impeller/wrapper)
                  (:headers "impeller.h")
                  (:includes :impeller-includes)
                  (:include-definitions "^Impeller\\w+" "^IMPELLER_\\w+")
                  (:targets ((:and :x86-64 :linux) "x86_64-pc-linux-gnu")
                            ((:and :x86-64 :windows) "x86_64-w64-mingw32")
                            ((:and :x86-64 :darwin) "x86_64-apple-darwin-gnu")
                            ((:and :aarch64 :android) "aarch64-linux-android"))
                  (:persistent t :depends-on (:claw-utils)))
  :in-package :%impeller
  :trim-enum-prefix t
  :recognize-bitfields t
  :recognize-strings t
  :override-types ((:string claw-utils:claw-string)
                   (:pointer claw-utils:claw-pointer))
  :symbolicate-names (:in-pipeline
                      (:by-removing-prefixes "Impeller" "IMPELLER_")))
