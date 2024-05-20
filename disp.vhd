LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY disp IS
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
END ENTITY;

ARCHITECTURE behavior OF disp IS

CONSTANT HSTART : SIGNED(12 DOWNTO 0) := -HBACK - HSYNC - HFRONT;
CONSTANT HSSTART : SIGNED(12 DOWNTO 0) := -HBACK - HSYNC;
CONSTANT HSEND : SIGNED(12 DOWNTO 0) := -HBACK;
CONSTANT HAEND : SIGNED(12 DOWNTO 0) := HRES - 1;

CONSTANT VSTART : SIGNED(12 DOWNTO 0) := -VBACK - VSYNC - VFRONT;
CONSTANT VSSTART : SIGNED(12 DOWNTO 0) := -VBACK - VSYNC;
CONSTANT VSEND : SIGNED(12 DOWNTO 0) := -VBACK;
CONSTANT VAEND : SIGNED(12 DOWNTO 0) := VRES - 1;

BEGIN
    PROCESS(pixel_clk)
    BEGIN
        hvs(2) <= '1' WHEN (x >= 0 AND y >= 0) ELSE '0';
        IF (y >= VSSTART AND y < VSEND) THEN
            hvs(1) <= VPOL XOR '1';
        END IF;
        IF (x >= HSSTART AND x < HSEND) THEN
            hvs(0) <= HPOL XOR '1';
        END IF;
        frame <= '1' WHEN (y = VSTART AND x = HSTART) ELSE '0';
        IF(RISING_EDGE(pixel_clk)) THEN
            IF (RESET) THEN
                x <= HSTART;
                y <= VSTART;
            ELSE
                IF (x = HAEND) THEN
                    x <= HSTART;
                    IF (y = VAEND) THEN
                        y <= VSTART;
                    ELSE
                        y <= y + 1;
                    END IF;
                ELSE
                    x <= x + 1;
                END IF;
            END IF;
        END IF;
    END PROCESS;

END ARCHITECTURE;