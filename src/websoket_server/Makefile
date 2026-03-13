# ============================
#   GF‑Network‑Tools Makefile
# ============================

FC      = gfortran
CC      = gcc
FFLAGS  = -Wall -O2
CFLAGS  = -Wall -O2
LDFLAGS = -lssl -lcrypto

BUILDDIR = build

# ============================
#   Source files (existants)
# ============================

CORE_F90 = \
    net/core/tcp.f90 \
    net/core/tls.f90 \
    net/core/ws_tls_shim.f90


SERVER_F90 = \
    net/server/client.f90 \
    net/server/router.f90 \
    net/server/tls_server.f90 \
    net/wrapper/select_wrapper.f90 \
    net/wrapper/crypto_wrapper.f90 \
    net/websocket/websocket.f90 \
    net/websocket/websocket_handshake.f90 \
    net/websocket/wss_server.f90

CLIENT_F90 = \
    net/client/tls_client.f90

C_WRAPPERS = \
    net/c/tcp_wrapper.c \
    net/c/tls_wrapper.c \
    net/c/select_wrapper.c \
    net/c/crypto_wrapper.c


# ============================
#   Object files
# ============================

CORE_OBJ   = $(CORE_F90:.f90=.o)
SERVER_OBJ = $(SERVER_F90:.f90=.o)
CLIENT_OBJ = $(CLIENT_F90:.f90=.o)
C_OBJ      = $(C_WRAPPERS:.c=.o)

SERVER_BIN = $(BUILDDIR)/wss_server
CLIENT_BIN = $(BUILDDIR)/tls_client

# ============================
#   Default target
# ============================

all: $(BUILDDIR) $(SERVER_BIN) $(CLIENT_BIN)

# ============================
#   Build WebSocket Server
# ============================

$(SERVER_BIN): $(C_OBJ) $(CORE_OBJ) $(SERVER_OBJ)
	$(FC) $(C_OBJ) $(CORE_OBJ) $(SERVER_OBJ) $(LDFLAGS) -o $@

# ============================
#   Build TLS Client
# ============================

$(CLIENT_BIN): $(C_OBJ) $(CORE_OBJ) $(CLIENT_OBJ)
	$(FC) $(C_OBJ) $(CORE_OBJ) $(CLIENT_OBJ) $(LDFLAGS) -o $@

# ============================
#   Compile Fortran modules
# ============================

%.o: %.f90
	$(FC) $(FFLAGS) -c $< -o $@

# ============================
#   Compile C wrappers
# ============================

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

# ============================
#   Create build directory
# ============================

$(BUILDDIR):
	mkdir -p $(BUILDDIR)

# ============================
#   Clean
# ============================

clean:
	rm -f net/**/*.o net/**/*.mod
	rm -rf $(BUILDDIR)

rebuild: clean all
