package main

import "core:fmt"
import w "shared:sys/windows"
import ar "shared:array"

draw_single_box :: proc(dim: w.Small_Rect, attr: u16 = 0) {
    c: u16;
    if attr == 0 {
        c = console_output.default_attributes;
    } else {
        c = attr;
    }

    write_char_at(SINGLE_LEFT_TOP_CORNER, dim.left, dim.top, c);
    write_char_at(SINGLE_RIGHT_TOP_CORNER, dim.right, dim.top, c);
    write_char_at(SINGLE_LEFT_BOTTOM_CORNER, dim.left, dim.bottom, c);
    write_char_at(SINGLE_RIGHT_BOTTOM_CORNER, dim.right, dim.bottom, c);

    draw_hor_line(SINGLE_HOR_LINE, dim.left + 1, dim.right - 1, dim.top, c);
    draw_hor_line(SINGLE_HOR_LINE, dim.left + 1, dim.right - 1, dim.bottom, c);
    draw_ver_line(SINGLE_VER_LINE, dim.top + 1, dim.bottom - 1, dim.left, c);
    draw_ver_line(SINGLE_VER_LINE, dim.top + 1, dim.bottom - 1, dim.right, c);
}

draw_double_box :: proc(dim: w.Small_Rect, attr: u16 = 0) {
    c: u16;
    if attr == 0 {
        c = console_output.default_attributes;
    } else {
        c = attr;
    }

    write_char_at(DOUBLE_LEFT_TOP_CORNER, dim.left, dim.top, c);
    write_char_at(DOUBLE_RIGHT_TOP_CORNER, dim.right, dim.top, c);
    write_char_at(DOUBLE_LEFT_BOTTOM_CORNER, dim.left, dim.bottom, c);
    write_char_at(DOUBLE_RIGHT_BOTTOM_CORNER, dim.right, dim.bottom, c);

    draw_hor_line(DOUBLE_HOR_LINE, dim.left + 1, dim.right - 1, dim.top, c);
    draw_hor_line(DOUBLE_HOR_LINE, dim.left + 1, dim.right - 1, dim.bottom, c);
    draw_ver_line(DOUBLE_VER_LINE, dim.top + 1, dim.bottom - 1, dim.left, c);
    draw_ver_line(DOUBLE_VER_LINE, dim.top + 1, dim.bottom - 1, dim.right, c);
}

fill_rect :: proc(using dim: w.Small_Rect, attr: u16 = 0) {
    attr := console_output.default_attributes & 0xFF00 | attr;

    for j := top; j <= bottom; j += 1 {
        idx := j * console_output.size.x;
        for i := left; i <= right; i += 1 {
            console_output.buf[idx + i].char = ' ';
            console_output.buf[idx + i].attr = attr;
        }
    }
    console_output.dirty = true;
}


draw_hor_line :: proc(pen: u16, from, to, pos: i16, attr: u16 = 0) {
    c: u16;
    if attr == 0 {
        c = console_output.default_attributes;
    } else {
        c = attr;
    }

    idx := pos * console_output.size.x;     //select correct row
    for i := from; i <= to; i += 1 {
        console_output.buf[idx + i].char = pen;
        console_output.buf[idx + i].attr = c;
    }
}

draw_ver_line :: proc(pen: u16, from, to, pos: i16, attr: u16 = 0) {
    c: u16;
    if attr == 0 {
        c = console_output.default_attributes;
    } else {
        c = attr;
    }

    for i := from; i <= to; i += 1 {
        idx := i * console_output.size.x + pos;
        console_output.buf[idx].char = pen;
        console_output.buf[idx].attr = c;
    }
}
            
draw_palette :: proc() {
    row := 20;
    from := 20;
    to := 50;

    attr := console_output.default_attributes & 0xFF0F;

    color := 0;
    for j := 0; j < 16; j += 1 {
        idx := (row + j) * int(console_output.size.x);
        for i := from; i <= to; i += 1 {
            console_output.buf[idx + i].char = '+';
            console_output.buf[idx + i].attr = u16(color << 4) + attr;
        }
        color += 1;
    }
    console_output.dirty = true;
}
            
