# ipcalc-lisp
A Common Lisp library for manipulating and calculating IPv4 and IPv6
network addresses.

This library is intended to do useful things with IP addresses. The following functions are available:

* (is-it-ipv4? ...)
* (is-it-ipv6? ...)
* (ipv6-addr-compress ...)
* (ipv6-addr-expand ...)
* (calc-network-addr ...)
* (calc-broadcast-addr ...)
* (ip-info ...)
* (same-ip-network? ...)
* (multicast-addr? ...)
* (cidr-to-ipv4-netmask ...)
* (cidr-to-ipv6-netmask ...)
* (ip-to-int ...)
* (int-to-ipv4 ...)
* (int-to-ipv6 ...)
* (iprange-to-cidr ...)

All functions other than (multicast-addr?) function with either IPv4 or IPv6 parameters (though, obviously, they can't be mixed). The functions which require both an address and a netmask will accept those parameters in multiple ways. Each of the following calculates the network address for 10.1.0.42/24:

* (calc-network-addr "10.1.0.42/24")
* (calc-network-addr "10.1.0.42/255.255.255.0")
* (calc-network-addr "10.1.0.42" "24")
* (calc-network-addr "10.1.0.42" "255.255.255.0")

The functions (is-it-ipv4?) and (is-it-ipv6?) each require a single parameter: a network address string. This function does a very simple string match to look for either "." or ":" as part of the supplied string, and returns t or nil based on that test. These functions to not check for 100% properly specified addresses.

(ipv6-addr-compress) and (ipv6-addr-expand) both expect a single parameter: an IPv6 network address string. The functions respectively compress or expand the address following the RFC guidelines. Example:

```
CL-USER> (ipcalc:ipv6-addr-compress "2001:b00b:1e5:0:0:0:0:1")
"2001:B00B:1E5::1"
CL-USER> (ipcalc:ipv6-addr-expand "2001:B00B:1E5::1")
"2001:B00B:1E5:0:0:0:0:1"
CL-USER>
```

(calc-network-addr) and (calc-broadcast-addr) require an address and netmask, and return the network address or the broadcast address respectively:

```
CL-USER> (ipcalc:calc-network-addr "10.11.12.13/19")
"10.11.0.0"
CL-USER> (ipcalc:calc-broadcast-addr "10.11.12.13/19")
"10.11.31.255"
CL-USER>
```

(ip-to-int), (int-to-ipv4), and (int-to-ipv6) convert IP addresses to and from their integer representations:

```
CL-USER> (ipcalc:ip-to-int "2001:b00b:1e5::1")
42544058738162202133965779820242534401
CL-USER> (ipcalc:ip-to-int "10.1.0.42")
167837738
CL-USER> (ipcalc:int-to-ipv6 42544058738162202133965779820242534401)
"2001:B00B:1E5::1"
CL-USER>
```

(ip-info) is a convenience function that returns info about the specified network:

```
CL-USER> (ipcalc:ip-info "2001:b00b:1e5:0:0:0:0:1/64")
Address: 2001:b00b:1e5:0:0:0:0:1
Netmask: FFFF:FFFF:FFFF:FFFF::
Broadcast: 2001:B00B:1E5:0:FFFF:FFFF:FFFF:FFFF
Network: 2001:B00B:1E5::
NIL
CL-USER>
```

(iprange-to-cidr) is a function accepts an IP range (lower IP and
upper IP) and returns the smallest possible set of CIDR blocks that
represent that range:

```
CL-USER> (iprange-to-cidr "10.11.12.13" "10.12.13.14")
("10.12.13.14/32" "10.12.13.12/31" "10.12.13.8/30" "10.12.13.0/29"
 "10.12.12.0/24" "10.12.8.0/22" "10.12.0.0/21" "10.11.128.0/17" "10.11.64.0/18"
 "10.11.32.0/19" "10.11.16.0/20" "10.11.14.0/23" "10.11.13.0/24"
 "10.11.12.128/25" "10.11.12.64/26" "10.11.12.32/27" "10.11.12.16/28"
 "10.11.12.14/31" "10.11.12.13/32")
CL-USER>
```

(same-ip-network?) takes three parameters (or two, if CIDR notation is used):  address one, address two, and a netmask (if not specified in CIDR notation in one of the first two arguments). Note that if argument one specifies a netmask, that is used. Else the netmask in argument two, else the explicitly supplied netmask. This function returns t if both addresses are part of the same network, else nil. Example:

```
CL-USER> (ipcalc:same-ip-network? "10.1.1.1/24" "10.2.2.1/24")
NIL
CL-USER>
```

(multicast-addr?) only works for IPv4 (as multicast is handled differently in IPv6) and returns t if the supplied address is an IPv4 multicast address or nil if the address is either an IPv6 address or a non-multicast IPv4 address.

(cidr-to-ipv4-netmask) and (cidr-to-ipv6-netmask) both accept a single integer as an argument and return a string of the full netmask representation. Example:

```
CL-USER> (ipcalc:cidr-to-ipv4-netmask 24)
"255.255.255.0"
CL-USER> (ipcalc:cidr-to-ipv6-netmask 64)
"FFFF:FFFF:FFFF:FFFF::"
CL-USER>
```

(proto-num-to-name) Converts a integer representing an IP protocol
number into it's English name:

```
CL-USER> (ipcalc:proto-num-to-name 6)
"tcp"
CL-USER> 
```

(name-to-proto-num) Converts a (case-insensitive) string containing
the English name of a protocol into the corresponding protocol number
(or nil if invalid/unknown):

```
CL-USER> (ipcalc:name-to-proto-num "TCP")
6
CL-USER> 
```

(iana-tcp-service-name) and (iana-udp-service-name) return the IANA
assigned name (or sometimes the de-facto name) of a service
represented by the integer port value supplied. If an optional flag is
t, it also includes an English string for port/proto:

```
CL-USER> (ipcalc:iana-tcp-service-name 22)
"ssh"
CL-USER> (ipcalc:iana-tcp-service-name 22 t)
"22/tcp (ssh)"
CL-USER> (ipcalc:iana-tcp-service-name 999)
NIL
CL-USER> (ipcalc:iana-tcp-service-name 999 t)
"999/tcp (unknown)"
CL-USER>
```



## ToDo
* Return a list of usable addresses in a given subnet
* RFC6052 conversion (embedding IPv4 addresses in IPv6)
