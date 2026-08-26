# Architecture and processing flow

The lab has two layers: basic object operations and a reusable inbound file-processing flow.

## Object operations

```text
Amazon S3
   │
   ├── LIST_OBJECTS  -> names + metadata
   ├── GET_OBJECT    -> BLOB
   ├── PUT_OBJECT    <- BLOB
   └── DELETE_OBJECT -> remove source object
```

Text and binary files arrive through the same S3 object interface: bytes. The application decides whether those bytes remain a `BLOB` or are decoded to a `CLOB`.

```text
PDF / JPEG
S3 bytes -> BLOB

TXT / CSV
S3 bytes -> BLOB -> UTF-8 decode -> CLOB
```

## Why the original file is stored first

The central design rule is:

> Processing is derived from the source file; it never replaces the source file.

```text
S3 source object
      │
      ├── GET_OBJECT -> S3_FILE_STORE.FILE_CONTENT (original BLOB)
      │
      └── COPY_DATA  -> CUSTOMER_STAGE -> CUSTOMER_DATA
                                      │
                                      └── FILE_ID provenance
```

The original source remains available in Oracle even after it has been removed from S3.

## Parameterized feed

`S3_INGEST_CONFIG` separates environment/configuration from processing logic:

```text
CONFIG_CODE      CUSTOMERS
S3_ENDPOINT      s3.eu-central-1.amazonaws.com
BUCKET_NAME      lslabsessions-adb-s3-lab
FOLDER_NAME      inbound
CREDENTIAL_NAME  AWS_S3_CRED
FILE_PREFIX      customer_
FILE_EXTENSION   .csv
ENABLED_FLAG     Y
```

The package exposes one getter for each property and derives the folder/object URI from those values.

## End-to-end batch

```text
PROCESS_FILES('CUSTOMERS')
        │
        ▼
read configuration
        │
        ▼
LIST_OBJECTS(inbound/)
        │
        ▼
literal prefix + extension filter
customer_*.csv
        │
        ▼
for each object
        │
        ├── read S3 metadata
        ├── check processing identity
        ├── GET_OBJECT
        ├── persist original BLOB
        ├── COMMIT
        ├── COPY_DATA -> CUSTOMER_STAGE
        ├── insert CUSTOMER_DATA with FILE_ID
        ├── mark PROCESSED
        ├── COMMIT
        └── DELETE_OBJECT
             ├── success -> COMPLETED
             └── failure -> DELETE_PENDING
```

![End-to-end processing](screenshots/185-prefix-based-end-to-end-processing.jpg)

## Transaction boundary

The S3 delete is not part of the Oracle transaction. This is why the database state is committed before `DELETE_OBJECT`:

```text
Oracle transaction                  External AWS operation
------------------                  ----------------------
persist source BLOB
insert business rows
status = PROCESSED
COMMIT
                                     DELETE_OBJECT
                                     |
                                     + success
                                       -> Oracle status = COMPLETED
                                     + failure
                                       -> Oracle status = DELETE_PENDING
```

This avoids deleting the only source copy before the database has safely persisted it.
