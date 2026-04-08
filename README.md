# ipcalc-lisp
A Common Lisp library for manipulating and calculating IPv4 and IPv6
network addresses.

## Functions

### Address Type Detection

* `(is-it-ipv4? addr)` — Returns t if addr contains a dot (IPv4 heuristic)
* `(is-it-ipv6? addr)` — Returns t if addr contains a colon (IPv6 heuristic)

### Address Parsing & Conversion

* `(parse-address addr netmask)` — Parse address with netmask in multiple formats; returns `(address expanded-netmask)`
* `(ip-to-int addr)` — Convert IP address string to integer (IPv4 or IPv6)
* `(int-to-ipv4 num)` — Convert integer to IPv4 dotted-quad string
* `(int-to-ipv6 num)` — Convert integer to compressed IPv6 string

### IPv6 Normalization

* `(ipv6-addr-expand addr)` — Expand compressed IPv6 address to full form
* `(ipv6-addr-compress addr)` — Compress IPv6 address to canonical form (RFC 5952)

```
CL-USER> (ipcalc:ipv6-addr-compress "2001:b00b:1e5:0:0:0:0:1")
"2001:B00B:1E5::1"
CL-USER> (ipcalc:ipv6-addr-expand "2001:B00B:1E5::1")
"2001:B00B:1E5:0:0:0:0:1"
```

### Network Calculations

* `(calc-network-addr addr &key netmask show-mask cidr-mask)` — Calculate network address
* `(calc-broadcast-addr addr &optional netmask)` — Calculate broadcast address
* `(ip-info addr &optional netmask)` — Print address, netmask, broadcast, and network address
* `(cidr-to-ipv4-netmask cidr)` — Convert integer CIDR prefix to IPv4 dotted-quad netmask
* `(cidr-to-ipv6-netmask cidr)` — Convert integer CIDR prefix to IPv6 netmask string
* `(netmask-to-cidr mask)` — Convert netmask string to CIDR prefix length integer

```
CL-USER> (ipcalc:calc-network-addr "10.11.12.13/19")
"10.11.0.0"
CL-USER> (ipcalc:calc-broadcast-addr "10.11.12.13/19")
"10.11.31.255"
CL-USER> (ipcalc:cidr-to-ipv4-netmask 24)
"255.255.255.0"
CL-USER> (ipcalc:netmask-to-cidr "255.255.255.0")
24
CL-USER> (ipcalc:cidr-to-ipv6-netmask 64)
"FFFF:FFFF:FFFF:FFFF::"
```

Functions that require both an address and netmask accept them in multiple
forms. Each of the following calculates the network address for 10.1.0.42/24:

```
(calc-network-addr "10.1.0.42/24")
(calc-network-addr "10.1.0.42/255.255.255.0")
(calc-network-addr "10.1.0.42" :netmask "24")
(calc-network-addr "10.1.0.42" :netmask "255.255.255.0")
```

### Network Size & Host Ranges

* `(network-size addr &optional netmask)` — Total number of addresses in a network (2^host_bits)
* `(usable-host-count addr &optional netmask)` — Usable host count (IPv4: network-size - 2; IPv6: network-size)
* `(first-host addr &optional netmask)` — First usable host address (network addr + 1 for IPv4)
* `(last-host addr &optional netmask)` — Last usable host address (broadcast - 1 for IPv4)

```
CL-USER> (ipcalc:network-size "10.0.0.0/24")
256
CL-USER> (ipcalc:usable-host-count "10.0.0.0/24")
254
CL-USER> (ipcalc:first-host "10.0.0.0/24")
"10.0.0.1"
CL-USER> (ipcalc:last-host "10.0.0.0/24")
"10.0.0.254"
```

### Network Membership & Relationships

* `(ip-in-network? ip network &optional netmask)` — Return t if ip falls within the given network
* `(same-ip-network? addr1 addr2 &optional netmask)` — Return t if two addresses are in the same network
* `(networks-overlap? net1 net2)` — Return t if two networks share any addresses
* `(network-contains-network? outer inner)` — Return t if outer wholly contains inner
* `(supernet addr &optional netmask)` — Return the next larger enclosing network as a CIDR string
* `(split-network addr new-prefix &optional netmask)` — Split a network into subnets of new-prefix length
* `(collapse-networks networks)` — Given a list of CIDR strings, return the minimal equivalent set

