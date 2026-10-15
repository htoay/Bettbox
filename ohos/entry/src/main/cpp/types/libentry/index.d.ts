/**
 * 把 tun fd 通过 SCM_RIGHTS 送给监听在 sockPath 上的 unix socket 服务端（Go 核心）。
 *
 * @param sockPath  目标地址；以 '@' 开头表示 Linux 抽象命名空间（无文件）
 * @param fd        要传递的文件描述符（VPN 扩展建链返回的 vNIC fd）
 * @param timeoutMs 单次连接超时（毫秒，默认 2500，上限 5000）。调用发生在 VPN 扩展
 *                  进程的 JS 线程上，必须避免长时间阻塞，否则会被系统判定 appfreeze
 *                  并杀掉扩展进程；重试请由 ArkTS 侧用异步循环完成。
 * @returns 0 表示成功；负数为 -errno（如 -13 EACCES / -2 ENOENT / -111 ECONNREFUSED）
 */
export const sendTunFd: (sockPath: string, fd: number, timeoutMs?: number) => number;
