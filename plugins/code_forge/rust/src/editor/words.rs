use ropey::Rope;
use std::cmp::Ordering;
use std::collections::HashSet;
use std::mem;

const MAX_WORDS: usize = 5_000;

// Mirrors plugins/code_forge/lib/code_forge/word_chars.dart, which decides the
// prefix these words are matched against.
const WORD_RANGES: [(char, char); 13] = [
    ('\u{30}', '\u{39}'),
    ('\u{41}', '\u{5A}'),
    ('\u{5F}', '\u{5F}'),
    ('\u{61}', '\u{7A}'),
    ('\u{0590}', '\u{05FF}'),
    ('\u{0600}', '\u{06FF}'),
    ('\u{08A0}', '\u{08FF}'),
    ('\u{3040}', '\u{309F}'),
    ('\u{30A0}', '\u{30FF}'),
    ('\u{3400}', '\u{4DBF}'),
    ('\u{4E00}', '\u{9FFF}'),
    ('\u{AC00}', '\u{D7AF}'),
    ('\u{F900}', '\u{FAFF}'),
];

const BYTE_CLASS: [u8; 256] = {
    let mut table = [0u8; 256];
    let mut i = 0usize;
    while i < 128 {
        let b = i as u8;
        if b.is_ascii_alphabetic() || b == b'_' {
            table[i] = 1;
        } else if b.is_ascii_digit() {
            table[i] = 2;
        }
        i += 1;
    }
    while i < 256 {
        table[i] = 4;
        i += 1;
    }
    table
};

#[derive(Clone, Copy, PartialEq, Eq)]
enum ScanState {
    Outside,
    Valid,
    Invalid,
}

#[inline(always)]
fn is_non_ascii_word_char(ch: char) -> bool {
    if ch < '\u{0590}' || ch > '\u{FAFF}' {
        return false;
    }
    WORD_RANGES[4..]
        .binary_search_by(|&(from, to)| {
            if ch < from {
                Ordering::Greater
            } else if ch > to {
                Ordering::Less
            } else {
                Ordering::Equal
            }
        })
        .is_ok()
}

#[inline(always)]
fn flush_slice(words: &mut HashSet<String>, slice: &str) -> bool {
    if !words.contains(slice) {
        words.insert(slice.to_owned());
        if words.len() >= MAX_WORDS {
            return true;
        }
    }
    false
}

#[inline(always)]
fn flush_owned(words: &mut HashSet<String>, current_word: &mut String) -> bool {
    if !words.contains(current_word.as_str()) {
        words.insert(mem::take(current_word));
        if words.len() >= MAX_WORDS {
            return true;
        }
    } else {
        current_word.clear();
    }
    false
}

pub fn extract(rope: &Rope) -> Vec<String> {
    let estimated = (rope.len_bytes() / 16).min(MAX_WORDS);
    let mut words = HashSet::with_capacity(estimated);
    let mut current_word = String::new();
    let mut state = ScanState::Outside;

    'chunks: for chunk in rope.chunks() {
        let bytes = chunk.as_bytes();
        let len = bytes.len();
        let mut i = 0usize;
        let mut word_start = 0usize;

        while i < len {
            match state {
                ScanState::Outside => {
                    while i < len && BYTE_CLASS[bytes[i] as usize] == 0 {
                        i += 1;
                    }
                    if i >= len {
                        break;
                    }
                    match BYTE_CLASS[bytes[i] as usize] {
                        1 => {
                            word_start = i;
                            i += 1;
                            state = ScanState::Valid;
                        }
                        2 => {
                            i += 1;
                            state = ScanState::Invalid;
                        }
                        _ => {
                            let ch = chunk[i..].chars().next().unwrap();
                            let ch_len = ch.len_utf8();
                            if is_non_ascii_word_char(ch) {
                                word_start = i;
                                state = ScanState::Valid;
                            }
                            i += ch_len;
                        }
                    }
                }
                ScanState::Valid => {
                    while i < len && (BYTE_CLASS[bytes[i] as usize] & 3) != 0 {
                        i += 1;
                    }
                    if i >= len {
                        break;
                    }
                    let advance = if BYTE_CLASS[bytes[i] as usize] == 0 {
                        1
                    } else {
                        let ch = chunk[i..].chars().next().unwrap();
                        let ch_len = ch.len_utf8();
                        if is_non_ascii_word_char(ch) {
                            i += ch_len;
                            continue;
                        }
                        ch_len
                    };
                    let reached_limit = if current_word.is_empty() {
                        flush_slice(&mut words, &chunk[word_start..i])
                    } else {
                        current_word.push_str(&chunk[word_start..i]);
                        flush_owned(&mut words, &mut current_word)
                    };
                    if reached_limit {
                        state = ScanState::Outside;
                        break 'chunks;
                    }
                    state = ScanState::Outside;
                    i += advance;
                }
                ScanState::Invalid => {
                    while i < len && (BYTE_CLASS[bytes[i] as usize] & 3) != 0 {
                        i += 1;
                    }
                    if i >= len {
                        break;
                    }
                    if BYTE_CLASS[bytes[i] as usize] == 0 {
                        i += 1;
                        state = ScanState::Outside;
                    } else {
                        let ch = chunk[i..].chars().next().unwrap();
                        i += ch.len_utf8();
                        if !is_non_ascii_word_char(ch) {
                            state = ScanState::Outside;
                        }
                    }
                }
            }
        }

        if state == ScanState::Valid && word_start < len {
            current_word.push_str(&chunk[word_start..]);
        }
    }

    if state == ScanState::Valid && !current_word.is_empty() && words.len() < MAX_WORDS {
        let _ = flush_owned(&mut words, &mut current_word);
    }

    words.into_iter().collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    fn sorted(text: &str) -> Vec<String> {
        let mut words = extract(&Rope::from_str(text));
        words.sort();
        words
    }

    #[test]
    fn words_follow_the_dart_word_chars() {
        assert_eq!(
            sorted("a1 1abc _x café 名前 8080"),
            ["_x", "a1", "caf", "名前"]
        );
    }
}
