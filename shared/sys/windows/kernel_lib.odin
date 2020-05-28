//+build windows
package windows

foreign import "system:kernel32.lib"

foreign kernel32 {
    /* WINBASEAPI BOOL WINAPI GetConsoleScreenBufferInfo(
        _In_ HANDLE hConsoleOutput,
        _Out_ PCONSOLE_SCREEN_BUFFER_INFO lpConsoleScreenBufferInfo);
    */
    @(link_name="GetConsoleScreenBufferInfo")
        get_console_screen_buffer_info :: proc(
            console_output: Handle,
            console_screen_buffer_info: ^Console_Screen_Buffer_Info) -> Bool ---;

    /* WINBASEAPI HANDLE WINAPI GetStdHandle(_In_ DWORD nStdHandle); */
    @(link_name="GetStdHandle")
        get_std_handle :: proc(std_handle: Dword) -> Handle ---;

    /* WINBASEAPI BOOL APIENTRY SetConsoleDisplayMode(
        _In_ HANDLE hConsoleOutput,
        _In_ DWORD dwFlags,
        -Out_opt_ PCOORD lpNewScreenBufferDimensions);
    */
    @(link_name="SetConsoleDisplayMode")
        set_console_display_mode :: proc(
            console_output: Handle,
            flags: Dword, 
            new_screen_buffer_dimensions: ^Coord) -> Bool ---;

    /* WINBASEAPI HWND APIENTRY GetConsoleWindow(VOID); */
    @(link_name="GetConsoleWindow")
        get_console_window :: proc() -> Hwnd ---;

    /* WINBASEAPI HANDLE WINAPI CreateConsoleScreenBuffer(
        _In_ DWORD dwDesiredAccess,
        _In_ DWORD dwShareMode,
        _In_opt_ CONST SECURITY_ATTRIBUTES* lpSecurityAttributes,
        _In_ DWORD dwFlags,
        -Reserved_ LPVOID lpScreenBufferData);
    */
    @(link_name="CreateConsoleScreenBuffer")
        create_console_screen_buffer :: proc(
            desired_access: Dword,
            shared_mode: Dword,
            security_attributes: ^Security_Attributes,
            flags: Dword, 
            screen_buffer_data: Lp_Void) -> Handle ---;

    /* WINBASEAPI BOOL WINAPI SetConsoleActiveScreenBuffer(_In_ HANDLE hConsoleOutput); */
    @(link_name="SetConsoleActiveScreenBuffer")
        set_console_active_screen_buffer :: proc(console_output: Handle) -> Bool ---;

    /* WINBASEAPI BOOL WINAPI WriteConsoleOutputW(
        _In_ HANDLE hConsoleOutput,
        _In_ CONST CHAR_INFO* lpBuffer,
        _In_ COORD dwBufferSize,
        _In_ COORD dwBufferCoord,
        -Inout_ PSMALL_RECT lpWriteRegion);
    */
    @(link_name="WriteConsoleOutputW")
        write_console_output :: proc(
            console_output: Handle,
            buffer: ^Char_Info,
            buffer_size: Coord,
            buffer_coord: Coord, 
            write_region: ^Small_Rect) -> Bool ---;

    /* WINBASEAPI BOOL WINAPI GetConsoleMode(
        _In_ HANDLE hConsoleHandle,
        _Out_ LPDWORD lpMode);
    */
    @(link_name="GetConsoleMode")
        get_console_mode :: proc(
            console_handle: Handle,
            mode: ^Dword) -> Bool ---;

    /* WINBASEAPI BOOL WINAPI SetConsoleMode(
        _In_ HANDLE hConsoleHandle,
        _In_ DWORD dwMode);
    */
    @(link_name="SetConsoleMode")
        set_console_mode :: proc(
            console_handle: Handle,
            mode: Dword) -> Bool ---;

    /* WINBASEAPI BOOL WINAPI PeekConsoleInputW(
        _In_ HANDLE hConsoleInput,
        _Out_ PINPUT_RECORD lpBuffer,
        _In_ DWORD nLength,
        _Out_ LPDWORD lpNumberOfEventsRead);
    */
    @(link_name="PeekConsoleInputW")
        peek_console_input :: proc(
            console_input: Handle,
            buffer: ^Input_Record,
            length: Dword,
            number_of_events_read: ^Dword) -> Bool ---;

    /* WINBASEAPI BOOL WINAPI FlushConsoleInputBuffer(_In_ HANDLE hConsoleInput);*/
    @(link_name="FlushConsoleInputBuffer")
        flush_console_input_buffer :: proc(console_input: Handle) -> Bool ---;

//-------------------------------------------------------------------------------------
    /* WINBASEAPI DWORD WINAPI GetLastError(VOID); */
    @(link_name="GetLastError")
        get_last_error :: proc() -> Dword ---;

    /* WINBASEAPI DWORD WINAPI FormatMessageW(
        _In_ DWORD dwFlags,
        _In_opt_ LPCVOID lpSource,
        _In_ DWORD dwMessageId,
        _In_ DWORD dwLanguageId,
        _Inout_ LPWSTR lpBuffer,
        _In_ DWORD nSize,
        _In_opt_ va_list *Arguments);
    */
    @(link_name="FormatMessageW")
        format_message :: proc(
            flags: Dword,
            source: rawptr,     //always nil
            message_id: Dword,
            language_id: Dword,
            buffer: rawptr,     //pointer to u16 array
            size: Dword,        //size of the u16 array
            arguments: rawptr   //always nil
        ) -> Dword ---;


}
                                          

