# still working this out...
$ ip route add 10.200.1.0/24 via 10.240.0.7

- worker-0

ip route add 10.200.1.0/24 via 10.240.0.7
ip route add 10.200.2.0/24 via 10.240.0.8

- worker-1

ip route add 10.200.0.0/24 via 10.240.0.6
ip route add 10.200.2.0/24 via 10.240.0.8

- worker-2

ip route add 10.200.0.0/24 via 10.240.0.6
ip route add 10.200.1.0/24 via 10.240.0.7

