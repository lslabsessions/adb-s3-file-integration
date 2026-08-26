# Oracle Autonomous Database and Amazon S3 File Integration with DBMS_CLOUD

Hands-on lab for integrating **Oracle Autonomous AI Database** with a **private Amazon S3 bucket** using `DBMS_CLOUD`.

The lab starts with basic object operations and then builds a parameterized ingestion flow that discovers files by prefix, preserves the original source object as a `BLOB`, loads CSV rows into relational tables, and deletes the source from S3 only after the database work has committed successfully.

## What this lab demonstrates

- Private Amazon S3 access with an AWS IAM user and `DBMS_CLOUD.CREATE_CREDENTIAL`
- `DBMS_CLOUD.LIST_OBJECTS`, `GET_OBJECT`, `PUT_OBJECT`, `DELETE_OBJECT`, and `COPY_DATA`
- Preserving original TXT, CSV, PDF, and JPEG objects as `BLOB`
- Explicit UTF-8 `BLOB`/`CLOB` conversion with `DBMS_LOB.CONVERTTOCLOB` and `CONVERTTOBLOB`
- Binary round-trip integrity with `DBMS_LOB.COMPARE = 0`
- PDF/JPEG file-signature inspection using the first bytes of each `BLOB`
- `COPY_DATA` header mapping with `detectfieldorder`
- Parameterized endpoint, bucket, folder, credential, filename prefix, and extension
- Prefix-based discovery (`customer_` + `.csv`) while unrelated objects remain untouched
- Processing idempotency based on object identity and metadata
- Safe source deletion with `DELETE_PENDING` retry semantics
- S3 metadata details such as `CREATED`, `LAST_MODIFIED`, and `CHECKSUM`

![Prefix-based end-to-end processing](docs/screenshots/185-prefix-based-end-to-end-processing.jpg)

## Lab architecture

```text
Amazon S3 (private)
│
├── inbound/
│   ├── message.txt
│   ├── customers.csv
│   ├── sample-document.pdf
│   ├── lume-lab-sessions.jpeg
│   ├── customer_20260823_001.csv
│   ├── customer_20260823_002.csv
│   └── orders_20260823_001.csv
│
│        LIST_OBJECTS / GET_OBJECT / COPY_DATA / DELETE_OBJECT
│                              │
│                              ▼
│                    Oracle Autonomous Database
│                    ├── S3_FILE_STORE   (original BLOB)
│                    ├── S3_FILE_TEXT    (derived CLOB)
│                    ├── CUSTOMER_STAGE  (COPY_DATA staging)
│                    ├── CUSTOMER_DATA   (business rows)
│                    └── S3_INGEST_CONFIG
│
└── outbound/
    ├── sample-document-copy.pdf
    ├── lume-lab-sessions-copy.jpeg
    └── message-generated.txt
             ▲
             └── PUT_OBJECT
```

See [docs/architecture.md](docs/architecture.md) for the full flow.

## Repository structure

```text
.
├── aws/
│   ├── README.md
│   └── iam-policy.json
├── sample-data/
├── sql/
├── docs/
│   ├── architecture.md
│   ├── aws-setup.md
│   ├── object-operations.md
│   ├── copy-data-and-csv.md
│   ├── parameterized-ingest.md
│   ├── security-networking.md
│   ├── metadata-idempotency.md
│   ├── troubleshooting.md
│   └── screenshots/
└── README.md
```

## Important setup notes

The scripts contain the bucket used by this lab:

```text
lslabsessions-adb-s3-lab
```

Amazon S3 bucket names in the shared global namespace are globally unique within an AWS partition. If you reproduce the lab, replace the bucket name and, if necessary, the region endpoint in both the SQL scripts and `aws/iam-policy.json`.

The lab uses:

```text
AWS Region:      eu-central-1 (Frankfurt)
S3 endpoint:     s3.eu-central-1.amazonaws.com
Credential name: AWS_S3_CRED
Inbound prefix:  inbound/
Outbound prefix: outbound/
```

The S3 bucket remains private. **Block all public access stays enabled**; the database accesses S3 with authenticated IAM permissions.

## AWS IAM permissions

