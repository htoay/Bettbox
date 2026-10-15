//! The YAML grammar of highlight.js as re_highlight 0.0.3 ships it, one line
//! at a time: every rule below is one of its modes, tried in its order.

use super::*;

const LITERALS: [&str; 5] = ["true", "false", "yes", "no", "null"];
const DOCTAGS: [&str; 7] = ["TODO", "FIXME", "NOTE", "BUG", "OPTIMIZE", "HACK", "XXX"];
const PHRASE_WORDS: [&str; 11] = [
    "i", "a", "is", "so", "us", "to", "at", "if", "in", "it", "on",
];
const CONTRACTIONS: [&str; 7] = ["d", "ve", "re", "ll", "t", "s", "n"];

#[derive(Clone, Copy, PartialEq)]
enum Container {
    Object,
    Array,
}

fn is_key_char(ch: char) -> bool {
    is_word(ch) || matches!(ch, ' ' | ':' | '/' | '.' | '-')
}

fn is_uri_char(ch: char) -> bool {
    is_word(ch)
        || matches!(
            ch,
            '#' | ';' | '/' | '?' | ':' | '@' | '&' | '=' | '+' | '$' | ',' | '.' | '~' | '*'
                | '\'' | '(' | ')' | '[' | ']'
        )
}

fn run(line: &Line, from: usize, accepts: fn(char) -> bool) -> usize {
    let mut end = from;
    while line.at(end).is_some_and(accepts) {
        end += 1;
    }
    end
}

fn ends_key(line: &Line, colon: usize) -> bool {
    matches!(line.at(colon + 1), Some(' ' | '\t')) || line.ends_at(colon + 1)
}

/// `keyless` is how far a run of key characters is known to hold no key, so
/// a line of plain words is not scanned again from each of them.
fn key(line: &Line, at: usize, keyless: &mut usize) -> Option<usize> {
    let first = line.at(at)?;
    if is_word(first) {
        if at < *keyless {
            return None;
        }
        let end = run(line, at, is_key_char);
        let found = (at + 1..end)
            .rev()
            .find(|&colon| line.chars[colon] == ':' && ends_key(line, colon))
            .map(|colon| colon + 1);
        if found.is_none() {
            *keyless = end;
        }
        return found;
    }
    if first != '"' && first != '\'' {
        return None;
    }
    if !line.at(at + 1).is_some_and(is_word) {
        return None;
    }
    let end = run(line, at + 1, is_key_char);
    (line.at(end) == Some(first) && line.at(end + 1) == Some(':') && ends_key(line, end + 1))
        .then_some(end + 2)
}

fn document_marker(line: &Line, at: usize) -> Option<usize> {
    if !line.starts_at(at) || (0..3).any(|i| line.at(at + i) != Some('-')) {
        return None;
    }
    let spaces = run(line, at + 3, is_space);
    (at + 3..=spaces).rev().find(|&end| line.ends_at(end))
}

fn tag(line: &Line, at: usize) -> Option<usize> {
    let uri = |from: usize| {
        let end = run(line, from, is_uri_char);
        (end > from).then_some(end)
    };
    let handle = run(line, at + 1, is_word);
    if handle > at + 1 && line.at(handle) == Some('!') {
        if let Some(end) = uri(handle + 1) {
            return Some(end);
        }
    }
    if line.at(at + 1) == Some('<') {
        if let Some(end) = uri(at + 2) {
            if line.at(end) == Some('>') {
                return Some(end + 1);
            }
        }
    }
    if let Some(end) = uri(at + 1) {
        return Some(end);
    }
    if line.at(at + 1) == Some('!') {
        return uri(at + 2);
    }
    None
}

fn anchor(line: &Line, at: usize) -> Option<usize> {
    if !line
        .at(at + 1)
        .is_some_and(|ch| ch.is_ascii_alphabetic() || ch == '_')
    {
        return None;
    }
    let end = run(line, at + 2, is_word);
    line.ends_at(end).then_some(end)
}

fn literal(line: &Line, at: usize) -> Option<usize> {
    if !is_word(line.chars[at]) || (at > 0 && is_word(line.chars[at - 1])) {
        return None;
    }
    LITERALS.iter().find_map(|word| {
        let end = at + word.len();
        (starts_with(line, at, word)
            && !line.at(end).is_some_and(|next| is_word(next) || next == '.'))
        .then_some(end)
    })
}

/// Whether `\b` matches here.
fn boundary(line: &Line, at: usize) -> bool {
    let before = at > 0 && is_word(line.chars[at - 1]);
    before != line.at(at).is_some_and(is_word)
}

