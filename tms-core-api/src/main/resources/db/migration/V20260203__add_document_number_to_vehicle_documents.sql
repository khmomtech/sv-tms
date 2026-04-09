-- Adds a searchable document number to the vehicle_documents table.
ALTER TABLE vehicle_documents
  ADD COLUMN document_number VARCHAR(80);
