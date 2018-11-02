# Sets up the GTKwave session by setting zoom and which nets to view
# Written by David Bascelli
# August 2018
set nfacs [ gtkwave::getNumFacs ]
set dumpname [ gtkwave::getDumpFileName ]
set dmt [ gtkwave::getDumpType ]

lappend bundle1 "test.clk"
lappend bundle1 "test.reset"
lappend bundle1 "test.in"
lappend bundle1 "test.drdy"
lappend bundle1 "test.dut.\\taps\[0\]"
lappend bundle1 "test.dut.\\taps\[1\]"
lappend bundle1 "test.dut.\\taps\[2\]"
lappend bundle1 "test.dut.\\taps\[3\]"
lappend bundle1 "test.dut.\\taps\[4\]"
lappend bundle1 "test.dut.\\taps\[5\]"
lappend bundle1 "test.out"
lappend bundle1 "test.dnew"
lappend bundle1 "test.outCorrect"

set num_added [ gtkwave::addSignalsFromList $bundle1 ]

gtkwave::/Edit/UnHighlight_All

gtkwave::setZoomFactor -5
gtkwave::setWindowStartTime 0
