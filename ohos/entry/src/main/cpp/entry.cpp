#include "napi/native_api.h"
#include "hilog/log.h"
#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>
#include <fcntl.h>
#include <poll.h>
#include <cstring>
#include <cerrno>
#include <cstddef>
#include <string>

// 必须定义 LOG_DOMAIN/LOG_TAG，否则 OH_LOG_* 会用默认（空 tag）导致日志不落盘
#undef LOG_DOMAIN
#undef LOG_TAG
#define LOG_DOMAIN 0x0001
#define LOG_TAG "TunBridge"

namespace {

napi_value IntResult(napi_env env, int32_t value) {
    napi_value res;
    napi_create_int32(env, value, &res);
    return res;
}

/**
 * 构造 unix socket 地址。
 * 以 '@' 开头的名字走 Linux 抽象命名空间（无文件、无文件标签，可绕过文件级策略）；
 * 其余按普通路径处理。addrLen 必须精确，否则抽象名会被尾部的 0 撑长。
 */
bool BuildUnixAddr(const char* path, struct sockaddr_un* addr, socklen_t* addrLen) {
    memset(addr, 0, sizeof(*addr));
    addr->sun_family = AF_UNIX;
    const size_t len = strlen(path);
    if (len == 0 || len >= sizeof(addr->sun_path)) {
        return false;
    }
    if (path[0] == '@') {
        addr->sun_path[0] = '\0';
        memcpy(addr->sun_path + 1, path + 1, len - 1);
        *addrLen = static_cast<socklen_t>(offsetof(struct sockaddr_un, sun_path) + len);
    } else {
        memcpy(addr->sun_path, path, len);
        *addrLen = static_cast<socklen_t>(offsetof(struct sockaddr_un, sun_path) + len + 1);
    }
    return true;
}

/**
 * 非阻塞 connect + poll 限时，返回已连接的 fd，失败返回负 errno。
 *
 * 关键：调用发生在 VPN 扩展进程的 JS 线程上，长时间同步阻塞会被系统判定
 * 应用无响应（appfreeze）并杀掉扩展进程 —— 真机日志里 DfxFaultLogger 的
 * 崩溃栈就落在本函数（musl ← libentry.so ← napi ← onCreate）。因此这里
 * 单次最多阻塞 timeoutMs，重试交给 ArkTS 侧的异步循环。
 */
int ConnectUnix(const char* path, int timeoutMs) {
    struct sockaddr_un addr;
    socklen_t addrLen = 0;
    if (!BuildUnixAddr(path, &addr, &addrLen)) {
        return -EINVAL;
    }

    int sock = socket(AF_UNIX, SOCK_STREAM, 0);
    if (sock < 0) {
        return -errno;
    }

    const int flags = fcntl(sock, F_GETFL, 0);
    if (flags >= 0) {
        fcntl(sock, F_SETFL, flags | O_NONBLOCK);
    }

    int ret = connect(sock, reinterpret_cast<struct sockaddr*>(&addr), addrLen);
    if (ret < 0 && errno == EINPROGRESS) {
        struct pollfd pfd;
        pfd.fd = sock;
        pfd.events = POLLOUT;
        pfd.revents = 0;
        const int polled = poll(&pfd, 1, timeoutMs);
        if (polled > 0) {
            int soError = 0;
            socklen_t errorLen = sizeof(soError);
            if (getsockopt(sock, SOL_SOCKET, SO_ERROR, &soError, &errorLen) == 0 && soError == 0) {
                ret = 0;
            } else {
                errno = soError != 0 ? soError : ECONNREFUSED;
                ret = -1;
            }
        } else if (polled == 0) {
            errno = ETIMEDOUT;
            ret = -1;
        }
    }

    if (ret < 0) {
        const int savedErrno = errno;
        close(sock);
        return -savedErrno;
    }

    // 恢复阻塞模式：SCM_RIGHTS 的消息必须整体发出
    if (flags >= 0) {
        fcntl(sock, F_SETFL, flags);
    }
    return sock;
}

/**
 * 把 [tunFd] 通过 SCM_RIGHTS 送到 [sockPath] 对应的 unix socket 服务端。
 * 参数：path(string), fd(number), timeoutMs(number, 可选)
 * 返回：0 成功；负数为 -errno（如 -13 EACCES、-2 ENOENT、-111 ECONNREFUSED）
 */
napi_value SendTunFd(napi_env env, napi_callback_info info) {
    size_t argc = 3;
    napi_value args[3] = {nullptr, nullptr, nullptr};
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    char sockPath[256] = {0};
    size_t pathLen = 0;
    if (napi_get_value_string_utf8(env, args[0], sockPath, sizeof(sockPath) - 1, &pathLen) != napi_ok) {
        OH_LOG_ERROR(LOG_APP, "SendTunFd: invalid sockPath argument");
        return IntResult(env, -EINVAL);
    }

    int32_t fd = -1;
    napi_get_value_int32(env, args[1], &fd);

    int32_t timeoutMs = 2500;
    if (argc >= 3 && args[2] != nullptr) {
        napi_get_value_int32(env, args[2], &timeoutMs);
    }
    if (timeoutMs <= 0 || timeoutMs > 5000) {
        timeoutMs = 2500;
    }

    const int sock = ConnectUnix(sockPath, timeoutMs);
    if (sock < 0) {
        OH_LOG_ERROR(LOG_APP, "connect(%{public}s) failed: %{public}d", sockPath, sock);
        return IntResult(env, sock);
    }

    char dummy = 'T';
    struct iovec iov;
    iov.iov_base = &dummy;
    iov.iov_len = 1;

    char cmsgBuf[CMSG_SPACE(sizeof(int))];
    memset(cmsgBuf, 0, sizeof(cmsgBuf));

    struct msghdr msg;
    memset(&msg, 0, sizeof(msg));
    msg.msg_iov = &iov;
    msg.msg_iovlen = 1;
    msg.msg_control = cmsgBuf;
    msg.msg_controllen = sizeof(cmsgBuf);

    struct cmsghdr* cmsg = CMSG_FIRSTHDR(&msg);
    cmsg->cmsg_level = SOL_SOCKET;
    cmsg->cmsg_type = SCM_RIGHTS;
    cmsg->cmsg_len = CMSG_LEN(sizeof(int));
    memcpy(CMSG_DATA(cmsg), &fd, sizeof(int));

    const ssize_t sent = sendmsg(sock, &msg, 0);
    if (sent <= 0) {
        const int savedErrno = errno;
        OH_LOG_ERROR(LOG_APP, "sendmsg(SCM_RIGHTS) failed: %{public}d", savedErrno);
        close(sock);
        return IntResult(env, -savedErrno);
    }

    OH_LOG_INFO(LOG_APP, "SendTunFd ok: fd %{public}d -> %{public}s", fd, sockPath);
    close(sock);
    return IntResult(env, 0);
}



} // namespace

EXTERN_C_START
static napi_value Init(napi_env env, napi_value exports) {
    napi_property_descriptor desc[] = {
        {"sendTunFd", nullptr, SendTunFd, nullptr, nullptr, nullptr, napi_default, nullptr}
    };
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}
EXTERN_C_END

static napi_module entryModule = {
    .nm_version = 1,
    .nm_flags = 0,
    .nm_filename = nullptr,
    .nm_register_func = Init,
    .nm_modname = "entry",
    .nm_priv = ((void *)0),
    .reserved = {0},
};

extern "C" __attribute__((constructor)) void RegisterEntryModule(void) {
    napi_module_register(&entryModule);
}