The sample policy follows least privilege for the lab:

- list only `inbound/*` and `outbound/*`
- read/delete objects under `inbound/*`
- read/write/delete objects under `outbound/*`

See [aws/README.md](aws/README.md) and [aws/iam-policy.json](aws/iam-policy.json).

This lab deliberately uses an IAM user access key and secret access key because this authentication model is straightforward to reproduce. Autonomous AI Database also supports AWS ARN-based authentication, where an IAM role and trust relationship are configured instead of storing long-lived AWS user keys. In that model, AWS STS temporary role credentials are used for access

ARN-based authentication can use an automatically provided AWS$ARN credential or a named DBMS_CLOUD credential containing the AWS role ARN configuration rather than an access key and secret key.

## Database prerequisites

Run as `ADMIN` or another privileged user:

```sql
GRANT EXECUTE ON DBMS_CLOUD TO <LAB_SCHEMA>;
GRANT READ, WRITE ON DIRECTORY DATA_PUMP_DIR TO <LAB_SCHEMA>;
```

The `DATA_PUMP_DIR` grant becomes relevant when `COPY_DATA` is introduced; the earlier `LIST_OBJECTS`/`GET_OBJECT` exercises do not depend on that directory grant.

Then create the AWS credential with `sql/001-create-aws-credential.sql` using a **local copy** containing the real values. Never commit the access key or secret key.

## Script order

| Script | Purpose |
|---|---|
| `000-prerequisites.sql` | Grants required privileges |
| `001-create-aws-credential.sql` | Stores AWS access key/secret in a DBMS_CLOUD credential |
| `005-list-s3-objects.sql` | Lists S3 objects and metadata |
| `010-get-text-object.sql` | Reads UTF-8 text as BLOB and decodes it to CLOB |
| `015-get-binary-objects.sql` | Reads PDF/JPEG and inspects their first bytes |
| `020-create-file-store.sql` | Creates the original-file BLOB store |
| `025-store-s3-objects.sql` | Persists S3 objects as original BLOBs |
| `030-put-binary-objects.sql` | BLOB -> S3 -> BLOB round-trip integrity |
| `035-process-text-object.sql` | Stores a derived text CLOB while preserving the original BLOB |
| `040-put-text-object.sql` | CLOB -> UTF-8 BLOB -> S3 -> CLOB round-trip |
| `045-read-csv-as-text.sql` | Treats a stored CSV as text |
| `050-load-csv-data.sql` | Uses `COPY_DATA` and links extracted rows to the original file |
| `055-copy-data-detect-field-order.sql` | Proves name-based CSV column mapping |
| `060-create-ingest-config.sql` | Creates the parameter table |
| `065-prepare-file-store-for-ingest.sql` | Adds configuration + S3 occurrence metadata |
| `070-create-s3-ingest-package-spec.sql` | Creates package specification |
| `075-create-s3-ingest-package-body.sql` | Creates package implementation |
| `080-test-ingest-config-functions.sql` | Tests individual parameter getter functions |
| `085-test-object-discovery.sql` | Tests prefix/extension discovery |
| `090-test-single-file-processing.sql` | Processes one source without deleting it |
| `095-test-source-delete.sql` | Deletes a processed source safely |
| `100-test-prefix-ingest.sql` | Runs full prefix-based end-to-end ingestion |
| `105-validate-end-to-end-ingest.sql` | Validates stored files, extracted rows, and remaining S3 objects |

## Key design decision: preserve the source first

`COPY_DATA` loads rows into an Oracle table, but it does **not** persist the original source file. The ingestion flow therefore combines two different operations:

```text
GET_OBJECT  -> preserve original bytes as BLOB
COPY_DATA   -> load structured CSV rows
```

This means a business row can be traced back to the exact `FILE_ID`, while the original source bytes remain available even after the S3 object has been removed.

![Original CSV and extracted rows](docs/screenshots/145-csv-original-and-extracted-data.jpg)

## Key metadata detail: `CREATED`, `LAST_MODIFIED`, and `CHECKSUM`

For Amazon S3, `DBMS_CLOUD.LIST_OBJECTS` returns `NULL` for `CREATED` and a timestamp for `LAST_MODIFIED`. Oracle documents the `CHECKSUM` column as an MD5 checksum computed on object contents.

