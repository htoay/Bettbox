use fancy_regex::{Regex, RegexBuilder};
use std::sync::Mutex;

const BACKTRACK_LIMIT: usize = 200_000;

#[derive(Clone, PartialEq, Eq)]
pub struct Query {
    pub pattern: String,
    pub is_regex: bool,
    pub case_sensitive: bool,
    pub whole_word: bool,
}

static COMPILED: Mutex<Option<(Query, Regex)>> = Mutex::new(None);

fn compile(query: &Query) -> Option<Regex> {
    let mut cached = COMPILED.lock().unwrap_or_else(|poisoned| poisoned.into_inner());
    if let Some((key, regex)) = cached.as_ref() {
        if key == query {
            return Some(regex.clone());
        }
    }
    let mut full_pattern = String::with_capacity(query.pattern.len() + 16);
    full_pattern.push_str(if query.case_sensitive { "(?m)" } else { "(?mi)" });
    if query.whole_word {
        full_pattern.push_str(r"\b");
    }
    if query.is_regex {
        full_pattern.push_str(&query.pattern);
    } else {
        full_pattern.push_str(&fancy_regex::escape(&query.pattern));
    }
    if query.whole_word {
        full_pattern.push_str(r"\b");
    }
    let regex = RegexBuilder::new(&full_pattern)
        .backtrack_limit(BACKTRACK_LIMIT)
        .build()
        .ok()?;
    *cached = Some((query.clone(), regex.clone()));
    Some(regex)
}


#[inline(always)]
fn can_use_ascii_ci(text: &str, text_is_ascii: bool, pat: &str) -> bool {
    if !pat.is_ascii() {
        return false;
    }
    if text_is_ascii || !pat.bytes().any(|b| matches!(b, b's' | b'S' | b'k' | b'K')) {
        return true;
    }
    !text.contains('\u{017f}') && !text.contains('\u{212a}')
}

#[inline(always)]
fn find_next_ascii_ci(
    haystack: &[u8],
    needle: &[u8],
    from: usize,
    first_lo: u8,
    first_hi: u8,
    last_lo: u8,
    last_hi: u8,
) -> Option<usize> {
    let m = needle.len();
    if haystack.len() < m || from > haystack.len() - m {
        return None;
    }
    let limit = haystack.len() - m;
    let mut pos = from;
    if m == 1 {
        if first_lo == first_hi {
            return haystack[pos..].iter().position(|&b| b == first_lo).map(|o| pos + o);
        }
        return haystack[pos..].iter().position(|&b| b == first_lo || b == first_hi).map(|o| pos + o);
    }
    let mid_needle = &needle[1..m - 1];
    while pos <= limit {
        let offset = if first_lo == first_hi {
            haystack[pos..=limit].iter().position(|&b| b == first_lo)?
        } else {
            haystack[pos..=limit].iter().position(|&b| b == first_lo || b == first_hi)?
        };
        let idx = pos + offset;
        let bl = haystack[idx + m - 1];
        if (bl == last_lo || bl == last_hi)
            && haystack[idx + 1..idx + m - 1].eq_ignore_ascii_case(mid_needle)
        {
            return Some(idx);
        }
        pos = idx + 1;
    }
    None
}

