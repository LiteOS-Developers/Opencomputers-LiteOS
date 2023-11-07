import argparse
import curses, curses.ascii
import sys

def _exit(stdscr):
    curses.nocbreak()
    stdscr.keypad(False)
    curses.echo()
    curses.raw(False)
    sys.exit()

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


def main(stdscr, lines):
    curses.noecho()
    stdscr.keypad(True)
    curses.cbreak()
    curses.raw(True)
    window = Window(curses.LINES - 1, curses.COLS - 1)
    stdscr.refresh()
    # win = curses.newwin(window.n_rows, window.n_cols, window.row, window.col)
    # win.scrollok(True)

    while True:
        k = stdscr.getch()
        # win.addstr(f'key {chr(k)} typed.\n')
        if k == 3:
            _exit(stdscr)


        stdscr.refresh()
        # time.sleep(0.1)

def init(lines):
    curses.wrapper(main, lines)

if __name__ == '__main__':
    with open("editor.py") as f:
        init([x[:-1] for x in f.readlines()])