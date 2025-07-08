-- ========== MAIN PROGRAM 1: Aircraft Fleet Management System ==========
-- This program provides comprehensive fleet management functionality
-- Demonstrates: Calling functions and procedures, Complex program flow, Exception handling

DO $$
DECLARE
    -- Program control variables
    operation_mode VARCHAR(20) := 'FULL_ANALYSIS'; -- Options: FULL_ANALYSIS, MAINTENANCE_ONLY, PILOT_ANALYSIS
    target_operator_id INT := NULL; -- NULL for all operators, specific ID for targeted analysis
    
    -- Function and procedure call variables
    maintenance_cursor REFCURSOR;
    pilot_performance_record RECORD;
    
    -- Analysis variables
    total_aircraft_analyzed INT := 0;
    total_maintenance_cost DECIMAL(12,2) := 0;
    total_pilots_analyzed INT := 0;
    avg_pilot_performance DECIMAL(5,2) := 0;
    fleet_efficiency_score DECIMAL(5,2) := 0;
    
    -- Maintenance variables for procedure call
    maintenance_plane_id INT;
    maintenance_parts_needed TEXT[];
    emergency_maintenance_needed BOOLEAN := FALSE;
    
    -- Status tracking
    analysis_start_time TIMESTAMP;
    analysis_end_time TIMESTAMP;
    analysis_duration INTERVAL;
    
    -- Error handling
    error_count INT := 0;
    warning_count INT := 0;
    
    -- Report generation
    report_summary TEXT := '';
    recommendations TEXT := '';
    
