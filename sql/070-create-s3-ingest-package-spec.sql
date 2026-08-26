create or replace PACKAGE pkg_s3_ingest AS

    FUNCTION get_s3_endpoint (
        p_config_code IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_bucket_name (
        p_config_code IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_folder_name (
        p_config_code IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_credential_name (
        p_config_code IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_file_prefix (
        p_config_code IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_file_extension (
        p_config_code IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_enabled_flag (
        p_config_code IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_folder_uri (
        p_config_code IN VARCHAR2
    ) RETURN VARCHAR2;
    
	FUNCTION get_object_uri (
        p_config_code IN VARCHAR2,
        p_object_name IN VARCHAR2
    ) RETURN VARCHAR2;

    PROCEDURE list_matching_files (
        p_config_code IN VARCHAR2
    );
    
    PROCEDURE process_file (
        p_config_code IN VARCHAR2,
        p_object_name IN VARCHAR2
);

PROCEDURE delete_source_object (
    p_file_id IN NUMBER
);

PROCEDURE process_files (
    p_config_code IN VARCHAR2
);

END pkg_s3_ingest;
/