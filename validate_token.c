#include <openssl/evp.h>
#include <openssl/pem.h>
#include <openssl/rand.h>
#include <jansson.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>

// Hardcoded array of public keys
const char* publicKeys[] = {"publicKey1", "publicKey2", /* ... */};
size_t numPublicKeys = sizeof(publicKeys) / sizeof(publicKeys[0]);

bool validate_token(char* token) {
    // Decode the token from Base64
    unsigned char* decodedToken = base64_decode(token);
    if (decodedToken == NULL) {
        return false;
    }

    // Parse the JSON
    json_error_t error;
    json_t* root = json_loads((char*)decodedToken, 0, &error);
    if (root == NULL) {
        free(decodedToken);
        return false;
    }

    // Get the ID, signature, and public key from the JSON
    const char* id = json_string_value(json_object_get(root, "id"));
    const char* sig = json_string_value(json_object_get(root, "sig"));
    const char* pubkey = json_string_value(json_object_get(root, "pubkey"));

    // Check the ID, signature, and public key
    if (id == NULL || sig == NULL || pubkey == NULL) {
        json_decref(root);
        free(decodedToken);
        return false;
    }

    // Check if the public key is in the list of allowed keys
    bool isAllowed = false;
    for (size_t i = 0; i < numPublicKeys; ++i) {
        if (strcmp(publicKeys[i], pubkey) == 0) {
            isAllowed = true;
            break;
        }
    }

    if (!isAllowed) {
        json_decref(root);
        free(decodedToken);
        return false;
    }

    // TODO: Validate the signature
    // This depends on the specific signature algorithm used

    json_decref(root);
    free(decodedToken);
    return true;
}
