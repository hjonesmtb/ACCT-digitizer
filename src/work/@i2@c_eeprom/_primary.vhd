library verilog;
use verilog.vl_types.all;
entity I2C_eeprom is
    generic(
        CONF_BUF_SIZE   : integer := 16;
        PAGE_SIZE       : integer := 16;
        PAGE_NUM        : vl_notype;
        CHIP_ADDR       : vl_logic_vector(0 to 6) := (Hi1, Hi0, Hi1, Hi0, Hi0, Hi0, Hi0);
        state_idle      : integer := 0
    );
    port(
        clk             : in     vl_logic;
        rst             : in     vl_logic;
        conf_data       : in     vl_logic;
        read            : in     vl_logic;
        write           : in     vl_logic;
        \buffer\        : out    vl_logic;
        busy            : out    vl_logic;
        valid           : out    vl_logic;
        SDA             : inout  vl_logic;
        SCL             : out    vl_logic
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of CONF_BUF_SIZE : constant is 1;
    attribute mti_svvh_generic_type of PAGE_SIZE : constant is 1;
    attribute mti_svvh_generic_type of PAGE_NUM : constant is 3;
    attribute mti_svvh_generic_type of CHIP_ADDR : constant is 1;
    attribute mti_svvh_generic_type of state_idle : constant is 1;
end I2C_eeprom;
