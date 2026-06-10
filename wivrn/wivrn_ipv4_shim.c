/* Força WiVRn a usar AF_INET em vez de AF_INET6.
 * Necessário quando o kernel é iniciado com ipv6.disable=1. */
#define _GNU_SOURCE
#include <dlfcn.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <string.h>
#include <stdint.h>

static int (*real_socket)(int, int, int);
static int (*real_setsockopt)(int, int, int, const void *, socklen_t);
static int (*real_bind)(int, const struct sockaddr *, socklen_t);
static int (*real_getsockname)(int, struct sockaddr *, socklen_t *);

__attribute__((constructor))
static void shim_init(void) {
    real_socket     = dlsym(RTLD_NEXT, "socket");
    real_setsockopt = dlsym(RTLD_NEXT, "setsockopt");
    real_bind       = dlsym(RTLD_NEXT, "bind");
    real_getsockname = dlsym(RTLD_NEXT, "getsockname");
}

int socket(int domain, int type, int protocol) {
    if (domain == AF_INET6)
        domain = AF_INET;
    return real_socket(domain, type, protocol);
}

int setsockopt(int fd, int level, int optname,
               const void *optval, socklen_t optlen) {
    if (level == IPPROTO_IPV6)
        return 0;
    return real_setsockopt(fd, level, optname, optval, optlen);
}

int bind(int fd, const struct sockaddr *addr, socklen_t addrlen) {
    if (addr->sa_family == AF_INET6) {
        const struct sockaddr_in6 *a6 = (const struct sockaddr_in6 *)addr;
        struct sockaddr_in a4;
        memset(&a4, 0, sizeof(a4));
        a4.sin_family = AF_INET;
        a4.sin_port   = a6->sin6_port;
        a4.sin_addr.s_addr = INADDR_ANY;
        return real_bind(fd, (const struct sockaddr *)&a4, sizeof(a4));
    }
    return real_bind(fd, addr, addrlen);
}

int getsockname(int fd, struct sockaddr *addr, socklen_t *addrlen) {
    int ret = real_getsockname(fd, addr, addrlen);
    /* Se o caller esperava AF_INET6 mas recebeu AF_INET, ajusta. */
    if (ret == 0 && addr->sa_family == AF_INET &&
        addrlen && *addrlen >= sizeof(struct sockaddr_in6)) {
        /* Não converte – retorna como está; apenas evita leitura além do buffer. */
    }
    return ret;
}
