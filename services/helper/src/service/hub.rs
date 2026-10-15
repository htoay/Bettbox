use crate::ipc;

const DEFAULT_PIPE_NAME: &str = r"\\.\pipe\Bettbox.Helper";

fn pipe_name() -> String {
    std::env::var("HELPER_PIPE_NAME").unwrap_or_else(|_| DEFAULT_PIPE_NAME.to_string())
}

pub async fn run_service() -> anyhow::Result<()> {
    crate::rpc::init_auth_key();
    ipc::named_pipe::run(&pipe_name()).await
}

#[cfg(all(feature = "windows-service", target_os = "windows"))]
pub fn stop() -> String {
    crate::ops::core::stop_core()
}
