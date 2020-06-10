//+build windows
package windows

foreign import "system:user32.lib"

foreign user32 {
    /* WINUSERAPI BOOL WINAPI ShowWindow(
        _In_ HWND hWnd,
        _In_ int nCmdShow);
    */
    @(link_name="ShowWindow")
        show_window :: proc( window: Hwnd, command: int) -> Bool ---;

    /* WINUSERAPI BOOL WINAPI GetWindowRect(
        _In_ HWND hWnd,
        _Out_ LPRECT lpRect);
    */
    @(link_name="GetWindowRect")
        get_window_rect :: proc( window: Hwnd, rect: ^Rect) -> Bool ---;

    /* WINUSERAPI BOOL WINAPI SetWindowPos(
        _In_ HWND hWnd,
        _In_opt_ HWND hWndInsertAfter,
        _In_ int X,
        _In_ int Y,
        _In_ int cx,
        _In_ int cy,
        _In_ UINT uFlags);
    */
    @(link_name="SetWindowPos")
        set_window_position :: proc( window: Hwnd, parent: Hwnd,
                        x, y, cx, cy: int, flags: Uint) -> Bool ---;

}

