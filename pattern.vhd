LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD_UNSIGNED.ALL;

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
SIGNAL grid : INTEGER;
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
                    outer <= ix < 52 OR ix > 206 OR iy < 32 OR iy > 160;

                    yellow <= ix > 160 AND ix < 202 AND ycell = 6;
                    red <= ycell = 8 AND xcell <= 5 OR (xcell >= 6 AND xcell <= 10 AND (ix XOR iy) MOD 2 = 2);
                    blue <= ycell = 9 AND xcell <= 5 OR (xcell >= 6 AND xcell <= 10 AND (ix XOR iy) MOD 2 = 2);
                    spike <= ix > 126 AND iy > 122 AND (ix * 4 + iy < 645);
                END IF;
            END IF;
            
            r <= en AND NOT spike AND ((grid OR (NOT outer AND ycell < 3 AND (xcell < 6 OR (xcell >= 12 AND xcell <= 17)))) OR yellow OR red);
            g <= en AND NOT spike AND ((grid OR (NOT outer AND ycell < 3 AND xcell < 12)) OR yellow);
            b <= en AND NOT spike AND ((grid OR (NOT outer AND ycell < 3 AND xcell MOD 6 < 3)) OR blue);

            rgb <= r & g & b;
    END PROCESS;
END ARCHITECTURE;
