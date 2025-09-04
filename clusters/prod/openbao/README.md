# Manual set up required.

```
k exec -it -n openbao openbao-openbao-0 -- sh
vault operator init -n 1 -t 1
# copy the unseal key
vault operator unseal
# enter unseal key

# for nodes 2-3:
vault operator raft join https://openbao-openbao-0.openbao-openbao-internal:8200
vault operator unseal
```

Ready to rock... hopefully
