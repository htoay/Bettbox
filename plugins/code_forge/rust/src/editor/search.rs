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
    let mut pattern = if query.is_regex {
        query.pattern.clone()
    } else {
        fancy_regex::escape(&query.pattern).into_owned()
    };
    if query.whole_word {
        pattern = format!(r"\b{pattern}\b");
    }
    let flags = if query.case_sensitive { "(?m)" } else { "(?mi)" };
    let regex = RegexBuilder::new(&format!("{flags}{pattern}"))
        .backtrack_limit(BACKTRACK_LIMIT)
        .build()
        .ok()?;
    *cached = Some((query.clone(), regex.clone()));
    Some(regex)
}

/// Match ends as `[start, end, ...]` in scalar values; `None` for a pattern
/// that does not compile. A match that runs out of backtracking ends the list.
pub fn find(text: &str, query: &Query) -> Option<Vec<u32>> {
    let regex = compile(query)?;
    let mut ranges = Vec::new();
    let mut byte = 0;
    let mut scalar = 0u32;
    for found in regex.find_iter(text) {
        let Ok(found) = found else { break };
        scalar += text[byte..found.start()].chars().count() as u32;
        let end = scalar + found.as_str().chars().count() as u32;
        ranges.push(scalar);
        ranges.push(end);
        byte = found.end();
        scalar = end;
    }
    Some(ranges)
}

/// The text with every match replaced by `replacement` taken literally.
pub fn replace_all(text: &str, query: &Query, replacement: &str) -> Option<String> {
    let regex = compile(query)?;
    let mut result = String::with_capacity(text.len());
    let mut byte = 0;
    for found in regex.find_iter(text) {
        let Ok(found) = found else { break };
        result.push_str(&text[byte..found.start()]);
        result.push_str(replacement);
        byte = found.end();
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
}
