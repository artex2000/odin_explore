//+build windows
package windows

//Targeting 64-bit Unicode Windows only

/*
typedef unsigned short WORD;
typedef void *PVOID, *LPVOID;
typedef PVOID HANDLE
typedef int BOOL;
typedef unsigned long DWORD;
typedef __int64 LONG_PTR;
typedef HANDLE HWND;
typedef wchar_t WCHAR;
typedef __int64 LONGLONG;
typedef long LONG;
typedef unsigned int UINT;
*/

Handle   :: distinct rawptr; //to compare with INVALID_HANDLE without cast
Hwnd     :: Handle;
Bool     :: b32;
Word     :: u16;
Dword    :: u32;
Short    :: i16;
Long_Ptr :: i64;
Lp_Void  :: rawptr;
Wchar    :: u16;
Char     :: u8;
Long     :: i32;
LongLong :: i64;
Uint     :: u32;

/* typedef struct _COORD {
    SHORT X;
    SHORT Y;
} COORD, *PCOORD;
*/
Coord :: struct {
    x: Short,
    y: Short,
}

/* typedef struct _SMALL_RECT {
    SHORT Left;
    SHORT Top;
    SHORT Right;
    SHORT Bottom;
} SMALL_RECT;
*/
Small_Rect :: struct {
    left:   Short,
    top:    Short,
    right:  Short,
    bottom: Short,
}

/* typedef struct _CONSOLE_SCREEN_BUFFER_INFO {
    COORD      dwSize;
    COORD      dwCursorPosition;
    WORD       wAttributes;
    SMALL_RECT srWindow;
    COORD      dwMaximumWindowSize;
} CONSOLE_SCREEN_BUFFER_INFO;
*/
Console_Screen_Buffer_Info :: struct {
    size:                Coord,
    cursor_position:     Coord,
    attributes:          Word,
    window:              Small_Rect,
    max_window_size:     Coord,
}

/* typedef struct _SECURITY_ATTRIBUTES {
    DWORD nLength;
    LPVOID lpSecurityDescriptor;
    BOOL bInheritHandle;
} SECURITY_ATTRIBUTES, *PSECURITY_ATTRIBUTES, *LPSECURITY_ATTRIBUTES;
*/
Security_Attributes :: struct {
    length: Dword,
    security_descriptor: Lp_Void,
    inherit_handle: Bool,
}

/* typedef struct _CHAR_INFO {
    WCHAR Unicodechar;
    WORD  Attributes;
} CHAR_INFO, *PCHAR_INFO;
*/
Char_Info :: struct {
    char: Wchar,
    attr: Word,
}

/* typedef struct _INPUT_RECORD {
    WORD EventType;
    union {
        KEY_EVENT_RECORD KeyEvent;
        MOUSE_EVENT_RECORD MouseEvent;
        WINDOW_BUFFER_SIZE_RECORD WindowBufferSizeEvent;
        MENU_EVENT_RECORD MenuEvent;
        FOCUS_EVENT_RECORD FocusEvent;
    } Event;
} INPUT_RECORD, *PINPUT_RECORD;
*/
Input_Record :: struct {
    event_type: Word,
    event: struct #raw_union {
        key_event: Key_Event_Record,
        mouse_event: Mouse_Event_Record,
        resize_event: Resize_Event_Record,
        menu_event: Menu_Event_Record,
        focus_event: Focus_Event_Record,
    },
}

/* typedef struct _KEY_EVENT_RECORD {
    BOOL bKeyDown;
    WORD wRepeatCount;
    WORD wVirtualKeyCode;
    WORD wVirtualScanCode;
    union {
        WCHAR UnicodeChar;
        CHAR  AsciiChar;
    } uChar;
    DWORD dwControlKeyState;
} KEY_EVENT_RECORD, *PKEY_EVENT_RECORD;
*/
Key_Event_Record :: struct {
    key_down: Bool,
    repeat_count: Word,
    virtual_key_code: Word,
    virtual_scan_code: Word,
    char: struct #raw_union {
        unicode_char: Wchar,
        ascii_char: Char,
    },
    control_key_state: Dword,
}

/* typedef struct _MOUSE_EVENT_RECORD {
    COORD dwMousePosition;
    DWORD dwButtonState;
    DWORD dwControlKeyState;
    DWORD dwEventFlags;
} MOUSE_EVENT_RECORD, *PMOUSE_EVENT_RECORD;
*/
Mouse_Event_Record :: struct {
    mouse_position: Coord,
    button_state: Dword,
    control_key_state: Dword,
    event_flags: Dword,
}

/* typedef struct _WINDOW_BUFFER_SIZE_RECORD {
    COORD dwSize;
} WINDOW_BUFFER_SIZE_RECORD, *PWINDOW_BUFFER_SIZE_RECORD;
*/
Resize_Event_Record :: struct {
    size: Coord,
}

/* typedef struct _MENU_EVENT_RECORD {
    UINT dwCommandId;
} MENU_EVENT_RECORD, *PMENU_EVENT_RECORD; 
*/
Menu_Event_Record :: struct {
    command_id: u32,
}

/* typedef struct _FOCUS_EVENT_RECORD {
    BOOL bSetFocus;
} FOCUS_EVENT_RECORD, *PFOCUS_EVENT_RECORD; 
*/
Focus_Event_Record :: struct {
    set_focus: Bool,
}

/* typedef union _LARGE_INTEGER {
    struct {
        DWORD LowPart;
        LONG HighPart;
    } DUMMYSTRUCTNAME;
    struct {
        DWORD LowPart;
        LONG HighPart;
    } u;
    LONGLONG QuadPart;
} LARGE_INTEGER;
*/
Large_Integer :: struct #raw_union {
    u: struct {
        low_part: Dword,
        high_part: Long,
    },
    quad_part: LongLong,
}

/* typedef struct tagRECT {
    LONG left;
    LONG top;
    LONG right;
    LONG bottom;
} RECT, *PRECT, *NRECT, *LPRECT;
*/
Rect :: struct  {
    left: Long,
    top: Long,
    right: Long,
    bottom: Long,
}