BEGIN
    analysis_start_time := CURRENT_TIMESTAMP;
    
    RAISE NOTICE '========== AIRCRAFT FLEET MANAGEMENT SYSTEM ==========';
    RAISE NOTICE 'Starting fleet management analysis at %', analysis_start_time;
    RAISE NOTICE 'Operation Mode: %, Target Operator: %', 
                operation_mode, COALESCE(target_operator_id::TEXT, 'ALL');
    RAISE NOTICE '';
    
    -- ==========================================================
    -- PHASE 1: MAINTENANCE COST ANALYSIS (CALLING FUNCTION 1)
    -- ==========================================================
    
    IF operation_mode IN ('FULL_ANALYSIS', 'MAINTENANCE_ONLY') THEN
        BEGIN
            RAISE NOTICE '--- PHASE 1: Maintenance Cost Analysis ---';
            
            -- Call the maintenance analysis function
            SELECT get_aircraft_maintenance_analysis(
                target_operator_id,                    -- operator filter
                CURRENT_DATE - INTERVAL '12 months',   -- from date
                CURRENT_DATE                           -- to date
            ) INTO maintenance_cursor;
            
            -- Process the cursor results
            LOOP
                FETCH maintenance_cursor INTO 
                    maintenance_plane_id,                 -- plane_id
                    pilot_performance_record.pilot_name,  -- aircraft_model (reusing record)
                    pilot_performance_record.pilot_rank,  -- aircraft_status
                    pilot_performance_record.experience_years, -- operator_name
                    total_aircraft_analyzed,              -- maintenance_count (reusing variable)
                    total_maintenance_cost,               -- total_maintenance_cost
                    avg_pilot_performance,                -- avg_maintenance_cost (reusing variable)
                    analysis_start_time,                  -- last_maintenance_date (reusing variable)
                    pilot_performance_record.workload_status, -- efficiency_rating
                    pilot_performance_record.aircraft_assignments, -- unique_parts_used
                    pilot_performance_record.maintenance_involvement, -- cost_rank
                    pilot_performance_record.performance_score, -- frequency_rank
                    fleet_efficiency_score,               -- pct_of_total_cost
                    recommendations;                      -- maintenance_urgency
                
                EXIT WHEN NOT FOUND;
                
                -- Analyze each aircraft's maintenance status
                IF pilot_performance_record.workload_status = 'Maintenance Pending' THEN
                    emergency_maintenance_needed := TRUE;
                    warning_count := warning_count + 1;
                    
                    RAISE NOTICE 'WARNING: Aircraft % (%) requires immediate maintenance', 
                                maintenance_plane_id, pilot_performance_record.pilot_name;
                    
                    -- Prepare parts for emergency maintenance
                    maintenance_parts_needed := ARRAY[1, 2]; -- Default emergency parts
                    
                    -- Call maintenance workflow procedure for urgent cases
                    IF total_maintenance_cost > 5000 THEN
                        RAISE NOTICE 'Initiating emergency maintenance workflow for aircraft %', 
                                    maintenance_plane_id;
                        
                        CALL manage_aircraft_maintenance(
                            maintenance_plane_id,           -- plane_id
                            'Emergency Repair',             -- maintenance_type
                            1,                              -- employee_id (default technician)
                            1,                              -- warehouse_id (primary warehouse)
                            maintenance_parts_needed,       -- parts_needed
                            total_maintenance_cost,         -- estimated_cost
                            'Auto-generated emergency maintenance from fleet analysis'
                        );
                        
                        RAISE NOTICE 'Emergency maintenance workflow completed for aircraft %', 
                                    maintenance_plane_id;
                    END IF;
                END IF;
                
                -- Track high-cost maintenance items
                IF total_maintenance_cost > 10000 THEN
                    report_summary := report_summary || 
                        'High-cost maintenance: Aircraft ' || maintenance_plane_id || 
                        ' ($' || total_maintenance_cost || '); ';
                END IF;
                
                total_aircraft_analyzed := total_aircraft_analyzed + 1;
            END LOOP;
            
            CLOSE maintenance_cursor;
            
            RAISE NOTICE 'Maintenance analysis completed. Aircraft analyzed: %, Warnings: %', 
                        total_aircraft_analyzed, warning_count;
            RAISE NOTICE '';
            
        EXCEPTION
            WHEN OTHERS THEN
                error_count := error_count + 1;
                RAISE NOTICE 'ERROR in maintenance analysis: %', SQLERRM;
                -- Continue with program execution
        END;
    END IF;
    
    -- ==========================================================
    -- PHASE 2: PILOT PERFORMANCE ANALYSIS (CALLING FUNCTION 2)
    -- ==========================================================
    
    IF operation_mode IN ('FULL_ANALYSIS', 'PILOT_ANALYSIS') THEN
        BEGIN
            RAISE NOTICE '--- PHASE 2: Pilot Performance Analysis ---';
            
            total_pilots_analyzed := 0;
            avg_pilot_performance := 0;
            
            -- Call the pilot performance function and analyze results
            FOR pilot_performance_record IN 
                SELECT * FROM calculate_pilot_performance(NULL, TRUE)
            LOOP
                total_pilots_analyzed := total_pilots_analyzed + 1;
                avg_pilot_performance := avg_pilot_performance + pilot_performance_record.performance_score;
                
                -- Handle different performance levels
                IF pilot_performance_record.efficiency_rating = 'Below Average' THEN
                    warning_count := warning_count + 1;
                    
                    RAISE NOTICE 'WARNING: Pilot % (ID: %) has below average performance (Score: %)', 
                                pilot_performance_record.pilot_name,
                                pilot_performance_record.pilot_id,
                                pilot_performance_record.performance_score;
                    
                    recommendations := recommendations || 
                        'Pilot training needed for ' || pilot_performance_record.pilot_name || '; ';
                    
                ELSIF pilot_performance_record.efficiency_rating = 'Excellent' THEN
                    RAISE NOTICE 'EXCELLENT: Pilot % (ID: %) shows outstanding performance (Score: %)', 
                                pilot_performance_record.pilot_name,
                                pilot_performance_record.pilot_id,
                                pilot_performance_record.performance_score;
                    
                    recommendations := recommendations || 
                        'Consider ' || pilot_performance_record.pilot_name || ' for leadership roles; ';
                END IF;
                
                -- Check workload distribution
                IF pilot_performance_record.workload_status = 'Overloaded' THEN
                    warning_count := warning_count + 1;
                    
                    RAISE NOTICE 'WARNING: Pilot % is overloaded with % assignments', 
                                pilot_performance_record.pilot_name,
                                pilot_performance_record.aircraft_assignments;
                    
                    recommendations := recommendations || 
                        'Redistribute workload for ' || pilot_performance_record.pilot_name || '; ';
                        
                ELSIF pilot_performance_record.workload_status = 'None' AND 
                      pilot_performance_record.experience_years > 5 THEN
                    
                    RAISE NOTICE 'OPPORTUNITY: Experienced pilot % has no current assignments', 
                                pilot_performance_record.pilot_name;
                    
                    recommendations := recommendations || 
                        'Assign responsibilities to ' || pilot_performance_record.pilot_name || '; ';
                END IF;
            END LOOP;
            
            -- Calculate average performance
            IF total_pilots_analyzed > 0 THEN
                avg_pilot_performance := avg_pilot_performance / total_pilots_analyzed;
            END IF;
            
            RAISE NOTICE 'Pilot analysis completed. Pilots analyzed: %, Average performance: %', 
                        total_pilots_analyzed, ROUND(avg_pilot_performance, 2);
            RAISE NOTICE '';
            
        EXCEPTION
            WHEN OTHERS THEN
                error_count := error_count + 1;
                RAISE NOTICE 'ERROR in pilot analysis: %', SQLERRM;
        END;
    END IF;
    
    -- ==========================================================
    -- PHASE 3: PREVENTIVE MAINTENANCE SCHEDULING (PROCEDURE CALL)
    -- ==========================================================
    
    IF operation_mode = 'FULL_ANALYSIS' THEN
        BEGIN
            RAISE NOTICE '--- PHASE 3: Preventive Maintenance Scheduling ---';
            
            -- Schedule preventive maintenance for operational aircraft
            FOR pilot_performance_record IN (
                SELECT p.plane_id, p.model, p.status, 
                       pp.assignment_date as last_assignment
                FROM Plane p
                LEFT JOIN Pilot_Plane pp ON p.plane_id = pp.plane_id
                WHERE p.status = 'Operational'
                AND (pp.assignment_date IS NULL OR 
                     pp.assignment_date < CURRENT_DATE - INTERVAL '6 months')
                ORDER BY pp.assignment_date ASC NULLS FIRST
                LIMIT 3
            ) LOOP
                
                RAISE NOTICE 'Scheduling preventive maintenance for aircraft % (%)', 
                            pilot_performance_record.pilot_id,  -- reusing as plane_id
                            pilot_performance_record.pilot_name; -- reusing as model
                
                -- Prepare standard maintenance parts
                maintenance_parts_needed := ARRAY[1]; -- Standard maintenance part
                
                -- Call maintenance procedure
                CALL manage_aircraft_maintenance(
                    pilot_performance_record.pilot_id,     -- plane_id
                    'Scheduled Maintenance',               -- maintenance_type
                    2,                                     -- employee_id
                    1,                                     -- warehouse_id
                    maintenance_parts_needed,              -- parts_needed
                    1500.00,                               -- estimated_cost
                    'Preventive maintenance scheduled by fleet management system'
                );
                
                RAISE NOTICE 'Preventive maintenance scheduled for aircraft %', 
                            pilot_performance_record.pilot_id;
            END LOOP;
            
        EXCEPTION
            WHEN OTHERS THEN
                error_count := error_count + 1;
                RAISE NOTICE 'ERROR in preventive maintenance scheduling: %', SQLERRM;
        END;
    END IF;
    
    -- ==========================================================
    -- PHASE 4: FLEET EFFICIENCY CALCULATION AND REPORTING
    -- ==========================================================
    
    BEGIN
        RAISE NOTICE '--- PHASE 4: Fleet Efficiency Analysis ---';
        
        -- Calculate overall fleet efficiency score
        IF total_aircraft_analyzed > 0 AND total_pilots_analyzed > 0 THEN
            fleet_efficiency_score := (
                (avg_pilot_performance * 0.4) +                           -- 40% pilot performance
                ((100 - (warning_count * 10)) * 0.3) +                   -- 30% warning factor
                ((total_aircraft_analyzed - error_count) * 100.0 / 
                 total_aircraft_analyzed * 0.3)                          -- 30% analysis success rate
            );
            
            -- Ensure score is within bounds
            IF fleet_efficiency_score > 100 THEN
                fleet_efficiency_score := 100;
            ELSIF fleet_efficiency_score < 0 THEN
                fleet_efficiency_score := 0;
            END IF;
        ELSE
            fleet_efficiency_score := 0;
        END IF;
        
        -- Generate efficiency rating
        IF fleet_efficiency_score >= 85 THEN
            report_summary := 'EXCELLENT: ' || report_summary;
        ELSIF fleet_efficiency_score >= 70 THEN
            report_summary := 'GOOD: ' || report_summary;
        ELSIF fleet_efficiency_score >= 55 THEN
            report_summary := 'AVERAGE: ' || report_summary;
        ELSE
            report_summary := 'NEEDS IMPROVEMENT: ' || report_summary;
        END IF;
        
    EXCEPTION
        WHEN OTHERS THEN
            error_count := error_count + 1;
            RAISE NOTICE 'ERROR in efficiency calculation: %', SQLERRM;
    END;
    
    -- ==========================================================
    -- FINAL REPORTING
    -- ==========================================================
    
    analysis_end_time := CURRENT_TIMESTAMP;
    analysis_duration := analysis_end_time - analysis_start_time;
    
    RAISE NOTICE '';
    RAISE NOTICE '========== FLEET MANAGEMENT ANALYSIS COMPLETE ==========';
    RAISE NOTICE 'Analysis Duration: %', analysis_duration;
    RAISE NOTICE 'Fleet Efficiency Score: %/100', ROUND(fleet_efficiency_score, 2);
    RAISE NOTICE 'Aircraft Analyzed: %', total_aircraft_analyzed;
    RAISE NOTICE 'Pilots Analyzed: %', total_pilots_analyzed;
    RAISE NOTICE 'Average Pilot Performance: %', ROUND(avg_pilot_performance, 2);
    RAISE NOTICE 'Warnings Generated: %', warning_count;
    RAISE NOTICE 'Errors Encountered: %', error_count;
    
    IF emergency_maintenance_needed THEN
        RAISE NOTICE 'ALERT: Emergency maintenance was initiated for critical aircraft';
    END IF;
    
    RAISE NOTICE '';
    RAISE NOTICE 'SUMMARY: %', report_summary;
    
    IF length(recommendations) > 0 THEN
        RAISE NOTICE 'RECOMMENDATIONS: %', recommendations;
    END IF;
    
    -- Log the analysis results
    INSERT INTO fleet_analysis_log (
        analysis_date, operation_mode, target_operator_id,
        aircraft_analyzed, pilots_analyzed, fleet_efficiency_score,
        avg_pilot_performance, warnings_generated, errors_encountered,
        analysis_duration, summary, recommendations
    ) VALUES (
        analysis_start_time, operation_mode, target_operator_id,
        total_aircraft_analyzed, total_pilots_analyzed, fleet_efficiency_score,
        avg_pilot_performance, warning_count, error_count,
        analysis_duration, report_summary, recommendations
    );
    
    RAISE NOTICE 'Fleet management analysis logged successfully.';
    RAISE NOTICE '========================================================';
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'CRITICAL ERROR in fleet management system: %', SQLERRM;
        RAISE EXCEPTION 'Fleet management analysis failed: %', SQLERRM;
END;
$$;