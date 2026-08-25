
# Screenshot catalog

Screenshots are grouped by the phase of the lab.

## AWS account and bucket

- `001_register.jpg` - AWS registration screen 
- `002_plan_choose.jpg` - free/paid plan selection 
- `005-create-s3-bucket.jpg` - S3 entry point
- `010-create-bucket-general-settings.jpg` - region, general-purpose type, global namespace, bucket name
- `015-create-bucket-access-settings.jpg` - ACLs disabled and Block Public Access enabled
- `020-create-bucket-storage-settings.jpg` - versioning and SSE-S3 settings
- `025-bucket-created.jpg` - bucket creation success
- `030-create-folder.jpg` - creating the `inbound` prefix/folder
- `035-s3-bucket-prefixes.jpg` - `inbound/` and `outbound/`
- `040-s3-files-upload-successfull.jpg` - sample upload success
- `045-s3-inbound-test-files.jpg` - initial TXT/CSV/PDF/JPEG samples

## IAM

- `050-create-iam-policy.jpg` - IAM policy navigation
- `055-create-iam-policy-json-editor.jpg` - least-privilege JSON policy
- `060-iam-policy-created.jpg` - policy created
- `065-create-iam-user.jpg` - IAM user creation
- `070-iam-user-created.jpg` - IAM user + policy
- `075-iam-user-create-access-key.jpg` - access-key entry point
- `080-iam-user-access-key-use-case.jpg` - "Application running outside AWS" use case
- `085-iam-user-access-key-created.jpg` - access-key creation result

## DBMS_CLOUD object operations

- `090-list-s3-objects-from-adb.jpg` - first successful `LIST_OBJECTS`
- `095-existing-network-aces.jpg` - existing Oracle host ACEs, no explicit AWS host
- `100-get-text-object-as-clob.jpg` - UTF-8 BLOB -> CLOB
- `105-get-binary-objects.jpg` - PDF/JPEG first-byte signatures
- `110-s3-objects-persisted-as-blobs.jpg` - original objects persisted as BLOBs
- `115-s3-outbound-before-upload.jpg` - empty outbound prefix
- `120-binary-roundtrip-integrity.jpg` - `DBMS_LOB.COMPARE = 0`
- `125-s3-outbound-binary-objects.jpg` - binary copies in S3
- `130-text-blob-to-clob-processing.jpg` - stored BLOB + derived CLOB
- `135-text-clob-s3-roundtrip.jpg` - text round-trip integrity
- `140-s3-outbound-text-and-binary-objects.jpg` - outbound text + binary objects

## CSV and ingestion flow

- `145-csv-original-and-extracted-data.jpg` - original BLOB plus extracted customer rows
- `150-copy-data-detect-field-order.jpg` - reordered CSV loaded by header name
- `155-s3-prefix-filter-test-files.jpg` - matching/nonmatching S3 objects
- `160-parameterized-ingest-config.jpg` - individual parameter getters
- `160-parameterized-object-discovery.jpg` - package discovers two matching objects
- `165-single-file-ingest-idempotency.jpg` - intermediate package-development idempotency test
- `170-single-file-csv-processing.jpg` - staged-development view after CSV processing reached `PROCESSED`
- `175-safe-source-object-delete.jpg` - staged-development explicit safe-delete test
- `180-s3-after-single-source-delete.jpg` - one source removed, unrelated objects retained
- `185-prefix-based-end-to-end-processing.jpg` - batch prefix-based processing
- `190-completed-files-and-extracted-data.jpg` - completed files + four business rows
- `195-s3-after-prefix-processing.jpg` - matching sources removed, unrelated objects remain

`165-single-file-ingest-idempotency.jpg` and the `170`-`180` sequence were captured while the package was being built incrementally. The final package calls the same safe-delete routine automatically from `PROCESS_FILE` after the database work is committed. These screenshots remain useful evidence of the individual stages and design decisions.

## Metadata and troubleshooting additions

- `200-list-objects-created-vs-last-modified.png` - Amazon S3 `CREATED` is NULL while `LAST_MODIFIED` is populated
- `205-copy-data-data-pump-dir-error.png` - missing `DATA_PUMP_DIR` grant
- `210-copy-data-staging-deadlock.png` - staging DML lock conflict observed before adding the commit
