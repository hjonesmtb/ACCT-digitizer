library verilog;
use verilog.vl_types.all;
entity i2c_master is
    port(
        addr            : in     vl_logic_vector(2 downto 0);
        in_data         : in     vl_logic_vector(7 downto 0);
        out_data        : out    vl_logic_vector(7 downto 0);
        sda             : inout  vl_logic;
        scl             : inout  vl_logic;
        cs              : in     vl_logic;
        rd              : in     vl_logic;
        wr              : in     vl_logic;
        clk             : in     vl_logic
    );
end i2c_master;
