-- MyPA — Migration 1: Extensions & Enum Types
-- Ref: Technical Design Document (TDD) v1.3, Section 3

-- gen_random_uuid() is provided by pgcrypto on Supabase-managed Postgres
create extension if not exists pgcrypto;

-- Core Platform (TDD 3.1)
create type account_type as enum ('individual', 'consultant', 'business');
create type subscription_tier as enum ('free', 'pro', 'business');
create type team_role as enum ('admin', 'manager', 'contributor', 'viewer');

-- Content & Publishing (TDD 3.4)
create type content_status as enum ('draft', 'pending_approval', 'scheduled', 'published', 'failed');
create type social_platform as enum ('instagram', 'facebook', 'linkedin', 'x', 'tiktok', 'youtube');
