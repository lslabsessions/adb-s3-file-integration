# SQL execution notes

Run the scripts in numeric order in a dedicated lab schema.

Important points:

- `000-prerequisites.sql` is run as `ADMIN` or another privileged account.
- `001-create-aws-credential.sql` must be executed from a local copy containing the real AWS values; keep the repository copy as placeholders.
- `020` initially uses a simple `(bucket_name, object_key)` unique constraint for the introductory storage exercise. `065` intentionally replaces that model for recurring deliveries.
- `050` and `055` use `COPY_DATA`, so the `DATA_PUMP_DIR` grant from `000` must already be present.
- `070` and `075` contain the final package specification/body used by the later tests.
- `090` tests the final single-object flow. A successful `PROCESS_FILE` run preserves the BLOB, extracts business rows, and safely deletes the S3 source, ending at `COMPLETED`.
- `095` calls `DELETE_SOURCE_OBJECT` again for that completed file to demonstrate that the delete routine is safe to retry.
- `100` is the end-to-end batch entry point and processes only objects matching the configured prefix and extension.

The sample configuration expects the files in `../sample-data/` to be uploaded to `inbound/` before the related exercises are run.
