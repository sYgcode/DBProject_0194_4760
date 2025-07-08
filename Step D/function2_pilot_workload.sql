-- ========== FUNCTION 2: Pilot Workload and Performance Calculator ==========
-- This function calculates comprehensive pilot performance metrics
-- Demonstrates: Records, Loops, Branching, Complex calculations, Exception handling

CREATE OR REPLACE FUNCTION calculate_pilot_performance(
    p_pilot_id INT DEFAULT NULL,
    p_include_inactive BOOLEAN DEFAULT FALSE
) RETURNS TABLE (
    pilot_id INT,
    pilot_name VARCHAR(50),
    pilot_rank VARCHAR(20),
    experience_years INT,
    performance_score DECIMAL(5,2),
    workload_status VARCHAR(20),
    aircraft_assignments INT,
    maintenance_involvement INT,
    efficiency_rating VARCHAR(15),
    recommended_action VARCHAR(50)
) AS $$
DECLARE
    pilot_rec RECORD;
    assignment_rec RECORD;
    maintenance_rec RECORD;
    performance_metrics RECORD;
    
    -- Variables for calculations
    base_score DECIMAL(5,2);
    experience_bonus DECIMAL(5,2);
    workload_factor DECIMAL(5,2);
    maintenance_bonus DECIMAL(5,2);
    final_score DECIMAL(5,2);
    
    -- Counters and accumulators
    total_assignments INT;
    active_assignments INT;
    total_maintenance_tasks INT;
    avg_maintenance_cost DECIMAL(10,2);
    
    -- Status indicators
    workload_level VARCHAR(20);
    efficiency_level VARCHAR(15);
    action_recommendation VARCHAR(50);
    
