use ropey::{Rope, RopeSlice};
use std::sync::{RwLock, RwLockReadGuard};

pub struct Buffer {
    rope: RwLock<Rope>,
}

impl Buffer {
    pub fn new(initial_text: &str) -> Self {
        Self {
            rope: RwLock::new(Rope::from_str(initial_text)),
        }
    }

    pub fn rope(&self) -> RwLockReadGuard<'_, Rope> {
        self.rope.read().unwrap()
    }

    pub fn snapshot(&self) -> Rope {
        self.rope().clone()
    }

    pub fn len_chars(&self) -> usize {
        self.rope().len_chars()
    }

    pub fn text(&self) -> String {
        self.rope().to_string()
    }

    pub fn insert(&self, char_idx: usize, text: &str) {
        if text.is_empty() {
            return;
        }
        let mut rope = self.rope.write().unwrap();
        let idx = char_idx.min(rope.len_chars());
        rope.insert(idx, text);
    }

    pub fn remove(&self, start: usize, end: usize) {
        if start >= end {
            return;
        }
        let mut rope = self.rope.write().unwrap();
        let len = rope.len_chars();
        if start >= len {
            return;
        }
        rope.remove(start..end.min(len));
    }

    pub fn slice(&self, start: usize, end: usize) -> String {
        let rope = self.rope();
        let len = rope.len_chars();
        let valid_start = start.min(len);
        let valid_end = end.max(valid_start).min(len);
        if valid_start == valid_end {
            return String::new();
        }
        let slice = rope.slice(valid_start..valid_end);
        match slice.as_str() {
            Some(s) => s.to_owned(),
            None => slice.to_string(),
        }
    }

    pub fn char_to_line(&self, char_idx: usize) -> usize {
        let rope = self.rope();
        rope.char_to_line(char_idx.min(rope.len_chars()))
    }

    pub fn line_to_char(&self, line_idx: usize) -> usize {
        let rope = self.rope();
        rope.line_to_char(line_idx.min(rope.len_lines().saturating_sub(1)))
    }

    pub fn line(&self, line_idx: usize) -> String {
        let rope = self.rope();
        let valid_idx = line_idx.min(rope.len_lines().saturating_sub(1));
        line_without_break(&rope, valid_idx)
    }

    pub fn len_lines(&self) -> usize {
        self.rope().len_lines()
    }

    pub fn lines(&self, start_line: usize, end_line: usize) -> Vec<String> {
        let rope = self.rope();
        let total = rope.len_lines();
        let start = start_line.min(total);
        let end = end_line.min(total).max(start);
        let count = end - start;
        let mut result = Vec::with_capacity(count);
        result.extend(rope.lines_at(start).take(count).map(trim_line_break));
        result
    }
}

pub(super) fn line_without_break(rope: &Rope, line_idx: usize) -> String {
    trim_line_break(rope.line(line_idx))
}

fn trim_line_break(line: RopeSlice<'_>) -> String {
    if let Some(s) = line.as_str() {
        return s
            .strip_suffix("\r\n")
            .or_else(|| s.strip_suffix('\n'))
            .unwrap_or(s)
            .to_owned();
    }
    let len = line.len_chars();
    let trim = if len > 0 && line.char(len - 1) == '\n' {
        if len > 1 && line.char(len - 2) == '\r' {
            2
        } else {
            1
        }
    } else {
        0
    };
    line.slice(..len - trim).to_string()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn edits_out_of_bounds_are_clamped() {
        let buffer = Buffer::new("abc");
        buffer.insert(10, "d");
        buffer.remove(2, 10);
        buffer.remove(3, 1);
        assert_eq!(buffer.text(), "ab");
    }

    #[test]
    fn test_lines_and_slices_crlf_and_lf() {
        let text = "line 1\r\nline 2\nline 3\r\n\r\nlast line";
        let buffer = Buffer::new(text);
        assert_eq!(buffer.len_lines(), 5);
        assert_eq!(
            buffer.lines(0, 5),
            vec!["line 1", "line 2", "line 3", "", "last line"]
        );
        assert_eq!(buffer.lines(1, 3), vec!["line 2", "line 3"]);
        assert_eq!(buffer.lines(4, 10), vec!["last line"]);
        assert_eq!(buffer.lines(5, 10), Vec::<String>::new());
        assert_eq!(buffer.lines(3, 3), Vec::<String>::new());

        assert_eq!(buffer.slice(0, 6), "line 1");
        assert_eq!(buffer.slice(0, 0), "");
        assert_eq!(buffer.slice(100, 200), "");
    }
}
