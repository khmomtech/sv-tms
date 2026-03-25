-- Add performance metrics columns to drivers table
ALTER TABLE drivers
ADD COLUMN performance_score INT DEFAULT 92,
ADD COLUMN leaderboard_rank INT DEFAULT 0,
ADD COLUMN on_time_percent INT DEFAULT 98,
ADD COLUMN safety_score VARCHAR(50) DEFAULT 'Excellent';

-- Add indexes for performance queries
CREATE INDEX idx_drivers_performance_score ON drivers(performance_score);
CREATE INDEX idx_drivers_leaderboard_rank ON drivers(leaderboard_rank);

-- Update existing drivers with default performance values
UPDATE drivers
SET 
  performance_score = COALESCE(performance_score, 92),
  leaderboard_rank = COALESCE(leaderboard_rank, 0),
  on_time_percent = COALESCE(on_time_percent, 98),
  safety_score = COALESCE(safety_score, 'Excellent')
WHERE performance_score IS NULL 
   OR leaderboard_rank IS NULL 
   OR on_time_percent IS NULL 
   OR safety_score IS NULL;
