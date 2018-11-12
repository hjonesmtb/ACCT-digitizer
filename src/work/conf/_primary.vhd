library verilog;
use verilog.vl_types.all;
entity conf is
    generic(
        CONF_BUF_SIZE   : integer := 16
    );
    port(
        SYS_CLK         : in     vl_logic;
        SYS_RST         : in     vl_logic;
        wr_conf         : in     vl_logic;
        rd_eeprom       : in     vl_logic;
        wr_eeprom       : in     vl_logic;
        pca_gain_reg    : in     vl_logic_vector(15 downto 0);
        sda             : inout  vl_logic;
        scl             : out    vl_logic
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of CONF_BUF_SIZE : constant is 1;
end conf;
