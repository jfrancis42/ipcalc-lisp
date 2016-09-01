;;;; ipcalc.asd

(asdf:defsystem #:ipcalc
  :description "A Common Lisp library for manipulating and calculating IPv4 and IPv6 network addresses."
  :author "Jeff Francis <jeff@gritch.org>"
  :license "MIT, see file LICENSE"
  :depends-on (#:split-sequence
               #:alexandria
               #:cl-ppcre)
  :serial t
  :components ((:file "package")
               (:file "ipcalc")))

