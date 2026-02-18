---
id: PD-GDE-005
type: Product Documentation
category: Guide
version: 1.0
created: 2025-06-10
updated: 2025-06-10
---

# Local Supabase Setup Guide for BreakoutBuddies

This guide provides detailed instructions for setting up and using a local Supabase instance for development and testing of the BreakoutBuddies application.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Starting the Local Supabase Instance](#starting-the-local-supabase-instance)
3. [Configuring the Flutter App](#configuring-the-flutter-app)
4. [Using Supabase Studio](#using-supabase-studio)
5. [Database Schema Setup](#database-schema-setup)
6. [Common Issues and Troubleshooting](#common-issues-and-troubleshooting)
7. [Stopping the Local Supabase Instance](#stopping-the-local-supabase-instance)

## Prerequisites

Before you begin, ensure you have the following installed:

- Docker Desktop (latest version)
- Docker Compose
- Flutter SDK (latest stable version)
- Git

## Starting the Local Supabase Instance

1. Navigate to the project root directory:

```bash
cd c:/Users/ronny/VS_Code/BreakoutBuddies/breakoutbuddies
```

2. Start the Supabase services using Docker Compose:

```bash
docker-compose up -d
```

This command starts all the necessary Supabase services in detached mode (running in the background).

3. Verify that the services are running:

```bash
docker ps
```

You should see containers for the following services:
- `breakoutbuddies-supabase-db-1` (PostgreSQL database)
- `breakoutbuddies-kong-1` (API Gateway)
- `breakoutbuddies-auth-1` (Authentication service)
- `breakoutbuddies-rest-1` (REST API)
- `breakoutbuddies-realtime-1` (Realtime service)
- `breakoutbuddies-storage-1` (Storage service)
- `breakoutbuddies-supabase-studio-1` (Supabase Studio UI)

4. Wait for all services to be healthy:

```bash
docker ps --format "{{.Names}}: {{.Status}}"
```

The Supabase Studio may take a few minutes to become healthy. You can proceed with the next steps while it's starting up.

## Configuring the Flutter App

1. Open the environment configuration file:

```
../../development/guides/lib/lib/constants/env.dart
```

2. Ensure the file is configured to use the local Supabase instance:

```dart
/// Environment constants for the application
class Env {
  /// Supabase URL - Local development URL
  static const String supabaseUrl = 'http://localhost:8000';

  /// Supabase Anon Key - Local development anon key
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyAgCiAgICAicm9sZSI6ICJhbm9uIiwKICAgICJpc3MiOiAic3VwYWJhc2UtZGVtbyIsCiAgICAiaWF0IjogMTY0MTc2OTIwMCwKICAgICJleHAiOiAxNzk5NTM1NjAwCn0.dc_X5iR_VP_qT0zsiyj_I_OZ2T9FtRU2BBNWN8Bu4GE';

  /// Production Supabase URL (uncomment when deploying to production)
  // static const String supabaseUrl = 'https://ynpizhhrphzvhemqddvu.supabase.co';

  /// Production Supabase Anon Key (uncomment when deploying to production)
  // static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
}
```

3. Run the Flutter app:

```bash
flutter run
```

The app should now connect to your local Supabase instance.

## Using Supabase Studio

Supabase Studio provides a web interface for managing your Supabase project.

1. Access Supabase Studio at [http://localhost:3000](http://localhost:3000)

2. You'll be redirected to the project dashboard at [http://localhost:3000/project/default](http://localhost:3000/project/default)

3. From here, you can:
   - Browse and edit database tables
   - Manage authentication settings
   - Configure storage buckets
   - Run SQL queries
   - View API documentation

## Database Schema Setup

You can set up your database schema using SQL migrations or directly through the Supabase Studio interface.

### Using SQL Migrations

1. Create a new SQL file in the `supabase/migrations` directory:

```bash
mkdir -p supabase/migrations
touch supabase<!-- /migrations/01_initial_schema.sql - File not found -->
```

2. Add your SQL schema to the migration file:

```sql
-- Example schema for a users table
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID REFERENCES auth.users NOT NULL PRIMARY KEY,
  username TEXT UNIQUE,
  avatar_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Example schema for a games table
CREATE TABLE IF NOT EXISTS public.games (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  created_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Set up Row Level Security (RLS)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.games ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Public profiles are viewable by everyone"
  ON public.profiles FOR SELECT
  USING (true);

CREATE POLICY "Users can insert their own profile"
  ON public.profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id);

-- Similar policies for games table
-- ...
```

3. Apply the migration by running the SQL in Supabase Studio's SQL Editor.

### Using Supabase Studio Interface

1. Go to the "Table Editor" in Supabase Studio
2. Click "Create a new table"
3. Define your table schema using the UI
4. Set up Row Level Security (RLS) policies in the "Authentication" section

## Common Issues and Troubleshooting

### Vector Service Issues

If you encounter issues with the Vector service:

1. Edit the `docker-compose.yml` file to comment out the Vector service:

```yaml
# Removed vector service due to networking issues
#  vector:
#    image: public.ecr.aws/supabase/vector:0.28.1-alpine
#    container_name: supabase_vector_breakoutbuddies
#    environment:
#      PGPASSWORD: postgres
#      PGUSER: postgres
#      PGHOST: supabase-db
#      PGDATABASE: postgres
#      PGPORT: 5432
#    depends_on:
#      - supabase-db
#    networks:
#      - supabase-network
```

2. Restart the services:

```bash
docker-compose down
docker-compose up -d
```

### Container Name Conflicts

If you see errors about container name conflicts:

```
Error response from daemon: Conflict. The container name "/supabase_vector_breakoutbuddies" is already in use by container "dcee34fc67ff770f8ca8221ae79d4f5ddf227508d7c8610d73ac9b5f61634223". You have to remove (or rename) that container to be able to reuse that name.
```

Remove the conflicting container:

```bash
docker rm -f supabase_vector_breakoutbuddies
```

Then try starting the services again.

### Database Connection Issues

If your app can't connect to the database:

1. Check that the database container is running:

```bash
docker ps | grep supabase-db
```

2. Check the database logs:

```bash
docker logs breakoutbuddies-supabase-db-1
```

3. Verify that the database is accessible:

```bash
docker exec breakoutbuddies-supabase-db-1 psql -U postgres -c "SELECT version();"
```

### Supabase Studio Not Loading

If Supabase Studio is not loading:

1. Check the container status:

```bash
docker ps | grep supabase-studio
```

2. Check the logs:

```bash
docker logs breakoutbuddies-supabase-studio-1
```

3. Restart the container:

```bash
docker restart breakoutbuddies-supabase-studio-1
```

## Stopping the Local Supabase Instance

When you're done working with the local Supabase instance, you can stop the services:

```bash
docker-compose down
```

To remove all data and start fresh:

```bash
docker-compose down -v
```

This will remove all volumes, including the database data.

---

This guide should help you set up and use a local Supabase instance for development and testing of the BreakoutBuddies application. If you encounter any issues not covered in this guide, please refer to the [Supabase documentation](https://supabase.io/docs) or contact the development team.
