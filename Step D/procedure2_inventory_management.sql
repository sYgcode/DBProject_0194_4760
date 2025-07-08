-- ========== PROCEDURE 2: Warehouse Inventory Management System ==========
-- This procedure manages inventory levels, automatic reordering, and optimization
-- Demonstrates: Explicit cursors, Loops, DML statements, Exception handling

CREATE OR REPLACE PROCEDURE manage_warehouse_inventory(
    p_warehouse_id INT DEFAULT NULL,
    p_reorder_threshold INT DEFAULT 10,
    p_max_reorder_amount INT DEFAULT 100,
    p_auto_reorder BOOLEAN DEFAULT TRUE
) AS $$
DECLARE
    -- Explicit cursor for warehouse parts analysis
    inventory_cursor CURSOR FOR
        SELECT 
            w.warehouse_id,
            w.location as warehouse_location,
            w.capacity as warehouse_capacity,
            p.part_id,
            p.name as part_name,
            wp.wQuantity as current_quantity,
            wp.last_updated,
            sp.price as supplier_price,
            sp.sQuantity as supplier_quantity,
            sp.supplier_id
        FROM Warehouse w
        JOIN WarehouseParts wp ON w.warehouse_id = wp.warehouse_id
        JOIN Part p ON wp.part_id = p.part_id
        LEFT JOIN SupplierParts sp ON p.part_id = sp.part_id
        WHERE (p_warehouse_id IS NULL OR w.warehouse_id = p_warehouse_id)
        AND wp.wQuantity <= p_reorder_threshold
        ORDER BY w.warehouse_id, wp.wQuantity ASC, sp.price ASC;
    
    -- Cursor for capacity analysis
    capacity_cursor CURSOR FOR
        SELECT 
            w.warehouse_id,
            w.location,
            w.capacity,
            COUNT(wp.part_id) as total_part_types,
            SUM(wp.wQuantity) as total_items,
            AVG(wp.wQuantity) as avg_quantity_per_part
        FROM Warehouse w
        LEFT JOIN WarehouseParts wp ON w.warehouse_id = wp.warehouse_id
        WHERE (p_warehouse_id IS NULL OR w.warehouse_id = p_warehouse_id)
        GROUP BY w.warehouse_id, w.location, w.capacity;
    
    -- Record variables
    inventory_rec RECORD;
    capacity_rec RECORD;
    supplier_rec RECORD;
    
    -- Variables for calculations and tracking
    reorder_amount INT;
    total_reorders INT := 0;
    total_cost DECIMAL(12,2) := 0;
    warehouse_utilization DECIMAL(5,2);
    optimization_actions TEXT := '';
    
    -- Status tracking
    inventory_status VARCHAR(20);
    needs_attention BOOLEAN := FALSE;
    
