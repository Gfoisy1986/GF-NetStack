gcc -shared -fPIC \
  tls_wrapper_v3.c \
  -I./bearssl \
  -o libtls_wrapper_v3.so


gcc -c tls_wrapper_v3.c -o tls_wrapper_v3.o -lbearssl


build win bearssl under linux: --> .a

x86_64-w64-mingw32-gcc -c \
  src/*.c \
  src/aead/*.c \
  src/codec/*.c \
  src/ec/*.c \
  src/hash/*.c \
  src/int/*.c \
  src/kdf/*.c \
  src/mac/*.c \
  src/rand/*.c \
  src/rsa/*.c \
  src/ssl/*.c \
  src/symcipher/*.c \
  src/x509/*.c \
  -Iinc -Isrc



x86_64-w64-mingw32-ar rcs libbearssl.a *.o


x86_64-w64-mingw32-gcc -shared \
  tls_wrapper_v3.c \
  -Ibearssl/inc \
  bearssl/libbearssl.a \
  -lws2_32 \
  -o tls_wrapper_v3.dll











./ubuntu-certificate_key.sh


openssl x509 -in server.pem -out cert.der -outform DER 


openssl rsa -in server.key -out key.der -outform DER


fbc server_fb.bas tls_wrapper_v3.o
fbc tls_client.bas tls_wrapper_v3.o

gcc server_c.c tls_wrapper_v3.o -o server_c -lbearssl


win:

openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.der -outform DER -nodes -days 365
openssl rsa -in key.pem -out key.der -outform DER

