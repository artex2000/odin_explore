package main

import "core:fmt"
import "core:mem"
import ar "shared:array"
import w "shared:sys/windows"

Console_Output :: struct {
    handle: w.Handle,
    size: w.Coord,
    cursor: w.Coord,
    surface: w.Small_Rect,
    buf: []w.Char_Info,
    dirty: bool,
    default_attributes: w.Word,
}

Console_Input :: struct {
    handle: w.Handle,
    buf: []w.Input_Record,
}

Console_State :: struct {
    out: w.Handle,
    inp: w.Handle,
    window: w.Hwnd,
    input_mode: w.Dword,
    window_position: w.Rect,
}

INPUT_BUFFER_LENGTH :: 50;

console_save_state: Console_State;
console_output: Console_Output;
console_input: Console_Input;

init_console_output :: proc() -> bool {
    out := w.get_std_handle(w.STD_OUTPUT_HANDLE);
    if uintptr(out) == w.INVALID_HANDLE_VALUE {
        fmt.println("Error getting STD_OUT handle");
        return false;
    }
    console_save_state.out = out;

    wnd := w.get_console_window();
    if uintptr(wnd) == w.INVALID_HANDLE_VALUE {
        fmt.println("Error getting console window");
        return false;
    }
    console_save_state.window = wnd;

    //TODO: get window normal size for restoring
    r := w.get_window_rect(wnd, &console_save_state.window_position);
    if !r {
        fmt.println("Error getting window position");
        return false;
    }

    r = w.show_window(wnd, w.SW_SHOWMAXIMIZED);
    if !r {
        fmt.println("Error maximizing console window");
        return false;
    }

    out2 := w.create_console_screen_buffer(w.GENERIC_READ | w.GENERIC_WRITE,
                    w.FILE_SHARE_READ | w.FILE_SHARE_WRITE,
                    nil, w.CONSOLE_TEXTMODE_BUFFER, nil);
    if uintptr(out2) == w.INVALID_HANDLE_VALUE {
        fmt.println("Error creating console screen buffer");
        return false;
    }

    console_output.handle = out2;

    r = w.set_console_active_screen_buffer(out2);
    if !r {
        fmt.println("Error setting new active buffer");
        return false;
    }

    info: w.Console_Screen_Buffer_Info;
    r = w.get_console_screen_buffer_info(out2, &info);
    if !r {
        fmt.println("Error getting console info");
        return false;
    }

    console_output.size = info.size;
    console_output.surface = info.window;
    console_output.default_attributes = info.attributes;
    console_output.buf = make([]w.Char_Info, info.size.x * info.size.y);
    console_output.cursor = w.Coord{0, 0};

    for _, i in console_output.buf {
        console_output.buf[i].char = ' ';
        console_output.buf[i].attr = info.attributes;
    }

    raw := transmute(mem.Raw_Slice)console_output.buf;
    r = w.write_console_output(out2, cast(^w.Char_Info)raw.data,
            info.size, w.Coord{0, 0}, &info.window);
    if !r {
        fmt.println("Error writing console output");
        return false;
    }
    console_output.dirty = false;
    return true;
}

restore_console_output :: proc() {
    /*
    r := w.show_window(console_save_state.window, w.SW_SHOWNORMAL);
    if !r {
        fmt.println("Error restoring console window");
        return;
    }
    */
    r := w.set_console_active_screen_buffer(console_save_state.out);
    if !r {
        fmt.println("Error restoring screen buffer");
        return;
    }
    rc := console_save_state.window_position;
    r = w.set_window_position(console_save_state.window, nil, 
            int(rc.left), int(rc.top), 
            int(rc.right - rc. left + 1), int(rc.bottom - rc.left + 1),
            w.SWP_SHOWWINDOW);
}

flush_console_output :: proc() {
    if !console_output.dirty do return;

    raw := transmute(mem.Raw_Slice)console_output.buf;
    r := w.write_console_output(console_output.handle,
            cast(^w.Char_Info)raw.data, console_output.size, w.Coord{0, 0},
            &console_output.surface);
    if !r {
        fmt.println("Error writing console output");
    }
    console_output.dirty = false;
}

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

main :: proc() {
    init_console_input();
    init_console_output();
    run();
    restore_console_output();
    restore_console_input();
}

run :: proc() {
    running: bool = true;
    for running {
        read_console_input();
        update_world(&running);
        flush_console_output();
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

    
quit_request := false;
char_pressed : u16 = 0;
translate_key_event :: proc(ev: w.Key_Event_Record) {
    if ev.key_down {
        if ev.char.unicode_char == 'q' do quit_request = true;
        else                           do char_pressed = ev.char.unicode_char;
    }
}
translate_mouse_event :: proc(ev: w.Mouse_Event_Record) {
}
translate_resize_event :: proc(ev: w.Resize_Event_Record) {
}
translate_menu_event :: proc(ev: w.Menu_Event_Record) {
}
translate_focus_event :: proc(ev: w.Focus_Event_Record) {

}
update_world :: proc(running: ^bool) {
    if quit_request do running^ = false;
    if char_pressed != 0 {
        write_char(char_pressed);
        char_pressed = 0;
    }
}

write_char :: proc(ch: u16) {
    out := &console_output;
    write_char_at(ch, out.cursor.x, out.cursor.y, out.default_attributes);
    if out.cursor.x < out.size.x - 1 {
        out.cursor.x += 1;
    } else if out.cursor.y < out.size.y - 1 {
        out.cursor.x = 0;
        out.cursor.y += 1;
    }
    w.set_console_cursor_position(out.handle, out.cursor);
}

write_char_at :: proc(ch: u16, x, y: i16, attr: u16) {
    size := console_output.size;
    if x >= size.x || y >= size.y do return;
    idx := y * size.x + x;
    console_output.buf[idx].char = ch;
    console_output.buf[idx].attr = attr;
    console_output.dirty = true;
}




