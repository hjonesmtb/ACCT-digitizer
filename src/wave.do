onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -format Logic /base_line_tb/Baseline_inst/clk
add wave -noupdate -divider -height 30 <NULL>
add wave -noupdate -format Analog-Step -radix unsigned -scale 0.10000000000000001 /base_line_tb/Baseline_inst/din
add wave -noupdate -format Literal -radix unsigned /base_line_tb/Baseline_inst/dout
add wave -noupdate -divider <NULL>
add wave -noupdate -format Logic /base_line_tb/Baseline_inst/reset
add wave -noupdate -format Logic /base_line_tb/Baseline_inst/trigger
add wave -noupdate -format Logic /base_line_tb/Baseline_inst/integration
add wave -noupdate -format Literal /base_line_tb/Baseline_inst/inptr
add wave -noupdate -format Literal /base_line_tb/Baseline_inst/outptr
add wave -noupdate -format Literal /base_line_tb/Baseline_inst/sum
add wave -noupdate -format Literal -radix unsigned /base_line_tb/Baseline_inst/buffer
add wave -noupdate -divider <NULL>
add wave -noupdate -format Analog-Step -radix unsigned -scale 0.10000000000000001 /base_line_tb/Summer_inst/dout
add wave -noupdate -format Literal -radix unsigned /base_line_tb/Summer_inst/din1
add wave -noupdate -format Literal -radix unsigned /base_line_tb/Summer_inst/din2
add wave -noupdate -divider <NULL>
add wave -noupdate -format Literal /base_line_tb/U_Delay/din
add wave -noupdate -format Literal /base_line_tb/U_Delay/delayed_db
add wave -noupdate -format Logic /base_line_tb/enable_bl
add wave -noupdate -format Logic /base_line_tb/enable_pg
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {660000 ps} 0} {{Cursor 2} {3220000 ps} 0}
configure wave -namecolwidth 201
configure wave -valuecolwidth 40
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
update
WaveRestoreZoom {457875 ps} {1314947 ps}
