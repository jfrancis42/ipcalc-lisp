;;;; ipcalc.lisp

(in-package #:ipcalc)

;;; "ipcalc" goes here. Hacks and glory await!

(defun ip-or (a b) (if (or (equal a 1) (equal b 1)) 1 0))
(defun ip-not (n) (if (equal n 0) 1 0))
(defun ip-and (a b) (logand a b))

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
		(format nil "~4,'0X" (bin-to-dec (subseq n 0 16))) ":" (format nil "~4,'0X" (bin-to-dec (subseq n 16 32))) ":"
		(format nil "~4,'0X" (bin-to-dec (subseq n 32 48))) ":" (format nil "~4,'0X" (bin-to-dec (subseq n 48 64))) ":"
		(format nil "~4,'0X" (bin-to-dec (subseq n 64 80))) ":" (format nil "~4,'0X" (bin-to-dec (subseq n 80 96))) ":"
		(format nil "~4,'0X" (bin-to-dec (subseq n 96 112))) ":" (format nil "~4,'0X" (bin-to-dec (subseq n 112 128)))
		)))

(defun bin-to-ipv6-string (n)
  "Convert a list of binary digits into an IPv6 string."
  (string-downcase
   (concatenate 'string
		(format nil "~X" (bin-to-dec (subseq n 0 16))) ":" (format nil "~X" (bin-to-dec (subseq n 16 32))) ":"
		(format nil "~X" (bin-to-dec (subseq n 32 48))) ":" (format nil "~X" (bin-to-dec (subseq n 48 64))) ":"
		(format nil "~X" (bin-to-dec (subseq n 64 80))) ":" (format nil "~X" (bin-to-dec (subseq n 80 96))) ":"
		(format nil "~X" (bin-to-dec (subseq n 96 112))) ":" (format nil "~X" (bin-to-dec (subseq n 112 128)))
		)))

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
    (concatenate 'list (make-list (- desired-length current-length) :initial-element 0) bits)))

(defun ipv6-to-bin (addr)
  (let* ((nums (split-sequence:split-sequence #\: addr))
	 (len (length nums))
	 (missing (position "" nums :test #'equal)))
    (if (< len 8)
	(progn
	  (setf (nth missing nums) (make-list (- 9 len) :initial-element "0"))
	  (setf nums (alexandria:flatten nums))))
    (concatenate 'list
		 (int-to-binary (parse-integer (nth 0 nums) :radix 16) 16) (int-to-binary (parse-integer (nth 1 nums) :radix 16) 16)
		 (int-to-binary (parse-integer (nth 2 nums) :radix 16) 16) (int-to-binary (parse-integer (nth 3 nums) :radix 16) 16)
		 (int-to-binary (parse-integer (nth 4 nums) :radix 16) 16) (int-to-binary (parse-integer (nth 5 nums) :radix 16) 16)
		 (int-to-binary (parse-integer (nth 6 nums) :radix 16) 16) (int-to-binary (parse-integer (nth 7 nums) :radix 16) 16))))

(defun ipv6-full-to-bin (addr)
  "Convert the string representation of a fully-expanded IPv6
address (or netmask) in to a list of binary digits."
  (let ((nums (map 'list (lambda (n) (parse-integer n :radix 16))
		   (split-sequence:split-sequence #\: addr))))
    (concatenate 'list
		 (int-to-binary (nth 0 nums) 16) (int-to-binary (nth 1 nums) 16)
		 (int-to-binary (nth 2 nums) 16) (int-to-binary (nth 3 nums) 16)
		 (int-to-binary (nth 4 nums) 16) (int-to-binary (nth 5 nums) 16)
		 (int-to-binary (nth 6 nums) 16) (int-to-binary (nth 7 nums) 16))))

(defun ipv6-addr-compress (addr)
  "Compress a fully-specified IPv6 address down to it's canonical
form."
  (let* ((zeros (map 'list (lambda (n) (if (equal n "0") 1 0)) (split-sequence:split-sequence #\: (bin-to-ipv6-string (ipv6-full-to-bin addr)))))
	 (sequences (ipv6-addr-compress-helper (copy-list zeros)))
	 (addr-parts (map 'list (lambda (n) (format nil "~X" (parse-integer n :radix 16))) (split-sequence:split-sequence #\: addr)))
	 (rep-length (first (sort (copy-list sequences) #'>)))
	 (rep-pos (position rep-length sequences))
	 (end-pos (+ rep-pos rep-length)))
    (cl-ppcre::regex-replace ":$" (cl-ppcre::regex-replace "::+" 
							   (apply #'concatenate 'string
								  (map 'list (lambda (n) (format nil "~A:" n))
								       (loop for y from 0 to 7
									  collect
									    (if (and (>= y rep-pos) (< y end-pos) (> rep-length 1))
										":"
										(nth y addr-parts)))))
							   "::") "")))

(defun bin-to-ip-string (n)
  "Convert a list of binary digits to a dotted quad. IPv6 if it's 128
bits, else IPv4."
  (if (equal 128 (length n))
      (ipv6-addr-compress (bin-to-ipv6-string n))
      (bin-to-ipv4-string n)))

(defun cidr-to-ipv4-netmask (cidr)
  "Convert a CIDR (slash) notation into a list of binary digits."
  (bin-to-ip-string (concatenate 'list (make-list cidr :initial-element 1) (make-list (- 32 cidr) :initial-element 0))))

(defun cidr-to-ipv6-netmask (cidr)
  "Convert a CIDR (slash) notation into a list of binary digits."
  (bin-to-ip-string (concatenate 'list (make-list cidr :initial-element 1) (make-list (- 128 cidr) :initial-element 0))))

(defun is-it-ipv6? (addr)
  "Returns t if there's a colon in the string, else nil."
  (if (position #\: addr)
      t
      nil))

(defun ipv4-to-bin (addr)
  "Convert the string representation of an IPv4 address (or netmask) in
dotted-quad format to a list of binary digits."
  (let ((nums (map 'list (lambda (n) (parse-integer n))
		   (split-sequence:split-sequence #\. addr))))
    (concatenate 'list
		 (int-to-binary (nth 0 nums) 8) (int-to-binary (nth 1 nums) 8)
		 (int-to-binary (nth 2 nums) 8) (int-to-binary (nth 3 nums) 8))))

(defun ip-to-bin (addr)
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
  (loop for x in netmask for y in (ip-network addr netmask) collect (ip-or y (ip-not x))))

(defun calc-network-addr (addr netmask)
  "Given an IP address and a netmask, calculate the network address."
  (bin-to-ip-string (ip-network (ip-to-bin addr) (ip-to-bin netmask))))

(defun calc-broadcast-addr (addr netmask)
  "Given an IP address and a netmask, calculate the broadcast
address."
  (bin-to-ip-string (ip-broadcast (ip-to-bin addr) (ip-to-bin netmask))))

(defun ip-info (addr netmask)
  "Given an IP address and a netmask, show me the network and the
broadcast addresses."
  (format t "Address: ~A~%Netmask: ~A~%Broadcast: ~A~%Network: ~A~%"
	  addr netmask
	  (calc-broadcast-addr addr netmask)
	  (calc-network-addr addr netmask)))

(defun same-ip-network? (addr1 addr2 netmask)
  "Given two IP addresses and a netmask as dotted quad strings, tell
me if both IP addresses are part of the same network."
  (if (equal
       (ip-network (ip-to-bin addr1) (ip-to-bin netmask))
       (ip-network (ip-to-bin addr2) (ip-to-bin netmask)))
      t
      nil))

(defun multicast-addr? (ip)
  "Given a dotted quad string IP address, tell me if it's a multicast
address or not. (currently only works for IPv4)."
  (if (is-it-ipv6? ip)
      nil
      (if (same-ip-network? ip "224.0.0.0" (cidr-to-ipv4-netmask 4))
	  t
	  nil)))