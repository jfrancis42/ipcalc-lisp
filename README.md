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
603053633991302184961
CL-USER> (ipcalc:ip-to-int "10.1.0.42")
167837738
CL-USER> (ipcalc:int-to-ipv6 603053633991302184961)
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

## ToDo
* Convert IPv4 address to integer
* Convert integer to IPv4 address
* Convert IPv6 address to integer
* Convert integer to IPv6 address
* Return a list of usable addresses in a given subnet
* RFC6052 conversion (embedding IPv4 addresses in IPv6)
