-- Initialize shared database for multi-application infrastructure
-- This script sets up common database structures and permissions

-- Create application-specific databases
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_database WHERE datname = 'flask_app_db') THEN
        CREATE DATABASE flask_app_db;
    END IF;
    IF NOT EXISTS (SELECT FROM pg_database WHERE datname = 'node_app_db') THEN
        CREATE DATABASE node_app_db;
    END IF;
    IF NOT EXISTS (SELECT FROM pg_database WHERE datname = 'shared_data_db') THEN
        CREATE DATABASE shared_data_db;
    END IF;
END
$$;

-- Create application-specific users
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'flask_user') THEN
        CREATE ROLE flask_user WITH LOGIN PASSWORD 'flask_password';
    END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'node_user') THEN
        CREATE ROLE node_user WITH LOGIN PASSWORD 'node_password';
    END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'shared_user') THEN
        CREATE ROLE shared_user WITH LOGIN PASSWORD 'shared_password';
    END IF;
END
$$;

-- Grant permissions for application users
GRANT ALL PRIVILEGES ON DATABASE flask_app_db TO flask_user;
GRANT ALL PRIVILEGES ON DATABASE node_app_db TO node_user;
GRANT ALL PRIVILEGES ON DATABASE shared_data_db TO shared_user;
GRANT CONNECT ON DATABASE shared_data_db TO flask_user, node_user;

-- Connect to shared database to create common tables
\c shared_data_db;

-- Create common tables for shared functionality
CREATE TABLE IF NOT EXISTS audit_logs (
    id SERIAL PRIMARY KEY,
    application VARCHAR(50) NOT NULL,
    user_id VARCHAR(100),
    action VARCHAR(100) NOT NULL,
    details JSONB,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS application_config (
    id SERIAL PRIMARY KEY,
    app_name VARCHAR(50) UNIQUE NOT NULL,
    config_key VARCHAR(100) NOT NULL,
    config_value TEXT,
    environment VARCHAR(20) DEFAULT 'development',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_audit_logs_app ON audit_logs(application);
CREATE INDEX IF NOT EXISTS idx_audit_logs_timestamp ON audit_logs(timestamp);
CREATE INDEX IF NOT EXISTS idx_app_config_name_env ON application_config(app_name, environment);

-- Insert default configuration
INSERT INTO application_config (app_name, config_key, config_value, environment) 
VALUES 
    ('flask-app', 'default_page_size', '20', 'development'),
    ('node-app', 'default_page_size', '20', 'development'),
    ('shared', 'session_timeout', '3600', 'development')
ON CONFLICT (app_name) DO NOTHING;