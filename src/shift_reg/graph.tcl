# Sets up the GTKwave session by setting zoom and which nets to view
# Written by David Bascelli
# August 2018
set nfacs [ gtkwave::getNumFacs ]
set dumpname [ gtkwave::getDumpFileName ]
set dmt [ gtkwave::getDumpType ]

lappend bundle1 "test.clk"
lappend bundle1 "test.reset"
lappend bundle1 "test.passed"
lappend bundle1 "test.in"
lappend bundle1 "test.out"

set num_added [ gtkwave::addSignalsFromList $bundle1 ]

gtkwave::/Edit/UnHighlight_All

gtkwave::setZoomFactor -9
gtkwave::setWindowStartTime 0
