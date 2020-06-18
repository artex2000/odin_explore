package main

import w "shared:sys/windows"

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
            




