# Troubleshooting and lessons learned

## `ORA-06564: Object DATA_PUMP_DIR does not exist or is not accessible`

Observed when the lab first introduced `DBMS_CLOUD.COPY_DATA`.

Cause: the application schema had `DBMS_CLOUD` access but did not have the directory privilege required by the loader for log/bad-file information.

Fix, executed by `ADMIN` or another privileged user:

```sql
GRANT READ, WRITE ON DIRECTORY DATA_PUMP_DIR TO <LAB_SCHEMA>;
```

See `sql/000-prerequisites.sql`.

![DATA_PUMP_DIR error](screenshots/205-copy-data-data-pump-dir-error.png)

## `ORA-00060: deadlock detected while waiting for resource` around COPY_DATA

During package development the lab cleared the shared staging table with `DELETE` and immediately invoked `COPY_DATA` without committing the DML. That produced a lock conflict in this environment.

The working sequence is:

```sql
DELETE FROM customer_stage;
COMMIT;

DBMS_CLOUD.COPY_DATA(...);
```

![Deadlock observed](screenshots/210-copy-data-staging-deadlock.png)

The repository treats this as a transaction/locking lesson observed in the lab, not as a universal rule for every possible `COPY_DATA` setup.

## AWS `AccessDenied` / HTTP 403

If `LIST_OBJECTS`, `GET_OBJECT`, `PUT_OBJECT`, or `DELETE_OBJECT` fails with AWS authorization errors, check the IAM policy first:

- bucket-level `s3:ListBucket`
- correct `s3:prefix` condition
- object-level `s3:GetObject`, `s3:PutObject`, or `s3:DeleteObject`
- correct bucket/object ARN

A network ACL change will not fix an AWS IAM authorization failure.

## `ORA-24247` / network ACL errors

A database network ACL error is a different layer from AWS IAM. Standard S3 worked without a new host ACE in this Autonomous Database lab, but customer-managed endpoints or different private-network deployments may require additional outbound network configuration.

## Text is corrupted after GET_OBJECT

`GET_OBJECT` returns bytes. Do not assume those bytes are already database text.

For this lab's UTF-8 samples:

```sql
blob_csid => NLS_CHARSET_ID('AL32UTF8')
```

is supplied explicitly to `DBMS_LOB.CONVERTTOCLOB` / `CONVERTTOBLOB`.

## Why BLOB size and CLOB length differ

A BLOB length is bytes; a CLOB length is characters. UTF-8 characters can consume more than one byte, so the values need not match.

The lab sample shows:

```text
222 bytes
210 characters
```

with a conversion warning of `0`.

## Why not delete the S3 source immediately after GET_OBJECT?

Because a later CSV load/business insert could still fail. The package persists the original, processes the data, commits, and only then calls `DELETE_OBJECT`.

If deletion fails after successful processing, the file is marked `DELETE_PENDING` rather than reloading the business rows.

## Why a checksum is not the idempotency key by itself

Equal bytes can occur under different object keys or as separate later deliveries. See [metadata-idempotency.md](metadata-idempotency.md).
