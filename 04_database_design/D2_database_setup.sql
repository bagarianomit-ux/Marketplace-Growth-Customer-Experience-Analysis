-- ============================================================
-- Marketplace Growth & Customer Experience Analysis
-- File: D2_database_setup.sql
-- Purpose: Create the project database
-- ============================================================

DROP DATABASE IF EXISTS marketplace_growth_analysis;

CREATE DATABASE marketplace_growth_analysis
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE marketplace_growth_analysis;


-- Verify database setup

SELECT
    DATABASE() AS active_database,
    @@character_set_database AS character_set,
    @@collation_database AS collation;