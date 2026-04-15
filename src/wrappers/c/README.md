gcc -shared -fPIC \
  tls_wrapper_v3.c \
  -I./bearssl \
  -o libtls_wrapper_v3.so


gcc -c tls_wrapper_v3.c -o tls_wrapper_v3.o -lbearssl



x86_64-w64-mingw32-gcc -shared \
  tls_wrapper_v3.c \
  bearssl/src/*.c \
  bearssl/src/aead/*.c \
  bearssl/src/codec/*.c \
  bearssl/src/ec/*.c \
  bearssl/src/hash/*.c \
  bearssl/src/int/*.c \
  bearssl/src/kdf/*.c \
  bearssl/src/mac/*.c \
  bearssl/src/rand/*.c \
  bearssl/src/rsa/*.c \
  bearssl/src/ssl/*.c \
  bearssl/src/symcipher/*.c \
  bearssl/src/x509/*.c \
  -I./bearssl/inc \
  -I./bearssl/src \
  -lws2_32 \
  -o tls_wrapper_v3.dll








./ubuntu-certificate_key.sh


openssl x509 -in server.pem -out cert.der -outform DER 


openssl rsa -in server.key -out key.der -outform DER


fbc server_fb.bas tls_wrapper_v3.o
fbc tls_client.bas tls_wrapper_v3.o

gcc server_c.c tls_wrapper_v3.o -o server_c -lbearssl
