# pqi-ffi

The FFI adapter for [`pqi`](https://github.com/nikita-volkov/pqi),
backed by [`postgresql-libpq`](https://hackage.haskell.org/package/postgresql-libpq)
(a binding to the C `libpq` library).

`Pqi.Ffi.Connection` wraps a C-backed `PGconn` and provides an
`IsConnection` instance whose every method is a near-mechanical delegation to
the matching `Database.PostgreSQL.LibPQ` function. The only work is converting
between this family's portable types (OIDs as `Word32`, indices as `Int32`,
the shared enums) and `postgresql-libpq`'s C-specific newtypes.

This adapter is the **fidelity reference** for the `pqi` family: it is the
oracle against which all other adapters are tested. The
[`pqi-conformance`](https://github.com/nikita-volkov/pqi-conformance) suite
runs every operation on both the candidate adapter and this one, asserts
byte-identical output, and thereby defines what "correct" means for the family.
