LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY tmds_encode IS
    PORT (tmds_clk : IN STD_LOGIC;
          tmds_reset : IN STD_LOGIC;
          tmds_en : IN STD_LOGIC;
          tmds_ctrl : IN STD_LOGIC_VECTOR (1 DOWNTO 0);
          tmds_data : IN STD_LOGIC_VECTOR (7 DOWNTO 0);
          tmds : OUT STD_LOGIC_VECTOR (9 DOWNTO 0)
    );
END ENTITY;

ARCHITECTURE behavior OF tmds_encode IS
FUNCTION countOnes (data : STD_LOGIC_VECTOR) RETURN UNSIGNED IS
VARIABLE ones : UNSIGNED (3 DOWNTO 0) := (OTHERS => '0');
BEGIN
    FOR i IN 0 TO 7 LOOP
        IF data(i) = '1' THEN
            ones := ones + 1;
        END IF;
    END LOOP;
    RETURN ones;
END FUNCTION;

SIGNAL ctrl : STD_LOGIC_VECTOR (1 DOWNTO 0);
SIGNAL blank : STD_LOGIC;
SIGNAL parity : STD_LOGIC;
SIGNAL buff : STD_LOGIC_VECTOR (7 DOWNTO 1) := (OTHERS => parity);
SIGNAL enc : STD_LOGIC_VECTOR (7 DOWNTO 0);
SIGNAL balance : SIGNED (4 DOWNTO 0);
SIGNAL bias : SIGNED (4 DOWNTO 0) := (OTHERS => '0');
SIGNAL biasvbalance : STD_LOGIC;
SIGNAL con : STD_LOGIC_VECTOR (9 DOWNTO 0) := (OTHERS => ctrl(0));
SIGNAL bvb : STD_LOGIC_VECTOR (7 DOWNTO 0):= (OTHERS => biasvbalance);
SIGNAL bivba : STD_LOGIC_VECTOR (4 DOWNTO 0):= (OTHERS => biasvbalance);

BEGIN
    ctrl <= tmds_ctrl when tmds_reset = '0' else "00";
    blank <= tmds_reset OR NOT tmds_en;
    enc <= (buff XOR enc(6 DOWNTO 0) XOR tmds_data(7 DOWNTO 1)) & tmds_data(0);
    parity <= '1' when (countOnes(tmds_data) & NOT tmds_data(0)) > 8 else '0';
    balance <= ('0' & signed(countOnes(enc))) - 8;
    biasvbalance <= '1' when bias(4) = balance(4) ELSE '0';
    PROCESS(tmds_clk)
    BEGIN
        IF (RISING_EDGE(tmds_clk)) THEN
            IF blank THEN
                tmds <= NOT ctrl(1) & "101010100" XOR con;
                bias <= (OTHERS => '0');
            ELSE
                tmds <= biasvbalance & NOT parity & bvb XOR enc;
                bias <= bias + (SIGNED(bivba) XOR balance) + ("000" & biasvbalance XOR parity & biasvbalance);
            END IF;
        END IF;
    END PROCESS;
END ARCHITECTURE;

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY hdmi IS
    PORT(hdmi_clk : IN STD_LOGIC;
         hdmi_clk_5x : IN STD_LOGIC;
         hdmi_reset : IN STD_LOGIC;
         hdmi_sync : IN STD_LOGIC_VECTOR (2 DOWNTO 0);
         hdmi_RGB : IN STD_LOGIC_VECTOR (23 DOWNTO 0);
         hdmi_p : OUT STD_LOGIC_VECTOR (3 DOWNTO 0);
         hdmi_n : OUT STD_LOGIC_VECTOR (3 DOWNTO 0)
    );

END ENTITY;

ARCHITECTURE model OF hdmi IS
FUNCTION OSER (SIGNAL clk : STD_LOGIC; din : STD_LOGIC_VECTOR) RETURN STD_LOGIC IS
VARIABLE internal : STD_LOGIC_VECTOR (9 DOWNTO 0) := (OTHERS => '0');
VARIABLE count : INTEGER RANGE 0 TO 10 := 0;
BEGIN
    IF clk'EVENT THEN
        count := count + 1;
        IF count = 9 THEN
            internal := din;
        ELSIF count = 10 THEN
            count := 0;
        END IF;
        RETURN internal(count);
    END IF;
END FUNCTION;

SIGNAL ch0 : STD_LOGIC_VECTOR(9 DOWNTO 0);
SIGNAL ch1 : STD_LOGIC_VECTOR(9 DOWNTO 0);
SIGNAL ch2 : STD_LOGIC_VECTOR(9 DOWNTO 0);

TYPE serial IS ARRAY (0 TO 2) OF STD_LOGIC;
SIGNAL linear : serial;

COMPONENT tmds_encode IS
    PORT (tmds_clk : IN STD_LOGIC;
          tmds_reset : IN STD_LOGIC;
          tmds_en : IN STD_LOGIC;
          tmds_ctrl : IN STD_LOGIC_VECTOR (1 DOWNTO 0);
          tmds_data : IN STD_LOGIC_VECTOR (7 DOWNTO 0);
          tmds : OUT STD_LOGIC_VECTOR (9 DOWNTO 0)
    );
END COMPONENT;

COMPONENT TLVDS_OBUF 
    PORT ( 
        I:IN std_logic;
        O:OUT std_logic; 
        OB:OUT std_logic
    ); 
END COMPONENT; 

BEGIN
    b : tmds_encode PORT MAP(tmds_clk => hdmi_clk, tmds_reset => hdmi_reset, tmds_en => hdmi_sync(2), tmds_ctrl => hdmi_sync(1 DOWNTO 0), tmds_data => hdmi_RGB(23 DOWNTO 16), tmds => ch0);
    g : tmds_encode PORT MAP(tmds_clk => hdmi_clk, tmds_reset => hdmi_reset, tmds_en => hdmi_sync(2), tmds_ctrl => "00", tmds_data => hdmi_RGB(15 DOWNTO 8), tmds => ch1);
    r : tmds_encode PORT MAP(tmds_clk => hdmi_clk, tmds_reset => hdmi_reset, tmds_en => hdmi_sync(2), tmds_ctrl => "00", tmds_data => hdmi_RGB(7 DOWNTO 0), tmds => ch2);

    linear(0) <= OSER(hdmi_clk_5x, ch0);
    linear(1) <= OSER(hdmi_clk_5x, ch1);
    linear(2) <= OSER(hdmi_clk_5x, ch2);

    OBUFDS_clock : TLVDS_OBUF PORT MAP(hdmi_clk, hdmi_p(3), hdmi_n(3));
    OBUFDS_red : TLVDS_OBUF PORT MAP(linear(2), hdmi_p(2), hdmi_n(2));
    OBUFDS_green : TLVDS_OBUF PORT MAP(linear(1), hdmi_p(1), hdmi_n(1));
    OBUFDS_blue : TLVDS_OBUF PORT MAP(linear(0), hdmi_p(0), hdmi_n(0));                    
END ARCHITECTURE;