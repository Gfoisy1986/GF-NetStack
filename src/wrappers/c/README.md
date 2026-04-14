gcc -c tls_wrapper_v3.c -o tls_wrapper_v3.o -lbearssl


./ubuntu-certificate_key.sh


openssl x509 -in server.pem -out cert.der -outform DER 


openssl rsa -in server.key -out key.der -outform DER



