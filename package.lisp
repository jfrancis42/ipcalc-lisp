;;;; package.lisp

(defpackage #:ipcalc
  (:use #:cl)
  (:import-from :jeffutils
                :join)
  (:import-from :split-sequence
		:split-sequence)
  (:export :is-it-ipv4?
	   :is-it-ipv6?
	   :parse-address
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
	   :iprange-to-cidr
	   :cidr-to-iprange
	   :rfc1918-addr?
	   :netmask-to-cidr
	   :valid-netmask?
	   :ip-in-network?
	   :network-size
	   :usable-host-count
	   :first-host
	   :last-host
	   :networks-overlap?
	   :network-contains-network?
	   :supernet
	   :split-network
	   :collapse-networks
	   :loopback-addr?
	   :link-local-addr?
	   :unspecified-addr?
	   :unique-local-addr?
	   :wildcard-mask
	   :reverse-dns-ptr
	   ))
