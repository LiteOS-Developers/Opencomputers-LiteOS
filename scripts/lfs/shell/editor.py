import string
import time
import typing

import _curses
import curses, curses.ascii
import sys
import lfs.shell.vk_code as vk

def _exit(stdscr):
    curses.raw(False)

class Buffer:
    def __init__(self, lines:list[str]):
        self.lines = lines

    def __len__(self):
        return len(self.lines)

    def __getitem__(self, index):
        return self.lines[index]

    @property
    def bottom(self):
        return len(self.lines) - 1

    def insert(self, cursor, string):
        row, col = cursor.row, cursor.col
        current = self.lines.pop(row)
        new = current[:col] + string + current[col:]
        self.lines.insert(row, new)

    def split(self, cursor):
        row, col = cursor.row, cursor.col
        current = self.lines.pop(row)
        self.lines.insert(row, current[:col])
        self.lines.insert(row + 1, current[col:])

    def delete(self, cursor): 
        row, col = cursor.row, cursor.col
        if (row, col) < (self.bottom, len(self.lines[row])):
            # print(col, len(self.lines[row]), len(self[row]))
            # sys.exit()
            if 1 <= col < len(self.lines[row]):
                current = self.lines.pop(row)
                new = current[:col - 1] + current[col:]
                self.lines.insert(row, new)
                return True
            if 1 <= col == len(self.lines[row]):
                current = self.lines.pop(row)
                new = current[:col - 1]
                self.lines.insert(row, new)
                return True
            elif col == 0 and col <= len(self.lines[row]):
                current = self.lines.pop(row)
                prev = self.lines.pop(row - 1)
                new = prev + current
                self.lines.insert(row - 1, new)
                cursor.row -= 1
                cursor.col = len(prev)
                return False
            # elif col == 0 and col == len(self.lines)
            else:
                print((col, len(self.lines[row]), 1 <= col, col < len(self.lines[row]), repr(self.lines[row]), row))
                print(self.lines[:10])
                sys.exit()


def clamp(x, lower, upper):
    if x < lower:
        return lower
    if x > upper:
        return upper
    return x


class Cursor:
    def __init__(self, row=0, col=0, col_hint=None):
        self.row = row
        self._col = col
        self._col_hint = col if col_hint is None else col_hint

    @property
    def col(self):
        return self._col

    @col.setter
    def col(self, col):
        self._col = col
        self._col_hint = col

    def _clamp_col(self, buffer):
        self._col = min(self._col_hint, len(buffer[self.row]))

    def up(self, buffer):
        if self.row > 0:
            self.row -= 1
            self._clamp_col(buffer)

    def down(self, buffer):
        if self.row < len(buffer) - 1:
            self.row += 1
            self._clamp_col(buffer)

    def left(self, buffer):
        if self.col > 0:
            self.col -= 1
        elif self.row > 0:
            self.row -= 1
            self.col = len(buffer[self.row])

    def right(self, buffer):
        if self.col < len(buffer[self.row]):
            self.col += 1
        elif self.row < len(buffer) - 1:
            self.row += 1
            self.col = 0


class Window:
    def __init__(self, n_rows, n_cols, row=0, col=0):
        self.n_rows = n_rows
        self.n_cols = n_cols
        self.row = row
        self.col = col

    @property
    def bottom(self):
        return self.row + self.n_rows - 1

    def up(self, cursor):
        if cursor.row == self.row - 1 and self.row > 0:
            self.row -= 1

    def down(self, buffer, cursor):
        if cursor.row == self.bottom + 1 and self.bottom < len(buffer) - 1:
            self.row += 1

    def horizontal_scroll(self, cursor, left_margin=5, right_margin=2):
        n_pages = cursor.col // (self.n_cols - right_margin)
        self.col = max(n_pages * self.n_cols - right_margin - left_margin, 0)

    def translate(self, cursor):
        return cursor.row - self.row, cursor.col - self.col


