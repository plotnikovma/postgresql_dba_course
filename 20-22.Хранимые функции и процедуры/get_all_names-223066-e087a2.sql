CREATE OR REPLACE FUNCTION public.get_all_names (IN tables2scan  text[] DEFAULT NULL)
RETURNS table   (
        table_name  text,
        column_name text,
        column_str  text
        )
AS 
$$
DECLARE
    v_table_full_name   name;
    v_table_name        name;
    v_schema_name     name;
    v_column_name     name;
    query       text;
    v_string    text;


BEGIN
    DROP TABLE IF EXISTS tmp_tables;

    CREATE TEMP TABLE tmp_tables    (
                    table_name  text,
                    column_name text,
                    column_str  text
                    );
    
    FOR v_table_full_name, v_column_name, v_table_name, v_schema_name
    IN
    SELECT C.table_schema || '.' || C.table_name, C.column_name, C.table_schema, C.table_name
    FROM information_schema.columns C
    INNER JOIN unnest (tables2scan) T ON T.T = C.table_name
    WHERE C.column_name LIKE '%name'
      AND table_schema NOT LIKE 'pg_%'
      AND table_schema <> 'information_schema'
    LOOP
                /* format см. в 9.4.1.*/
        query = format('INSERT INTO tmp_tables (table_name, column_name, column_str) SELECT %s, %s, %s FROM %I.%I', quote_literal(v_table_full_name), quote_literal(v_column_name), v_column_name, v_table_name, v_schema_name);

        -- RAISE NOTICE '%', query;

        EXECUTE query;   
    END LOOP;

    RETURN QUERY
    SELECT T.table_name, T.column_name, T.column_str FROM tmp_tables T;
    
    DROP TABLE IF EXISTS tmp_tables;
END;
$$
LANGUAGE plpgsql
    VOLATILE 
    SECURITY DEFINER
    STRICT
    COST 100
    ROWS 3000;

SELECT * FROM public.get_all_names(ARRAY['author', 'book']);
