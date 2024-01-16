# Client

Adds to global config:
```
[http "https://<host>/<owner>/repo"]
  extraHeader = "Authorization: Nostr $(./create_nostr_auth_header.sh)"
  
```

TODO:
- [ ] add signing for header generation
- [ ] add id for header generation
- [ ] add base64 encofing for header generation
- [ ] add key retrieval mechanism
- [ ] add script for extendign config file for speicific urls

# Sever
TODO:
- [ ] Appache config to intercept and verify header (also for ACL)
- [ ] script for auto setup with bare repo and ACL