draw_palette_ex :: proc() {
    row : i16 = 20;
    col : i16 = 20;

    attr := console_output.default_attributes & 0xFF0F;

    color := 0;
    for j : i16 = 0; j < 16; j += 1 {
        msg := fmt.aprintf("Index: %02d               ", j);
        write_string_at(ar.str8_to_str16(msg), col, row + j, u16(color << 4) + attr);
        color += 1;
    }
    console_output.dirty = true;
}

Color_String :: struct {
    str: string,
    attr: u16,
}

Box_Type :: enum {
    THIN_SINGLE,
    THIN_DOUBLE
}

Button_State :: enum {
    NONE,
    FOCUS,
    PRESSED
}

//make sure x-size of button is big enough to hold caption
Button :: struct {
    offset: w.Coord,
    size : w.Coord,
    state: Button_State,
    caps: ar.str8,
}

Button_Pad :: struct {
    buttons: []Button,
}

PAD_SEPARATOR_WIDTH :: 5;
PAD_SEPARATOR_HEIGHT :: 3;

NUM_PAD_WIDTH :: 35;
ARROW_PAD_WIDTH :: 26;
LETTER_PAD_WIDTH :: 125;
PAD_HEIGHT :: 24;

num_pad: Button_Pad = { 
    {
        { { 0, 0 }, { 8, 4 },   .NONE, "N_Lock" },
        { { 9, 0 }, { 8, 4 },   .NONE, " / " },
        { { 18, 0 }, { 8, 4 },  .NONE, " * " },
        { { 27, 0 }, { 8, 4 },  .NONE, " - " },

        { { 0, 4 }, { 8, 4 },   .NONE, " 7 " },
        { { 9, 4 }, { 8, 4 },   .NONE, " 8 " },
        { { 18, 4 }, { 8, 4 },  .NONE, " 9 " },
        { { 27, 4 }, { 8, 8 },  .NONE, " + " },
        
        { { 0, 8 }, { 8, 4 },  .NONE, " 4 " },
        { { 9, 8 }, { 8, 4 },  .NONE, " 5 " },
        { { 18, 8 }, { 8, 4 }, .NONE, " 6 " },

        { { 0, 12 }, { 8, 4 },  .NONE, " 1 " },
        { { 9, 12 }, { 8, 4 },  .NONE, " 2 " },
        { { 18, 12 }, { 8, 4 }, .NONE, " 3 " },
        { { 27, 12 }, { 8, 8 }, .NONE, "Enter" },

        { { 0, 16 }, { 17, 4 }, .NONE, " 0 " },
        { { 18, 16 }, { 8, 4 }, .NONE, " . " },
    }
};

arrow_pad: Button_Pad = {
    {
        { { 0, 0 }, { 8, 4 },   .NONE, "Ins" },
        { { 9, 0 }, { 8, 4 },   .NONE, "Home" },
        { { 18, 0 }, { 8, 4 },  .NONE, "PgUp" },
        { { 0, 4 }, { 8, 4 },   .NONE, "Del" },
        { { 9, 4 }, { 8, 4 },   .NONE, "End" },
        { { 18, 4 }, { 8, 4 },  .NONE, "PgDown" },

        { { 9, 12 }, { 8, 4 },  .NONE, " ^ " },
        { { 0, 16 }, { 8, 4 },  .NONE, " < " },
        { { 9, 16 }, { 8, 4 },  .NONE, " v " },
        { { 18, 16 }, { 8, 4 }, .NONE, " > " },
    }
};

