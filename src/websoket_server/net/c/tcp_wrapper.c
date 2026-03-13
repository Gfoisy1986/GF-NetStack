#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>

int tcp_listen(int port)
{
    int sock = socket(AF_INET, SOCK_STREAM, 0);

    struct sockaddr_in addr;
    addr.sin_family = AF_INET;
    addr.sin_port = htons(port);
    addr.sin_addr.s_addr = INADDR_ANY;

    bind(sock, (struct sockaddr*)&addr, sizeof(addr));
    listen(sock, 5);

    return sock;
}

int tcp_accept(int sock)
{
    return accept(sock, NULL, NULL);
}
