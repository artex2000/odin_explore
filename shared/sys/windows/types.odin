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
typedef HANDLE HWND
typedef wchar_t WCHAR
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
    maximum_window_size: Coord,
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
