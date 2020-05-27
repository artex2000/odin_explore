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

}