def left(window, buffer, cursor):
    cursor.left(buffer)
    window.up(cursor)
    window.horizontal_scroll(cursor)


def right(window, buffer, cursor):
    cursor.right(buffer)
    window.down(buffer, cursor)
    window.horizontal_scroll(cursor)


def main(stdscr:_curses.window, lines, savefunc:typing.Callable):
    # curses.noecho()
    # stdscr.keypad(True)
    # curses.cbreak()
    curses.raw(True)
    buffer = Buffer(lines)
    window = Window(curses.LINES - 2, curses.COLS - 1)
    cursor = Cursor()
    stdscr.refresh()

    while True:
        stdscr.erase()
        for row, line in enumerate(buffer[window.row:window.row + window.n_rows]):
            if row == cursor.row - window.row and window.col > 0:
                line = "«" + line[window.col + 1:]
            if len(line) > window.n_cols:
                line = line[:window.n_cols - 1] + "»"
            stdscr.addstr(row, 0, line)
        stdscr.move(*window.translate(cursor))
        stdscr.refresh()
        k = stdscr.getch()
        if k == vk.VK_CANCEL:
            height, width = stdscr.getmaxyx()
            y, x = stdscr.getyx()
            stdscr.move(height - 1, 0)
            stdscr.addstr(": ")
            stdscr.refresh()
            while True:
                key = stdscr.getkey()
                _y, _x = stdscr.getyx()
                stdscr.move(_y, _x + 1)
                stdscr.refresh()
                stdscr.move(height - 1, 2)
                # stdscr.clrtoeol()
                if not key in string.printable:
                    stdscr.addstr("String not printable")
                    stdscr.refresh()
                    stdscr.clrtoeol()
                    continue
                if key == "q":
                    _exit(stdscr)
                    return
                elif key == "c":
                    stdscr.move(height - 1, 0)
                    stdscr.refresh()
                    stdscr.clrtoeol()
                    stdscr.move(y, x)
                    stdscr.refresh()
                    # stdscr.addstr(": ")
                    break
                elif key == curses.KEY_LEFT: pass
                elif key == curses.KEY_DOWN: pass
                elif key == curses.KEY_UP: pass
                elif key == curses.KEY_RIGHT: pass
                elif key == "w":
                    stdscr.move(height - 1, 0)
                    stdscr.refresh()
                    stdscr.clrtoeol()
                    stdscr.move(y, x)
                    stdscr.refresh()
                    savefunc(buffer.lines)

            # time.sleep(1)
        elif k == curses.KEY_LEFT:
            left(window, buffer, cursor)
        elif k == curses.KEY_DOWN:
            cursor.down(buffer)
            window.down(buffer, cursor)
            window.horizontal_scroll(cursor)
        elif k == curses.KEY_UP:
            cursor.up(buffer)
            window.up(cursor)
            window.horizontal_scroll(cursor)
        elif k == vk.VK_TAB:
            for _ in range(4):
                buffer.insert(cursor, " ")
                right(window, buffer, cursor)
        elif k == curses.KEY_RIGHT:
            right(window, buffer, cursor)
        elif k == vk.VK_RETURN:
            buffer.split(cursor)
            right(window, buffer, cursor)
        elif k == vk.VK_DELETE:
            buffer.delete(cursor)
        elif k == vk.VK_BACK:
            if (cursor.row, cursor.col) > (0, 0):
                if buffer.delete(cursor):
                    left(window, buffer, cursor)
        else:
            print(vk.code_to_name[k])
            _exit(stdscr)
            return
            buffer.insert(cursor, chr(k))
            for _ in k:
                right(window, buffer, cursor)

def save(lines):
    with open("editor.buf", "w") as f:
        f.writelines([x + "\n" for x in lines])

def init(lines, savefnc):
    curses.wrapper(main, lines, savefnc)


# EXAMPLE:
if __name__ == '__main__':
    with open("editor.py") as f:
        init([x[:-1] for x in f.readlines()], save)