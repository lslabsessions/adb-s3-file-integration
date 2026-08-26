-- Run as ADMIN or another privileged user.

-- EXECUTE on DBMS_CLOUD is required by the lab schema.
-- READ/WRITE on DATA_PUMP_DIR is specifically required by COPY_DATA because
-- load log/bad-file information is written through that directory object.

GRANT EXECUTE ON DBMS_CLOUD TO <LAB_SCHEMA>;
GRANT READ, WRITE ON DIRECTORY DATA_PUMP_DIR TO <LAB_SCHEMA>;
