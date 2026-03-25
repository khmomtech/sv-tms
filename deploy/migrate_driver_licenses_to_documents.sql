-- Migration: Move all driver_licenses to driver_documents as category = 'license'
-- Assumes new columns already exist in driver_documents

INSERT INTO driver_documents (
    driver_id,
    name,
    category,
    expiry_date,
    license_number,
    license_class,
    issued_date,
    issuing_authority,
    license_image_url,
    license_front_image,
    license_back_image,
    license_notes,
    description,
    is_required,
    file_url,
    created_at,
    updated_at,
    updated_by
)
SELECT
    dl.driver_id,
    'Driver License',
    'license',
    dl.expiry_date,
    dl.license_number,
    dl.license_class,
    dl.issued_date,
    dl.issuing_authority,
    dl.license_image_url,
    dl.license_front_image,
    dl.license_back_image,
    dl.notes,
    dl.notes,
    false,
    NULL,
    NOW(),
    NOW(),
    'migration'
FROM driver_licenses dl
WHERE dl.deleted = false;

-- Optionally, mark migrated driver_licenses as deleted
UPDATE driver_licenses SET deleted = true WHERE deleted = false;
