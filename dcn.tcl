

# read the command line arguments
set k [lindex $argv 0]
set ns [new Simulator]

# Define the 'finish' procedure and set up tracing
set nf [open out.nam w]
$ns namtrace-all $nf
proc finish {}	{
	global ns nf
	$ns flush-trace
	close $nf
	exec nam out.nam &
	exit 0
}

set bandwidthUnits 1000Mb
set pktsize 1250
set delaywithUnits_1 0.001ms
set delaywithUnits_2 0.002ms
set delaywithUnits_3 0.003ms
set qLimit 1000
Node set multiPath_ 1

################################### FAT TREE ALGORITHM #######################################################
# - k pods, each consist of (k/2)^2 hosts and two layers(edge/aggregate) each with k/2 k-port switches
# - Each edge switch connects to k/2 hosts and k/2 aggregate switches
# - Each aggregate switch connects to k/2 edge and k/2 core switches
# - (k/2)^2 core switches: each connects to k pods 
# - Supports k^3/4 hosts!
##############################################################################################################

# loop variables: p: pod, s: switch, i: host
# generating hosts
set hosts [expr ($k/2)*($k/2)*$k]
puts "Number of hosts in red: $hosts"
for {set p 0} {$p < $k} {incr p} {
	for {set s 0} {$s < $k/2} {incr s} {
		for {set i 0} {$i < $k/2} {incr i} {			
  		set h($p,$s,$i) [$ns node]
			$h($p,$s,$i) color red	
			$h($p,$s,$i) label "host"
			$h($p,$s,$i) label-color blue
			$h($p,$s,$i) label-at up	
			puts "host# $p $s $i"

		}
	}
}

# generating edge switches (es)  level 1
set edgeSwitches [expr ($k/2)*$k]
puts "Number of edge switches in blue: $edgeSwitches"
for {set p 0} {$p < $k} {incr p} {
	for {set s 0} {$s < $k/2} {incr s} {
    set es($p,$s) [$ns node]
		$es($p,$s) shape box
		$es($p,$s) color blue
		puts "edgeswitch# $p $s"
	}
}

# generating aggregation switches (as)  level 2
set aggregateSwitches [expr ($k/2)*$k]
puts "Number of aggregate switches in green: $aggregateSwitches"
for {set p 0} {$p < $k} {incr p} {
	for {set s 0} {$s < $k/2} {incr s} {
  	set as($p,$s) [$ns node]
		$as($p,$s) shape box	
		$as($p,$s) color green
		puts "aggregateswitch# $p $s"
	}
}

# generating core switches (cs)  level 3
set coreSwitches [expr ($k/2)*($k/2)]
puts "Number of core switches in yellow: $coreSwitches"
for {set p 0} {$p < $k/2} {incr p} {
	for {set s 0} {$s < $k/2} {incr s} {
		set cs($p,$s) [$ns node]
		$cs($p,$s) shape hexagon
		$cs($p,$s) color yellow
		puts "coreswitch# $p $s"
	}
}

# generating links between hosts and es
global a 
set a 0
for {set p 0} {$p < $k} {incr p} {
	for {set s 0} {$s < $k/2} {incr s} {
		for {set i 0} {$i < $k/2} {incr i} {
			$ns duplex-link $h($p,$s,$i) $es($p,$s) $bandwidthUnits $delaywithUnits_1 DropTail
			if { $a % 2 == 0 } { $ns duplex-link-op $es($p,$s) $h($p,$s,$i) orient right-down }
			if { $a % 2 == 1 } { $ns duplex-link-op $es($p,$s) $h($p,$s,$i) orient left-down }
			incr a
			$ns queue-limit $h($p,$s,$i) $es($p,$s) $qLimit
			$ns queue-limit $es($p,$s) $h($p,$s,$i) $qLimit
		}
	}
}

# generating links between es and as
global a 
set a 0
for {set p 0} {$p < $k} {incr p} {
	for {set s 0} {$s < $k/2} {incr s} {
		for {set i 0} {$i < $k/2} {incr i} {
			$ns duplex-link $es($p,$i) $as($p,$s) $bandwidthUnits $delaywithUnits_2 DropTail
			if { $a % 2 == 0 } { $ns duplex-link-op $as($p,$s) $es($p,$i) orient down }
			if { $a % 2 == 1 } { $ns duplex-link-op $as($p,$s) $es($p,$i) orient down }
			incr a
			$ns queue-limit $es($p,$i) $as($p,$s) $qLimit
			$ns queue-limit $as($p,$s) $es($p,$i) $qLimit
		}
	}
}

# generating links between as and cs
global a 
set a 0
for {set p 0} {$p < $k} {incr p} {
	for {set s 0} {$s < $k/2} {incr s} {
		for {set c 0} {$c < $k/2} {incr c} {
			$ns duplex-link $as($p,$s) $cs($c,$s) $bandwidthUnits $delaywithUnits_3 DropTail
			if { $a % 2 == 0 } { $ns duplex-link-op $cs($c,$s) $as($p,$s) orient right-down}
			if { $a % 2 == 1 } { $ns duplex-link-op $cs($c,$s) $as($p,$s) orient left-down }
			incr a
			$ns queue-limit $as($p,$s) $cs($c,$s) $qLimit
			$ns queue-limit $cs($c,$s) $as($p,$s) $qLimit
		}
	}
}

$ns at 5.0 "finish"

puts "Starting Simulation..."
$ns run
