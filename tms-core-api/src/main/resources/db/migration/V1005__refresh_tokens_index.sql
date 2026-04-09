-- Add index on refresh_tokens.user_id for faster queries
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user_id ON refresh_tokens (user_id);