/// Match ends as `[start, end, ...]` in scalar values; `None` for a pattern
/// that does not compile. A match that runs out of backtracking ends the list.
pub fn find(text: &str, query: &Query) -> Option<Vec<u32>> {
    let pat = query.pattern.as_str();
    let is_plain = !query.is_regex && !query.whole_word && !pat.is_empty();
    let text_is_ascii = text.is_ascii();

    if is_plain {
        if query.case_sensitive {
            let mut ranges = Vec::new();
            if text_is_ascii {
                let pat_len = pat.len() as u32;
                for (start, _) in text.match_indices(pat) {
                    let s = start as u32;
                    ranges.push(s);
                    ranges.push(s + pat_len);
                }
            } else {
                let pat_scalars = pat.chars().count() as u32;
                let mut byte = 0;
                let mut scalar = 0u32;
                for (start, _) in text.match_indices(pat) {
                    scalar += text[byte..start].chars().count() as u32;
                    let end = scalar + pat_scalars;
                    ranges.push(scalar);
                    ranges.push(end);
                    byte = start + pat.len();
                    scalar = end;
                }
            }
            return Some(ranges);
        } else if can_use_ascii_ci(text, text_is_ascii, pat) {
            let bytes = text.as_bytes();
            let mut ranges = Vec::new();
            let needle = pat.as_bytes();
            let m = needle.len();
            let first_lo = needle[0].to_ascii_lowercase();
            let first_hi = needle[0].to_ascii_uppercase();
            let last_lo = needle[m - 1].to_ascii_lowercase();
            let last_hi = needle[m - 1].to_ascii_uppercase();
            let mut pos = 0;
            if text_is_ascii {
                let pat_len = m as u32;
                while let Some(start) =
                    find_next_ascii_ci(bytes, needle, pos, first_lo, first_hi, last_lo, last_hi)
                {
                    let s = start as u32;
                    ranges.push(s);
                    ranges.push(s + pat_len);
                    pos = start + m;
                }
            } else {
                let pat_scalars = m as u32;
                let mut scalar = 0u32;
                while let Some(start) =
                    find_next_ascii_ci(bytes, needle, pos, first_lo, first_hi, last_lo, last_hi)
                {
                    scalar += text[pos..start].chars().count() as u32;
                    let end = scalar + pat_scalars;
                    ranges.push(scalar);
                    ranges.push(end);
                    pos = start + m;
                    scalar = end;
                }
            }
            return Some(ranges);
        }
    }

    let regex = compile(query)?;
    let mut ranges = Vec::new();
    if text_is_ascii {
        for found in regex.find_iter(text) {
            let Ok(found) = found else { break };
            ranges.push(found.start() as u32);
            ranges.push(found.end() as u32);
        }
    } else {
        let mut byte = 0;
        let mut scalar = 0u32;
        for found in regex.find_iter(text) {
            let Ok(found) = found else { break };
            let start_byte = found.start();
            let end_byte = found.end();
            scalar += text[byte..start_byte].chars().count() as u32;
            let end = scalar + text[start_byte..end_byte].chars().count() as u32;
            ranges.push(scalar);
            ranges.push(end);
            byte = end_byte;
            scalar = end;
        }
    }
    Some(ranges)
}

