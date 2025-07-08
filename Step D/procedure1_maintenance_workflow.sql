-- ========== PROCEDURE 1: Aircraft Maintenance Workflow Manager ==========
-- This procedure manages the complete aircraft maintenance workflow
-- Demonstrates: DML statements, Exception handling, Branching, Transactions

CREATE OR REPLACE PROCEDURE manage_aircraft_maintenance(
    p_plane_id INT,
    p_maintenance_type VARCHAR(50),
    p_employee_id INT,
    p_warehouse_id INT,
    p_parts_needed TEXT[], -- Array of part IDs needed
    p_estimated_cost DECIMAL(10,2) DEFAULT NULL,
    p_description TEXT DEFAULT NULL
) AS $$
DECLARE
    aircraft_record RECORD;
    part_record RECORD;
    maintenance_id INT;
    current_status VARCHAR(30);
    part_id INT;
    parts_available BOOLEAN := TRUE;
    total_estimated_cost DECIMAL(10,2) := 0;
    parts_cost DECIMAL(10,2) := 0;
    labor_cost DECIMAL(10,2) := 500.00; -- Base labor cost
    warehouse_has_capacity BOOLEAN;
    employee_available BOOLEAN;
    
BEGIN
    -- Start transaction for all maintenance operations
    BEGIN
        -- Validate aircraft exists and get current status
        SELECT plane_id, model, status, operator_id INTO aircraft_record
        FROM Plane 
        WHERE plane_id = p_plane_id;
        
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Aircraft with ID % not found', p_plane_id;
        END IF;
        
        current_status := aircraft_record.status;
        
        -- Validate employee exists and is available
        SELECT COUNT(*) > 0 INTO employee_available
        FROM employee e
        JOIN WorksAt wa ON e.employee_id = wa.employee_id
        WHERE e.employee_id = p_employee_id 
        AND wa.warehouse_id = p_warehouse_id
        AND e.role IN ('Technician', 'Manager', 'Supervisor');
        
        IF NOT employee_available THEN
            RAISE EXCEPTION 'Employee % is not available or not qualified for maintenance at warehouse %', 
                          p_employee_id, p_warehouse_id;
        END IF;
        
        -- Validate warehouse exists and has capacity
        SELECT capacity > 50 INTO warehouse_has_capacity
        FROM Warehouse 
        WHERE warehouse_id = p_warehouse_id;
        
        IF NOT warehouse_has_capacity THEN
            RAISE EXCEPTION 'Warehouse % does not have sufficient capacity for maintenance operations', 
                          p_warehouse_id;
        END IF;
        
        -- Check parts availability and calculate costs
        IF p_parts_needed IS NOT NULL AND array_length(p_parts_needed, 1) > 0 THEN
            FOR i IN 1..array_length(p_parts_needed, 1) LOOP
                part_id := p_parts_needed[i]::INT;
                
                -- Check if part exists and is available in warehouse
                SELECT p.part_id, p.name, wp.wQuantity, sp.price 
                INTO part_record
                FROM Part p
                LEFT JOIN WarehouseParts wp ON p.part_id = wp.part_id AND wp.warehouse_id = p_warehouse_id
                LEFT JOIN SupplierParts sp ON p.part_id = sp.part_id
                WHERE p.part_id = part_id;
                
                IF NOT FOUND THEN
                    RAISE EXCEPTION 'Part with ID % not found', part_id;
                END IF;
                
                -- Check availability
                IF part_record.wQuantity IS NULL OR part_record.wQuantity < 1 THEN
                    parts_available := FALSE;
                    RAISE NOTICE 'Part % (%) not available in warehouse %', 
                                part_id, part_record.name, p_warehouse_id;
                ELSE
                    -- Add to parts cost
                    parts_cost := parts_cost + COALESCE(part_record.price, 100.00);
                END IF;
            END LOOP;
        END IF;
        
        -- If parts are not available, try to auto-order them
        IF NOT parts_available THEN
            RAISE NOTICE 'Attempting to auto-order missing parts...';
            
            -- This would trigger automatic ordering logic
            FOR i IN 1..array_length(p_parts_needed, 1) LOOP
                part_id := p_parts_needed[i]::INT;
                
                -- Check if we can order from suppliers
                SELECT sp.supplier_id, sp.price, sp.sQuantity
                INTO part_record
                FROM SupplierParts sp
                WHERE sp.part_id = part_id 
                AND sp.sQuantity > 0
                ORDER BY sp.price ASC
                LIMIT 1;
                
                IF FOUND AND part_record.sQuantity > 0 THEN
                    -- Create automatic order
                    INSERT INTO myorder (
                        order_id, amount, order_date, arrival_date, 
                        part_id, supplier_id, warehouse_id
                    ) VALUES (
                        nextval('order_id_seq'),
                        1,
                        CURRENT_DATE,
                        CURRENT_DATE + INTERVAL '3 days',
                        part_id,
                        part_record.supplier_id,
                        p_warehouse_id
                    );
                    
                    RAISE NOTICE 'Auto-ordered part % from supplier %', part_id, part_record.supplier_id;
                ELSE
                    RAISE EXCEPTION 'Part % cannot be ordered - no suppliers available', part_id;
                END IF;
            END LOOP;
        END IF;
        
        -- Calculate total estimated cost
        total_estimated_cost := parts_cost + labor_cost;
        
        -- Adjust labor cost based on maintenance type
        IF p_maintenance_type = 'Emergency Repair' THEN
            labor_cost := labor_cost * 2.0;
            total_estimated_cost := total_estimated_cost + labor_cost;
        ELSIF p_maintenance_type = 'Scheduled Maintenance' THEN
            labor_cost := labor_cost * 0.8;
            total_estimated_cost := total_estimated_cost - (labor_cost * 0.2);
        ELSIF p_maintenance_type = 'Inspection' THEN
            labor_cost := labor_cost * 0.5;
            total_estimated_cost := total_estimated_cost - (labor_cost * 0.5);
        END IF;
        
        -- Use provided cost if given, otherwise use calculated
        IF p_estimated_cost IS NOT NULL THEN
            total_estimated_cost := p_estimated_cost;
        END IF;
        
        -- Update aircraft status based on maintenance type
        IF p_maintenance_type IN ('Emergency Repair', 'Major Overhaul') THEN
            UPDATE Plane 
            SET status = 'In Maintenance'
            WHERE plane_id = p_plane_id;
            
            RAISE NOTICE 'Aircraft % status updated to "In Maintenance"', p_plane_id;
        END IF;
        
        -- Create maintenance record
        INSERT INTO Maintenance_Record (
            plane_id, employee_id, warehouse_id, maintenance_date,
            maintenance_type, cost, description, completed
        ) VALUES (
            p_plane_id, p_employee_id, p_warehouse_id, CURRENT_DATE,
            p_maintenance_type, total_estimated_cost, p_description, FALSE
        ) RETURNING maintenance_id INTO maintenance_id;
        
        -- Update parts inventory if maintenance is starting
        IF p_parts_needed IS NOT NULL AND array_length(p_parts_needed, 1) > 0 THEN
            FOR i IN 1..array_length(p_parts_needed, 1) LOOP
                part_id := p_parts_needed[i]::INT;
                
                -- Reserve parts by reducing warehouse quantity
                UPDATE WarehouseParts 
                SET wQuantity = wQuantity - 1,
                    last_updated = CURRENT_DATE
                WHERE part_id = part_id AND warehouse_id = p_warehouse_id;
                
                -- Create aircraft-parts relationship
                INSERT INTO Aircraft_Parts (
                    plane_id, part_id, quantity_used, installation_date, 
                    next_maintenance_date, status
                ) VALUES (
                    p_plane_id, part_id, 1, CURRENT_DATE,
                    CURRENT_DATE + INTERVAL '6 months', 'Reserved'
                );
            END LOOP;
        END IF;
        
        -- Log the maintenance initiation
        INSERT INTO maintenance_log (
            log_date, maintenance_id, plane_id, action_type, 
            performed_by, notes
        ) VALUES (
            CURRENT_TIMESTAMP, maintenance_id, p_plane_id, 'INITIATED',
            p_employee_id, 'Maintenance workflow started: ' || p_maintenance_type
        );
        
        RAISE NOTICE 'Maintenance workflow initiated successfully. Maintenance ID: %, Estimated Cost: $%', 
                    maintenance_id, total_estimated_cost;
        
        -- Commit transaction
        COMMIT;
        
    EXCEPTION
        WHEN OTHERS THEN
            -- Rollback transaction on any error
            ROLLBACK;
            
            -- Log the error
            INSERT INTO error_log (
                error_date, error_context, error_message, 
                related_plane_id, related_employee_id
            ) VALUES (
                CURRENT_TIMESTAMP, 'manage_aircraft_maintenance', SQLERRM,
                p_plane_id, p_employee_id
            );
            
            RAISE EXCEPTION 'Maintenance workflow failed: %', SQLERRM;
    END;
    
END;
$$ LANGUAGE plpgsql;