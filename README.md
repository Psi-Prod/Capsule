# Capsule

Our gemini capsule living at gemini://heyplzlookat.me/.

## Setup

```bash
opam install . --deps-only
make build # Building the site.
# Push the site to a distant directory.
make push DEST_PORT=... USER=AN_USER DEST=DEST_IP DEST_DIR=/home/AN_USER/public .
```
