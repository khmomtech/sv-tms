-- Normalize enum-like fields to our canonical values

-- Vehicles: status/type/fuel/ownership
UPDATE vehicles SET status='ACTIVE'           WHERE status IN ('Active','active','A', '') OR status IS NULL;
UPDATE vehicles SET status='IN_MAINTENANCE'   WHERE status IN ('MAINTENANCE','IN_MAINT','REPAIR');
UPDATE vehicles SET status='INACTIVE'         WHERE status IN ('Inactive','OFF');
UPDATE vehicles SET status='RETIRED'          WHERE status IN ('Retired','DECOM','Scrapped');

UPDATE vehicles SET type='TRUCK'      WHERE type IS NULL OR type IN ('Truck','Lorry');
UPDATE vehicles SET type='VAN'        WHERE type IN ('Van');
UPDATE vehicles SET type='MOTORBIKE'  WHERE type IN ('Bike','Motorbike','Moto');
UPDATE vehicles SET type='SUV'        WHERE type IN ('SUV','Car');
UPDATE vehicles SET type='OTHER'      WHERE type NOT IN ('TRUCK','VAN','MOTORBIKE','SUV','OTHER');

UPDATE vehicles SET fuel_type='DIESEL'   WHERE fuel_type IN ('Diesel','diesel') OR fuel_type IS NULL;
UPDATE vehicles SET fuel_type='GASOLINE' WHERE fuel_type IN ('Gas','Petrol','GASOLINE','gasoline');
UPDATE vehicles SET fuel_type='HYBRID'   WHERE fuel_type IN ('Hybrid');
UPDATE vehicles SET fuel_type='ELECTRIC' WHERE fuel_type IN ('Electric','EV');
UPDATE vehicles SET fuel_type='OTHER'    WHERE fuel_type NOT IN ('DIESEL','GASOLINE','ELECTRIC','HYBRID','OTHER');

UPDATE vehicles SET ownership='COMPANY'  WHERE ownership IS NULL OR ownership IN ('Company','Internal');
UPDATE vehicles SET ownership='PARTNER'  WHERE ownership IN ('Partner','Subcontractor','Vendor');

-- Drivers
UPDATE drivers SET status='ACTIVE'     WHERE status IS NULL OR status IN ('Active','A','');
UPDATE drivers SET status='INACTIVE'   WHERE status IN ('Inactive','OFF');
UPDATE drivers SET status='SUSPENDED'  WHERE status IN ('Suspended','SUSP');

UPDATE drivers SET ownership='COMPANY' WHERE ownership IS NULL OR ownership IN ('Company','Internal');
UPDATE drivers SET ownership='PARTNER' WHERE ownership IN ('Partner','Subcontractor');

-- Driver assignments
UPDATE driver_assignments SET status='ACTIVE'     WHERE status IS NULL OR status IN ('Active','A','');
UPDATE driver_assignments SET status='COMPLETED'  WHERE status IN ('Completed','CLOSE','Done');