BEGIN
    RAISE NOTICE 'Starting warehouse inventory management process...';
    
    -- First, analyze warehouse capacity utilization
    FOR capacity_rec IN capacity_cursor LOOP
        BEGIN
            -- Calculate utilization percentage
            IF capacity_rec.capacity > 0 THEN
                warehouse_utilization := (capacity_rec.total_items * 100.0) / capacity_rec.capacity;
            ELSE
                warehouse_utilization := 0;
            END IF;
            
            -- Determine status and recommendations
            IF warehouse_utilization > 90 THEN
                inventory_status := 'Critical - Overloaded';
                needs_attention := TRUE;
                optimization_actions := optimization_actions || 
                    'Warehouse ' || capacity_rec.warehouse_id || ': Immediate capacity expansion needed. ';
            ELSIF warehouse_utilization > 75 THEN
                inventory_status := 'High Utilization';
                optimization_actions := optimization_actions || 
                    'Warehouse ' || capacity_rec.warehouse_id || ': Consider capacity planning. ';
            ELSIF warehouse_utilization < 25 THEN
                inventory_status := 'Under-utilized';
                optimization_actions := optimization_actions || 
                    'Warehouse ' || capacity_rec.warehouse_id || ': Consider consolidation opportunities. ';
            ELSE
                inventory_status := 'Optimal';
            END IF;
            
            -- Update warehouse statistics
            UPDATE Warehouse 
            SET 
                last_inventory_check = CURRENT_DATE,
                utilization_percentage = warehouse_utilization,
                status_notes = inventory_status
            WHERE warehouse_id = capacity_rec.warehouse_id;
            
            RAISE NOTICE 'Warehouse % (%) - Utilization: %%, Status: %', 
                        capacity_rec.warehouse_id, capacity_rec.location, 
                        warehouse_utilization, inventory_status;
                        
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'Error analyzing warehouse %: %', capacity_rec.warehouse_id, SQLERRM;
                CONTINUE;
        END;
    END LOOP;
    
    -- Process low inventory items using explicit cursor
    FOR inventory_rec IN inventory_cursor LOOP
        BEGIN
            -- Determine reorder amount based on usage patterns and supplier availability
            IF inventory_rec.current_quantity = 0 THEN
                reorder_amount := p_max_reorder_amount; -- Emergency restock
            ELSIF inventory_rec.current_quantity <= 3 THEN
                reorder_amount := p_max_reorder_amount * 0.75; -- High priority
            ELSIF inventory_rec.current_quantity <= 7 THEN
                reorder_amount := p_max_reorder_amount * 0.5; -- Medium priority
            ELSE
                reorder_amount := p_max_reorder_amount * 0.25; -- Low priority
            END IF;
            
            -- Check supplier availability
            IF inventory_rec.supplier_quantity IS NULL OR inventory_rec.supplier_quantity < reorder_amount THEN
                -- Find alternative supplier
                SELECT supplier_id, price, sQuantity INTO supplier_rec
                FROM SupplierParts sp2
                WHERE sp2.part_id = inventory_rec.part_id
                AND sp2.sQuantity >= reorder_amount
                ORDER BY sp2.price ASC
                LIMIT 1;
                
                IF FOUND THEN
                    inventory_rec.supplier_id := supplier_rec.supplier_id;
                    inventory_rec.supplier_price := supplier_rec.price;
                    inventory_rec.supplier_quantity := supplier_rec.sQuantity;
                ELSE
                    -- Reduce reorder amount to available quantity
                    reorder_amount := COALESCE(inventory_rec.supplier_quantity, 0);
                    IF reorder_amount = 0 THEN
                        RAISE NOTICE 'Cannot reorder part % - no suppliers available', inventory_rec.part_id;
                        CONTINUE;
                    END IF;
                END IF;
            END IF;
            
            -- Create reorder if auto-reorder is enabled and we have a supplier
            IF p_auto_reorder AND inventory_rec.supplier_id IS NOT NULL AND reorder_amount > 0 THEN
                -- Insert new order
                INSERT INTO myorder (
                    order_id,
                    amount,
                    order_date,
                    arrival_date,
                    part_id,
                    supplier_id,
                    warehouse_id
                ) VALUES (
                    nextval('order_id_seq'),
                    reorder_amount,
                    CURRENT_DATE,
                    CURRENT_DATE + INTERVAL '5 days', -- Standard delivery time
                    inventory_rec.part_id,
                    inventory_rec.supplier_id,
                    inventory_rec.warehouse_id
                );
                
                -- Update supplier inventory (simulate order processing)
                UPDATE SupplierParts 
                SET sQuantity = sQuantity - reorder_amount
                WHERE supplier_id = inventory_rec.supplier_id 
                AND part_id = inventory_rec.part_id;
                
                -- Calculate order cost
                total_cost := total_cost + (reorder_amount * inventory_rec.supplier_price);
                total_reorders := total_reorders + 1;
                
                RAISE NOTICE 'Reordered % units of % (Part ID: %) for Warehouse % - Cost: $%',
                            reorder_amount, inventory_rec.part_name, inventory_rec.part_id,
                            inventory_rec.warehouse_id, (reorder_amount * inventory_rec.supplier_price);
            ELSE
                -- Log manual reorder recommendation
                INSERT INTO reorder_recommendations (
                    recommendation_date,
                    warehouse_id,
                    part_id,
                    current_quantity,
                    recommended_quantity,
                    estimated_cost,
                    priority_level,
                    notes
                ) VALUES (
                    CURRENT_DATE,
                    inventory_rec.warehouse_id,
                    inventory_rec.part_id,
                    inventory_rec.current_quantity,
                    reorder_amount,
                    reorder_amount * inventory_rec.supplier_price,
                    CASE 
                        WHEN inventory_rec.current_quantity = 0 THEN 'CRITICAL'
                        WHEN inventory_rec.current_quantity <= 3 THEN 'HIGH'
                        WHEN inventory_rec.current_quantity <= 7 THEN 'MEDIUM'
                        ELSE 'LOW'
                    END,
                    'Auto-generated recommendation - ' || 
                    CASE WHEN NOT p_auto_reorder THEN 'Manual approval required' 
                         ELSE 'Supplier unavailable' END
                );
            END IF;
            
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'Error processing part % in warehouse %: %', 
                            inventory_rec.part_id, inventory_rec.warehouse_id, SQLERRM;
                
                -- Log error for manual review
                INSERT INTO inventory_errors (
                    error_date, warehouse_id, part_id, error_message
                ) VALUES (
                    CURRENT_TIMESTAMP, inventory_rec.warehouse_id, 
                    inventory_rec.part_id, SQLERRM
                );
                CONTINUE;
        END;
    END LOOP;
    
    -- Perform inventory optimization analysis
    IF needs_attention THEN
        -- Create optimization tasks
        INSERT INTO optimization_tasks (
            task_date, task_type, description, priority, status
        ) VALUES (
            CURRENT_DATE, 'CAPACITY_OPTIMIZATION', optimization_actions, 'HIGH', 'PENDING'
        );
    END IF;
    
    -- Update inventory management summary
    INSERT INTO inventory_management_log (
        management_date,
        warehouse_id,
        total_reorders_created,
        total_cost_incurred,
        optimization_notes,
        process_status
    ) VALUES (
        CURRENT_TIMESTAMP,
        p_warehouse_id,
        total_reorders,
        total_cost,
        optimization_actions,
        'COMPLETED'
    );
    
    -- Final summary
    RAISE NOTICE 'Inventory management completed. Total reorders: %, Total cost: $%, Optimization actions: %',
                total_reorders, total_cost, 
                CASE WHEN length(optimization_actions) > 0 THEN 'Required' ELSE 'None needed' END;
    
EXCEPTION
    WHEN OTHERS THEN
        -- Global error handling
        RAISE EXCEPTION 'Critical error in inventory management: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;