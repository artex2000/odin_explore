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

//make sure x-size of button is big enough to hold caption
Button :: struct {
    size : w.Coord,
    color: u16,
    type: Box_Type,
    caps: ar.str8,
}

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

draw_button_at :: proc(using bt: ^Button, x, y: i16) {
    dim := w.Small_Rect{ x, y, x + size.x - 1, y + size.y - 1 };

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

draw_button :: proc(acc: bool) {
    bt := Button{ { 10, 5 }, 0, .THIN_SINGLE, "Button" };

    if acc {
        bt.type = .THIN_DOUBLE;
        bt.color = u16((DARK_BASE0 << 4) | LIGHT_BASE0);
    } else {
        bt.type = .THIN_SINGLE;
        bt.color = u16((LIGHT_BASE0 << 4) | DARK_BASE0);
    }

    draw_button_at(&bt, 40, 40);
}