```
CL-USER> (ipcalc:ip-in-network? "10.0.5.1" "10.0.0.0/8")
T
CL-USER> (ipcalc:ip-in-network? "192.168.1.1" "10.0.0.0/8")
NIL
CL-USER> (ipcalc:networks-overlap? "10.0.0.0/23" "10.0.1.0/24")
T
CL-USER> (ipcalc:network-contains-network? "10.0.0.0/8" "10.1.2.0/24")
T
CL-USER> (ipcalc:supernet "192.168.1.0/24")
"192.168.0.0/23"
CL-USER> (ipcalc:split-network "10.0.0.0/24" 25)
("10.0.0.0/25" "10.0.0.128/25")
CL-USER> (ipcalc:collapse-networks '("10.0.0.0/25" "10.0.0.128/25" "192.168.1.0/24"))
("10.0.0.0/24" "192.168.1.0/24")
```

### CIDR / Range Conversion

* `(iprange-to-cidr ip-start ip-end)` — Convert IP range to smallest set of CIDR blocks
* `(cidr-to-iprange cidr)` — Convert CIDR block to `(start-int . end-int)` cons

```
CL-USER> (ipcalc:iprange-to-cidr "10.11.12.13" "10.12.13.14")
("10.12.13.14/32" "10.12.13.12/31" ...)
```

### Address Classification

* `(rfc1918-addr? ip)` — Return t if IPv4 address is in RFC 1918 private space
* `(multicast-addr? ip)` — Return t if address is multicast (224.0.0.0/4 IPv4, ff00::/8 IPv6)
* `(loopback-addr? ip)` — Return t if address is loopback (127.0.0.0/8 IPv4, ::1 IPv6)
* `(link-local-addr? ip)` — Return t if address is link-local (169.254.0.0/16 IPv4, fe80::/10 IPv6)
* `(unspecified-addr? ip)` — Return t if address is the unspecified address (0.0.0.0 or ::)
* `(unique-local-addr? ip)` — Return t if IPv6 address is unique local (fc00::/7, the IPv6 RFC 1918 equivalent)

```
CL-USER> (ipcalc:loopback-addr? "127.0.0.1")
T
CL-USER> (ipcalc:loopback-addr? "::1")
T
CL-USER> (ipcalc:link-local-addr? "169.254.1.1")
T
CL-USER> (ipcalc:link-local-addr? "fe80::1")
T
CL-USER> (ipcalc:multicast-addr? "ff02::1")
T
CL-USER> (ipcalc:unique-local-addr? "fd12:3456::1")
T
```

### Netmask Utilities

* `(valid-netmask? mask)` — Return t if string is a valid netmask (contiguous 1-bits then 0-bits)
* `(wildcard-mask addr &optional netmask)` — Return the wildcard (inverse/Cisco ACL) mask

```
CL-USER> (ipcalc:valid-netmask? "255.255.255.0")
T
CL-USER> (ipcalc:valid-netmask? "255.255.254.1")
NIL
CL-USER> (ipcalc:wildcard-mask "10.0.0.0/24")
"0.0.0.255"
CL-USER> (ipcalc:wildcard-mask "255.255.255.0")
"0.0.0.255"
```

### Reverse DNS

* `(reverse-dns-ptr ip)` — Return the PTR record name for an IP address

```
CL-USER> (ipcalc:reverse-dns-ptr "192.168.1.1")
"1.1.168.192.in-addr.arpa"
CL-USER> (ipcalc:reverse-dns-ptr "2001:db8::1")
"1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.8.b.d.0.1.0.0.2.ip6.arpa"
```

### Integer Conversion

```
CL-USER> (ipcalc:ip-to-int "2001:b00b:1e5::1")
42544058738162202133965779820242534401
CL-USER> (ipcalc:ip-to-int "10.1.0.42")
167837738
CL-USER> (ipcalc:int-to-ipv6 42544058738162202133965779820242534401)
"2001:B00B:1E5::1"
```

### Protocol & Service Name Lookup

* `(proto-num-to-name num)` — Convert protocol number to name (e.g., 6 → "tcp")
* `(name-to-proto-num name)` — Convert protocol name to number (case-insensitive)
* `(iana-tcp-service-name port &optional formatted)` — IANA TCP service name for a port
* `(iana-udp-service-name port &optional formatted)` — IANA UDP service name for a port
* `(iana-port-name port proto)` — Unified service lookup by port and protocol number

```
CL-USER> (ipcalc:proto-num-to-name 6)
"tcp"
CL-USER> (ipcalc:name-to-proto-num "TCP")
6
CL-USER> (ipcalc:iana-tcp-service-name 22)
"ssh"
CL-USER> (ipcalc:iana-tcp-service-name 22 t)
"22/tcp (ssh)"
CL-USER> (ipcalc:iana-tcp-service-name 999 t)
"999/tcp (unknown)"
```

## Notes

* `collapse-networks` is currently IPv4 only.
* `unique-local-addr?` returns nil for IPv4 (no equivalent concept).
* `(is-it-ipv4?)` and `(is-it-ipv6?)` use simple string heuristics (presence of `.` or `:`), not strict validation.
