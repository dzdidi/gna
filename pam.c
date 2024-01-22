#include <security/pam_modules.h>
#include <security/pam_ext.h>

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

PAM_EXTERN int pam_sm_authenticate(pam_handle_t *pamh, int flags, int argc, const char **argv) {
    const char *header = NULL;
    if (pam_get_item(pamh, PAM_AUTHTOK, (const void **)&header) != PAM_SUCCESS || header == NULL) {
        pam_syslog(pamh, LOG_ERR, "Failed to get authtok");
        return PAM_AUTH_ERR;
    }

    char *token = strstr(header, "X-Authorization: Bearer ");
    if (!token) {
        pam_syslog(pamh, LOG_ERR, "No Bearer token found in authtok");
        return PAM_AUTH_ERR;
    }

    token += strlen("X-Authorization: Bearer ");

    // Code to validate the token goes here
    // Assume 'validate_token' is a function that takes a token and returns true if the token is valid, false otherwise
    bool tokenIsValid = validate_token(token);

    return (tokenIsValid ? PAM_SUCCESS : PAM_AUTH_ERR);
}


int main() {
    // Main function doesn't do much in this case. The actual work is done in pam_sm_authenticate.
    return 0;
}

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
