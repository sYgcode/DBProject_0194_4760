-- ========== FUNCTION 1: Aircraft Maintenance Cost Analysis ==========
-- This function analyzes maintenance costs for aircraft and returns a cursor with detailed analysis
-- Demonstrates: Explicit cursor, Ref cursor, Exception handling, Branching, Records

CREATE OR REPLACE FUNCTION get_aircraft_maintenance_analysis(
    p_operator_id INT DEFAULT NULL,
    p_date_from DATE DEFAULT CURRENT_DATE - INTERVAL '1 year',
    p_date_to DATE DEFAULT CURRENT_DATE
) RETURNS REFCURSOR AS $$
DECLARE
    maintenance_cursor REFCURSOR := 'maintenance_analysis_cursor';
    plane_record RECORD;
    maintenance_record RECORD;
    total_cost DECIMAL(12,2) := 0;
    plane_count INT := 0;
    avg_cost_per_plane DECIMAL(12,2);
    
    -- Explicit cursor for plane data
    plane_cursor CURSOR FOR 
        SELECT p.plane_id, p.model, p.status, o.name as operator_name
        FROM Plane p 
        JOIN Operator o ON p.operator_id = o.operator_id
        WHERE (p_operator_id IS NULL OR p.operator_id = p_operator_id);
        
BEGIN
    -- Exception handling for invalid parameters
    IF p_date_from > p_date_to THEN
        RAISE EXCEPTION 'Invalid date range: from_date cannot be greater than to_date';
    END IF;
    
    -- Open the return cursor
    OPEN maintenance_cursor FOR
        WITH maintenance_summary AS (
            SELECT 
                p.plane_id,
                p.model,
                p.status,
                o.name as operator_name,
                COUNT(mr.maintenance_id) as maintenance_count,
                COALESCE(SUM(mr.cost), 0) as total_maintenance_cost,
                COALESCE(AVG(mr.cost), 0) as avg_maintenance_cost,
                MAX(mr.maintenance_date) as last_maintenance_date,
                -- Calculate efficiency rating based on cost and frequency
                CASE 
                    WHEN COUNT(mr.maintenance_id) = 0 THEN 'No Data'
                    WHEN AVG(mr.cost) < 2000 AND COUNT(mr.maintenance_id) <= 2 THEN 'Excellent'
                    WHEN AVG(mr.cost) < 4000 AND COUNT(mr.maintenance_id) <= 4 THEN 'Good'
                    WHEN AVG(mr.cost) < 6000 OR COUNT(mr.maintenance_id) <= 6 THEN 'Average'
                    ELSE 'Needs Attention'
                END as efficiency_rating,
                -- Parts usage analysis
                (SELECT COUNT(DISTINCT ap.part_id) 
                 FROM Aircraft_Parts ap 
                 WHERE ap.plane_id = p.plane_id) as unique_parts_used
            FROM Plane p
            JOIN Operator o ON p.operator_id = o.operator_id
            LEFT JOIN Maintenance_Record mr ON p.plane_id = mr.plane_id 
                AND mr.maintenance_date BETWEEN p_date_from AND p_date_to
            WHERE (p_operator_id IS NULL OR o.operator_id = p_operator_id)
            GROUP BY p.plane_id, p.model, p.status, o.name
        ),
        cost_rankings AS (
            SELECT *,
                RANK() OVER (ORDER BY total_maintenance_cost DESC) as cost_rank,
                RANK() OVER (ORDER BY maintenance_count DESC) as frequency_rank
            FROM maintenance_summary
        )
        SELECT 
            cr.*,
            -- Add percentage of total fleet cost
            ROUND((cr.total_maintenance_cost * 100.0 / 
                NULLIF(SUM(cr.total_maintenance_cost) OVER(), 0)), 2) as pct_of_total_cost,
            -- Maintenance trend indicator
            CASE 
                WHEN cr.last_maintenance_date > CURRENT_DATE - INTERVAL '30 days' THEN 'Recent'
                WHEN cr.last_maintenance_date > CURRENT_DATE - INTERVAL '90 days' THEN 'Moderate'
                WHEN cr.last_maintenance_date IS NOT NULL THEN 'Overdue Check'
                ELSE 'No History'
            END as maintenance_urgency
        FROM cost_rankings cr
        ORDER BY cr.total_maintenance_cost DESC, cr.maintenance_count DESC;
    
    -- Loop through planes using explicit cursor for additional processing
    FOR plane_record IN plane_cursor LOOP
        plane_count := plane_count + 1;
        
        -- Calculate total costs using implicit cursor
        FOR maintenance_record IN (
            SELECT COALESCE(SUM(cost), 0) as plane_total_cost
            FROM Maintenance_Record 
            WHERE plane_id = plane_record.plane_id
            AND maintenance_date BETWEEN p_date_from AND p_date_to
        ) LOOP
            total_cost := total_cost + maintenance_record.plane_total_cost;
        END LOOP;
    END LOOP;
    
    -- Calculate average cost per plane
    IF plane_count > 0 THEN
        avg_cost_per_plane := total_cost / plane_count;
    ELSE
        avg_cost_per_plane := 0;
    END IF;
    
    -- Log summary information (can be retrieved separately)
    INSERT INTO maintenance_analysis_log (
        analysis_date, 
        operator_id, 
        date_range_from, 
        date_range_to, 
        total_planes_analyzed, 
        total_cost_analyzed, 
        avg_cost_per_plane
    ) VALUES (
        CURRENT_TIMESTAMP, 
        p_operator_id, 
        p_date_from, 
        p_date_to, 
        plane_count, 
        total_cost, 
        avg_cost_per_plane
    );
    
    RETURN maintenance_cursor;
    
EXCEPTION
    WHEN OTHERS THEN
        -- Comprehensive error handling
        RAISE NOTICE 'Error in get_aircraft_maintenance_analysis: %', SQLERRM;
        RAISE EXCEPTION 'Failed to generate maintenance analysis: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;