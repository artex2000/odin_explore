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

string_buffer: [dynamic]ar.str8;

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
    msg := fmt.aprintf("Resize event: new size is %v", ev.size);
    append(&string_buffer, transmute(ar.str8)msg);
    resize_console_output(ev.size);
}
translate_menu_event :: proc(ev: w.Menu_Event_Record) {
}
translate_focus_event :: proc(ev: w.Focus_Event_Record) {

}
update_world :: proc(running: ^bool) {
    if quit_request do running^ = false;
    if char_pressed != 0 {
        process_char(char_pressed);
        char_pressed = 0;
    }
    for v in string_buffer do write_string(v);
    clear_dynamic_array(&string_buffer);
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

write_string :: proc(s: ar.str8) {
    s16 := ar.str8_to_str16(s);
    out := &console_output;
    //print on new line for now
    if out.cursor.x != 0 {
        out.cursor.x = 0;
        out.cursor.y += 1;
    }
    write_string_at(s16, out.cursor.x, out.cursor.y, out.default_attributes);
    out.cursor.x += i16(len(s16));
    w.set_console_cursor_position(out.handle, out.cursor);
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

bx: i16 = 10;
by: i16 = 10;
process_char :: proc(c: u16) {
    if c == 'a' do draw_single_box(w.Small_Rect { bx, by, bx + 6, by + 3});
    else if c == 's' do draw_double_box(w.Small_Rect { bx, by, bx + 6, by + 3});
    else if c == 'p' do draw_palette_ex();
    else if c == 'd' do draw_palette_str();
    else if c == 'l' do bx += 10;
    else if c == 'j' do by += 10;
}