/// The text with every match replaced by `replacement` taken literally.
pub fn replace_all(text: &str, query: &Query, replacement: &str) -> Option<String> {
    let pat = query.pattern.as_str();
    let is_plain = !query.is_regex && !query.whole_word && !pat.is_empty();

    if is_plain {
        let m = pat.len();
        if query.case_sensitive {
            let mut starts = Vec::new();
            for (start, _) in text.match_indices(pat) {
                starts.push(start);
            }
            if starts.is_empty() {
                return Some(text.to_string());
            }
            let exact_len = text.len() - starts.len() * m + starts.len() * replacement.len();
            let mut result = String::with_capacity(exact_len);
            let mut byte = 0;
            for start in starts {
                result.push_str(&text[byte..start]);
                result.push_str(replacement);
                byte = start + m;
            }
            result.push_str(&text[byte..]);
            return Some(result);
        } else if can_use_ascii_ci(text, text.is_ascii(), pat) {
            let bytes = text.as_bytes();
            let needle = pat.as_bytes();
            let first_lo = needle[0].to_ascii_lowercase();
            let first_hi = needle[0].to_ascii_uppercase();
            let last_lo = needle[m - 1].to_ascii_lowercase();
            let last_hi = needle[m - 1].to_ascii_uppercase();
            let mut starts = Vec::new();
            let mut pos = 0;
            while let Some(start) =
                find_next_ascii_ci(bytes, needle, pos, first_lo, first_hi, last_lo, last_hi)
            {
                starts.push(start);
                pos = start + m;
            }
            if starts.is_empty() {
                return Some(text.to_string());
            }
            let exact_len = text.len() - starts.len() * m + starts.len() * replacement.len();
            let mut result = String::with_capacity(exact_len);
            let mut byte = 0;
            for start in starts {
                result.push_str(&text[byte..start]);
                result.push_str(replacement);
                byte = start + m;
            }
            result.push_str(&text[byte..]);
            return Some(result);
        }
    }

    let regex = compile(query)?;
    let mut spans = Vec::new();
    let mut matched_bytes = 0usize;
    for found in regex.find_iter(text) {
        let Ok(found) = found else { break };
        matched_bytes += found.end() - found.start();
        spans.push((found.start(), found.end()));
    }
    if spans.is_empty() {
        return Some(text.to_string());
    }
    let exact_len = text.len() - matched_bytes + spans.len() * replacement.len();
    let mut result = String::with_capacity(exact_len);
    let mut byte = 0;
    for (start, end) in spans {
        result.push_str(&text[byte..start]);
        result.push_str(replacement);
        byte = end;
    }
    result.push_str(&text[byte..]);
    Some(result)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn query(pattern: &str, is_regex: bool) -> Query {
        Query {
            pattern: pattern.to_string(),
            is_regex,
            case_sensitive: false,
            whole_word: false,
        }
    }

    #[test]
    fn offsets_count_scalars() {
        assert_eq!(find("节点😀 a节点", &query("节点", false)), Some(vec![0, 2, 5, 7]));
        assert_eq!(find("éa x éa", &query("éa", false)), Some(vec![0, 2, 5, 7]));
    }

    #[test]
    fn plain_text_is_not_a_pattern() {
        assert_eq!(find("a.b axb", &query("a.b", false)), Some(vec![0, 3]));
        assert_eq!(find("a.b axb", &query("a.b", true)), Some(vec![0, 3, 4, 7]));
    }

    #[test]
    fn options_narrow_the_matches() {
        let mut q = query("port", false);
        assert_eq!(find("Port port ports", &q), Some(vec![0, 4, 5, 9, 10, 14]));
        q.case_sensitive = true;
        assert_eq!(find("Port port ports", &q), Some(vec![5, 9, 10, 14]));
        q.whole_word = true;
        assert_eq!(find("Port port ports", &q), Some(vec![5, 9]));
    }

    #[test]
    fn anchors_work_per_line() {
        assert_eq!(find("a\nb\n", &query("^.", true)), Some(vec![0, 1, 2, 3]));
        assert_eq!(find("ab\ncd", &query("$", true)), Some(vec![2, 2, 5, 5]));
    }

    #[test]
    fn lookaround_and_backreferences_are_supported() {
        assert_eq!(find("port: 80", &query(r"(?<=port: )\d+", true)), Some(vec![6, 8]));
        assert_eq!(find("aa ab bb", &query(r"(\w)\1", true)), Some(vec![0, 2, 6, 8]));
    }

    #[test]
    fn an_invalid_pattern_is_reported() {
        assert_eq!(find("abc", &query("(", true)), None);
        assert_eq!(replace_all("abc", &query("(", true), "x"), None);
    }

    #[test]
    fn a_runaway_pattern_ends_instead_of_hanging() {
        let text = format!("{}b", "a".repeat(40));
        let started = std::time::Instant::now();
        let found = find(&text, &query(r"(?=(a+)+$)x|(a+)+\1$", true));
        assert!(found.is_some());
        assert!(started.elapsed().as_secs() < 2);
    }

    #[test]
    fn replacement_is_literal() {
        assert_eq!(
            replace_all("port: 80", &query(r"(\d+)", true), "$1x"),
            Some("port: $1x".to_string())
        );
    }


    #[test]
    fn test_plain_replace_all_case_sensitive_and_insensitive() {
        let mut q = query("port", false);
        assert_eq!(
            replace_all("Port port ports", &q, "proxy"),
            Some("proxy proxy proxys".to_string())
        );
        q.case_sensitive = true;
        assert_eq!(
            replace_all("Port port ports", &q, "proxy"),
            Some("Port proxy proxys".to_string())
        );
        assert_eq!(
            replace_all("no matches here", &q, "proxy"),
            Some("no matches here".to_string())
        );
    }

    #[test]
    fn test_boundary_search() {
        let q = query(":80", false);
        assert_eq!(find("host:80", &q), Some(vec![4, 7]));
        assert_eq!(find("host:", &q), Some(vec![]));
        assert_eq!(find(":", &q), Some(vec![]));
        assert_eq!(find("", &q), Some(vec![]));
    }
}

