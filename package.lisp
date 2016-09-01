;;;; package.lisp

(defpackage #:ipcalc
  (:use #:cl)
  (:export :ipv6-addr-compress
	   :calc-network-addr
	   :calc-broadcast-addr
	   :ip-info
	   :same-ip-network?
	   :multicast-addr?
	   :cidr-to-ipv4-netmask
	   :cidr-to-ipv6-netmask
	   ))
