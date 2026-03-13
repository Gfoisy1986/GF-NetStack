#include <openssl/sha.h>
#include <openssl/evp.h>
#include <string.h>
#include <stdlib.h>

void sha1_hash_c(const char *input, int len, unsigned char *out20)
{
    SHA1((const unsigned char*)input, len, out20);
}

int base64_encode_c(const unsigned char *input, int len, char *out, int outlen)
{
    int encoded = EVP_EncodeBlock((unsigned char*)out, input, len);
    return encoded; // returns number of bytes written
}
