LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY toplevel IS
    PORT(clk : IN STD_LOGIC;
         reset_button : IN STD_LOGIC;
         HDMI_TX_N : OUT STD_LOGIC_VECTOR (3 DOWNTO 0);
         HDMI_TX_P : OUT STD_LOGIC_VECTOR (3 DOWNTO 0)
    );
END toplevel;

ARCHITECTURE  behavior OF toplevel IS
    SIGNAL HDMI_CLK : STD_LOGIC;
    SIGNAL HDMI_CLK_5X : STD_LOGIC;
    SIGNAL HDMI_LOCK : STD_LOGIC;

    SIGNAL reset : STD_LOGIC := NOT HDMI_LOCK OR NOT reset_button;
    SIGNAL x, y : SIGNED (12 DOWNTO 0);
    SIGNAL hve_sync : STD_LOGIC_VECTOR (2 DOWNTO 0);

    SIGNAL rgb : STD_LOGIC_VECTOR (23 DOWNTO 0);

    COMPONENT GowIN_rPLL
        PORT (
            clkOUT: OUT std_logic;
            lock: OUT std_logic;
            clkIN: IN std_logic
        );
    END COMPONENT;

    COMPONENT GowIN_CLKDIV
        PORT (
            clkOUT: OUT std_logic;
            hclkIN: IN std_logic;
            resetn: IN std_logic;
            calib: IN std_logic
        );
    END COMPONENT;

    COMPONENT disp 
        GENERIC(HRES : SIGNED;
                VRES : SIGNED;
                HFRONT : SIGNED;
                HSYNC : SIGNED;
                HBACK : SIGNED;
                VFRONT : SIGNED;
                VSYNC : SIGNED;
                VBACK : SIGNED;
                HPOL :STD_LOGIC;
                VPOL :STD_LOGIC);
        PORT(pixel_clk : IN STD_LOGIC;
             reset : IN STD_LOGIC;
             frame : OUT STD_LOGIC;
             hvs : OUT STD_LOGIC_VECTOR (2 DOWNTO 0);
             x : OUT SIGNED (12 DOWNTO 0);
             y : OUT SIGNED (12 DOWNTO 0));  
    END COMPONENT;

    BEGIN
        rPLL: GowIN_rPLL
            PORT MAP (
                clkOUT => HDMI_CLK_5X,
                lock => HDMI_LOCK,
                clkIN => clk
            );

        clkDiv: GowIN_CLKDIV
            PORT MAP (
                clkOUT => HDMI_CLK,
                hclkIN => HDMI_CLK_5X,
                resetn => HDMI_LOCK,
                calib => '1'
            );

        ds: disp
            GENERIC MAP(
                    HRES => 640,
                    VRES => 480,
                    HFRONT => 16,
                    HSYNC => 96,
                    HBACK => 48,
                    VFRONT => 10,
                    VSYNC => 2,
                    VBACK => 33,
                    HPOL => '0',
                    VPOL => '0'
            )
            PORT MAP(
                 pixel_clk => HDMI_CLK,
                 reset => reset,
                 frame => OPEN,
                 hvs => hve_sync,
                 x => x,
                 y => y
            );
END behavior;