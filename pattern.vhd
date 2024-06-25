LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY pattern IS
    PORT(clk, en : IN STD_LOGIC;
         x, y : IN SIGNED (12 DOWNTO 0);
         rgb : OUT STD_LOGIC_VECTOR (23 DOWNTO 0));
END ENTITY;

ARCHITECTURE behavior OF pattern IS

SIGNAL ix : STD_LOGIC_VECTOR (12 DOWNTO 0);
SIGNAL iy : STD_LOGIC_VECTOR (12 DOWNTO 0);

CONSTANT cx : SIGNED (12 DOWNTO 0) := TO_SIGNED(130, 13);
CONSTANT cy : SIGNED (12 DOWNTO 0) := TO_SIGNED(96, 13);

SIGNAL xgrid : STD_LOGIC_VECTOR (16 DOWNTO 0);
SIGNAL ygrid : STD_LOGIC_VECTOR (16 DOWNTO 0);
SIGNAL circle : STD_LOGIC_VECTOR (16 DOWNTO 0);
SIGNAL grid : STD_LOGIC;
SIGNAL xcell : STD_LOGIC_VECTOR (12 DOWNTO 0);
SIGNAL ycell : STD_LOGIC_VECTOR (12 DOWNTO 0);
SIGNAL block5 : STD_LOGIC_VECTOR (12 DOWNTO 0);
SIGNAL block10 : STD_LOGIC_VECTOR (12 DOWNTO 0);
SIGNAL outer : STD_LOGIC;
SIGNAL yellow: STD_LOGIC;
SIGNAL red : STD_LOGIC;
SIGNAL blue: STD_LOGIC;
SIGNAL spike : STD_LOGIC;

SIGNAL r : STD_LOGIC_VECTOR (7 DOWNTO 0);
SIGNAL g : STD_LOGIC_VECTOR (7 DOWNTO 0);
SIGNAL b : STD_LOGIC_VECTOR (7 DOWNTO 0);

BEGIN
    PROCESS (ALL)
        BEGIN
            IF RISING_EDGE(clk) THEN
                IF en = '1' THEN
                    ix <= x * 2/5;
                    iy <= y * 2/5;
                    xgrid <= "0" & ix + 1;
                    ygrid <= "0" & iy + 8;
                    circle <= ("0" & ix - cx) * ("0" & ix - cx) + ("0" & iy - cy) * ("0" & iy - cy);
                    xcell <= (ix - 52) * 2/13;
                    ycell <= (iy - 32) / 13;
                    block10 <= (ix - 52) * 2/31;
                    block5 <= (ix - 52) / 31;
                    outer <= '1' WHEN ix < d"52" OR ix > d"206" OR iy < d"32" OR iy > d"160" ELSE '0';

                    yellow <= '1' WHEN ix > d"160" AND ix < d"202" AND ycell = d"6" ELSE '0';
                    red <= '1' WHEN ycell = d"8" AND xcell <= d"5" OR (xcell >= d"6" AND xcell <= d"10" AND (ix XOR iy) MOD 2 = d"2") ELSE '0';
                    blue <= '1' WHEN ycell = d"9" AND xcell <= d"5" OR (xcell >= d"6" AND xcell <= d"10" AND (ix XOR iy) MOD 2 = d"2") ELSE '0';
                    spike <= '1' WHEN ix > d"126" AND iy > d"122" AND (ix * 4 + iy < d"645") ELSE '0';
                END IF;
            END IF;
            
            r <= "00000001" WHEN en AND NOT spike AND ((grid OR (NOT outer AND ycell < 3 AND (xcell < 6 OR (xcell >= 12 AND xcell <= 17)))) OR yellow OR red) ELSE (OTHERS => '0');
            g <= "00000001" WHEN en AND NOT spike AND ((grid OR (NOT outer AND ycell < 3 AND xcell < 12)) OR yellow) ELSE (OTHERS => '0');
            b <= "00000001" WHEN en AND NOT spike AND ((grid OR (NOT outer AND ycell < 3 AND xcell MOD 6 < 3)) OR blue) ELSE (OTHERS => '0');

            rgb <= r & g & b;
    END PROCESS;
END ARCHITECTURE;