fn digit(line: &Line, at: usize) -> bool {
    line.at(at).is_some_and(|ch| ch.is_ascii_digit())
}

fn digits(line: &Line, at: usize) -> usize {
    run(line, at, |ch| ch.is_ascii_digit())
}

fn starts_with(line: &Line, at: usize, word: &str) -> bool {
    let end = at + word.len();
    end <= line.len()
        && word
            .chars()
            .zip(&line.chars[at..end])
            .all(|(expected, ch)| ch.to_ascii_lowercase() == expected)
}

/// `([eE][-+]?\d+)?\b` from `at`, the exponent first and then without it.
fn number_end(line: &Line, at: usize) -> Option<usize> {
    if matches!(line.at(at), Some('e' | 'E')) {
        let sign = at + 1 + usize::from(matches!(line.at(at + 1), Some('-' | '+')));
        let end = digits(line, sign);
        if end > sign && boundary(line, end) {
            return Some(end);
        }
    }
    boundary(line, at).then_some(at)
}

/// `(-?)(\b0[xX][a-fA-F0-9]+|(\b\d+(\.\d*)?|\.\d+)([eE][-+]?\d+)?)\b`
fn number(line: &Line, at: usize) -> Option<usize> {
    let start = at + usize::from(line.chars[at] == '-');
    if digit(line, start) {
        if !boundary(line, start) {
            return None;
        }
        if line.chars[start] == '0' && matches!(line.at(start + 1), Some('x' | 'X')) {
            let end = run(line, start + 2, |ch| ch.is_ascii_hexdigit());
            if end > start + 2 && boundary(line, end) {
                return Some(end);
            }
        }
        let whole = digits(line, start);
        if line.at(whole) == Some('.') {
            let fraction = digits(line, whole + 1);
            if let Some(end) = (whole + 1..=fraction)
                .rev()
                .find_map(|end| number_end(line, end))
            {
                return Some(end);
            }
        }
        return number_end(line, whole);
    }
    if line.at(start) == Some('.') {
        let fraction = digits(line, start + 1);
        return (start + 2..=fraction)
            .rev()
            .find_map(|end| number_end(line, end));
    }
    None
}

fn pair(line: &Line, at: usize, lead: char) -> bool {
    line.at(at) == Some(lead) && digit(line, at + 1) && digit(line, at + 2)
}

/// `\b[0-9]{4}(-[0-9][0-9]){0,2}([Tt \t][0-9][0-9]?(:[0-9][0-9]){2})?`
/// `(\.[0-9]*)?([ \t])*(Z|[-+][0-9][0-9]?(:[0-9][0-9])?)?\b`, each part
/// taken as far as it goes first and then shorter, as the pattern backtracks.
fn timestamp(line: &Line, at: usize) -> Option<usize> {
    if !boundary(line, at) || digits(line, at) < at + 4 {
        return None;
    }
    let year = at + 4;
    let mut dates = vec![year];
    if pair(line, year, '-') {
        dates.insert(0, year + 3);
        if pair(line, year + 3, '-') {
            dates.insert(0, year + 6);
        }
    }
    for date in dates {
        let mut times = Vec::new();
        if matches!(line.at(date), Some('T' | 't' | ' ' | '\t')) && digit(line, date + 1) {
            for hour in [date + 3, date + 2] {
                if (hour == date + 2 || digit(line, date + 2))
                    && pair(line, hour, ':')
                    && pair(line, hour + 3, ':')
                {
                    times.push(hour + 6);
                }
            }
        }
        times.push(date);
        for time in times {
            let mut fractions = Vec::new();
            if line.at(time) == Some('.') {
                fractions.extend((time + 1..=digits(line, time + 1)).rev());
            }
            fractions.push(time);
            for fraction in fractions {
                let blanks = run(line, fraction, |ch| ch == ' ' || ch == '\t');
                for blank in (fraction..=blanks).rev() {
                    let mut zones = Vec::new();
                    if matches!(line.at(blank), Some('Z' | 'z')) {
                        zones.push(blank + 1);
                    }
                    if matches!(line.at(blank), Some('-' | '+')) && digit(line, blank + 1) {
                        for hour in [blank + 3, blank + 2] {
                            if hour == blank + 3 && !digit(line, blank + 2) {
                                continue;
                            }
                            if pair(line, hour, ':') {
                                zones.push(hour + 3);
                            }
                            zones.push(hour);
                        }
                    }
                    zones.push(blank);
                    if let Some(end) = zones.into_iter().find(|&end| boundary(line, end)) {
                        return Some(end);
                    }
                }
            }
        }
    }
    None
}

