//+build windows
package windows

/*
#define STD_INPUT_HANDLE  ((DWORD)-10)
#define STD_OUTPUT_HANDLE ((DWORD)-11)
#define STD_ERROR_HANDLE  ((DWORD)-12)
*/
STD_INPUT_HANDLE  :: 0xFFFF_FFF6;
STD_OUTPUT_HANDLE :: 0xFFFF_FFF5;
STD_ERROR_HANDLE  :: 0xFFFF_FFF4;

//#define INVALID_HANDLE_VALULE ((HANDLE)(LONG_PTR)-1)
INVALID_HANDLE_VALUE :: 0xFFFF_FFFF_FFFF_FFFF;

/*
#define CONSOLE_FULLSCREEN_MODE 1
#define CONSOLE_WINDOWED_MODE 2
*/
CONSOLE_FULLSCREEN_MODE :: 1;
CONSOLE_WINDOWED_MODE   :: 2;

//define FORMAT_MESSAGE_FROM_SYSTEM 0x1000
FORMAT_MESSAGE_FROM_SYSTEM :: 0x0000_1000;

/*
#define SW_SHOWNORMAL    1
#define SW_SHOWMINIMIZED 2
#define SW_SHOWMAXIMIZED 3
#define SW_RESTORE       9
*/
SW_SHOWNORMAL    :: 1;
SW_SHOWMINIMIZED :: 2;
SW_SHOWMAXIMIZED :: 3;
SW_RESTORE       :: 9;

/*
#define GENERIC_READ    0x80000000
#define GENERIC_WRITE   0x40000000
#define GENERIC_EXECUTE 0x20000000
*/
GENERIC_READ    :: 0x8000_0000;
GENERIC_WRITE   :: 0x4000_0000;
GENERIC_EXECUTE :: 0x2000_0000;

/*
#define FILE_SHARE_READ  0x00000001
#define FILE_SHARE_WRITE 0x00000002
*/
FILE_SHARE_READ  :: 0x0000_0001;
FILE_SHARE_WRITE :: 0x0000_0002;

//#define CONSOLE_TEXTMODE_BUFFER 1
CONSOLE_TEXTMODE_BUFFER :: 1;

/*
#define ENABLE_PROCESSED_INPUT         0x0001
#define ENABLE_LINE_INPUT              0x0002
#define ENABLE_ECHO_INPUT              0x0004
#define ENABLE_WINDOW_INPUT            0x0008
#define ENABLE_MOUSE_INPUT             0x0010
#define ENABLE_INSERT_MODE             0x0020
#define ENABLE_QUICK_EDIT_MODE         0x0040
#define ENABLE_EXTENDED_FLAGS          0x0080
#define ENABLE_AUTO_POSITION           0x0100
#define ENABLE_VIRTUAL_TERMINAL_INPUT  0x0200
*/
ENABLE_PROCESSED_INPUT        :: 0x0001;
ENABLE_LINE_INPUT             :: 0x0002;
ENABLE_ECHO_INPUT             :: 0x0004;
ENABLE_WINDOW_INPUT           :: 0x0008;
ENABLE_MOUSE_INPUT            :: 0x0010;
ENABLE_INSERT_MODE            :: 0x0020;
ENABLE_QUICK_EDIT_MODE        :: 0x0040;
ENABLE_EXTENDED_FLAGS         :: 0x0080;
ENABLE_AUTO_POSITION          :: 0x0100;
ENABLE_VIRTUAL_TERMINAL_INPUT :: 0x0200;

/*
#define KEY_EVENT                 0x0001
#define MOUSE_EVENT               0x0002
#define WINDOW_BUFFER_SIZE_EVENT  0x0004
#define MENU_EVENT                0x0008
#define FOCUS_EVENT               0x0010
*/
KEY_EVENT                :: 0x0001;
MOUSE_EVENT              :: 0x0002;
WINDOW_BUFFER_SIZE_EVENT :: 0x0004;
MENU_EVENT               :: 0x0008;
FOCUS_EVENT              :: 0x0010;

/*
#define RIGHT_ALT_PRESSED    0x0001
#define LEFT_ALT_PRESSED     0x0002
#define RIGHT_CTRL_PRESSED   0x0004
#define LEFT_CTRL_PRESSED    0x0008
#define SHIFT_PRESSED        0x0010
#define NUMLOCK_ON           0x0020
#define SCROLLLOCK_ON        0x0040
#define CAPSLOCK_ON          0x0080
#define ENHANCED_KEY         0x0100
*/
RIGHT_ALT_PRESSED  :: 0x0001;
LEFT_ALT_PRESSED   :: 0x0002;
RIGHT_CTRL_PRESSED :: 0x0004;
LEFT_CTRL_PRESSED  :: 0x0008;
SHIFT_PRESSED      :: 0x0010;
NUMLOCK_ON         :: 0x0020;
SCROLLLOCK_ON      :: 0x0040;
CAPSLOCK_ON        :: 0x0080;
ENHANCED_KEY       :: 0x0100;

/*
#define FROM_LEFT_1ST_BUTTON_PRESSED  0x0001
#define RIGHTMOST_BUTTON_PRESSED      0x0002
#define FROM_LEFT_2ND_BUTTON_PRESSED  0x0004
#define FROM_LEFT_3RD_BUTTON_PRESSED  0x0008
#define FROM_LEFT_4RH_BUTTON_PRESSED  0x0010
*/
FROM_LEFT_1ST_BUTTON_PRESSED :: 0x0001;
RIGHTMOST_BUTTON_PRESSED     :: 0x0002;
FROM_LEFT_2ND_BUTTON_PRESSED :: 0x0004;
FROM_LEFT_3RD_BUTTON_PRESSED :: 0x0008;
FROM_LEFT_4RH_BUTTON_PRESSED :: 0x0010;

/*
#define MOUSE_MOVED     0x0001
#define DOUBLE_CLICK    0x0002
#define MOUSE_WHEELED   0x0004
#define MOUSE_HWHEELED  0x0008
*/
MOUSE_MOVED    :: 0x0001;
DOUBLE_CLICK   :: 0x0002;
MOUSE_WHEELED  :: 0x0004;
MOUSE_HWHEELED :: 0x0008;

/*
#define SWP_SHOWWINDOW   0x0040
#define SWP_NOZORDER     0x0004
*/
SWP_SHOWWINDOW :: 0x0040;
SWP_NOZORDER   :: 0x0004;

