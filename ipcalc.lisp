;;;; ipcalc.lisp

(in-package #:ipcalc)

(defvar iana-tcp (make-hash-table :test #'equal))
(defvar iana-udp (make-hash-table :test #'equal))
(defvar *pname-list* '("hopopt" "icmp" "igmp" "ggp" "ip-in-ip" "st" "tcp" "cbt" "egp" "igp" "bbn-rcc-mon" 
		       "nvp-ii" "pup" "argus" "emcon" "xnet" "chaos" "udp" "mux" "dcn-meas" "hmp" "prm" 
		       "xns-idp" "trunk-1" "trunk-2" "leaf-1" "leaf-2" "rdp" "irtp" "iso-tp4" "netblt" 
		       "mfe-nsp" "merit-inp" "dccp" "3pc" "idpr" "xtp" "ddp" "idpr-cmtp" "tp++" "il" "ipv6" 
		       "sdrp" "ipv6-route" "ipv6-frag" "idrp" "rsvp" "gre" "mhrp" "bna" "esp" "ah" "i-nlsp"
		       "swipe" "narp" "mobile" "tlsp" "skip" "ipv6-icmp" "ipv6-nonxt" "ipv6-opts" "any" 
		       "cftp" "any" "sat-expak" "kryptolan" "rvd" "ippc" "any" "sat-mon" "visa" "ipcu" "cpnx" 
		       "cphb" "wsn" "pvp" "br-sat-mon" "sun-nd" "wb-mon" "wb-expak" "iso-ip" "vmtp" 
		       "secure-vmtp" "vines" "iptm" "nsfnet-igp" "dgp" "tcf" "eigrp" "ospf" "sprite-rpc" 
		       "larp" "mtp" "ax.25" "ipip" "micp" "scc-sp" "etherip" "encap" "any" "gmtp" "ifmp"
		       "pnni" "pim" "aris" "scps" "qnx" "a/n" "ipcomp" "snp" "compaq-peer" "ipx-in-ip" "vrrp" 
		       "pgm" "any" "l2tp" "ddx" "iatp" "stp" "srp" "uti" "smp" "sm" "ptp" "is-is" "fire" 
		       "crtp" "crudp" "sscopmce" "iplt" "sps" "pipe" "sctp" "fc" "rsvp-e2e-ignore" 
		       "mobility" "udplite" "mpls-in-ip" "manet" "hip" "shim6" "wesp" "rohc"))

(defun proto-num-to-name (num)
  "Given a protocol number, return a string containing it's English
name (lowercase)."
  (nth num *pname-list*))

(defun name-to-proto-num (proto-name)
  "Given a string containing an English protocol name, return it's
number (or nil)."
  (let* ((name (string-downcase proto-name))
	 (which (member name *pname-list* :test #'equal)))
    (if which
	(- (length *pname-list*) (length which))
	nil)))

(defun ip-or (a b) (if (or (equal a 1) (equal b 1)) 1 0))
(defun ip-not (n) (if (equal n 0) 1 0))
(defun ip-and (a b) (logand a b))

; todo: use jeffutils (join)
(defun join (stuff separator)
  "Join a list of strings with a separator (like ruby string.join())."
  (with-output-to-string (out)
    (loop (princ (pop stuff) out)
       (unless stuff (return))
       (princ separator out))))

(defun parse-address (addr netmask)
  "Pass an address and a netmask, and this function will figure out if
the address is just an address, or an address/CIDR, and passes back a
list consisting of a separate address and netmask (in fully-expanded
form) as the first and second elements."
  (if (search "/" addr)
      (let ((pieces (split-sequence:split-sequence #\/ addr)))
	(list (first pieces)
	      (if (is-it-ipv4? addr)
		  (cidr-to-ipv4-netmask
		   (parse-integer (second pieces)))
		  (cidr-to-ipv6-netmask
		   (parse-integer (second pieces))))))
      (list addr
	    (cond
	      ((is-it-ipv4? netmask)
	       netmask)
	      ((is-it-ipv6? netmask)
	       netmask)
	      ((null netmask)
	       nil)
	      ((is-it-ipv4? addr)
	       (cidr-to-ipv4-netmask (parse-integer netmask)))
	      ((is-it-ipv6? addr)
	       (cidr-to-ipv6-netmask (parse-integer netmask)))))))	

(defun bin-to-dec (lst)
  "Convert a list of binary digits into a number."
  (reduce (lambda (x y) (+ (* x 2) y)) lst))

(defun bin-to-ipv4-string (n)
  "Convert a list of binary digits into a dotted quad IPv4 string."
  (concatenate 'string
	       (format nil "~A" (bin-to-dec (subseq n 0 8))) "."
	       (format nil "~A" (bin-to-dec (subseq n 8 16))) "."
	       (format nil "~A" (bin-to-dec (subseq n 16 24))) "."
	       (format nil "~A" (bin-to-dec (subseq n 24 32)))))

(defun bin-to-ipv6-full-string (n)
  "Convert a list of binary digits into an IPv6 string."
  (string-downcase
   (concatenate 'string
		(format nil "~4,'0X"
			(bin-to-dec (subseq n 0 16))) ":"
			(format nil "~4,'0X" (bin-to-dec (subseq n 16 32))) ":"
			(format nil "~4,'0X" (bin-to-dec (subseq n 32 48))) ":"
			(format nil "~4,'0X" (bin-to-dec (subseq n 48 64))) ":"
			(format nil "~4,'0X" (bin-to-dec (subseq n 64 80))) ":"
			(format nil "~4,'0X" (bin-to-dec (subseq n 80 96))) ":"
			(format nil "~4,'0X" (bin-to-dec (subseq n 96 112))) ":"
			(format nil "~4,'0X" (bin-to-dec (subseq n 112 128)))
		)))

(defun bin-to-ipv6-string (n)
  "Convert a list of binary digits into an IPv6 string."
  (string-downcase
   (concatenate 'string
		(format nil "~X" (bin-to-dec (subseq n 0 16))) ":"
		(format nil "~X" (bin-to-dec (subseq n 16 32))) ":"
		(format nil "~X" (bin-to-dec (subseq n 32 48))) ":"
		(format nil "~X" (bin-to-dec (subseq n 48 64))) ":"
		(format nil "~X" (bin-to-dec (subseq n 64 80))) ":"
		(format nil "~X" (bin-to-dec (subseq n 80 96))) ":"
		(format nil "~X" (bin-to-dec (subseq n 96 112))) ":"
		(format nil "~X" (bin-to-dec (subseq n 112 128)))
		)))

(defun binary-list (n &optional acc)
  "Helper function for int-to-binary."
  (assert (>= n 0))
  (multiple-value-bind (q r) (floor n 2)
    (if (zerop q)
	(cons r acc)
	(binary-list q (cons r acc)))))

(defun int-to-binary (my-int desired-length)
  "Convert an int into a list of binary digits padded with zeros to
length 'desired-length'."
  (let* ((bits (binary-list my-int))
	 (current-length (length bits)))
    (concatenate 'list
		 (make-list
		  (- desired-length current-length) :initial-element 0) bits)))

(defun ipv6-addr-expand (addr)
  "Expand a compressed IPv6 address."
  (if (not (search "::" addr))
      addr
      (let* ((nums (split-sequence:split-sequence #\: addr))
	     (len (length nums))
	     (missing (position "" nums :test #'equal)))
	(when (eq 3 len)
	  (setf (first nums) "0")
	  (setf missing 1))
	(when (< len 8)
	    (progn
	      (setf (nth missing nums) (make-list (- 9 len) :initial-element "0"))
	      (let ((almost (join (alexandria:flatten nums) ":")))
		(if (equal ":" (subseq almost (- (length almost) 1)))
		    (concatenate 'string almost "0")
		    almost)))))))

(defun ipv6-to-int (addr)
  "Convert the string representation of an IPv6 address (or netmask)
to a an integer."
  (let ((nums (map 'list (lambda (n) (parse-integer n :radix 16))
		   (split-sequence:split-sequence #\: (ipv6-addr-expand (subseq addr 0 (search "/" addr)))))))
    (+
     (nth 7 nums)
     (* (expt 2 16) (nth 6 nums))
     (* (expt 2 32) (nth 5 nums))
     (* (expt 2 48) (nth 4 nums))
     (* (expt 2 64) (nth 3 nums))
     (* (expt 2 80) (nth 2 nums))
     (* (expt 2 96) (nth 1 nums))
     (* (expt 2 112) (nth 0 nums)))))

(defun int-to-ipv6 (num)
  "Convert an integer into a compressed IPv6 address string. Yes, this
could be re-written much mo' betta, but for the moment, it works."
  (let* ((one (truncate (* 1.0 (/ num (expt 2 112)))))
	 (one-c (* one (expt 2 112)))
	 (two (truncate (* 1.0 (/ (- num one-c) (expt 2 96)))))
	 (two-c (* two (expt 2 96)))
	 (three (truncate (* 1.0 (/ (- num one-c two-c) (expt 2 80)))))
	 (three-c (* three (expt 2 80)))
	 (four (truncate (* 1.0 (/ (- num one-c two-c three-c) (expt 2 64)))))
	 (four-c (* four (expt 2 64)))
	 (five (truncate (* 1.0 (/ (- num one-c two-c three-c four-c)
				   (expt 2 48)))))
	 (five-c (* five (expt 2 48)))
	 (six (truncate (* 1.0 (/ (- num one-c two-c three-c four-c five-c)
				  (expt 2 32)))))
	 (six-c (* six (expt 2 32)))
	 (seven (truncate (* 1.0 (/ (- num one-c two-c three-c four-c five-c six-c)
				    (expt 2 16)))))
	 (seven-c (* seven (expt 2 16)))
	 (eight (- num one-c two-c three-c four-c five-c six-c seven-c)))
    (ipv6-addr-compress
     (format nil "~4,'0X:~4,'0X:~4,'0X:~4,'0X:~4,'0X:~4,'0X:~4,'0X:~4,'0X"
	     one two three four five six seven eight))))

(defun ipv6-to-bin (addr)
  "Convert the string representation of a fully-expanded IPv6
address (or netmask) to a list of binary digits."
  (let ((nums (map 'list (lambda (n) (parse-integer n :radix 16))
		   (split-sequence:split-sequence #\: (ipv6-addr-expand addr)))))
    (concatenate 'list
		 (int-to-binary (nth 0 nums) 16)
		 (int-to-binary (nth 1 nums) 16)
		 (int-to-binary (nth 2 nums) 16)
		 (int-to-binary (nth 3 nums) 16)
		 (int-to-binary (nth 4 nums) 16)
		 (int-to-binary (nth 5 nums) 16)
		 (int-to-binary (nth 6 nums) 16)
		 (int-to-binary (nth 7 nums) 16))))

(defun ipv6-addr-compress-helper (seq)
  "The recusive part of ipv6-addr-compress."
  (let ((n nil)
	(l (length seq)))
    (setf n
	  (loop for y from 0 to (- (length seq) 2)
	     collect
	       (if (and
		    (not (equal 0 (nth y seq)))
		    (not (equal 0 (nth (+ y 1) seq))))
		   t
		   nil)))
    (let ((m (position t n)))
      (if m
	  (setf (subseq seq m (+ m 2)) (list (+ (nth m seq) (nth (+ m 1) seq)) nil)))
      (setf seq (remove nil seq)))
    (if (equal l (length seq))
	seq
	(ipv6-addr-compress-helper seq))))

(defun ipv6-addr-compress (addr)
  "Compress a fully-specified IPv6 address down to it's canonical
form."
  (setf addr (ipv6-addr-expand addr))
  (let* ((zeros
	  (map 'list
	       (lambda (n)
		 (if (equal n "0") 1 0))
	       (split-sequence:split-sequence
		#\:
		(bin-to-ipv6-string (ipv6-to-bin addr)))))
	 (sequences (ipv6-addr-compress-helper (copy-list zeros)))
	 (addr-parts
	  (map 'list
	       (lambda (n)
		 (format nil "~X"
			 (parse-integer n :radix 16)))
	       (split-sequence:split-sequence #\: addr)))
	 (rep-length (first (sort (copy-list sequences) #'>)))
	 (rep-pos (position rep-length sequences))
	 (end-pos (+ rep-pos rep-length))
	 (almost
	  (cl-ppcre::regex-replace
	   ":$"
	   (cl-ppcre::regex-replace
	    "::+" 
	    (apply #'concatenate 'string
		   (map 'list (lambda (n) (format nil "~A:" n))
			(loop for y from 0 to 7
			   collect
			     (if (and (>= y rep-pos)
				      (< y end-pos)
				      (> rep-length 1))
				 ":"
				 (nth y addr-parts)))))
	    "::") "")))
    (if (and (equal ":" (subseq almost (- (length almost) 1)))
	     (not (equal "::" (subseq almost (- (length almost) 2)))))
	(concatenate 'string almost ":")
	almost)))

(defun bin-to-ip-string (n)
  "Convert a list of binary digits to a dotted quad. IPv6 if it's 128
bits, else IPv4."
  (if (equal 128 (length n))
      (ipv6-addr-compress (bin-to-ipv6-string n))
      (bin-to-ipv4-string n)))

(defun cidr-to-ipv4-netmask (cidr)
  "Convert a CIDR (slash) notation into a list of binary digits."
  (bin-to-ip-string
   (concatenate 'list
		(make-list cidr :initial-element 1)
		(make-list (- 32 cidr) :initial-element 0))))

(defun cidr-to-ipv6-netmask (cidr)
  "Convert a CIDR (slash) notation into a list of binary digits."
  (bin-to-ip-string
   (concatenate 'list
		(make-list cidr :initial-element 1)
		(make-list (- 128 cidr) :initial-element 0))))

(defun is-it-ipv6? (addr)
  "Returns t if there's a colon in the string, else nil."
  (if (position #\: addr)
      t
      nil))

(defun is-it-ipv4? (addr)
  "Returns t if there's a . in the string, else nil."
  (if (position #\. addr)
      t
      nil))

(defun ipv4-to-int (addr)
  "Convert the string representation of an IPv4 address (or netmask)
to a an integer."
  (let ((nums (map 'list (lambda (n) (parse-integer n))
		   (split-sequence:split-sequence #\. (subseq addr 0 (search "/" addr))))))
    (+
     (nth 3 nums)
     (* (expt 2 8) (nth 2 nums))
     (* (expt 2 16) (nth 1 nums))
     (* (expt 2 24) (nth 0 nums)))))

(defun int-to-ipv4 (num)
  "Convert an integer into an IPv4 address string. Probably not
portable. XXX"
  (format nil "~A.~A.~A.~A"
	  (ldb (byte 8 24) num)
	  (ldb (byte 8 16) num)
	  (ldb (byte 8 8) num)
	  (ldb (byte 8 0) num)))

(defun ipv4-to-bin (addr)
  "Convert the string representation of an IPv4 address (or netmask) in
dotted-quad format to a list of binary digits."
  (let ((nums (map 'list (lambda (n) (parse-integer n))
		   (split-sequence:split-sequence #\. addr))))
    (concatenate 'list
		 (int-to-binary (nth 0 nums) 8) (int-to-binary (nth 1 nums) 8)
		 (int-to-binary (nth 2 nums) 8) (int-to-binary (nth 3 nums) 8))))

(defun ip-to-int (addr)
  "Convert the string representation of an IP address to an int."
  (if (is-it-ipv6? addr)
      (ipv6-to-int addr)
      (ipv4-to-int addr)))

(defun ip-to-bin (addr)
  "Convert the string representation of an IP address to binary
digits."
  (if (is-it-ipv6? addr)
      (ipv6-to-bin addr)
      (ipv4-to-bin addr)))

(defun ip-network (addr netmask)
  "Supplied an address and netmask in binary format, return the
network part of an address as a list of binary digits."
  (loop for x in addr for y in netmask collect (ip-and x y)))

(defun ip-broadcast (addr netmask)
  "Supplied an address and netmask in binary format, return the
broadcast address as a list of binary digits."
  (loop
     for x in netmask
     for y in (ip-network addr netmask)
     collect (ip-or y (ip-not x))))

(defun calc-network-addr (addr &key netmask show-mask cidr-mask)
  "Given an IP address and a netmask, calculate the network address."
  (let* ((tmp (parse-address addr netmask))
	 (addr (first tmp))
	 (netmask (second tmp)))
    (cond
      ((null netmask)
       nil)
      (show-mask
       (concatenate 'string
		    (bin-to-ip-string
		     (ip-network (ip-to-bin addr) (ip-to-bin netmask)))
		    "/" netmask))
      (cidr-mask
       (concatenate 'string
		    (bin-to-ip-string
		     (ip-network (ip-to-bin addr) (ip-to-bin netmask)))
		    "/" (format nil "~A" (length (remove 0 (ipv4-to-bin netmask))))))
      (t
       (bin-to-ip-string
	(ip-network (ip-to-bin addr) (ip-to-bin netmask)))))))

(defun calc-broadcast-addr (addr &optional netmask)
  "Given an IP address and a netmask, calculate the broadcast
address."
  (let* ((tmp (parse-address addr netmask))
	 (addr (first tmp))
	 (netmask (second tmp)))
    (bin-to-ip-string (ip-broadcast (ip-to-bin addr) (ip-to-bin netmask)))))

(defun ip-info (addr &optional netmask)
  "Given an IP address and a netmask, show me the network and the
broadcast addresses."
  (let* ((tmp (parse-address addr netmask))
	 (addr (first tmp))
	 (netmask (second tmp)))
    (format t "Address: ~A~%Netmask: ~A~%Broadcast: ~A~%Network: ~A~%"
	    addr netmask
	    (calc-broadcast-addr addr netmask)
	    (calc-network-addr addr :netmask netmask))))

(defun same-ip-network? (addr1 addr2 &optional netmask)
  "Given two IP addresses and a netmask as dotted quad strings, tell
me if both IP addresses are part of the same network."
  (let* ((tmp1 (parse-address addr1 netmask))
	 (addr1 (first tmp1))
	 (netmask1 (second tmp1))
	 (tmp2 (parse-address addr2 netmask))
	 (addr2 (first tmp2))
	 (netmask2 (second tmp2)))
    (if (not netmask)
	(progn 
	  (if netmask1 (setf netmask netmask1))
	  (if netmask2 (setf netmask netmask2))))
    (if (equal
	 (ip-network (ip-to-bin addr1) (ip-to-bin netmask))
	 (ip-network (ip-to-bin addr2) (ip-to-bin netmask)))
	t
	nil)))

(defun rfc1918-addr? (ip)
  "Is this IP address in RFC 1918 address space?"
  (or (same-ip-network? ip "10.0.0.0" "255.0.0.0")
      (same-ip-network? ip "172.16.0.0" "255.240.0.0")
      (same-ip-network? ip "192.168.0.0" "255.255.0.0")))

(defun multicast-addr? (ip)
  "Given a dotted quad string IP address, tell me if it's a multicast
address or not. (currently only works for IPv4)."
  (if (is-it-ipv6? ip)
      nil
      (if (same-ip-network? ip "224.0.0.0" (cidr-to-ipv4-netmask 4))
	  t
	  nil)))

(defun iprange-to-cidr (ip-start ip-end)
  "Given a range of IP addresses, return the smallest possible number
of CIDR blocks that represent that range."
  (let ((start-r (ip-to-int ip-start))
	(end-r (ip-to-int ip-end))
	(x 0) (ip 0) (result nil) (max-size 0)
	(mask 0) (max-diff 0) (mask-base))
    (loop while (>= end-r start-r)
       do
	 (setf max-size 32)
	 (loop while (> max-size 0)
	    do
	      (setf mask (- (expt 2 32) (expt 2 (- 32 (- max-size 1)))))
	      (setf mask-base (logand start-r mask))
	      (unless (= mask-base start-r)
		(return))
	      (decf max-size))
	 (setf x (/ (log (+ 1 (- end-r start-r))) (log 2)))
	 (setf max-diff (floor (- 32 (floor x))))
	 (when (< max-size max-diff)
	   (setf max-size max-diff) )
	 (setf ip (int-to-ipv4 start-r))
	 (push (cons ip max-size) result)
	 (setf start-r (+ start-r (expt 2 (- 32 max-size)))))
    (mapcar
     (lambda (ipr)
       (format nil "~A/~A" (car ipr) (cdr ipr)))
     result)))

(defun iana-tcp-service-name (n &optional port)
  "Returns the IANA TCP service name for the integer port specified."
  (let ((name (gethash n iana-tcp)))
    (if name
	(if port (format nil "~A/tcp (~A)" n name) name)
	(if port (format nil "~A/tcp (unknown)" n)))))

(defun iana-udp-service-name (n &optional port)
  "Returns the IANA UDP service name for the integer port specified."
  (let ((name (gethash n iana-udp)))
    (if name
	(if port (format nil "~A/udp (~A)" n name) name)
	(if port (format nil "~A/udp (unknown)" n)))))

(defun iana-port-name (port proto)
  "Given a port and protocol, return the common name."
  (cond
    ((equal proto 6)
     (iana-tcp-service-name port t))
    ((equal proto 17)
     (iana-udp-service-name port t))
    (t
     (format nil "~A/~A" port (proto-num-to-name proto)))))
  
(setf (gethash 1 iana-tcp) "tcpmux")
(setf (gethash 7 iana-tcp) "echo")
(setf (gethash 7 iana-udp) "echo")
(setf (gethash 9 iana-tcp) "discard")
(setf (gethash 9 iana-udp) "discard")
(setf (gethash 11 iana-tcp) "systat")
(setf (gethash 13 iana-tcp) "daytime")
(setf (gethash 13 iana-udp) "daytime")
(setf (gethash 15 iana-tcp) "netstat")
(setf (gethash 17 iana-tcp) "qotd")
(setf (gethash 18 iana-tcp) "msp")
(setf (gethash 18 iana-udp) "msp")
(setf (gethash 19 iana-tcp) "chargen")
(setf (gethash 19 iana-udp) "chargen")
(setf (gethash 20 iana-tcp) "ftp-data")
(setf (gethash 21 iana-tcp) "ftp")
(setf (gethash 21 iana-udp) "fsp")
(setf (gethash 22 iana-tcp) "ssh")
(setf (gethash 22 iana-udp) "ssh")
(setf (gethash 23 iana-tcp) "telnet")
(setf (gethash 25 iana-tcp) "smtp")
(setf (gethash 37 iana-tcp) "time")
(setf (gethash 37 iana-udp) "time")
(setf (gethash 39 iana-udp) "rlp")
(setf (gethash 42 iana-tcp) "nameserver")
(setf (gethash 43 iana-tcp) "whois")
(setf (gethash 49 iana-tcp) "tacacs")
(setf (gethash 49 iana-udp) "tacacs")
(setf (gethash 50 iana-tcp) "re-mail-ck")
(setf (gethash 50 iana-udp) "re-mail-ck")
(setf (gethash 53 iana-tcp) "domain")
(setf (gethash 53 iana-udp) "domain")
(setf (gethash 57 iana-tcp) "mtp")
(setf (gethash 65 iana-tcp) "tacacs-ds")
(setf (gethash 65 iana-udp) "tacacs-ds")
(setf (gethash 67 iana-tcp) "bootps")
(setf (gethash 67 iana-udp) "bootps")
(setf (gethash 68 iana-tcp) "bootpc")
(setf (gethash 68 iana-udp) "bootpc")
(setf (gethash 69 iana-udp) "tftp")
(setf (gethash 70 iana-tcp) "gopher")
(setf (gethash 70 iana-udp) "gopher")
(setf (gethash 77 iana-tcp) "rje")
(setf (gethash 79 iana-tcp) "finger")
(setf (gethash 80 iana-tcp) "http")
(setf (gethash 80 iana-udp) "http")
(setf (gethash 87 iana-tcp) "link")
(setf (gethash 88 iana-tcp) "kerberos")
(setf (gethash 88 iana-udp) "kerberos")
(setf (gethash 95 iana-tcp) "supdup")
(setf (gethash 101 iana-tcp) "hostnames")
(setf (gethash 102 iana-tcp) "iso-tsap")
(setf (gethash 104 iana-tcp) "acr-nema")
(setf (gethash 104 iana-udp) "acr-nema")
(setf (gethash 105 iana-tcp) "csnet-ns")
(setf (gethash 105 iana-udp) "csnet-ns")
(setf (gethash 107 iana-tcp) "rtelnet")
(setf (gethash 107 iana-udp) "rtelnet")
(setf (gethash 109 iana-tcp) "pop2")
(setf (gethash 109 iana-udp) "pop2")
(setf (gethash 110 iana-tcp) "pop3")
(setf (gethash 110 iana-udp) "pop3")
(setf (gethash 111 iana-tcp) "sunrpc")
(setf (gethash 111 iana-udp) "sunrpc")
(setf (gethash 113 iana-tcp) "auth")
(setf (gethash 115 iana-tcp) "sftp")
(setf (gethash 117 iana-tcp) "uucp-path")
(setf (gethash 119 iana-tcp) "nntp")
(setf (gethash 123 iana-tcp) "ntp")
(setf (gethash 123 iana-udp) "ntp")
(setf (gethash 129 iana-tcp) "pwdgen")
(setf (gethash 129 iana-udp) "pwdgen")
(setf (gethash 135 iana-tcp) "loc-srv")
(setf (gethash 135 iana-udp) "loc-srv")
(setf (gethash 137 iana-tcp) "netbios-ns")
(setf (gethash 137 iana-udp) "netbios-ns")
(setf (gethash 138 iana-tcp) "netbios-dgm")
(setf (gethash 138 iana-udp) "netbios-dgm")
(setf (gethash 139 iana-tcp) "netbios-ssn")
(setf (gethash 139 iana-udp) "netbios-ssn")
(setf (gethash 143 iana-tcp) "imap2")
(setf (gethash 143 iana-udp) "imap2")
(setf (gethash 161 iana-tcp) "snmp")
(setf (gethash 161 iana-udp) "snmp")
(setf (gethash 162 iana-tcp) "snmp-trap")
(setf (gethash 162 iana-udp) "snmp-trap")
(setf (gethash 163 iana-tcp) "cmip-man")
(setf (gethash 163 iana-udp) "cmip-man")
(setf (gethash 164 iana-tcp) "cmip-agent")
(setf (gethash 164 iana-udp) "cmip-agent")
(setf (gethash 174 iana-tcp) "mailq")
(setf (gethash 174 iana-udp) "mailq")
(setf (gethash 177 iana-tcp) "xdmcp")
(setf (gethash 177 iana-udp) "xdmcp")
(setf (gethash 178 iana-tcp) "nextstep")
(setf (gethash 178 iana-udp) "nextstep")
(setf (gethash 179 iana-tcp) "bgp")
(setf (gethash 179 iana-udp) "bgp")
(setf (gethash 191 iana-tcp) "prospero")
(setf (gethash 191 iana-udp) "prospero")
(setf (gethash 194 iana-tcp) "irc")
(setf (gethash 194 iana-udp) "irc")
(setf (gethash 199 iana-tcp) "smux")
(setf (gethash 199 iana-udp) "smux")
(setf (gethash 201 iana-tcp) "at-rtmp")
(setf (gethash 201 iana-udp) "at-rtmp")
(setf (gethash 202 iana-tcp) "at-nbp")
(setf (gethash 202 iana-udp) "at-nbp")
(setf (gethash 204 iana-tcp) "at-echo")
(setf (gethash 204 iana-udp) "at-echo")
(setf (gethash 206 iana-tcp) "at-zis")
(setf (gethash 206 iana-udp) "at-zis")
(setf (gethash 209 iana-tcp) "qmtp")
(setf (gethash 209 iana-udp) "qmtp")
(setf (gethash 210 iana-tcp) "z3950")
(setf (gethash 210 iana-udp) "z3950")
(setf (gethash 213 iana-tcp) "ipx")
(setf (gethash 213 iana-udp) "ipx")
(setf (gethash 220 iana-tcp) "imap3")
(setf (gethash 220 iana-udp) "imap3")
(setf (gethash 345 iana-tcp) "pawserv")
(setf (gethash 345 iana-udp) "pawserv")
(setf (gethash 346 iana-tcp) "zserv")
(setf (gethash 346 iana-udp) "zserv")
(setf (gethash 347 iana-tcp) "fatserv")
(setf (gethash 347 iana-udp) "fatserv")
(setf (gethash 369 iana-tcp) "rpc2portmap")
(setf (gethash 369 iana-udp) "rpc2portmap")
(setf (gethash 370 iana-tcp) "codaauth2")
(setf (gethash 370 iana-udp) "codaauth2")
(setf (gethash 371 iana-tcp) "clearcase")
(setf (gethash 371 iana-udp) "clearcase")
(setf (gethash 372 iana-tcp) "ulistserv")
(setf (gethash 372 iana-udp) "ulistserv")
(setf (gethash 389 iana-tcp) "ldap")
(setf (gethash 389 iana-udp) "ldap")
(setf (gethash 406 iana-tcp) "imsp")
(setf (gethash 406 iana-udp) "imsp")
(setf (gethash 427 iana-tcp) "svrloc")
(setf (gethash 427 iana-udp) "svrloc")
(setf (gethash 443 iana-tcp) "https")
(setf (gethash 443 iana-udp) "https")
(setf (gethash 444 iana-tcp) "snpp")
(setf (gethash 444 iana-udp) "snpp")
(setf (gethash 445 iana-tcp) "microsoft-ds")
(setf (gethash 445 iana-udp) "microsoft-ds")
(setf (gethash 464 iana-tcp) "kpasswd")
(setf (gethash 464 iana-udp) "kpasswd")
(setf (gethash 465 iana-tcp) "urd")
(setf (gethash 487 iana-tcp) "saft")
(setf (gethash 487 iana-udp) "saft")
(setf (gethash 500 iana-tcp) "isakmp")
(setf (gethash 500 iana-udp) "isakmp")
(setf (gethash 554 iana-tcp) "rtsp")
(setf (gethash 554 iana-udp) "rtsp")
(setf (gethash 607 iana-tcp) "nqs")
(setf (gethash 607 iana-udp) "nqs")
(setf (gethash 610 iana-tcp) "npmp-local")
(setf (gethash 610 iana-udp) "npmp-local")
(setf (gethash 611 iana-tcp) "npmp-gui")
(setf (gethash 611 iana-udp) "npmp-gui")
(setf (gethash 612 iana-tcp) "hmmp-ind")
(setf (gethash 612 iana-udp) "hmmp-ind")
(setf (gethash 623 iana-udp) "asf-rmcp")
(setf (gethash 628 iana-tcp) "qmqp")
(setf (gethash 628 iana-udp) "qmqp")
(setf (gethash 631 iana-tcp) "ipp")
(setf (gethash 631 iana-udp) "ipp")
(setf (gethash 512 iana-tcp) "exec")
(setf (gethash 512 iana-udp) "biff")
(setf (gethash 513 iana-tcp) "login")
(setf (gethash 513 iana-udp) "who")
(setf (gethash 514 iana-tcp) "shell")
(setf (gethash 514 iana-udp) "syslog")
(setf (gethash 515 iana-tcp) "printer")
(setf (gethash 517 iana-udp) "talk")
(setf (gethash 518 iana-udp) "ntalk")
(setf (gethash 520 iana-udp) "route")
(setf (gethash 525 iana-udp) "timed")
(setf (gethash 526 iana-tcp) "tempo")
(setf (gethash 530 iana-tcp) "courier")
(setf (gethash 531 iana-tcp) "conference")
(setf (gethash 532 iana-tcp) "netnews")
(setf (gethash 533 iana-udp) "netwall")
(setf (gethash 538 iana-tcp) "gdomap")
(setf (gethash 538 iana-udp) "gdomap")
(setf (gethash 540 iana-tcp) "uucp")
(setf (gethash 543 iana-tcp) "klogin")
(setf (gethash 544 iana-tcp) "kshell")
(setf (gethash 546 iana-tcp) "dhcpv6-client")
(setf (gethash 546 iana-udp) "dhcpv6-client")
(setf (gethash 547 iana-tcp) "dhcpv6-server")
(setf (gethash 547 iana-udp) "dhcpv6-server")
(setf (gethash 548 iana-tcp) "afpovertcp")
(setf (gethash 548 iana-udp) "afpovertcp")
(setf (gethash 549 iana-tcp) "idfp")
(setf (gethash 549 iana-udp) "idfp")
(setf (gethash 556 iana-tcp) "remotefs")
(setf (gethash 563 iana-tcp) "nntps")
(setf (gethash 563 iana-udp) "nntps")
(setf (gethash 587 iana-tcp) "submission")
(setf (gethash 587 iana-udp) "submission")
(setf (gethash 636 iana-tcp) "ldaps")
(setf (gethash 636 iana-udp) "ldaps")
(setf (gethash 655 iana-tcp) "tinc")
(setf (gethash 655 iana-udp) "tinc")
(setf (gethash 706 iana-tcp) "silc")
(setf (gethash 706 iana-udp) "silc")
(setf (gethash 749 iana-tcp) "kerberos-adm")
(setf (gethash 765 iana-tcp) "webster")
(setf (gethash 765 iana-udp) "webster")
(setf (gethash 873 iana-tcp) "rsync")
(setf (gethash 873 iana-udp) "rsync")
(setf (gethash 989 iana-tcp) "ftps-data")
(setf (gethash 990 iana-tcp) "ftps")
(setf (gethash 992 iana-tcp) "telnets")
(setf (gethash 992 iana-udp) "telnets")
(setf (gethash 993 iana-tcp) "imaps")
(setf (gethash 993 iana-udp) "imaps")
(setf (gethash 994 iana-tcp) "ircs")
(setf (gethash 994 iana-udp) "ircs")
(setf (gethash 995 iana-tcp) "pop3s")
(setf (gethash 995 iana-udp) "pop3s")
(setf (gethash 1080 iana-tcp) "socks")
(setf (gethash 1080 iana-udp) "socks")
(setf (gethash 1093 iana-tcp) "proofd")
(setf (gethash 1093 iana-udp) "proofd")
(setf (gethash 1094 iana-tcp) "rootd")
(setf (gethash 1094 iana-udp) "rootd")
(setf (gethash 1194 iana-tcp) "openvpn")
(setf (gethash 1194 iana-udp) "openvpn")
(setf (gethash 1099 iana-tcp) "rmiregistry")
(setf (gethash 1099 iana-udp) "rmiregistry")
(setf (gethash 1214 iana-tcp) "kazaa")
(setf (gethash 1214 iana-udp) "kazaa")
(setf (gethash 1241 iana-tcp) "nessus")
(setf (gethash 1241 iana-udp) "nessus")
(setf (gethash 1352 iana-tcp) "lotusnote")
(setf (gethash 1352 iana-udp) "lotusnote")
(setf (gethash 1433 iana-tcp) "ms-sql-s")
(setf (gethash 1433 iana-udp) "ms-sql-s")
(setf (gethash 1434 iana-tcp) "ms-sql-m")
(setf (gethash 1434 iana-udp) "ms-sql-m")
(setf (gethash 1524 iana-tcp) "ingreslock")
(setf (gethash 1524 iana-udp) "ingreslock")
(setf (gethash 1525 iana-tcp) "prospero-np")
(setf (gethash 1525 iana-udp) "prospero-np")
(setf (gethash 1645 iana-tcp) "datametrics")
(setf (gethash 1645 iana-udp) "datametrics")
(setf (gethash 1646 iana-tcp) "sa-msg-port")
(setf (gethash 1646 iana-udp) "sa-msg-port")
(setf (gethash 1649 iana-tcp) "kermit")
(setf (gethash 1649 iana-udp) "kermit")
(setf (gethash 1677 iana-tcp) "groupwise")
(setf (gethash 1677 iana-udp) "groupwise")
(setf (gethash 1701 iana-tcp) "l2f")
(setf (gethash 1701 iana-udp) "l2f")
(setf (gethash 1812 iana-tcp) "radius")
(setf (gethash 1812 iana-udp) "radius")
(setf (gethash 1813 iana-tcp) "radius-acct")
(setf (gethash 1813 iana-udp) "radius-acct")
(setf (gethash 1863 iana-tcp) "msnp")
(setf (gethash 1863 iana-udp) "msnp")
(setf (gethash 1957 iana-tcp) "unix-status")
(setf (gethash 1958 iana-tcp) "log-server")
(setf (gethash 1959 iana-tcp) "remoteping")
(setf (gethash 2000 iana-tcp) "cisco-sccp")
(setf (gethash 2000 iana-udp) "cisco-sccp")
(setf (gethash 2010 iana-tcp) "search")
(setf (gethash 2010 iana-tcp) "pipe-server")
(setf (gethash 2049 iana-tcp) "nfs")
(setf (gethash 2049 iana-udp) "nfs")
(setf (gethash 2086 iana-tcp) "gnunet")
(setf (gethash 2086 iana-udp) "gnunet")
(setf (gethash 2101 iana-tcp) "rtcm-sc104")
(setf (gethash 2101 iana-udp) "rtcm-sc104")
(setf (gethash 2119 iana-tcp) "gsigatekeeper")
(setf (gethash 2119 iana-udp) "gsigatekeeper")
(setf (gethash 2135 iana-tcp) "gris")
(setf (gethash 2135 iana-udp) "gris")
(setf (gethash 2401 iana-tcp) "cvspserver")
(setf (gethash 2401 iana-udp) "cvspserver")
(setf (gethash 2430 iana-tcp) "venus")
(setf (gethash 2430 iana-udp) "venus")
(setf (gethash 2431 iana-tcp) "venus-se")
(setf (gethash 2431 iana-udp) "venus-se")
(setf (gethash 2432 iana-tcp) "codasrv")
(setf (gethash 2432 iana-udp) "codasrv")
(setf (gethash 2433 iana-tcp) "codasrv-se")
(setf (gethash 2433 iana-udp) "codasrv-se")
(setf (gethash 2583 iana-tcp) "mon")
(setf (gethash 2583 iana-udp) "mon")
(setf (gethash 2628 iana-tcp) "dict")
(setf (gethash 2628 iana-udp) "dict")
(setf (gethash 2792 iana-tcp) "f5-globalsite")
(setf (gethash 2792 iana-udp) "f5-globalsite")
(setf (gethash 2811 iana-tcp) "gsiftp")
(setf (gethash 2811 iana-udp) "gsiftp")
(setf (gethash 2947 iana-tcp) "gpsd")
(setf (gethash 2947 iana-udp) "gpsd")
(setf (gethash 3050 iana-tcp) "gds-db")
(setf (gethash 3050 iana-udp) "gds-db")
(setf (gethash 3130 iana-tcp) "icpv2")
(setf (gethash 3130 iana-udp) "icpv2")
(setf (gethash 3260 iana-tcp) "iscsi-target")
(setf (gethash 3306 iana-tcp) "mysql")
(setf (gethash 3306 iana-udp) "mysql")
(setf (gethash 3493 iana-tcp) "nut")
(setf (gethash 3493 iana-udp) "nut")
(setf (gethash 3632 iana-tcp) "distcc")
(setf (gethash 3632 iana-udp) "distcc")
(setf (gethash 3689 iana-tcp) "daap")
(setf (gethash 3689 iana-udp) "daap")
(setf (gethash 3690 iana-tcp) "svn")
(setf (gethash 3690 iana-udp) "svn")
(setf (gethash 4031 iana-tcp) "suucp")
(setf (gethash 4031 iana-udp) "suucp")
(setf (gethash 4094 iana-tcp) "sysrqd")
(setf (gethash 4094 iana-udp) "sysrqd")
(setf (gethash 4190 iana-tcp) "sieve")
(setf (gethash 4369 iana-tcp) "epmd")
(setf (gethash 4369 iana-udp) "epmd")
(setf (gethash 4373 iana-tcp) "remctl")
(setf (gethash 4373 iana-udp) "remctl")
(setf (gethash 4353 iana-tcp) "f5-iquery")
(setf (gethash 4353 iana-udp) "f5-iquery")
(setf (gethash 4500 iana-udp) "ipsec-nat-t")
(setf (gethash 4569 iana-tcp) "iax")
(setf (gethash 4569 iana-udp) "iax")
(setf (gethash 4691 iana-tcp) "mtn")
(setf (gethash 4691 iana-udp) "mtn")
(setf (gethash 4899 iana-tcp) "radmin-port")
(setf (gethash 4899 iana-udp) "radmin-port")
(setf (gethash 5002 iana-udp) "rfe")
(setf (gethash 5002 iana-tcp) "rfe")
(setf (gethash 5050 iana-tcp) "mmcc")
(setf (gethash 5050 iana-udp) "mmcc")
(setf (gethash 5060 iana-tcp) "sip")
(setf (gethash 5060 iana-udp) "sip")
(setf (gethash 5061 iana-tcp) "sip-tls")
(setf (gethash 5061 iana-udp) "sip-tls")
(setf (gethash 5190 iana-tcp) "aol")
(setf (gethash 5190 iana-udp) "aol")
(setf (gethash 5222 iana-tcp) "xmpp-client")
(setf (gethash 5222 iana-udp) "xmpp-client")
(setf (gethash 5269 iana-tcp) "xmpp-server")
(setf (gethash 5269 iana-udp) "xmpp-server")
(setf (gethash 5308 iana-tcp) "cfengine")
(setf (gethash 5308 iana-udp) "cfengine")
(setf (gethash 5353 iana-tcp) "mdns")
(setf (gethash 5353 iana-udp) "mdns")
(setf (gethash 5432 iana-tcp) "postgresql")
(setf (gethash 5432 iana-udp) "postgresql")
(setf (gethash 5556 iana-tcp) "freeciv")
(setf (gethash 5556 iana-udp) "freeciv")
(setf (gethash 5672 iana-tcp) "amqp")
(setf (gethash 5672 iana-udp) "amqp")
(setf (gethash 5688 iana-tcp) "ggz")
(setf (gethash 5688 iana-udp) "ggz")
(setf (gethash 6000 iana-tcp) "x11")
(setf (gethash 6000 iana-udp) "x11")
(setf (gethash 6001 iana-tcp) "x11-1")
(setf (gethash 6001 iana-udp) "x11-1")
(setf (gethash 6002 iana-tcp) "x11-2")
(setf (gethash 6002 iana-udp) "x11-2")
(setf (gethash 6003 iana-tcp) "x11-3")
(setf (gethash 6003 iana-udp) "x11-3")
(setf (gethash 6004 iana-tcp) "x11-4")
(setf (gethash 6004 iana-udp) "x11-4")
(setf (gethash 6005 iana-tcp) "x11-5")
(setf (gethash 6005 iana-udp) "x11-5")
(setf (gethash 6006 iana-tcp) "x11-6")
(setf (gethash 6006 iana-udp) "x11-6")
(setf (gethash 6007 iana-tcp) "x11-7")
(setf (gethash 6007 iana-udp) "x11-7")
(setf (gethash 6346 iana-tcp) "gnutella-svc")
(setf (gethash 6346 iana-udp) "gnutella-svc")
(setf (gethash 6347 iana-tcp) "gnutella-rtr")
(setf (gethash 6347 iana-udp) "gnutella-rtr")
(setf (gethash 6444 iana-tcp) "sge-qmaster")
(setf (gethash 6444 iana-udp) "sge-qmaster")
(setf (gethash 6445 iana-tcp) "sge-execd")
(setf (gethash 6445 iana-udp) "sge-execd")
(setf (gethash 6446 iana-tcp) "mysql-proxy")
(setf (gethash 6446 iana-udp) "mysql-proxy")
(setf (gethash 7000 iana-tcp) "afs3-fileserver")
(setf (gethash 7000 iana-udp) "afs3-fileserver")
(setf (gethash 7001 iana-tcp) "afs3-callback")
(setf (gethash 7001 iana-udp) "afs3-callback")
(setf (gethash 7002 iana-tcp) "afs3-prserver")
(setf (gethash 7002 iana-udp) "afs3-prserver")
(setf (gethash 7003 iana-tcp) "afs3-vlserver")
(setf (gethash 7003 iana-udp) "afs3-vlserver")
(setf (gethash 7004 iana-tcp) "afs3-kaserver")
(setf (gethash 7004 iana-udp) "afs3-kaserver")
(setf (gethash 7005 iana-tcp) "afs3-volser")
(setf (gethash 7005 iana-udp) "afs3-volser")
(setf (gethash 7006 iana-tcp) "afs3-errors")
(setf (gethash 7006 iana-udp) "afs3-errors")
(setf (gethash 7007 iana-tcp) "afs3-bos")
(setf (gethash 7007 iana-udp) "afs3-bos")
(setf (gethash 7008 iana-tcp) "afs3-update")
(setf (gethash 7008 iana-udp) "afs3-update")
(setf (gethash 7009 iana-tcp) "afs3-rmtsys")
(setf (gethash 7009 iana-udp) "afs3-rmtsys")
(setf (gethash 7100 iana-tcp) "font-service")
(setf (gethash 7100 iana-udp) "font-service")
(setf (gethash 8080 iana-tcp) "http-alt")
(setf (gethash 8080 iana-udp) "http-alt")
(setf (gethash 9101 iana-tcp) "bacula-dir")
(setf (gethash 9101 iana-udp) "bacula-dir")
(setf (gethash 9102 iana-tcp) "bacula-fd")
(setf (gethash 9102 iana-udp) "bacula-fd")
(setf (gethash 9103 iana-tcp) "bacula-sd")
(setf (gethash 9103 iana-udp) "bacula-sd")
(setf (gethash 9667 iana-tcp) "xmms2")
(setf (gethash 9667 iana-udp) "xmms2")
(setf (gethash 10809 iana-tcp) "nbd")
(setf (gethash 10050 iana-tcp) "zabbix-agent")
(setf (gethash 10050 iana-udp) "zabbix-agent")
(setf (gethash 10051 iana-tcp) "zabbix-trapper")
(setf (gethash 10051 iana-udp) "zabbix-trapper")
(setf (gethash 10080 iana-tcp) "amanda")
(setf (gethash 10080 iana-udp) "amanda")
(setf (gethash 11112 iana-tcp) "dicom")
(setf (gethash 11371 iana-tcp) "hkp")
(setf (gethash 11371 iana-udp) "hkp")
(setf (gethash 13720 iana-tcp) "bprd")
(setf (gethash 13720 iana-udp) "bprd")
(setf (gethash 13721 iana-tcp) "bpdbm")
(setf (gethash 13721 iana-udp) "bpdbm")
(setf (gethash 13722 iana-tcp) "bpjava-msvc")
(setf (gethash 13722 iana-udp) "bpjava-msvc")
(setf (gethash 13724 iana-tcp) "vnetd")
(setf (gethash 13724 iana-udp) "vnetd")
(setf (gethash 13782 iana-tcp) "bpcd")
(setf (gethash 13782 iana-udp) "bpcd")
(setf (gethash 13783 iana-tcp) "vopied")
(setf (gethash 13783 iana-udp) "vopied")
(setf (gethash 17500 iana-tcp) "db-lsp")
(setf (gethash 22125 iana-tcp) "dcap")
(setf (gethash 22128 iana-tcp) "gsidcap")
(setf (gethash 22273 iana-tcp) "wnn6")
(setf (gethash 22273 iana-udp) "wnn6")
(setf (gethash 750 iana-udp) "kerberos4")
(setf (gethash 750 iana-tcp) "kerberos4")
(setf (gethash 751 iana-udp) "kerberos-master")
(setf (gethash 751 iana-tcp) "kerberos-master")
(setf (gethash 752 iana-udp) "passwd-server")
(setf (gethash 754 iana-tcp) "krb-prop")
(setf (gethash 760 iana-tcp) "krbupdate")
(setf (gethash 901 iana-tcp) "swat")
(setf (gethash 1109 iana-tcp) "kpop")
(setf (gethash 2053 iana-tcp) "knetd")
(setf (gethash 2102 iana-udp) "zephyr-srv")
(setf (gethash 2103 iana-udp) "zephyr-clt")
(setf (gethash 2104 iana-udp) "zephyr-hm")
(setf (gethash 2105 iana-tcp) "eklogin")
(setf (gethash 2111 iana-tcp) "kx")
(setf (gethash 2121 iana-tcp) "iprop")
(setf (gethash 871 iana-tcp) "supfilesrv")
(setf (gethash 1127 iana-tcp) "supfiledbg")
(setf (gethash 98 iana-tcp) "linuxconf")
(setf (gethash 106 iana-tcp) "poppassd")
(setf (gethash 106 iana-udp) "poppassd")
(setf (gethash 775 iana-tcp) "moira-db")
(setf (gethash 777 iana-tcp) "moira-update")
(setf (gethash 779 iana-udp) "moira-ureg")
(setf (gethash 783 iana-tcp) "spamd")
(setf (gethash 808 iana-tcp) "omirr")
(setf (gethash 808 iana-udp) "omirr")
(setf (gethash 1001 iana-tcp) "customs")
(setf (gethash 1001 iana-udp) "customs")
(setf (gethash 1178 iana-tcp) "skkserv")
(setf (gethash 1210 iana-udp) "predict")
(setf (gethash 1236 iana-tcp) "rmtcfg")
(setf (gethash 1300 iana-tcp) "wipld")
(setf (gethash 1313 iana-tcp) "xtel")
(setf (gethash 1314 iana-tcp) "xtelw")
(setf (gethash 1529 iana-tcp) "support")
(setf (gethash 2003 iana-tcp) "cfinger")
(setf (gethash 2121 iana-tcp) "frox")
(setf (gethash 2150 iana-tcp) "ninstall")
(setf (gethash 2150 iana-udp) "ninstall")
(setf (gethash 2600 iana-tcp) "zebrasrv")
(setf (gethash 2601 iana-tcp) "zebra")
(setf (gethash 2602 iana-tcp) "ripd")
(setf (gethash 2603 iana-tcp) "ripngd")
(setf (gethash 2604 iana-tcp) "ospfd")
(setf (gethash 2605 iana-tcp) "bgpd")
(setf (gethash 2606 iana-tcp) "ospf6d")
(setf (gethash 2607 iana-tcp) "ospfapi")
(setf (gethash 2608 iana-tcp) "isisd")
(setf (gethash 2988 iana-tcp) "afbackup")
(setf (gethash 2988 iana-udp) "afbackup")
(setf (gethash 2989 iana-tcp) "afmbackup")
(setf (gethash 2989 iana-udp) "afmbackup")
(setf (gethash 4224 iana-tcp) "xtell")
(setf (gethash 4557 iana-tcp) "fax")
(setf (gethash 4559 iana-tcp) "hylafax")
(setf (gethash 4600 iana-tcp) "distmp3")
(setf (gethash 4949 iana-tcp) "munin")
(setf (gethash 5051 iana-tcp) "enbd-cstatd")
(setf (gethash 5052 iana-tcp) "enbd-sstatd")
(setf (gethash 5151 iana-tcp) "pcrd")
(setf (gethash 5354 iana-tcp) "noclog")
(setf (gethash 5354 iana-udp) "noclog")
(setf (gethash 5355 iana-tcp) "hostmon")
(setf (gethash 5355 iana-udp) "hostmon")
(setf (gethash 5555 iana-udp) "rplay")
(setf (gethash 5666 iana-tcp) "nrpe")
(setf (gethash 5667 iana-tcp) "nsca")
(setf (gethash 5674 iana-tcp) "mrtd")
(setf (gethash 5675 iana-tcp) "bgpsim")
(setf (gethash 5680 iana-tcp) "canna")
(setf (gethash 6514 iana-tcp) "syslog-tls")
(setf (gethash 6566 iana-tcp) "sane-port")
(setf (gethash 6667 iana-tcp) "ircd")
(setf (gethash 8021 iana-tcp) "zope-ftp")
(setf (gethash 8081 iana-tcp) "tproxy")
(setf (gethash 8088 iana-tcp) "omniorb")
(setf (gethash 8088 iana-udp) "omniorb")
(setf (gethash 8990 iana-tcp) "clc-build-daemon")
(setf (gethash 9098 iana-tcp) "xinetd")
(setf (gethash 9359 iana-udp) "mandelspawn")
(setf (gethash 9418 iana-tcp) "git")
(setf (gethash 9673 iana-tcp) "zope")
(setf (gethash 10000 iana-tcp) "webmin")
(setf (gethash 10081 iana-tcp) "kamanda")
(setf (gethash 10081 iana-udp) "kamanda")
(setf (gethash 10082 iana-tcp) "amandaidx")
(setf (gethash 10083 iana-tcp) "amidxtape")
(setf (gethash 11201 iana-tcp) "smsqp")
(setf (gethash 11201 iana-udp) "smsqp")
(setf (gethash 15345 iana-tcp) "xpilot")
(setf (gethash 15345 iana-udp) "xpilot")
(setf (gethash 17001 iana-udp) "sgi-cmsd")
(setf (gethash 17002 iana-udp) "sgi-crsd")
(setf (gethash 17003 iana-udp) "sgi-gcd")
(setf (gethash 17004 iana-tcp) "sgi-cad")
(setf (gethash 20011 iana-tcp) "isdnlog")
(setf (gethash 20011 iana-udp) "isdnlog")
(setf (gethash 20012 iana-tcp) "vboxd")
(setf (gethash 20012 iana-udp) "vboxd")
(setf (gethash 24554 iana-tcp) "binkp")
(setf (gethash 27374 iana-tcp) "asp")
(setf (gethash 27374 iana-udp) "asp")
(setf (gethash 30865 iana-tcp) "csync2")
(setf (gethash 57000 iana-tcp) "dircproxy")
(setf (gethash 60177 iana-tcp) "tfido")
(setf (gethash 60179 iana-tcp) "fido")
