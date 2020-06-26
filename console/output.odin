package main

import "core:fmt"
import "core:mem"
import w "shared:sys/windows"

init_console_output :: proc() -> bool {
    out := w.get_std_handle(w.STD_OUTPUT_HANDLE);
    if uintptr(out) == w.INVALID_HANDLE_VALUE {
        fmt.println("Error getting STD_OUT handle");
        return false;
    }
    console_save_state.out = out;

    info: w.Console_Screen_Buffer_Info;
    r := w.get_console_screen_buffer_info(out, &info);
    if !r {
        fmt.println("Error getting console info");
        return false;
    } else {
        fmt.printf("buf size %v\n", info.size);
        fmt.printf("max size %v\n", info.max_window_size);
        fmt.printf("window pos %v\n", info.window);
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

    new_buffer_size := w.Coord{ info.window.right - info.window.left + 1,
                                info.window.bottom - info.window.top + 1 };

    r = w.set_console_screen_buffer_size(out2, new_buffer_size);
    if !r {
        fmt.println("Error setting screen buffer size");
        return false;
    }

    surface := w.Small_Rect{ 0, 0, new_buffer_size.x - 1, new_buffer_size.y - 1 };
    console_output.size = new_buffer_size;
    console_output.surface = surface;
    console_output.default_attributes = (info.attributes & 0xFF00) | DARK_REGULAR;
    console_output.buf = make([]w.Char_Info, new_buffer_size.x * new_buffer_size.y);
    console_output.cursor = w.Coord{0, 0};

    for _, i in console_output.buf {
        console_output.buf[i].char = ' ';
        console_output.buf[i].attr = console_output.default_attributes;
    }

    raw := transmute(mem.Raw_Slice)console_output.buf;
    r = w.write_console_output(out2, cast(^w.Char_Info)raw.data,
            new_buffer_size, w.Coord{0, 0}, &surface);
    if !r {
        fmt.println("Error writing console output");
        return false;
    }
    console_output.dirty = false;
    return true;
}

restore_console_output :: proc() {
    r := w.set_console_active_screen_buffer(console_save_state.out);
    if !r {
        fmt.println("Error restoring screen buffer");
        return;
    }
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

resize_console_output :: proc(size: w.Coord) {
    if (size.x == console_output.size.x) && (size.y == console_output.size.y) do return;
    r := w.set_console_screen_buffer_size(console_output.handle, size);
    if !r {
        fmt.println("Error setting screen buffer size");
    }
    buf := make([]w.Char_Info, size.x * size.y);

    //we need to clear new buffer if it is bigger than current
    if size.x > console_output.size.x || size.y > console_output.size.y {
        for _, i in buf {
            buf[i].char = ' ';
            buf[i].attr = console_output.default_attributes;
        }
    }

    minx := min(size.x, console_output.size.x);
    miny := min(size.y, console_output.size.y);
    //copy content from current buffer
    for y : i16 = 0; y < miny; y += 1 {
        row_src := y * console_output.size.x;
        row_dst := y * size.x;
        for x : i16 = 0; x < minx; x += 1 {
            buf[row_dst + x].char = console_output.buf[row_src + x].char;
            buf[row_dst + x].attr = console_output.buf[row_src + x].attr;
        }
    }

    delete(console_output.buf);
    console_output.buf = buf;
    console_output.size = size;
    console_output.surface = w.Small_Rect{ 0, 0, size.x - 1, size.y - 1};
    console_output.dirty = true;
}



