onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /conf_tb/dut/SYS_RST
add wave -noupdate /conf_tb/dut/SYS_CLK
add wave -noupdate /conf_tb/dut/rd_eeprom
add wave -noupdate /conf_tb/dut/wr_eeprom
add wave -noupdate /conf_tb/dut/wr_conf
add wave -noupdate /conf_tb/dut/pca_gain_reg
add wave -noupdate /conf_tb/dut/sda
add wave -noupdate /conf_tb/dut/scl
add wave -noupdate /conf_tb/dut/eeprom_buffer
add wave -noupdate /conf_tb/dut/eeprom_busy
add wave -noupdate /conf_tb/dut/eeprom_data_valid
add wave -noupdate /conf_tb/dut/state
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {50032 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 263
configure wave -valuecolwidth 100
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
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {157500 ps}
