use rquickjs::function::Rest;
use rquickjs::{Ctx, Function, Object, Result, Value};
use std::cell::RefCell;
use std::rc::Rc;

const LEVELS: [&str; 6] = ["log", "info", "warn", "error", "debug", "trace"];
const MAX_LINES: usize = 200;
const MAX_BYTES: usize = 64 * 1024;

#[derive(Clone, Debug, PartialEq)]
pub struct LogLine {
    pub level: String,
    pub text: String,
}

#[derive(Default)]
pub struct LogBuffer {
    lines: Vec<LogLine>,
    bytes: usize,
}

impl LogBuffer {
    fn push(&mut self, level: &str, text: String) {
        if self.lines.len() >= MAX_LINES || self.bytes + text.len() > MAX_BYTES {
            return;
        }
        self.bytes += text.len();
        self.lines.push(LogLine {
            level: level.to_owned(),
            text,
        });
    }

    pub fn take(&mut self) -> Vec<LogLine> {
        self.bytes = 0;
        std::mem::take(&mut self.lines)
    }
}

pub type SharedLogs = Rc<RefCell<LogBuffer>>;

pub fn install(ctx: &Ctx<'_>, logs: Option<SharedLogs>) -> Result<()> {
    let console = Object::new(ctx.clone())?;
    for level in LEVELS {
        let logs = logs.clone();
        let print = Function::new(ctx.clone(), move |ctx, args| write(&logs, level, ctx, args))?;
        console.set(level, print)?;
    }
    ctx.globals().set("console", console)
}

fn write<'js>(logs: &Option<SharedLogs>, level: &str, ctx: Ctx<'js>, args: Rest<Value<'js>>) {
    let Some(logs) = logs else {
        return;
    };
    let line = args
        .iter()
        .map(|value| format(&ctx, value))
        .collect::<Vec<_>>()
        .join(" ");
    logs.borrow_mut().push(level, line);
}

fn format<'js>(ctx: &Ctx<'js>, value: &Value<'js>) -> String {
    if let Some(text) = value.as_string() {
        return text.to_string().unwrap_or_default();
    }
    match ctx.json_stringify(value.clone()) {
        Ok(Some(json)) => json.to_string().unwrap_or_default(),
        _ => format!("{value:?}"),
    }
}
