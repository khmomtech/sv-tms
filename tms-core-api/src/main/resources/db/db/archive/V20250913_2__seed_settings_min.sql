-- Minimal seed for groups and a few common definitions
INSERT INTO setting_group(code, name, description) VALUES
  ('system.core','System Core','Core system configuration'),
  ('security.auth','Auth & Password','Authentication and password policy'),
  ('features','Feature Flags','Runtime feature toggles'),
  ('maps.google','Google Maps','Google Maps configuration')
ON DUPLICATE KEY UPDATE name=VALUES(name), description=VALUES(description);

-- system.core
INSERT INTO setting_def (group_id,key_code,label,description,type,required,default_value)
SELECT id,'appName','App Name','Display/application name','STRING',1,'SV TMS'
FROM setting_group WHERE code='system.core'
ON DUPLICATE KEY UPDATE label=VALUES(label), description=VALUES(description), default_value=VALUES(default_value);

INSERT INTO setting_def (group_id,key_code,label,description,type,required,default_value)
SELECT id,'timezone','Timezone','IANA timezone','STRING',1,'Asia/Phnom_Penh'
FROM setting_group WHERE code='system.core'
ON DUPLICATE KEY UPDATE label=VALUES(label), description=VALUES(description), default_value=VALUES(default_value);

-- security.auth
INSERT INTO setting_def (group_id,key_code,label,description,type,required,default_value, min_value, max_value, requires_restart)
SELECT id,'jwt.expMinutes','JWT Expiry (minutes)','Auth token expiry','NUMBER',1,'60', 5, 4320, 0
FROM setting_group WHERE code='security.auth'
ON DUPLICATE KEY UPDATE label=VALUES(label), description=VALUES(description), default_value=VALUES(default_value), min_value=VALUES(min_value), max_value=VALUES(max_value), requires_restart=VALUES(requires_restart);

INSERT INTO setting_def (group_id,key_code,label,description,type,required,default_value)
SELECT id,'passwordPolicy','Password Policy','JSON policy object','JSON',0,'{"minLen":8,"numbers":true,"special":true}'
FROM setting_group WHERE code='security.auth'
ON DUPLICATE KEY UPDATE label=VALUES(label), description=VALUES(description), default_value=VALUES(default_value);

-- features
INSERT INTO setting_def (group_id,key_code,label,description,type,required,default_value)
SELECT id,'websocketV2','Enable WebSocket v2','Feature flag','BOOLEAN',1,'false'
FROM setting_group WHERE code='features'
ON DUPLICATE KEY UPDATE label=VALUES(label), description=VALUES(description), default_value=VALUES(default_value);

INSERT INTO setting_def (group_id,key_code,label,description,type,required,default_value)
SELECT id,'driverChat','Enable Driver Chat','Feature flag','BOOLEAN',1,'true'
FROM setting_group WHERE code='features'
ON DUPLICATE KEY UPDATE label=VALUES(label), description=VALUES(description), default_value=VALUES(default_value);

-- maps.google
INSERT INTO setting_def (group_id,key_code,label,description,type,required,default_value)
SELECT id,'apiKeyBrowser','Google Maps Key (browser)','Keep secret','PASSWORD',0,''
FROM setting_group WHERE code='maps.google'
ON DUPLICATE KEY UPDATE label=VALUES(label), description=VALUES(description);