BEGIN
    -- Loop through pilots (all if p_pilot_id is NULL, specific pilot otherwise)
    FOR pilot_rec IN (
        SELECT p.pilot_id, p.name, p.rank, p.experience, p.operator_id,
               o.name as operator_name, o.type as operator_type
        FROM Pilot p
        JOIN Operator o ON p.operator_id = o.operator_id
        WHERE (p_pilot_id IS NULL OR p.pilot_id = p_pilot_id)
        ORDER BY p.experience DESC, p.pilot_id
    ) LOOP
        
        -- Initialize variables for each pilot
        total_assignments := 0;
        active_assignments := 0;
        total_maintenance_tasks := 0;
        avg_maintenance_cost := 0;
        base_score := 50.0; -- Base score of 50
        
        BEGIN
            -- Count pilot assignments using explicit loop
            FOR assignment_rec IN (
                SELECT pp.plane_id, pp.assignment_date, pl.status as plane_status
                FROM Pilot_Plane pp
                JOIN Plane pl ON pp.plane_id = pl.plane_id
                WHERE pp.pilot_id = pilot_rec.pilot_id
            ) LOOP
                total_assignments := total_assignments + 1;
                
                -- Count active assignments (operational planes)
                IF assignment_rec.plane_status = 'Operational' THEN
                    active_assignments := active_assignments + 1;
                END IF;
            END LOOP;
            
            -- Analyze maintenance involvement
            FOR maintenance_rec IN (
                SELECT mr.maintenance_id, mr.cost, mr.completed, mr.maintenance_type
                FROM Maintenance_Record mr
                WHERE mr.employee_id = (
                    SELECT employee_id FROM Pilot WHERE pilot_id = pilot_rec.pilot_id
                )
            ) LOOP
                total_maintenance_tasks := total_maintenance_tasks + 1;
                avg_maintenance_cost := avg_maintenance_cost + COALESCE(maintenance_rec.cost, 0);
            END LOOP;
            
            -- Calculate average maintenance cost
            IF total_maintenance_tasks > 0 THEN
                avg_maintenance_cost := avg_maintenance_cost / total_maintenance_tasks;
            END IF;
            
            -- Calculate performance score using branching logic
            
            -- Experience bonus (0-25 points)
            IF pilot_rec.experience >= 20 THEN
                experience_bonus := 25.0;
            ELSIF pilot_rec.experience >= 15 THEN
                experience_bonus := 20.0;
            ELSIF pilot_rec.experience >= 10 THEN
                experience_bonus := 15.0;
            ELSIF pilot_rec.experience >= 5 THEN
                experience_bonus := 10.0;
            ELSE
                experience_bonus := 5.0;
            END IF;
            
            -- Workload factor (0-15 points)
            IF total_assignments = 0 THEN
                workload_factor := 0;
                workload_level := 'None';
            ELSIF total_assignments <= 2 THEN
                workload_factor := 10.0;
                workload_level := 'Light';
            ELSIF total_assignments <= 4 THEN
                workload_factor := 15.0;
                workload_level := 'Moderate';
            ELSIF total_assignments <= 6 THEN
                workload_factor := 12.0;
                workload_level := 'Heavy';
            ELSE
                workload_factor := 8.0;
                workload_level := 'Overloaded';
            END IF;
            
            -- Maintenance involvement bonus (0-10 points)
            IF total_maintenance_tasks = 0 THEN
                maintenance_bonus := 0;
            ELSIF total_maintenance_tasks <= 3 THEN
                maintenance_bonus := 5.0;
            ELSIF total_maintenance_tasks <= 6 THEN
                maintenance_bonus := 10.0;
            ELSE
                maintenance_bonus := 7.0; -- Too many maintenance tasks might indicate problems
            END IF;
            
            -- Calculate final score
            final_score := base_score + experience_bonus + workload_factor + maintenance_bonus;
            
            -- Ensure score is within bounds (0-100)
            IF final_score > 100 THEN
                final_score := 100;
            ELSIF final_score < 0 THEN
                final_score := 0;
            END IF;
            
            -- Determine efficiency rating and recommendations
            IF final_score >= 85 THEN
                efficiency_level := 'Excellent';
                action_recommendation := 'Consider for leadership roles';
            ELSIF final_score >= 70 THEN
                efficiency_level := 'Good';
                action_recommendation := 'Maintain current assignments';
            ELSIF final_score >= 55 THEN
                efficiency_level := 'Average';
                action_recommendation := 'Additional training recommended';
            ELSE
                efficiency_level := 'Below Average';
                action_recommendation := 'Performance review required';
            END IF;
            
            -- Special case recommendations based on specific conditions
            IF workload_level = 'Overloaded' THEN
                action_recommendation := 'Reduce workload immediately';
            ELSIF workload_level = 'None' AND pilot_rec.experience > 5 THEN
                action_recommendation := 'Assign more responsibilities';
            ELSIF total_maintenance_tasks > 8 THEN
                action_recommendation := 'Review maintenance procedures';
            END IF;
            
            -- Return calculated metrics for this pilot
            pilot_id := pilot_rec.pilot_id;
            pilot_name := pilot_rec.name;
            pilot_rank := pilot_rec.rank;
            experience_years := pilot_rec.experience;
            performance_score := final_score;
            workload_status := workload_level;
            aircraft_assignments := total_assignments;
            maintenance_involvement := total_maintenance_tasks;
            efficiency_rating := efficiency_level;
            recommended_action := action_recommendation;
            
            RETURN NEXT;
            
        EXCEPTION
            WHEN OTHERS THEN
                -- Handle errors for individual pilots without stopping the entire function
                RAISE NOTICE 'Error processing pilot %: %', pilot_rec.pilot_id, SQLERRM;
                
                -- Return error record
                pilot_id := pilot_rec.pilot_id;
                pilot_name := pilot_rec.name;
                pilot_rank := pilot_rec.rank;
                experience_years := pilot_rec.experience;
                performance_score := 0;
                workload_status := 'Error';
                aircraft_assignments := 0;
                maintenance_involvement := 0;
                efficiency_rating := 'Error';
                recommended_action := 'Data verification required';
                
                RETURN NEXT;
        END;
    END LOOP;
    
    RETURN;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Critical error in calculate_pilot_performance: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;