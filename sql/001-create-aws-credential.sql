-- AWS Access Key ID and Secret Access Key must never be committed to source control.
-- For Amazon S3 credentials, Oracle uses:
--   username = AWS Access Key ID
--   password = AWS Secret Access Key

-- Execute a local copy of this script with the placeholders replaced.

BEGIN
    DBMS_CLOUD.CREATE_CREDENTIAL(
        credential_name => 'AWS_S3_CRED',
        username        => '<AWS_ACCESS_KEY_ID>',
        password        => '<AWS_SECRET_ACCESS_KEY>',
        comments        => 'Amazon S3 credential for the ADB-S3 integration lab'
    );
END;
/
