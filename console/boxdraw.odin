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
        console_output.buf[idx].attr = c;
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
        write_string_at(ar.str8_to_str16(transmute(ar.str8)msg), col, row + j, u16(color << 4) + attr);
        color += 1;
    }
    console_output.dirty = true;
}

Color_String :: struct {
    str: string,
    attr: u16,
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

    attr := console_output.default_attributes & 0xFF00;
    for v in info {
        write_string_at(ar.str8_to_str16(transmute(ar.str8)v.str), col, row, u16(attr | v.attr));
        row += 1;
    }
}



