set_global_assignment -entity "SYS_PLL" -library "lib_SYS_PLL" -name IP_TOOL_NAME "altera_pll"
set_global_assignment -entity "SYS_PLL" -library "lib_SYS_PLL" -name IP_TOOL_VERSION "18.0"
set_global_assignment -entity "SYS_PLL" -library "lib_SYS_PLL" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_SYS_PLL" -name SPD_FILE [file join $::quartus(sip_path) "SYS_PLL.spd"]

set_global_assignment -library "lib_SYS_PLL" -name MISC_FILE [file join $::quartus(sip_path) "SYS_PLL_sim/SYS_PLL.vo"]
