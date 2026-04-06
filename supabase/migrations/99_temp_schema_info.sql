-- Diagnostic function to check for NOT NULL columns in auth tables
CREATE OR REPLACE FUNCTION public.get_auth_schema_info()
RETURNS TABLE (table_name text, column_name text, is_nullable text) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.table_name::text, 
        c.column_name::text, 
        c.is_nullable::text
    FROM 
        information_schema.columns c
    WHERE 
        c.table_schema IN ('auth')
        AND c.table_name IN ('users', 'identities')
        AND c.is_nullable = 'NO'
    ORDER BY 
        c.table_name, c.column_name;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
