-- Seed sample transport order, addresses, stops, and dispatch for testing UI (From/To/Delivery Date).
-- Adjust IDs as needed. Safe to run multiple times.

SET @now := NOW();
-- Base entities
SET @driverId := 72;
SET @creatorId := 56;

-- Order/Dispatch 1
SET @orderId1 := 99001;
SET @dispatchId1 := 9901;
SET @vehicleId1 := 1;
SET @pickupAddr1 := 91001;
SET @dropAddr1 := 91002;

-- Order/Dispatch 2
SET @orderId2 := 99002;
SET @dispatchId2 := 9902;
SET @vehicleId2 := 2;
SET @pickupAddr2 := 91003;
SET @dropAddr2 := 91004;

-- Order/Dispatch 3
SET @orderId3 := 99003;
SET @dispatchId3 := 9903;
SET @vehicleId3 := 3;
SET @pickupAddr3 := 91005;
SET @dropAddr3 := 91006;

-- Addresses
INSERT INTO customer_addresses (id,name,address,city,country,postcode,latitude,longitude,type)
VALUES
  (@pickupAddr1,'Warehouse Alpha','123 Main St','Phnom Penh','KH','12000',11.5620,104.8885,'WAREHOUSE'),
  (@dropAddr1,'Customer Beta','456 Market Rd','Phnom Penh','KH','12000',11.5675,104.9030,'CUSTOMER'),
  (@pickupAddr2,'Warehouse Gamma','789 Riverside','Phnom Penh','KH','12000',11.5600,104.8822,'WAREHOUSE'),
  (@dropAddr2,'Customer Delta','12 Ring Road','Phnom Penh','KH','12000',11.5705,104.9101,'CUSTOMER'),
  (@pickupAddr3,'Port Epsilon','Port Street 5','Phnom Penh','KH','12000',11.5500,104.8700,'WAREHOUSE'),
  (@dropAddr3,'Customer Zeta','88 Airport Rd','Phnom Penh','KH','12000',11.5900,104.9250,'CUSTOMER')
ON DUPLICATE KEY UPDATE name=VALUES(name), address=VALUES(address), latitude=VALUES(latitude), longitude=VALUES(longitude);

-- Order
INSERT INTO orders (id, order_reference, customer_id, status, created_by, created_at, delivery_date)
VALUES
  (@orderId1, 'TEST-DISPATCH-UI-001', 18, 'IN_TRANSIT', @creatorId, @now, DATE(@now)),
  (@orderId2, 'TEST-DISPATCH-UI-002', 17, 'ASSIGNED',   @creatorId, @now, DATE(@now)),
  (@orderId3, 'TEST-DISPATCH-UI-003', 16, 'ASSIGNED',   @creatorId, @now, DATE(@now))
ON DUPLICATE KEY UPDATE status=VALUES(status), delivery_date=VALUES(delivery_date);

-- Stops (PICKUP then DROP)
INSERT INTO order_stops (transport_order_id,address_id,sequence_order,type,eta,arrival_time,departure_time,remarks,proof_image_url,contact_phone,confirmed_by)
VALUES
  (@orderId1,@pickupAddr1,1,'PICKUP',DATE_ADD(@now,INTERVAL 30 MINUTE),NULL,NULL,'Pickup scheduled',NULL,'012345678','Gate A'),
  (@orderId1,@dropAddr1, 2,'DROP',DATE_ADD(@now,INTERVAL 120 MINUTE),NULL,NULL,'Drop scheduled',NULL,'012345678','Receiver'),
  (@orderId2,@pickupAddr2,1,'PICKUP',DATE_ADD(@now,INTERVAL 60 MINUTE),NULL,NULL,'Pickup scheduled',NULL,'012345679','Dock 1'),
  (@orderId2,@dropAddr2, 2,'DROP',DATE_ADD(@now,INTERVAL 180 MINUTE),NULL,NULL,'Drop scheduled',NULL,'012345679','Receiver B'),
  (@orderId3,@pickupAddr3,1,'PICKUP',DATE_ADD(@now,INTERVAL 90 MINUTE),NULL,NULL,'Pickup scheduled',NULL,'012345680','Port Gate'),
  (@orderId3,@dropAddr3, 2,'DROP',DATE_ADD(@now,INTERVAL 240 MINUTE),NULL,NULL,'Drop scheduled',NULL,'012345680','Receiver C')
ON DUPLICATE KEY UPDATE eta=VALUES(eta), remarks=VALUES(remarks);

-- Dispatch linked to the order
INSERT INTO dispatches (id, route_code, start_time, estimated_arrival, status, trip_type,
                        transport_order_id, driver_id, vehicle_id, created_by, created_date, updated_date)
VALUES
  (@dispatchId1, 'ROUTE-UI-001', @now, DATE_ADD(@now, INTERVAL 2 HOUR),
        'ASSIGNED', 'DELIVERY', @orderId1, @driverId, @vehicleId1, @creatorId, @now, @now),
  (@dispatchId2, 'ROUTE-UI-002', @now, DATE_ADD(@now, INTERVAL 3 HOUR),
        'ASSIGNED', 'DELIVERY', @orderId2, @driverId, @vehicleId2, @creatorId, @now, @now),
  (@dispatchId3, 'ROUTE-UI-003', @now, DATE_ADD(@now, INTERVAL 4 HOUR),
        'ASSIGNED', 'DELIVERY', @orderId3, @driverId, @vehicleId3, @creatorId, @now, @now)
ON DUPLICATE KEY UPDATE status=VALUES(status), estimated_arrival=VALUES(estimated_arrival), updated_date=@now;

-- Optional: load proof (schema supports remarks/signature only)
INSERT INTO load_proof (dispatch_id, remarks, signature_path, uploaded_at)
VALUES
  (@dispatchId1, 'Loaded test freight', 'load-proof/9901/sample.txt', @now),
  (@dispatchId2, 'Loaded test freight', 'load-proof/9902/sample.txt', @now),
  (@dispatchId3, 'Loaded test freight', 'load-proof/9903/sample.txt', @now)
ON DUPLICATE KEY UPDATE remarks=VALUES(remarks), signature_path=VALUES(signature_path), uploaded_at=@now;
