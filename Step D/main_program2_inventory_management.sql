-- ========== MAIN PROGRAM 2: Warehouse Inventory Management System ==========
-- This program provides comprehensive inventory management and optimization
-- Demonstrates: Complex program logic, Function/procedure integration, Business intelligence

DO $$
DECLARE
    -- Program configuration
    management_mode VARCHAR(30) := 'COMPREHENSIVE'; -- Options: COMPREHENSIVE, QUICK_CHECK, EMERGENCY_ONLY
    target_warehouse_id INT := NULL; -- NULL for all warehouses
    reorder_threshold INT := 15;
    max_reorder_quantity INT := 200;
    auto_reorder_enabled BOOLEAN := TRUE;
    
    -- Function call variables (reusing pilot performance structure for warehouse data)
    warehouse_performance_record RECORD;
    inventory_analysis_cursor REFCURSOR;
    
    -- Analysis tracking variables
    total_warehouses_processed INT := 0;
    total_parts_analyzed INT := 0;
    total_reorders_created INT := 0;
    total_inventory_value DECIMAL(15,2) := 0;
    total_optimization_opportunities INT := 0;
    
    -- Cost and efficiency metrics
    total_reorder_cost DECIMAL(12,2) := 0;
    avg_warehouse_utilization DECIMAL(5,2) := 0;
    efficiency_score DECIMAL(5,2) := 0;
    cost_savings_potential DECIMAL(10,2) := 0;
    
    -- Status tracking
    critical_stockouts INT := 0;
    overstock_items INT := 0;
    optimal_stock_items INT := 0;
    
    -- Time tracking
    process_start_time TIMESTAMP;
    process_end_time TIMESTAMP;
    process_duration INTERVAL;
    
    -- Error and warning tracking
    processing_errors INT := 0;
    warnings_generated INT := 0;
    
    -- Report generation
    executive_summary TEXT := '';
    detailed_recommendations TEXT := '';
    action_items TEXT := '';
    
    -- Temporary variables for calculations
    warehouse_count INT;
    part_count INT;
    temp_value DECIMAL(12,2);
    temp_utilization DECIMAL(5,2);
    