Two objects can therefore have the same checksum while having different names, keys, folders, or timestamps if their bytes are identical. **Content equality is not the same thing as processing identity.**

See [docs/metadata-idempotency.md](docs/metadata-idempotency.md).

## Binary signatures

The binary test does not trust the extension alone:

```text
PDF:  25 50 44 46       -> "%PDF"
JPEG: FF D8 FF ...       -> JPEG start-of-image
      ... 4A 46 49 46   -> "JFIF" in the sample
```

The subsequent S3 round-trip verifies byte-for-byte equality with `DBMS_LOB.COMPARE`.

![Binary round-trip integrity](docs/screenshots/120-binary-roundtrip-integrity.jpg)

## CSV field order

With `detectfieldorder = true`, the first record contains field names and `COPY_DATA` maps those names to Oracle columns case-insensitively. This allows the source to use a different physical column order from the target table.

![detectfieldorder result](docs/screenshots/150-copy-data-detect-field-order.jpg)

See [docs/copy-data-and-csv.md](docs/copy-data-and-csv.md) for the distinction between `detectfieldorder`, `skipheaders`, and headerless files.

## Prefix-based ingestion

The configured feed is:

```text
FILE_PREFIX    = customer_
FILE_EXTENSION = .csv
```

The process matches:

```text
customer_20260823_001.csv
customer_20260823_002.csv
```

and ignores:

```text
customers.csv
customers-reordered.csv
orders_20260823_001.csv
message.txt
sample-document.pdf
lume-lab-sessions.jpeg
```

The package deliberately performs a literal prefix comparison instead of SQL `LIKE`, because `_` is a one-character wildcard in `LIKE`.

`DBMS_CLOUD.LIST_OBJECTS` also supports `*` and `?` wildcards directly in `location_uri`; `sql/085-test-object-discovery.sql` includes an example using `customer_*.csv`.

## Safe deletion and processing states

```text
RECEIVED
   ↓
PROCESSING
   ↓
PROCESSED
   ↓
DELETE_OBJECT
   ├── success -> COMPLETED
   └── failure -> DELETE_PENDING
```

The S3 delete is deliberately performed **after** the original BLOB and extracted rows have committed. S3 is an external system and its delete operation is not part of the Oracle transaction.

See [docs/parameterized-ingest.md](docs/parameterized-ingest.md).

## Documentation

- [Architecture and processing flow](docs/architecture.md)
- [AWS setup and bucket/IAM choices](docs/aws-setup.md)
- [DBMS_CLOUD object operations and LOB handling](docs/object-operations.md)
- [COPY_DATA and CSV field mapping](docs/copy-data-and-csv.md)
- [Parameterized prefix-based ingestion package](docs/parameterized-ingest.md)
- [Security and networking considerations](docs/security-networking.md)
- [S3 metadata and idempotency](docs/metadata-idempotency.md)
- [Troubleshooting and lessons learned](docs/troubleshooting.md)
- [Screenshot catalog](docs/screenshots/README.md)

## Official references

- Oracle DBMS_CLOUD package: https://docs.oracle.com/en-us/iaas/autonomous-database-serverless/doc/dbms-cloud-package.html
- Oracle DBMS_CLOUD subprograms: https://docs.oracle.com/en-us/iaas/autonomous-database-serverless/doc/dbms-cloud-subprograms.html
- Oracle DBMS_CLOUD URI formats: https://docs.oracle.com/en-us/iaas/autonomous-database-serverless/doc/file-uri-formats.html
- Oracle DBMS_CLOUD format options: https://docs.oracle.com/en/cloud/paas/autonomous-database/serverless/adbsb/format-options.html
- Oracle - Load Data from AWS S3: https://docs.oracle.com/en-us/iaas/autonomous-database-serverless/doc/autonomous-database-load-data-from-aws-s3.html
- AWS S3 object keys: https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-keys.html
- AWS S3 folders/prefixes: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-folders.html
- AWS S3 Block Public Access: https://docs.aws.amazon.com/AmazonS3/latest/userguide/access-control-block-public-access.html