letter_pad: Button_Pad = {
    {
        { { 0, 0 }, { 8, 4 },   .NONE, "Esc" },
        { { 9, 0 }, { 8, 4 },   .NONE, "F1" },
        { { 18, 0 }, { 8, 4 },   .NONE, "F2" },
        { { 27, 0 }, { 8, 4 },   .NONE, "F3" },
        { { 36, 0 }, { 8, 4 },   .NONE, "F4" },
        { { 45, 0 }, { 8, 4 },   .NONE, "F5" },
        { { 54, 0 }, { 8, 4 },   .NONE, "F6" },
        { { 63, 0 }, { 8, 4 },   .NONE, "F7" },
        { { 72, 0 }, { 8, 4 },   .NONE, "F8" },
        { { 81, 0 }, { 8, 4 },   .NONE, "F9" },
        { { 90, 0 }, { 8, 4 },   .NONE, "F10" },
        { { 99, 0 }, { 8, 4 },   .NONE, "F11" },
        { { 108, 0 }, { 8, 4 },   .NONE, "F12" },
        { { 117, 0 }, { 8, 8 },   .NONE, "BkSp" },

        { { 0, 4 }, { 8, 4 },   .NONE, " ~ " },
        { { 9, 4 }, { 8, 4 },   .NONE, " 1 " },
        { { 18, 4 }, { 8, 4 },   .NONE, " 2 " },
        { { 27, 4 }, { 8, 4 },   .NONE, " 3 " },
        { { 36, 4 }, { 8, 4 },   .NONE, " 4 " },
        { { 45, 4 }, { 8, 4 },   .NONE, " 5 " },
        { { 54, 4 }, { 8, 4 },   .NONE, " 6 " },
        { { 63, 4 }, { 8, 4 },   .NONE, " 7 " },
        { { 72, 4 }, { 8, 4 },   .NONE, " 8 " },
        { { 81, 4 }, { 8, 4 },   .NONE, " 9 " },
        { { 90, 4 }, { 8, 4 },   .NONE, " 0 " },
        { { 99, 4 }, { 8, 4 },   .NONE, " - " },
        { { 108, 4 }, { 8, 4 },   .NONE, " + " },

        { { 0, 8 }, { 8, 4 },   .NONE, "Tab" },
        { { 9, 8 }, { 8, 4 },   .NONE, " Q " },
        { { 18, 8 }, { 8, 4 },   .NONE, " W " },
        { { 27, 8 }, { 8, 4 },   .NONE, " E " },
        { { 36, 8 }, { 8, 4 },   .NONE, " R" },
        { { 45, 8 }, { 8, 4 },   .NONE, " T" },
        { { 54, 8 }, { 8, 4 },   .NONE, " Y " },
        { { 63, 8 }, { 8, 4 },   .NONE, " U " },
        { { 72, 8 }, { 8, 4 },   .NONE, " I " },
        { { 81, 8 }, { 8, 4 },   .NONE, " O " },
        { { 90, 8 }, { 8, 4 },   .NONE, " P " },
        { { 99, 8 }, { 8, 4 },   .NONE, " [ " },
        { { 108, 8 }, { 8, 4 },   .NONE, " ] " },
        { { 117, 8 }, { 8, 8 },   .NONE, "Enter" },
        
        { { 0, 12 }, { 8, 4 },   .NONE, " Caps " },
        { { 9, 12 }, { 8, 4 },   .NONE, " A " },
        { { 18, 12 }, { 8, 4 },   .NONE, " S " },
        { { 27, 12 }, { 8, 4 },   .NONE, " D " },
        { { 36, 12 }, { 8, 4 },   .NONE, " F " },
        { { 45, 12 }, { 8, 4 },   .NONE, " G " },
        { { 54, 12 }, { 8, 4 },   .NONE, " H " },
        { { 63, 12 }, { 8, 4 },   .NONE, " J " },
        { { 72, 12 }, { 8, 4 },   .NONE, " K " },
        { { 81, 12 }, { 8, 4 },   .NONE, " L " },
        { { 90, 12 }, { 8, 4 },   .NONE, " ; " },
        { { 99, 12 }, { 8, 4 },   .NONE, " \" " },
        { { 108, 12 }, { 8, 4 },   .NONE, " \\ " },

        { { 0, 16 }, { 12, 4 },   .NONE, "LShift" },
        { { 13, 16 }, { 8, 4 },   .NONE, " Z " },
        { { 22, 16 }, { 8, 4 },   .NONE, " X " },
        { { 31, 16 }, { 8, 4 },   .NONE, " C " },
        { { 40, 16 }, { 8, 4 },   .NONE, " V " },
        { { 49, 16 }, { 8, 4 },   .NONE, " B " },
        { { 58, 16 }, { 8, 4 },   .NONE, " N " },
        { { 67, 16 }, { 8, 4 },   .NONE, " M " },
        { { 76, 16 }, { 8, 4 },   .NONE, " < " },
        { { 85, 16 }, { 8, 4 },   .NONE, " > " },
        { { 94, 16 }, { 8, 4 },   .NONE, " / " },
        { { 103, 16 }, { 13, 4 },   .NONE, "Rshift" },

        { { 0, 20 }, { 12, 4 },   .NONE, "LCtrl" },
        { { 13, 20 }, { 8, 4 },   .NONE, "Win" },
        { { 22, 20 }, { 8, 4 },   .NONE, "LAlt" },
        { { 31, 20 }, { 53, 4 },   .NONE, "Space" },
        { { 85, 20 }, { 8, 4 },   .NONE, "RAlt" },
        { { 94, 20 }, { 8, 4 },   .NONE, "Menu" },
        { { 103, 20 }, { 13, 4 },   .NONE, "RCtrl" },
    }
};

