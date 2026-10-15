use rquickjs::{Array, Ctx, Object, Result, Type, Value};
use serde_json::{Map, Number, Value as Json};

const MAX_DEPTH: usize = 128;
const MAX_SAFE_INTEGER: f64 = 9_007_199_254_740_991.0;

fn too_deep(from: &'static str) -> rquickjs::Error {
    rquickjs::Error::new_from_js(from, "a config nested within the depth limit")
}

pub fn to_js<'js>(ctx: &Ctx<'js>, json: &Json, depth: usize) -> Result<Value<'js>> {
    if depth > MAX_DEPTH {
        return Err(too_deep("json"));
    }
    Ok(match json {
        Json::Null => Value::new_null(ctx.clone()),
        Json::Bool(value) => Value::new_bool(ctx.clone(), *value),
        Json::Number(number) => match number.as_i64().and_then(|value| i32::try_from(value).ok()) {
            Some(value) => Value::new_int(ctx.clone(), value),
            None => Value::new_float(ctx.clone(), number.as_f64().unwrap_or(f64::NAN)),
        },
        Json::String(text) => rquickjs::String::from_str(ctx.clone(), text)?.into_value(),
        Json::Array(items) => {
            let array = Array::new(ctx.clone())?;
            for (index, item) in items.iter().enumerate() {
                array.set(index, to_js(ctx, item, depth + 1)?)?;
            }
            array.into_value()
        }
        Json::Object(map) => {
            let object = Object::new(ctx.clone())?;
            for (key, value) in map {
                object.set(key.as_str(), to_js(ctx, value, depth + 1)?)?;
            }
            object.into_value()
        }
    })
}

pub fn from_js(value: &Value<'_>, depth: usize) -> Result<Json> {
    if depth > MAX_DEPTH {
        return Err(too_deep("object"));
    }
    Ok(match value.type_of() {
        Type::Bool => Json::Bool(value.as_bool().unwrap_or_default()),
        Type::Int => Json::Number(value.as_int().unwrap_or_default().into()),
        Type::Float => {
            let float = value.as_float().unwrap_or_default();
            if float.fract() == 0.0 && float.abs() <= MAX_SAFE_INTEGER {
                Json::Number((float as i64).into())
            } else {
                Number::from_f64(float)
                    .map(Json::Number)
                    .unwrap_or(Json::Null)
            }
        }
        Type::String => match value.as_string() {
            Some(text) => Json::String(text.to_string()?),
            None => Json::Null,
        },
        Type::Array => {
            let mut items = Vec::new();
            if let Some(array) = value.as_array() {
                items.reserve(array.len());
                for item in array.iter::<Value>() {
                    items.push(from_js(&item?, depth + 1)?);
                }
            }
            Json::Array(items)
        }
        Type::Object => {
            let mut map = Map::new();
            if let Some(object) = value.as_object() {
                for entry in object.props::<String, Value>() {
                    let (key, item) = entry?;
                    if item.is_undefined() || item.is_function() {
                        continue;
                    }
                    map.insert(key, from_js(&item, depth + 1)?);
                }
            }
            Json::Object(map)
        }
        _ => Json::Null,
    })
}
