# Sets up the GTKwave session by setting zoom and which nets to view
# Written by David Bascelli
# August 2018
set nfacs [ gtkwave::getNumFacs ]
set dumpname [ gtkwave::getDumpFileName ]
set dmt [ gtkwave::getDumpType ]

lappend bundle1 "SPI_CLK"
lappend bundle1 "SYS_RST"
lappend bundle1 "ADC_SCLK"
lappend bundle1 "ADC_SS"
lappend bundle1 "ADC_MISO"
lappend bundle1 "DOUT"
lappend bundle1 "expected"
lappend bundle1 "DRDY"
lappend bundle1 "diff"
lappend bundle1 "dut.STATE"
lappend bundle1 "dut.shift_out_value"
lappend bundle1 "passed"

set num_added [ gtkwave::addSignalsFromList $bundle1 ]

gtkwave::/Edit/UnHighlight_All

gtkwave::setZoomFactor -18
gtkwave::setWindowStartTime 0
