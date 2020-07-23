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
    input_mode: w.Dword,
}

INPUT_BUFFER_LENGTH :: 50;

console_save_state: Console_State;
console_output: Console_Output;
console_input: Console_Input;


main :: proc() {
    r := init_console_output();
    if !r {
        fmt.println("Error initializing output");
        return;
    }
    defer restore_console_output();

    r = init_console_input();
    if !r {
        fmt.println("Error initializing input");
        return;
    }
    defer restore_console_input();

    string_buffer = make([dynamic]ar.str8, 20);
    run();
}

run :: proc() {
    running: bool = true;
    setup_main_screen();
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
    fmt.println(ar.cstr16_to_str8(str));
}

    
quit_request := false;
string_buffer: [dynamic]ar.str8;

Press_Type :: enum {
    KEY_UP,
    KEY_DOWN
}

Key_Event :: struct {
    type: Press_Type,
    key_code: u16,
    hw_code: u16,
}

//TODO: replace with ring buffer
key_event_buf : [10] Key_Event;
key_event_idx := 0;

translate_key_event :: proc(ev: w.Key_Event_Record) {
    key := &key_event_buf[key_event_idx];
    key.key_code = ev.virtual_key_code;
    key.hw_code = ev.virtual_scan_code;
    if ev.key_down {
        key.type = .KEY_DOWN;
        //TODO: replace with translation command
        if ev.char.unicode_char == 'q' do quit_request = true;
    } else {
        key.type = .KEY_UP;
    }
    key_event_idx += 1;
}

translate_mouse_event :: proc(ev: w.Mouse_Event_Record) {
}

translate_resize_event :: proc(ev: w.Resize_Event_Record) {
    msg := fmt.aprintf("Resize event: new size is %v", ev.size);
    append(&string_buffer, msg);
    resize_console_output(ev.size);
}

translate_menu_event :: proc(ev: w.Menu_Event_Record) {
}

translate_focus_event :: proc(ev: w.Focus_Event_Record) {

}

update_world :: proc(running: ^bool) {
    if quit_request do running^ = false;
    process_input();
    if keypad_redraw {
        draw_key_pad();
        keypad_redraw = false;
    }
    flush_string_buffer();
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

write_string_at :: proc(s: ar.str16, x, y: i16, attr: u16) {
    size := console_output.size;
    if x >= size.x || y >= size.y do return;
    idx := y * size.x + x;
    for v, i in s {
        console_output.buf[idx + i16(i)].char = v;
        console_output.buf[idx + i16(i)].attr = attr;
    }
    console_output.dirty = true;
}

setup_main_screen :: proc() {
    update_keypad();
    draw_key_pad();
}

current_bt : ^Button = nil;
keypad_redraw := false;

update_keypad :: proc() {
    bt := get_next_button();
    if bt != nil {
        if current_bt != nil do current_bt.state = .PRESSED;
        bt.state = .FOCUS;
        current_bt = bt;
        keypad_redraw = true;
    } else {
        if current_bt != nil {
            current_bt.state = .PRESSED;
            current_bt = bt;
            keypad_redraw = true;
        }
    }
}

process_input :: proc() {
    for key_event_idx > 0 {
        key := &key_event_buf[key_event_idx - 1];
        if key.type == .KEY_DOWN do update_keypad();
        msg := fmt.aprintf("Key press type %v", key.type);
        append(&string_buffer, msg);
        msg = fmt.aprintf("Key press code %v", key.key_code);
        append(&string_buffer, msg);
        msg = fmt.aprintf("Key press hw code %v", key.hw_code);
        append(&string_buffer, msg);
        key_event_idx -= 1;
    }
}

flush_string_buffer :: proc() {
    y : i16 = 20 + PAD_HEIGHT + PAD_SEPARATOR_HEIGHT;
    x : i16 = 10;
    color := u16((DARK_BASE0 << 4) | CONTENT_MEDIUM_LIGHT);

    for v in string_buffer {
        write_string_at(ar.str8_to_str16(v), x, y, color);
        y += 1;
    }
    clear_dynamic_array(&string_buffer);
}

draw_key_pad :: proc() {
    full := true;
    w : i16 = LETTER_PAD_WIDTH + ARROW_PAD_WIDTH + NUM_PAD_WIDTH + PAD_SEPARATOR_WIDTH * 2;
    if w > console_output.size.x {
        w = ARROW_PAD_WIDTH + NUM_PAD_WIDTH + PAD_SEPARATOR_WIDTH;
        full = false;
    }
    h : i16 = PAD_HEIGHT + PAD_SEPARATOR_HEIGHT;
    x := (console_output.size.x - w) / 2;
    //y := (console_output.size.y - h) / 2;
    //x : i16 = 2;
    y : i16 = 20;
    draw_key_pad_at(x, y, full);
}

        