fn letters(line: &Line, at: usize, to: usize) -> usize {
    let mut end = at;
    while end < to && line.chars[end].is_ascii_alphabetic() {
        end += 1;
    }
    end
}

/// The ends a word of the phrase pattern can have from `at`, in the order
/// the pattern tries them.
fn phrase_word_ends(line: &Line, at: usize, to: usize) -> Vec<usize> {
    let mut ends = Vec::new();
    for word in PHRASE_WORDS {
        if at + word.len() <= to && starts_with(line, at, word) {
            ends.push(at + word.len());
        }
    }
    let word = letters(line, at, to);
    if word > at {
        if word < to && line.chars[word] == '\'' {
            for suffix in CONTRACTIONS {
                if word + 1 + suffix.len() <= to && starts_with(line, word + 1, suffix) {
                    ends.push(word + 1 + suffix.len());
                }
            }
        }
        if word < to && line.chars[word] == '-' {
            ends.extend((word + 2..=letters(line, word + 1, to)).rev());
        }
        ends.extend((at + 3..=word).rev());
    }
    ends
}

/// `((?:word)[.]?[:]?([.][ ]|[ ])){count}` from `at`.
fn phrase_words(line: &Line, at: usize, to: usize, count: usize) -> Option<usize> {
    if count == 0 {
        return Some(at);
    }
    let is = |index: usize, ch: char| index < to && line.chars[index] == ch;
    for word in phrase_word_ends(line, at, to) {
        let dots: &[usize] = if is(word, '.') { &[1, 0] } else { &[0] };
        for &dot in dots {
            let colons: &[usize] = if is(word + dot, ':') { &[1, 0] } else { &[0] };
            for &colon in colons {
                let tail = word + dot + colon;
                let ends = [
                    (is(tail, '.') && is(tail + 1, ' ')).then_some(tail + 2),
                    is(tail, ' ').then_some(tail + 1),
                ];
                for end in ends.into_iter().flatten() {
                    if let Some(end) = phrase_words(line, end, to, count - 1) {
                        return Some(end);
                    }
                }
            }
        }
    }
    None
}

/// The first run of spaces three such words follow, and where they end.
fn phrase(line: &Line, from: usize, to: usize) -> Option<(usize, usize)> {
    let mut at = from;
    while at < to {
        if line.chars[at] != ' ' {
            at += 1;
            continue;
        }
        let mut words = at;
        while words < to && line.chars[words] == ' ' {
            words += 1;
        }
        if let Some(end) = phrase_words(line, words, to, 3) {
            return Some((at, end));
        }
        at = words;
    }
    None
}

fn find(line: &Line, from: usize, to: usize, text: &str) -> Option<usize> {
    let needle: Vec<char> = text.chars().collect();
    (from..to.saturating_sub(needle.len() - 1)).find(|&at| line.chars[at..].starts_with(&needle))
}

fn doctag(line: &Line, from: usize, to: usize) -> Option<(usize, usize, usize)> {
    (from..to).find_map(|at| {
        DOCTAGS.iter().find_map(|word| {
            let end = at + word.len();
            let matches = end < to
                && line.chars[end] == ':'
                && word
                    .chars()
                    .zip(&line.chars[at..end])
                    .all(|(expected, ch)| ch.to_ascii_uppercase() == expected);
            matches.then(|| {
                let mut begin = at;
                while begin > from && line.chars[begin - 1] == ' ' {
                    begin -= 1;
                }
                (begin, at, end + 1)
            })
        })
    })
}

fn comment(line: &mut Line, at: usize) -> usize {
    let end = (at + 1..=line.len())
        .find(|&index| line.ends_at(index))
        .unwrap_or(line.len());
    let mut emitted = at;
    let mut cursor = at + 1;
    loop {
        let tag = doctag(line, cursor, end);
        let words = phrase(line, cursor, end);
        match (tag, words) {
            (Some((begin, start, stop)), words)
                if words.map_or(true, |(phrase_start, _)| begin <= phrase_start) =>
            {
                line.emit(COMMENT, emitted, start);
                line.emit(DOCTAG, start, stop);
                emitted = stop;
                cursor = stop;
            }
            (_, Some((_, stop))) => cursor = stop,
            _ => break,
        }
    }
    line.emit(COMMENT, emitted, end);
    end
}

