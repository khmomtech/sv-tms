-- Create driver monthly performance tracking table
CREATE TABLE IF NOT EXISTS driver_monthly_performance (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  driver_id BIGINT NOT NULL,
  year INT NOT NULL,
  month INT NOT NULL,
  
  -- Delivery metrics
  total_deliveries INT DEFAULT 0,
  completed_deliveries INT DEFAULT 0,
  on_time_deliveries INT DEFAULT 0,
  late_deliveries INT DEFAULT 0,
  cancelled_deliveries INT DEFAULT 0,
  
  -- Safety metrics
  incidents_count INT DEFAULT 0,
  safety_violations INT DEFAULT 0,
  safety_score VARCHAR(50) DEFAULT 'Good',
  
  -- Performance scores
  performance_score INT DEFAULT 0,
  on_time_percent INT DEFAULT 0,
  
  -- Customer feedback
  total_ratings INT DEFAULT 0,
  average_rating DECIMAL(3,2),
  
  -- Ranking
  leaderboard_rank INT DEFAULT 0,
  rank_tier VARCHAR(20),
  
  -- Distance and fuel
  total_distance_km DECIMAL(10,2),
  fuel_efficiency DECIMAL(5,2),
  
  -- Metadata
  last_calculated_at DATE,
  is_finalized BOOLEAN DEFAULT FALSE,
  
  CONSTRAINT fk_monthly_perf_driver FOREIGN KEY (driver_id) REFERENCES drivers(id) ON DELETE CASCADE,
  CONSTRAINT uk_driver_year_month UNIQUE (driver_id, year, month)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Create indexes
CREATE INDEX idx_monthly_perf_driver ON driver_monthly_performance(driver_id);
CREATE INDEX idx_monthly_perf_period ON driver_monthly_performance(year, month);
CREATE INDEX idx_monthly_perf_score ON driver_monthly_performance(performance_score DESC);
CREATE INDEX idx_monthly_perf_rank ON driver_monthly_performance(leaderboard_rank);

-- Insert sample data for current month (December 2025)
INSERT INTO driver_monthly_performance 
  (driver_id, year, month, total_deliveries, completed_deliveries, on_time_deliveries, 
   late_deliveries, cancelled_deliveries, incidents_count, safety_violations, 
   performance_score, on_time_percent, total_ratings, average_rating, 
   leaderboard_rank, rank_tier, safety_score, total_distance_km, fuel_efficiency, 
   last_calculated_at, is_finalized)
VALUES 
  (1, 2025, 12, 45, 43, 42, 1, 2, 0, 0, 92, 98, 35, 4.8, 8, 'Gold', 'Excellent', 1250.50, 8.5, '2025-12-06', FALSE);

-- Update driver table to reference current monthly performance
UPDATE drivers 
SET 
  performance_score = (
    SELECT performance_score 
    FROM driver_monthly_performance 
    WHERE driver_id = drivers.id 
      AND year = YEAR(CURDATE()) 
      AND month = MONTH(CURDATE())
    LIMIT 1
  ),
  leaderboard_rank = (
    SELECT leaderboard_rank 
    FROM driver_monthly_performance 
    WHERE driver_id = drivers.id 
      AND year = YEAR(CURDATE()) 
      AND month = MONTH(CURDATE())
    LIMIT 1
  ),
  on_time_percent = (
    SELECT on_time_percent 
    FROM driver_monthly_performance 
    WHERE driver_id = drivers.id 
      AND year = YEAR(CURDATE()) 
      AND month = MONTH(CURDATE())
    LIMIT 1
  ),
  safety_score = (
    SELECT safety_score 
    FROM driver_monthly_performance 
    WHERE driver_id = drivers.id 
      AND year = YEAR(CURDATE()) 
      AND month = MONTH(CURDATE())
    LIMIT 1
  )
WHERE id IN (
  SELECT DISTINCT driver_id 
  FROM driver_monthly_performance 
  WHERE year = YEAR(CURDATE()) 
    AND month = MONTH(CURDATE())
);
