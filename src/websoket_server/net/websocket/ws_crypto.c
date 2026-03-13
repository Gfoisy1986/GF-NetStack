#include <stdint.h>
#include <string.h>
#include <openssl/sha.h>
#include <openssl/evp.h>

void ws_sha1_hash_bin(const unsigned char *input, int len, unsigned char *output)
{
    SHA1(input, len, output);
}

int ws_base64_encode_bin(const unsigned char *input, int len, char *output, int outlen)
{
    int encoded_len = EVP_EncodeBlock((unsigned char *)output, input, len);
    return encoded_len;
}
