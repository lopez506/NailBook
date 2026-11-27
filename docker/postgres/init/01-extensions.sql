-- Needed by the double-booking exclusion constraint (see 02-arquitectura, rule 2).
-- Runs only the first time the database volume is created.
CREATE EXTENSION IF NOT EXISTS btree_gist;