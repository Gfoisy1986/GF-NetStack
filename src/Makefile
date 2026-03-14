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
    wrappers/fortran/tcp.f90 \
    wrappers/modules/ws_tls_shim.f90


SERVER_F90 = \
    wrappers/fortran/websocket.f90 \
    wrappers/fortran/client.f90 \
    wrappers/fortran/select_wrapper.f90 \
    wrappers/fortran/crypto_wrapper.f90 \
    wrappers/fortran/websocket_handshake.f90 \
    wrappers/fortran/router.f90 \
    wrappers/fortran/tls_module.f90 \
    wrappers/fortran/ws_compat.f90 \
    core/websoket_server/ws_serveur.f90

CLIENT_F90 = \
    core/websoket_server/ws_client.f90

C_WRAPPERS = \
    wrappers/c/tcp_wrapper.c \
    wrappers/c/tls_wrapper.c \
    wrappers/c/select_wrapper.c \
    wrappers/c/crypto_wrapper.c


# ============================
#   Object files
# ============================

CORE_OBJ   = $(CORE_F90:.f90=.o)
SERVER_OBJ = $(SERVER_F90:.f90=.o)
CLIENT_OBJ = $(CLIENT_F90:.f90=.o)
C_OBJ      = $(C_WRAPPERS:.c=.o)

SERVER_BIN = $(BUILDDIR)/wss_server
CLIENT_BIN = $(BUILDDIR)/wss_client

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