/// A `{{ }}` or `%{ }` inside a string: where it ends, or the end of the
/// line when it never closes and so takes the rest of the line with it.
fn template(line: &mut Line, at: usize) -> Option<(usize, bool)> {
    let close = match (line.at(at), line.at(at + 1)) {
        (Some('{'), Some('{')) => "}}",
        (Some('%'), Some('{')) => "}",
        _ => return None,
    };
    let found = find(line, at + 2, line.len(), close);
    let end = found.map_or(line.len(), |start| start + close.len());
    line.emit(TEMPLATE_VARIABLE, at, end);
    Some((end, found.is_some()))
}

fn quoted(line: &mut Line, at: usize) -> usize {
    let quote = line.chars[at];
    let mut start = at;
    let mut cursor = at + 1;
    while cursor < line.len() {
        let ch = line.chars[cursor];
        if ch == '\\' && cursor + 1 < line.len() {
            cursor += 2;
        } else if ch == quote {
            line.emit(STRING, start, cursor + 1);
            return cursor + 1;
        } else if ch == '{' || ch == '%' {
            let before = line.tokens_len();
            match template(line, cursor) {
                Some((end, closed)) => {
                    line.insert(before, STRING, start, cursor);
                    if !closed {
                        return end;
                    }
                    start = end;
                    cursor = end;
                }
                None => cursor += 1,
            }
        } else {
            cursor += 1;
        }
    }
    line.emit(STRING, start, line.len());
    line.len()
}

fn plain(line: &mut Line, at: usize, contained: bool) -> usize {
    let accepts: fn(char) -> bool = if contained {
        |ch| !is_space(ch) && !matches!(ch, ',' | '{' | '}' | '[' | ']')
    } else {
        |ch| !is_space(ch)
    };
    let mut cursor = run(line, at, accepts);
    line.emit(STRING, at, cursor);
    loop {
        if line.at(cursor) == Some('\\') && cursor + 1 < line.len() {
            line.emit(STRING, cursor, cursor + 2);
            cursor += 2;
            continue;
        }
        match template(line, cursor) {
            Some((end, true)) => cursor = end,
            Some((end, false)) => return end,
            None => return cursor,
        }
    }
}

pub fn highlight(text: &str) -> Vec<u32> {
    let mut line = Line::new(text);
    let mut containers: Vec<Container> = Vec::new();
    let mut keyless = 0;
    let mut at = 0;
    while at < line.len() {
        let ch = line.chars[at];
        if is_space(ch) {
            at += 1;
            continue;
        }
        if let Some(&container) = containers.last() {
            let closes = match ch {
                '}' => Some(Container::Object),
                ']' => Some(Container::Array),
                _ => None,
            };
            if ch == ',' || closes.is_some() {
                if closes == Some(container) {
                    containers.pop();
                }
                at += 1;
                continue;
            }
        }
        if let Some(end) = key(&line, at, &mut keyless) {
            line.emit(ATTR, at, end);
            at = end;
            continue;
        }
        let next = line.at(at + 1);
        let token = match ch {
            '-' => document_marker(&line, at).map(|end| (META, end)).or_else(|| {
                (next == Some(' ') || line.ends_at(at + 1)).then_some((BULLET, at + 1))
            }),
            '!' => tag(&line, at).map(|end| (TYPE, end)),
            '&' | '*' => anchor(&line, at).map(|end| (META, end)),
            _ => None,
        };
        if let Some((scope, end)) = token {
            line.emit(scope, at, end);
            at = end;
            continue;
        }
        if ch == '<' && next == Some('%') {
            let begin = at + 2 + usize::from(matches!(line.at(at + 2), Some('%' | '=' | '-')));
            at = find(&line, begin, line.len(), "%>").map_or(line.len(), |found| found + 2);
            continue;
        }
        if ch == '#' {
            at = comment(&mut line, at);
            continue;
        }
        if let Some(end) = literal(&line, at) {
            if at == 0 || line.chars[at - 1] != '.' {
                line.emit(LITERAL, at, end);
                at = end;
                continue;
            }
        }
        if let Some(end) = timestamp(&line, at).or_else(|| number(&line, at)) {
            line.emit(NUMBER, at, end);
            at = end;
            continue;
        }
        at = match ch {
            '{' => {
                containers.push(Container::Object);
                at + 1
            }
            '[' => {
                containers.push(Container::Array);
                at + 1
            }
            '\'' | '"' => quoted(&mut line, at),
            _ => plain(&mut line, at, !containers.is_empty()),
        };
    }
    line.finish()
}
