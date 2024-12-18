set val(chan) Channel/WirelessChannel
set val(prop) Propagation/TwoRayGround
set val(netif) Phy/WirelessPhy
set val(mac) Mac/802_11
set val(ifq) Queue/DropTail/PriQueue
set val(ll) LL
set val(ant) Antenna/OmniAntenna
set val(x) 500
set val(y) 500
set val(ifqlen) 50
set val(nn) 5
set val(stop) 50.0
 set val(rp) AODV
 
set ns_ [new Simulator]

set tracefd [open 005.tr w]
$ns_ trace-all $tracefd

set namtrace [open 005.nam w]
$ns_ namtrace-all-wireless $namtrace $val(x) $val(y)
set cwind1 [open win51.tr w]
set cwind2 [open win52.tr w]

 
set prop [new $val(prop)]
set topo [new Topography]
$topo load_flatgrid $val(x) $val(y)
create-god $val(nn)

$ns_ node-config -adhocRouting $val(rp) \
-llType $val(ll) \
-macType $val(mac) \
-ifqType $val(ifq) \
-ifqLen $val(ifqlen) \
-antType $val(ant) \
-propType $val(prop) \
-phyType $val(netif) \
 -channelType $val(chan) \
-topoInstance $topo \
-agentTrace ON \
-routerTrace ON \
-macTrace ON \
-IncomingErrProc "uniformErr" \
-OutgoingErrProc "uniformErr"

proc uniformErr {} {
set err [new ErrorModel]
$err unit pkt
$err set rate_ 0.1
return $err
}

for {set i 0} {$i < $val(nn) } {incr i} {
 set node_($i) [$ns_ node]
$node_($i) random-motion 0
}

for {set i 0} {$i < $val(nn)} {incr i} {
$ns_ initial_node_pos $node_($i) 40
}

$ns_ at 1.0 "$node_(0) setdest 10.0 10.0 50.0"
$ns_ at 1.0 "$node_(1) setdest 10.0 100.0 50.0"
$ns_ at 1.0 "$node_(4) setdest 50.0 50.0 50.0"
$ns_ at 1.0 "$node_(2) setdest 100.0 100.0 50.0"
$ns_ at 1.0 "$node_(3) setdest 100.0 10.0 50.0"

set tcp0 [new Agent/TCP]
set sink0 [new Agent/TCPSink]
$ns_ attach-agent $node_(0) $tcp0
$ns_ attach-agent $node_(2) $sink0
$ns_ connect $tcp0 $sink0

set ftp0 [new Application/FTP]
$ftp0 attach-agent $tcp0

$ns_ at 1.0 "$ftp0 start"
$ns_ at 50.0 "$ftp0 stop"

set tcp1 [new Agent/TCP]
set sink1 [new Agent/TCPSink]
$ns_ attach-agent $node_(1) $tcp1
$ns_ attach-agent $node_(2) $sink1
$ns_ connect $tcp1 $sink1

set ftp1 [new Application/FTP]
$ftp1 attach-agent $tcp1
$ns_ at 1.0 "$ftp1 start"
$ns_ at 50.0 "$ftp1 stop"

$ns_ at 1.0 "plotWindow $tcp0 $cwind1"
$ns_ at 1.0 "plotWindow $tcp1 $cwind2"

for {set i 0} {$i < $val(nn) } {incr i} {
$ns_ at $val(stop) "$node_($i) reset";
}
$ns_ at $val(stop) "puts \"NS EXITING...\" ; finish"
puts "Starting Simulation..."

proc plotWindow {tcpSource file} {
global ns_
set time 0.1
set now [$ns_ now]
set cwnd [$tcpSource set cwnd_ ]
puts $file "$now $cwnd"
$ns_ at [expr $now+$time] "plotWindow $tcpSource $file" }

proc finish {} {
 global ns_ tracefd namtrace
 $ns_ flush-trace
 close $tracefd
 close $namtrace
 exec nam 005.nam &
 exec xgraph win51.tr &
 exec xgraph win52.tr &
 exit 0
 
}
$ns_ run



#awk 
BEGIN {
resd=0
hdrsz=0
stoptime=0
starttime=0
}

{
time=$2
if ($1=="s" && $4=="AGT" && $8>=512) {
if (time<starttime) {
starttime= time
}
}
if ($1 == "r" && $4 =="AGT" && $8>=512) {
if (time>starttime) {
stoptime =time
}
hdrsz = $8%512
$8-=hdrsz
recd+=$8
}
}
END {
printf("Goodput =%f kbps \n", (recd)/(stoptime-starttime)*8/1000);
}
