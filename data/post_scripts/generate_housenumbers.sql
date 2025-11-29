-- ==============================================================================
--  Fix aborted state (just in case)
-- ==============================================================================
DO $$
BEGIN
    IF (SELECT pg_is_in_recovery()) IS FALSE THEN
        NULL;
    END IF;
END $$;

ROLLBACK;  -- Safe even outside a transaction


-- ==============================================================================
--  1. Ensure source table exists
-- ==============================================================================
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.tables 
        WHERE table_schema = 'public'
          AND table_name = 'osm_buildings'
    ) THEN
        RAISE EXCEPTION 'Source table public.osm_buildings does not exist.';
    END IF;
END $$;


-- ==============================================================================
--  2. Create sequence if not exists
-- ==============================================================================
CREATE SEQUENCE IF NOT EXISTS public.osm_housenumbers_id_seq
    OWNED BY NONE;


-- ==============================================================================
--  3. Create table if not exists
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.osm_housenumbers (
    id bigint PRIMARY KEY DEFAULT nextval('public.osm_housenumbers_id_seq'),
    osm_id bigint NOT NULL,
    housenumber text NOT NULL,
    geometry geometry(Point) NOT NULL,
    UNIQUE(osm_id, housenumber)
);


-- ==============================================================================
--  4. Insert missing housenumbers (idempotent)
-- ==============================================================================
INSERT INTO public.osm_housenumbers (osm_id, housenumber, geometry)
SELECT
    b.osm_id,
    b.addr_housenumber,
    ST_PointOnSurface(b.geometry)  -- точка внутри полигона
FROM public.osm_buildings b
WHERE b.addr_housenumber IS NOT NULL
  AND b.addr_housenumber <> ''
ON CONFLICT (osm_id, housenumber) DO NOTHING;


-- ==============================================================================
--  5. Ensure geometry type is POINT with SRID from source
-- ==============================================================================
DO $$
DECLARE
    source_srid integer;
BEGIN
    SELECT Find_SRID('public','osm_buildings','geometry') INTO source_srid;

    IF source_srid IS NULL OR source_srid = 0 THEN
        RAISE WARNING 'Could not detect SRID for osm_buildings.geometry, defaulting to 4326';
        source_srid := 4326;
    END IF;

    EXECUTE format(
        'ALTER TABLE public.osm_housenumbers
            ALTER COLUMN geometry TYPE geometry(Point, %s)
            USING ST_SetSRID(geometry, %s);',
        source_srid, source_srid
    );
END $$;


-- ==============================================================================
--  6. Add indexes (if not exist)
-- ==============================================================================
CREATE INDEX IF NOT EXISTS osm_housenumbers_geometry_gist
    ON public.osm_housenumbers
    USING GIST (geometry);

CREATE INDEX IF NOT EXISTS osm_housenumbers_osm_id_idx
    ON public.osm_housenumbers (osm_id);

VACUUM ANALYZE public.osm_housenumbers;

