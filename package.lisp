;;;; package.lisp

(defpackage #:ipcalc
  (:use #:cl)
  (:export :is-it-ipv4?
	   :is-it-ipv6?
	   :ipv6-addr-compress
	   :ipv6-addr-expand
	   :calc-network-addr
	   :calc-broadcast-addr
	   :ip-info
	   :same-ip-network?
	   :multicast-addr?
	   :cidr-to-ipv4-netmask
	   :cidr-to-ipv6-netmask
	   :ip-to-int
	   :int-to-ipv4
	   :int-to-ipv6
	   :proto-num-to-name
	   :name-to-proto-num
	   :iana-tcp-service-name
	   :iana-udp-service-name
	   :iana-port-name
	   ))