info : []Color_String = {
    { "This is muted string", u16((DARK_BASE0 << 4) | CONTENT_DARK) },
    { "This is toned string", u16((DARK_BASE0 << 4) | CONTENT_MEDIUM_DARK) },
    { "This is regular string", u16((DARK_BASE0 << 4) | CONTENT_MEDIUM_LIGHT) },
    { "This is light string", u16((DARK_BASE0 << 4) | CONTENT_LIGHT) },
    { "This is contrast string", u16((DARK_BASE0 << 4) | LIGHT_BASE1) },
    { "This is high contrast string", u16((DARK_BASE0 << 4) | LIGHT_BASE0) },
};

draw_palette_str :: proc() {
    row : i16 = 20;
    col : i16 = 20;

//    attr := console_output.default_attributes & 0xFF00;
    for v in info {
        write_string_at(ar.str8_to_str16(v.str), col, row, v.attr);
        row += 1;
    }
}

draw_button :: proc(using bt: ^Button) {
    dim := w.Small_Rect{ offset.x, offset.y, offset.x + size.x - 1, offset.y + size.y - 1 };
    color : u16;
    type : Box_Type;

    switch bt.state {
    case .NONE:
        color = u16((DARK_BASE0 << 4) | CONTENT_MEDIUM_LIGHT);
        type = .THIN_SINGLE;
    case .FOCUS:
        color = u16((LIGHT_BASE0 << 4) | DARK_BASE0);
        type = .THIN_DOUBLE;
    case .PRESSED:
        color = u16(( CONTENT_DARK << 4) | DARK_BASE0);
        type = .THIN_SINGLE;
    }

    fill_rect(dim, color);
    switch type {
    case .THIN_SINGLE:
        draw_single_box(dim, color);
    case .THIN_DOUBLE:
        draw_double_box(dim, color);
    }

    //it's better to have odd number of lines for button height
    caps_y := (dim.bottom - dim.top) / 2 + dim.top;
    caps_x := (dim.right - dim.left + 1 - cast(i16)len(caps)) / 2 + dim.left;
    write_string_at(ar.str8_to_str16(caps), caps_x, caps_y, color);
}

draw_button_pad :: proc (x, y: i16, pad: ^Button_Pad) {
    for v in pad.buttons {
        tmp := v;
        tmp.offset.x += x;
        tmp.offset.y += y;
        draw_button(&tmp);
    }
}

draw_key_pad_at :: proc(x, y: i16, full: bool) {
    xl := x;
    if(!full) {
        draw_button_pad(xl, y, &arrow_pad);
        xl += ARROW_PAD_WIDTH + PAD_SEPARATOR_WIDTH;
        draw_button_pad(xl, y, &num_pad);
    } else {
        draw_button_pad(xl, y, &letter_pad);
        xl += LETTER_PAD_WIDTH + PAD_SEPARATOR_WIDTH;
        draw_button_pad(xl, y, &arrow_pad);
        xl += ARROW_PAD_WIDTH + PAD_SEPARATOR_WIDTH;
        draw_button_pad(xl, y, &num_pad);
    }
}

current_button := 0;

get_next_button :: proc() -> ^Button {
    defer current_button += 1;
    if current_button < len(arrow_pad.buttons) do return &arrow_pad.buttons[current_button];
    idx := current_button - len(arrow_pad.buttons);
    if idx < len(num_pad.buttons) do return &num_pad.buttons[idx];
    return nil;
}







