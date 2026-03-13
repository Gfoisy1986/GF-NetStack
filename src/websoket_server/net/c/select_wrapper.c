#include <sys/select.h>
#include <stddef.h>     // pour NULL
#include <unistd.h>     // pour select() sur Linux


int gf_select(int maxfd, int *fds, int nfds, int *ready_flags)
{
    fd_set readfds;
    int i, rc;
    FD_ZERO(&readfds);

    for (i = 0; i < nfds; ++i) {
        if (fds[i] >= 0) {
            FD_SET(fds[i], &readfds);
        }
    }

    rc = select(maxfd + 1, &readfds, NULL, NULL, NULL);
    if (rc <= 0) return rc;

    for (i = 0; i < nfds; ++i) {
        if (fds[i] >= 0 && FD_ISSET(fds[i], &readfds)) {
            ready_flags[i] = 1;
        } else {
            ready_flags[i] = 0;
        }
    }

    return rc;
}