BEGIN
    process_start_time := CURRENT_TIMESTAMP;
    
    RAISE NOTICE '========== WAREHOUSE INVENTORY MANAGEMENT SYSTEM ==========';
    RAISE NOTICE 'Process initiated at: %', process_start_time;
    RAISE NOTICE 'Management Mode: %, Target Warehouse: %', 
                management_mode, COALESCE(target_warehouse_id::TEXT, 'ALL');
    RAISE NOTICE 'Reorder Threshold: %, Max Reorder: %, Auto-Reorder: %',
                reorder_threshold, max_reorder_quantity, auto_reorder_enabled;
    RAISE NOTICE '';
    
    -- ==========================================================
    -- PHASE 1: WAREHOUSE INVENTORY ANALYSIS (FUNCTION INTEGRATION)
    -- ==========================================================
    
    BEGIN
        RAISE NOTICE '--- PHASE 1: Inventory Analysis and Optimization ---';
        
        -- Analyze current inventory status across all warehouses
        FOR warehouse_performance_record IN (
            SELECT 
                w.warehouse_id,
                w.location as warehouse_location,
                w.capacity,
                COUNT(wp.part_id) as total_part_types,
                SUM(wp.wQuantity) as total_inventory_items,
                AVG(wp.wQuantity) as avg_parts_per_type,
                -- Calculate inventory value using supplier prices
                SUM(wp.wQuantity * COALESCE(sp.price, 50.00)) as inventory_value,
                -- Calculate utilization
                CASE 
                    WHEN w.capacity > 0 THEN (SUM(wp.wQuantity) * 100.0) / w.capacity
                    ELSE 0 
                END as utilization_percentage
            FROM Warehouse w
            LEFT JOIN WarehouseParts wp ON w.warehouse_id = wp.warehouse_id
            LEFT JOIN SupplierParts sp ON wp.part_id = sp.part_id
            WHERE (target_warehouse_id IS NULL OR w.warehouse_id = target_warehouse_id)
            GROUP BY w.warehouse_id, w.location, w.capacity
            ORDER BY w.warehouse_id
        ) LOOP
            
            total_warehouses_processed := total_warehouses_processed + 1;
            total_parts_analyzed := total_parts_analyzed + warehouse_performance_record.total_part_types;
            total_inventory_value := total_inventory_value + COALESCE(warehouse_performance_record.inventory_value, 0);
            avg_warehouse_utilization := avg_warehouse_utilization + warehouse_performance_record.utilization_percentage;
            
            RAISE NOTICE 'Analyzing Warehouse % (%): % part types, % total items, %% utilization',
                        warehouse_performance_record.warehouse_id,
                        warehouse_performance_record.warehouse_location,
                        warehouse_performance_record.total_part_types,
                        warehouse_performance_record.total_inventory_items,
                        ROUND(warehouse_performance_record.utilization_percentage, 2);
            
            -- Analyze warehouse efficiency and identify issues
            IF warehouse_performance_record.utilization_percentage > 90 THEN
                warnings_generated := warnings_generated + 1;
                detailed_recommendations := detailed_recommendations || 
                    'CRITICAL: Warehouse ' || warehouse_performance_record.warehouse_id || 
                    ' is overcapacity (' || warehouse_performance_record.utilization_percentage || '%); ';
                action_items := action_items || 
                    'Immediate capacity expansion or redistribution needed for Warehouse ' || 
                    warehouse_performance_record.warehouse_id || '; ';
                    
            ELSIF warehouse_performance_record.utilization_percentage < 30 THEN
                total_optimization_opportunities := total_optimization_opportunities + 1;
                detailed_recommendations := detailed_recommendations || 
                    'OPPORTUNITY: Warehouse ' || warehouse_performance_record.warehouse_id || 
                    ' is underutilized (' || warehouse_performance_record.utilization_percentage || '%); ';
                    
            END IF;
            
            -- Calculate potential cost savings from optimization
            IF warehouse_performance_record.utilization_percentage < 50 THEN
                cost_savings_potential := cost_savings_potential + 
                    (warehouse_performance_record.inventory_value * 0.1); -- 10% potential savings
            END IF;
        END LOOP;
        
        -- Calculate average utilization
        IF total_warehouses_processed > 0 THEN
            avg_warehouse_utilization := avg_warehouse_utilization / total_warehouses_processed;
        END IF;
        
        RAISE NOTICE 'Warehouse analysis completed: % warehouses, avg utilization: %%',
                    total_warehouses_processed, ROUND(avg_warehouse_utilization, 2);
        RAISE NOTICE '';
        
    EXCEPTION
        WHEN OTHERS THEN
            processing_errors := processing_errors + 1;
            RAISE NOTICE 'ERROR in warehouse analysis: %', SQLERRM;
    END;
    
    -- ==========================================================
    -- PHASE 2: INVENTORY MANAGEMENT PROCEDURE EXECUTION
    -- ==========================================================
    
    IF management_mode IN ('COMPREHENSIVE', 'EMERGENCY_ONLY') THEN
        BEGIN
            RAISE NOTICE '--- PHASE 2: Automated Inventory Management ---';
            
            -- Call the inventory management procedure for each warehouse
            FOR warehouse_count IN (
                SELECT DISTINCT warehouse_id 
                FROM Warehouse 
                WHERE (target_warehouse_id IS NULL OR warehouse_id = target_warehouse_id)
                ORDER BY warehouse_id
            ) LOOP
                
                RAISE NOTICE 'Executing inventory management for Warehouse %', warehouse_count;
                
                -- Call the warehouse inventory management procedure
                CALL manage_warehouse_inventory(
                    warehouse_count,           -- warehouse_id
                    reorder_threshold,         -- reorder_threshold
                    max_reorder_quantity,      -- max_reorder_amount
                    auto_reorder_enabled       -- auto_reorder
                );
                
                -- Count the reorders created (this would be tracked in the procedure)
                SELECT COUNT(*) INTO part_count
                FROM myorder 
                WHERE warehouse_id = warehouse_count 
                AND order_date = CURRENT_DATE;
                
                total_reorders_created := total_reorders_created + part_count;
                
                -- Calculate reorder costs
                SELECT COALESCE(SUM(o.amount * sp.price), 0) INTO temp_value
                FROM myorder o
                JOIN SupplierParts sp ON o.part_id = sp.part_id AND o.supplier_id = sp.supplier_id
                WHERE o.warehouse_id = warehouse_count 
                AND o.order_date = CURRENT_DATE;
                
                total_reorder_cost := total_reorder_cost + temp_value;
                
                RAISE NOTICE 'Warehouse % processing complete: % reorders, $% cost',
                            warehouse_count, part_count, temp_value;
            END LOOP;
            
            RAISE NOTICE 'Automated inventory management completed: % total reorders, $% total cost',
                        total_reorders_created, total_reorder_cost;
            RAISE NOTICE '';
            
        EXCEPTION
            WHEN OTHERS THEN
                processing_errors := processing_errors + 1;
                RAISE NOTICE 'ERROR in inventory management: %', SQLERRM;
        END;
    END IF;
    
    -- ==========================================================
    -- PHASE 3: STOCKOUT AND OVERSTOCK ANALYSIS
    -- ==========================================================
    
    BEGIN
        RAISE NOTICE '--- PHASE 3: Stock Level Analysis ---';
        
        -- Analyze critical stock levels
        FOR warehouse_performance_record IN (
            SELECT 
                wp.warehouse_id,
                p.part_id,
                p.name as part_name,
                wp.wQuantity as current_stock,
                COALESCE(sp.price, 50.00) as unit_price,
                CASE 
                    WHEN wp.wQuantity = 0 THEN 'STOCKOUT'
                    WHEN wp.wQuantity <= 5 THEN 'CRITICAL'
                    WHEN wp.wQuantity <= reorder_threshold THEN 'LOW'
                    WHEN wp.wQuantity > (max_reorder_quantity * 2) THEN 'OVERSTOCK'
                    ELSE 'OPTIMAL'
                END as stock_status
            FROM WarehouseParts wp
            JOIN Part p ON wp.part_id = p.part_id
            LEFT JOIN SupplierParts sp ON p.part_id = sp.part_id
            WHERE (target_warehouse_id IS NULL OR wp.warehouse_id = target_warehouse_id)
            ORDER BY 
                CASE 
                    WHEN wp.wQuantity = 0 THEN 1
                    WHEN wp.wQuantity <= 5 THEN 2
                    WHEN wp.wQuantity <= reorder_threshold THEN 3
                    WHEN wp.wQuantity > (max_reorder_quantity * 2) THEN 4
                    ELSE 5
                END,
                wp.wQuantity ASC
        ) LOOP
            
            -- Count different stock statuses
            CASE warehouse_performance_record.stock_status
                WHEN 'STOCKOUT' THEN 
                    critical_stockouts := critical_stockouts + 1;
                    warnings_generated := warnings_generated + 1;
                    action_items := action_items || 
                        'URGENT: Restock ' || warehouse_performance_record.part_name || 
                        ' in Warehouse ' || warehouse_performance_record.warehouse_id || '; ';
                        
                WHEN 'CRITICAL' THEN
                    warnings_generated := warnings_generated + 1;
                    action_items := action_items || 
                        'PRIORITY: Low stock of ' || warehouse_performance_record.part_name || 
                        ' in Warehouse ' || warehouse_performance_record.warehouse_id || 
                        ' (' || warehouse_performance_record.current_stock || ' units); ';
                        
                WHEN 'OVERSTOCK' THEN
                    overstock_items := overstock_items + 1;
                    total_optimization_opportunities := total_optimization_opportunities + 1;
                    detailed_recommendations := detailed_recommendations || 
                        'OPTIMIZATION: Excess ' || warehouse_performance_record.part_name || 
                        ' in Warehouse ' || warehouse_performance_record.warehouse_id || 
                        ' (' || warehouse_performance_record.current_stock || ' units); ';
                    
                    -- Calculate potential savings from reducing overstock
                    temp_value := (warehouse_performance_record.current_stock - max_reorder_quantity) * 
                                 warehouse_performance_record.unit_price * 0.05; -- 5% carrying cost
                    cost_savings_potential := cost_savings_potential + temp_value;
                    
                WHEN 'OPTIMAL' THEN
                    optimal_stock_items := optimal_stock_items + 1;
            END CASE;
        END LOOP;
        
        RAISE NOTICE 'Stock analysis: % stockouts, % overstocked, % optimal levels',
                    critical_stockouts, overstock_items, optimal_stock_items;
        RAISE NOTICE '';
        
    EXCEPTION
        WHEN OTHERS THEN
            processing_errors := processing_errors + 1;
            RAISE NOTICE 'ERROR in stock level analysis: %', SQLERRM;
    END;
    
    -- ==========================================================
    -- PHASE 4: EFFICIENCY SCORING AND OPTIMIZATION
    -- ==========================================================
    
    BEGIN
        RAISE NOTICE '--- PHASE 4: Efficiency Analysis and Optimization ---';
        
        -- Calculate overall efficiency score
        efficiency_score := (
            -- Utilization factor (40% weight)
            LEAST(avg_warehouse_utilization, 80) * 0.5 +  -- Cap at 80% for optimal
            -- Stock level factor (30% weight)
            ((optimal_stock_items * 100.0) / GREATEST(total_parts_analyzed, 1)) * 0.3 +
            -- Error factor (20% weight)
            ((total_warehouses_processed - processing_errors) * 100.0 / 
             GREATEST(total_warehouses_processed, 1)) * 0.2 +
            -- Reorder success factor (10% weight)
            CASE 
                WHEN total_reorders_created > 0 AND auto_reorder_enabled THEN 10
                WHEN total_reorders_created = 0 AND critical_stockouts = 0 THEN 10
                ELSE 5
            END
        );
        
        -- Generate efficiency rating and executive summary
        IF efficiency_score >= 85 THEN
            executive_summary := 'EXCELLENT inventory management performance. ';
        ELSIF efficiency_score >= 70 THEN
            executive_summary := 'GOOD inventory management with minor optimization opportunities. ';
        ELSIF efficiency_score >= 55 THEN
            executive_summary := 'AVERAGE performance with significant improvement potential. ';
        ELSE
            executive_summary := 'BELOW STANDARD performance requiring immediate attention. ';
        END IF;
        
        -- Add key metrics to summary
        executive_summary := executive_summary || 
            'Efficiency Score: ' || ROUND(efficiency_score, 1) || '/100. ' ||
            'Total Inventory Value: $' || total_inventory_value || '. ' ||
            'Average Utilization: ' || ROUND(avg_warehouse_utilization, 1) || '%. ';
        
        -- Add optimization summary
        IF total_optimization_opportunities > 0 THEN
            executive_summary := executive_summary || 
                total_optimization_opportunities || ' optimization opportunities identified. ';
        END IF;
        
        IF cost_savings_potential > 0 THEN
            executive_summary := executive_summary || 
                'Potential cost savings: $' || ROUND(cost_savings_potential, 2) || '. ';
        END IF;
        
    EXCEPTION
        WHEN OTHERS THEN
            processing_errors := processing_errors + 1;
            RAISE NOTICE 'ERROR in efficiency calculation: %', SQLERRM;
    END;
    
    -- ==========================================================
    -- FINAL REPORTING AND LOGGING
    -- ==========================================================
    
    process_end_time := CURRENT_TIMESTAMP;
    process_duration := process_end_time - process_start_time;
    
    RAISE NOTICE '';
    RAISE NOTICE '========== INVENTORY MANAGEMENT ANALYSIS COMPLETE ==========';
    RAISE NOTICE 'Process Duration: %', process_duration;
    RAISE NOTICE 'Efficiency Score: %/100', ROUND(efficiency_score, 1);
    RAISE NOTICE 'Warehouses Processed: %', total_warehouses_processed;
    RAISE NOTICE 'Parts Analyzed: %', total_parts_analyzed;
    RAISE NOTICE 'Total Inventory Value: $%', total_inventory_value;
    RAISE NOTICE 'Average Warehouse Utilization: %%', ROUND(avg_warehouse_utilization, 1);
    RAISE NOTICE 'Reorders Created: %', total_reorders_created;
    RAISE NOTICE 'Total Reorder Cost: $%', total_reorder_cost;
    RAISE NOTICE 'Critical Stockouts: %', critical_stockouts;
    RAISE NOTICE 'Overstocked Items: %', overstock_items;
    RAISE NOTICE 'Optimization Opportunities: %', total_optimization_opportunities;
    RAISE NOTICE 'Potential Cost Savings: $%', ROUND(cost_savings_potential, 2);
    RAISE NOTICE 'Warnings Generated: %', warnings_generated;
    RAISE NOTICE 'Processing Errors: %', processing_errors;
    RAISE NOTICE '';
    RAISE NOTICE 'EXECUTIVE SUMMARY: %', executive_summary;
    
    IF length(detailed_recommendations) > 0 THEN
        RAISE NOTICE 'DETAILED RECOMMENDATIONS: %', detailed_recommendations;
    END IF;
    
    IF length(action_items) > 0 THEN
        RAISE NOTICE 'ACTION ITEMS: %', action_items;
    END IF;
    
    -- Log the comprehensive analysis
    INSERT INTO inventory_analysis_log (
        analysis_date, management_mode, target_warehouse_id,
        warehouses_processed, parts_analyzed, efficiency_score,
        total_inventory_value, avg_utilization, reorders_created,
        total_reorder_cost, critical_stockouts, overstock_items,
        optimization_opportunities, cost_savings_potential,
        warnings_generated, processing_errors, process_duration,
        executive_summary, recommendations, action_items
    ) VALUES (
        process_start_time, management_mode, target_warehouse_id,
        total_warehouses_processed, total_parts_analyzed, efficiency_score,
        total_inventory_value, avg_warehouse_utilization, total_reorders_created,
        total_reorder_cost, critical_stockouts, overstock_items,
        total_optimization_opportunities, cost_savings_potential,
        warnings_generated, processing_errors, process_duration,
        executive_summary, detailed_recommendations, action_items
    );
    
    RAISE NOTICE 'Inventory management analysis logged successfully.';
    RAISE NOTICE '==========================================================';
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'CRITICAL ERROR in inventory management system: %', SQLERRM;
        RAISE EXCEPTION 'Inventory management analysis failed: %', SQLERRM;
END;
$$;