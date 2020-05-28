package main

import "core:fmt"
import "core:mem"
import ar "shared:array"
import w "shared:sys/windows"

main :: proc() {
    out := w.get_std_handle(w.STD_OUTPUT_HANDLE);
    if uintptr(out) == w.INVALID_HANDLE_VALUE {
        fmt.println("Error getting STD_OUT handle");
        return;
    }

    info: w.Console_Screen_Buffer_Info;
    r := w.get_console_screen_buffer_info(out, &info);
    if !r {
        fmt.println("Error getting console info");
        return;
    }

    fmt.printf("Console size %v:\n", info.size);
    fmt.printf("Console cursor position %v:\n", info.cursor_position);
    fmt.printf("Console attributes %v:\n", info.attributes);
    fmt.printf("Console window %v:\n", info.window);
    fmt.printf("Console max window size %v:\n", info.maximum_window_size);

    /*
    new_dim: w.Coord;
    r = w.set_console_display_mode(out, w.CONSOLE_FULLSCREEN_MODE, &new_dim);
    if !r {
        report_error();
        fmt.println("Error setting full screen mode");
        return;
    }
    fmt.printf("new screen buffer size: %v\n", new_dim);
    */
    wnd := w.get_console_window();
    if uintptr(wnd) == w.INVALID_HANDLE_VALUE {
        fmt.println("Error getting console window");
        return;
    }
    r = w.show_window(wnd, w.SW_SHOWMAXIMIZED);
    if !r {
        fmt.println("Error maximizing console window");
        return;
    }

    /*
    out2 := w.create_console_screen_buffer(w.GENERIC_READ | w.GENERIC_WRITE,
                    w.FILE_SHARE_READ | w.FILE_SHARE_WRITE,
                    nil, w.CONSOLE_TEXTMODE_BUFFER, nil);
    if uintptr(out2) == w.INVALID_HANDLE_VALUE {
        fmt.println("Error creating console screen buffer");
        return;
    }
    r = w.set_console_active_screen_buffer(out2);
    if !r {
        fmt.println("Error setting new active buffer");
        return;
    }
    r = w.get_console_screen_buffer_info(out2, &info);
    if !r {
        fmt.println("Error getting console info");
        return;
    }

    fmt.printf("Console size %v:\n", info.size);
    fmt.printf("Console cursor position %v:\n", info.cursor_position);
    fmt.printf("Console attributes %v:\n", info.attributes);
    fmt.printf("Console window %v:\n", info.window);
    fmt.printf("Console max window size %v:\n", info.maximum_window_size);
    */

    /*
    buf := make([]w.Char_Info, info.size.x * info.size.y);
    for _, i in buf {
        buf[i].char = 0x0041;
        buf[i].attr = info.attributes;
    }
    raw := transmute(mem.Raw_Slice)buf;
    r = w.write_console_output(out2, cast(^w.Char_Info)raw.data, info.size, w.Coord{0, 0},
            &info.window);
    if !r {
        fmt.println("Error writing console output");
        return;
    }
    */

    inp := w.get_std_handle(w.STD_INPUT_HANDLE);
    if uintptr(inp) == w.INVALID_HANDLE_VALUE {
        fmt.println("Error getting STD_IN handle");
        return;
    }
    old_mode: w.Dword;
    r = w.get_console_mode(inp, &old_mode);
    if !r {
        fmt.println("Error getting input mode");
        return;
    }
    fmt.printf("input mode %b\n", old_mode);

    new_mode : w.Dword = w.ENABLE_WINDOW_INPUT | w.ENABLE_MOUSE_INPUT | w.ENABLE_EXTENDED_FLAGS;
    r = w.set_console_mode(inp, new_mode);
    if !r {
        fmt.println("Error setting input mode");
        return;
    }
    process_input(inp);

    w.set_console_mode(inp, old_mode);
}

process_input :: proc(input: w.Handle) {
    i := 0;
    buf := make([]w.Input_Record, 1024);
    raw := transmute(mem.Raw_Slice)buf;
    n : w.Dword = 0;
    for i < 5 {
        r := w.peek_console_input(input, cast(^w.Input_Record)raw.data, 1024, &n);
        if !r {
            fmt.println("Error peeking console");
            return;
        }
        if n == 0 do continue;

        fmt.printf("got %v events\n", n);
        c :u32 = 0;
        for v in buf {
            fmt.printf("event type %v\n", v.event_type);
            c += 1;
            if c == n do break;
        }

        r = w.flush_console_input_buffer(input);
        if !r {
            fmt.println("Error flushing input buffer");
            return;
        }
        n = 0;
        i += 1;
    }
}

report_error :: proc() {
    err := w.get_last_error();
    fmt.printf("Error ID is %v\n", err);

    tmp: [1024]u16;
    str := cast(ar.cstr16)&tmp[0];
    err = w.format_message(w.FORMAT_MESSAGE_FROM_SYSTEM, nil, err, 0, rawptr(str), 1024, nil);
    fmt.println(cast(string)ar.cstr16_to_str8(str));
}
    

