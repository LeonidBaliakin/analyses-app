# cloud_access

Schema-versioned policy DTO and HTTP adapter shared by resource services. No Flutter,
SQL, direct IO/FFI or browser imports. Usage remains in each resource's transaction.
The client rejects wrong owners, unknown schema, invalid limits and backend failures.
Effective expiry comes from the authoritative server snapshot, not device clocks.
