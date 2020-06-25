package main

//Single line box characters
SINGLE_HOR_LINE         :: 0x2501;
SINGLE_VER_LINE         :: 0x2503;
SINGLE_LEFT_TOP_CORNER  :: 0x250F;
SINGLE_RIGHT_TOP_CORNER :: 0x2513;
SINGLE_LEFT_BOTTOM_CORNER  :: 0x2517;
SINGLE_RIGHT_BOTTOM_CORNER :: 0x251B;

DOUBLE_HOR_LINE         :: 0x2550;
DOUBLE_VER_LINE         :: 0x2551;
DOUBLE_LEFT_TOP_CORNER  :: 0x2554;
DOUBLE_RIGHT_TOP_CORNER :: 0x2557;
DOUBLE_LEFT_BOTTOM_CORNER  :: 0x255A;
DOUBLE_RIGHT_BOTTOM_CORNER :: 0x255D;

//16 colors palette
DARK_BASE0           :: 0x8; //most darkest background
DARK_BASE1           :: 0x0;
LIGHT_BASE0          :: 0xF; //most bright background
LIGHT_BASE1          :: 0x7;
CONTENT_DARK         :: 0xA;
CONTENT_MEDIUM_DARK  :: 0xB;
CONTENT_MEDIUM_LIGHT :: 0xC;
CONTENT_LIGHT        :: 0xE;
ACCENT_RED           :: 0x1;
ACCENT_GREEN         :: 0x2;
ACCENT_YELLOW        :: 0x3;
ACCENT_BLUE          :: 0x4;
ACCENT_MAGENTA       :: 0x5;
ACCENT_CYAN          :: 0x6;
ACCENT_ORANGE        :: 0x9;
ACCENT_VIOLET        :: 0xD;


DARK_REGULAR :: (DARK_BASE0 << 4) | CONTENT_MEDIUM_LIGHT;




