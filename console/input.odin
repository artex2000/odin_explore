package main

import "core:fmt"
import "core:mem"
import w "shared:sys/windows"

init_console_input :: proc() -> bool {
    inp := w.get_std_handle(w.STD_INPUT_HANDLE);
    if uintptr(inp) == w.INVALID_HANDLE_VALUE {
        fmt.println("Error getting STD_IN handle");
        return false;
    }
    console_input.handle = inp;
    console_save_state.inp = inp;

    mode: w.Dword;
    r := w.get_console_mode(inp, &mode);
    if !r {
        fmt.println("Error getting input mode");
        return false;
    }
    console_save_state.input_mode = mode;

    r = w.flush_console_input_buffer(console_input.handle);
    if !r {
        fmt.println("Error flushing input buffer");
    }

    mode = w.ENABLE_WINDOW_INPUT | w.ENABLE_MOUSE_INPUT | w.ENABLE_EXTENDED_FLAGS;
    r = w.set_console_mode(inp, mode);
    if !r {
        fmt.println("Error setting input mode");
        return false;
    }
    
    console_input.buf = make([]w.Input_Record, INPUT_BUFFER_LENGTH);
    return true;
}

restore_console_input :: proc() {
    w.set_console_mode(console_save_state.inp, console_save_state.input_mode);
}

read_console_input :: proc() {
    raw := transmute(mem.Raw_Slice)console_input.buf;
    n : w.Dword = 0;
    r := w.peek_console_input(console_input.handle, cast(^w.Input_Record)raw.data, 
                            u32(raw.len), &n);
    if !r {
        fmt.println("Error peeking console");
    }
    if n == 0 do return;

    for v, i in console_input.buf {
        if u32(i) >= n do break;
        switch v.event_type {
        case w.KEY_EVENT:
            translate_key_event(v.event.key_event);
        case w.MOUSE_EVENT:
            translate_mouse_event(v.event.mouse_event);
        case w.WINDOW_BUFFER_SIZE_EVENT:
            translate_resize_event(v.event.resize_event);
        case w.MENU_EVENT:
            translate_menu_event(v.event.menu_event);
        case w.FOCUS_EVENT:
            translate_focus_event(v.event.focus_event);
        case:
            fmt.println("Unknown event type");
        }
    }

    r = w.flush_console_input_buffer(console_input.handle);
    if !r {
        fmt.println("Error flushing input buffer");
    }
}

