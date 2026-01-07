(asdf:defsystem :aw-impeller
  :description "Bindings to Flutter's Impeller cross-platform 2D graphics and text rendering engine"
  :version "1.0.0"
  :author "Pavel Korolev"
  :mailto "dev@borodust.org"
  :license "MIT"
  :depends-on (:aw-impeller-bindings))


(asdf:defsystem :aw-impeller/wrapper
  :description "Thin wrapper over Flutter's Impeller"
  :version "1.0.0"
  :author "Pavel Korolev"
  :mailto "dev@borodust.org"
  :license "MIT"
  :depends-on (:alexandria :claw-utils :claw)
  :serial t
  :components ((:file "src/claw")
               (:module :impeller-includes :pathname "src/lib/impeller/engine/src/flutter/impeller/toolkit/interop")))
