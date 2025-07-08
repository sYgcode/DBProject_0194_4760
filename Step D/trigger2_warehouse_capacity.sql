-- ========== TRIGGER 2: Warehouse Capacity Auto-Management System ==========
-- This trigger automatically manages warehouse capacity and inventory optimization
-- Demonstrates: Complex trigger logic, Conditional updates, Inventory management

-- Create warehouse capacity tracking table
CREATE TABLE IF NOT EXISTS warehouse_capacity_log (
    capacity_log_id SERIAL PRIMARY KEY,
    warehouse_id INT NOT NULL,
    log_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    operation_type VARCHAR(20) NOT NULL, -- PART_ADDED, PART_REMOVED, QUANTITY_CHANGED
    part_id INT,
    old_quantity INT,
    new_quantity INT,
    quantity_change INT,
    
    -- Capacity metrics
    total_items_before INT,
    total_items_after INT,
    capacity_utilization_before DECIMAL(5,2),
    capacity_utilization_after DECIMAL(5,2),
    
    -- Status and alerts
    capacity_status VARCHAR(20), -- NORMAL, HIGH, CRITICAL, OVERLOADED
    alert_triggered BOOLEAN DEFAULT FALSE,
    alert_type VARCHAR(30),
    alert_message TEXT,
    
    -- Optimization suggestions
    optimization_needed BOOLEAN DEFAULT FALSE,
    optimization_type VARCHAR(30),
    optimization_suggestion TEXT,
    
    FOREIGN KEY (warehouse_id) REFERENCES Warehouse(warehouse_id),
    FOREIGN KEY (part_id) REFERENCES Part(part_id)
);

-- Create the warehouse capacity management function
CREATE OR REPLACE FUNCTION manage_warehouse_capacity()
RETURNS TRIGGER AS $$
DECLARE
    warehouse_rec RECORD;
    total_items_before INT := 0;
    total_items_after INT := 0;
    capacity_utilization_before DECIMAL(5,2) := 0;
    capacity_utilization_after DECIMAL(5,2) := 0;
    capacity_status VARCHAR(20) := 'NORMAL';
    alert_needed BOOLEAN := FALSE;
    alert_type VARCHAR(30) := '';
    alert_message TEXT := '';
    optimization_needed BOOLEAN := FALSE;
    optimization_type VARCHAR(30) := '';
    optimization_suggestion TEXT := '';
    quantity_change INT := 0;
    operation_type VARCHAR(20) := '';
    
BEGIN
    -- Determine operation type and quantity changes
    IF TG_OP = 'INSERT' THEN
        operation_type := 'PART_ADDED';
        quantity_change := NEW.wQuantity;
    ELSIF TG_OP = 'DELETE' THEN
        operation_type := 'PART_REMOVED';
        quantity_change := -OLD.wQuantity;
    ELSIF TG_OP = 'UPDATE' THEN
        operation_type := 'QUANTITY_CHANGED';
        quantity_change := NEW.wQuantity - OLD.wQuantity;
    END IF;
    
    -- Get warehouse information and calculate current utilization
    SELECT w.warehouse_id, w.location, w.capacity,
           COALESCE(SUM(wp.wQuantity), 0) as current_total_items
    INTO warehouse_rec
    FROM Warehouse w
    LEFT JOIN WarehouseParts wp ON w.warehouse_id = wp.warehouse_id
    WHERE w.warehouse_id = COALESCE(NEW.warehouse_id, OLD.warehouse_id)
    GROUP BY w.warehouse_id, w.location, w.capacity;
    
    -- Calculate before and after metrics
    IF TG_OP = 'INSERT' THEN
        total_items_before := warehouse_rec.current_total_items - NEW.wQuantity;
        total_items_after := warehouse_rec.current_total_items;
    ELSIF TG_OP = 'DELETE' THEN
        total_items_before := warehouse_rec.current_total_items;
        total_items_after := warehouse_rec.current_total_items - OLD.wQuantity;
    ELSIF TG_OP = 'UPDATE' THEN
        total_items_before := warehouse_rec.current_total_items - NEW.wQuantity + OLD.wQuantity;
        total_items_after := warehouse_rec.current_total_items;
    END IF;
    
    -- Calculate utilization percentages
    IF warehouse_rec.capacity > 0 THEN
        capacity_utilization_before := (total_items_before * 100.0) / warehouse_rec.capacity;
        capacity_utilization_after := (total_items_after * 100.0) / warehouse_rec.capacity;
    END IF;
    
    -- Determine capacity status and alerts based on utilization
    IF capacity_utilization_after >= 100 THEN
        capacity_status := 'OVERLOADED';
        alert_needed := TRUE;
        alert_type := 'CAPACITY_EXCEEDED';
        alert_message := 'CRITICAL: Warehouse ' || warehouse_rec.warehouse_id || 
                        ' has exceeded capacity (' || capacity_utilization_after || '%)';
        optimization_needed := TRUE;
        optimization_type := 'EMERGENCY_REDISTRIBUTION';
        optimization_suggestion := 'Immediate action required: Redistribute items to other warehouses or expand capacity';
        
    ELSIF capacity_utilization_after >= 90 THEN
        capacity_status := 'CRITICAL';
        alert_needed := TRUE;
        alert_type := 'CAPACITY_CRITICAL';
        alert_message := 'WARNING: Warehouse ' || warehouse_rec.warehouse_id || 
                        ' is at critical capacity (' || capacity_utilization_after || '%)';
        optimization_needed := TRUE;
        optimization_type := 'CAPACITY_PLANNING';
        optimization_suggestion := 'Plan for capacity expansion or inventory redistribution within 30 days';
        
    ELSIF capacity_utilization_after >= 75 THEN
        capacity_status := 'HIGH';
        alert_needed := TRUE;
        alert_type := 'CAPACITY_HIGH';
        alert_message := 'NOTICE: Warehouse ' || warehouse_rec.warehouse_id || 
                        ' approaching high capacity (' || capacity_utilization_after || '%)';
        optimization_needed := TRUE;
        optimization_type := 'INVENTORY_OPTIMIZATION';
        optimization_suggestion := 'Review slow-moving inventory and consider redistribution';
        
    ELSIF capacity_utilization_after < 25 THEN
        capacity_status := 'UNDERUTILIZED';
        optimization_needed := TRUE;
        optimization_type := 'CONSOLIDATION_OPPORTUNITY';
        optimization_suggestion := 'Consider consolidating inventory from other locations';
        
    ELSE
        capacity_status := 'NORMAL';
    END IF;
    
    -- Log the capacity change
    INSERT INTO warehouse_capacity_log (
        warehouse_id, operation_type, part_id,
        old_quantity, new_quantity, quantity_change,
        total_items_before, total_items_after,
        capacity_utilization_before, capacity_utilization_after,
        capacity_status, alert_triggered, alert_type, alert_message,
        optimization_needed, optimization_type, optimization_suggestion
    ) VALUES (
        warehouse_rec.warehouse_id, operation_type, 
        COALESCE(NEW.part_id, OLD.part_id),
        CASE WHEN TG_OP = 'UPDATE' THEN OLD.wQuantity ELSE NULL END,
        CASE WHEN TG_OP != 'DELETE' THEN NEW.wQuantity ELSE NULL END,
        quantity_change,
        total_items_before, total_items_after,
        capacity_utilization_before, capacity_utilization_after,
        capacity_status, alert_needed, alert_type, alert_message,
        optimization_needed, optimization_type, optimization_suggestion
    );
    
    -- Update warehouse status if needed
    UPDATE Warehouse 
    SET 
        utilization_percentage = capacity_utilization_after,
        status_notes = capacity_status,
        last_inventory_check = CURRENT_TIMESTAMP
    WHERE warehouse_id = warehouse_rec.warehouse_id;
    
    -- Send notifications for alerts
    IF alert_needed THEN
        PERFORM pg_notify('warehouse_capacity_alerts', 
            alert_type || '|' || warehouse_rec.warehouse_id || '|' || 
            capacity_utilization_after || '|' || alert_message);
        
        -- For critical situations, also create immediate action items
        IF capacity_status IN ('CRITICAL', 'OVERLOADED') THEN
            INSERT INTO urgent_action_items (
                item_date, item_type, warehouse_id, priority_level,
                description, assigned_to, status
            ) VALUES (
                CURRENT_TIMESTAMP, 'CAPACITY_MANAGEMENT', warehouse_rec.warehouse_id, 'URGENT',
                alert_message || ' - ' || optimization_suggestion,
                'warehouse_manager', 'OPEN'
            );
        END IF;
    END IF;
    
    -- Handle optimization suggestions
    IF optimization_needed THEN
        -- Check if similar optimization suggestion exists recently
        IF NOT EXISTS (
            SELECT 1 FROM warehouse_optimization_queue 
            WHERE warehouse_id = warehouse_rec.warehouse_id 
            AND optimization_type = optimization_type
            AND created_date > CURRENT_DATE - INTERVAL '7 days'
            AND status IN ('PENDING', 'IN_PROGRESS')
        ) THEN
            -- Create new optimization task
            INSERT INTO warehouse_optimization_queue (
                warehouse_id, optimization_type, description,
                priority_level, estimated_benefit, created_date, status
            ) VALUES (
                warehouse_rec.warehouse_id, optimization_type, optimization_suggestion,
                CASE 
                    WHEN capacity_status = 'OVERLOADED' THEN 'CRITICAL'
                    WHEN capacity_status = 'CRITICAL' THEN 'HIGH'
                    WHEN capacity_status = 'HIGH' THEN 'MEDIUM'
                    ELSE 'LOW'
                END,
                CASE 
                    WHEN optimization_type = 'EMERGENCY_REDISTRIBUTION' THEN 'Prevent operational disruption'
                    WHEN optimization_type = 'CAPACITY_PLANNING' THEN 'Avoid future capacity issues'
                    WHEN optimization_type = 'INVENTORY_OPTIMIZATION' THEN 'Improve space utilization'
                    WHEN optimization_type = 'CONSOLIDATION_OPPORTUNITY' THEN 'Reduce operational costs'
                    ELSE 'Operational efficiency'
                END,
                CURRENT_TIMESTAMP, 'PENDING'
            );
        END IF;
    END IF;
    
    -- Special handling for specific scenarios
    
    -- If a new part type is added to warehouse
    IF TG_OP = 'INSERT' THEN
        -- Check if this is a new part type for this warehouse
        UPDATE Part 
        SET last_update = CURRENT_DATE 
        WHERE part_id = NEW.part_id;
        
        -- Auto-suggest reorder levels for new parts
        IF NEW.wQuantity <= 5 THEN
            INSERT INTO reorder_recommendations (
                recommendation_date, warehouse_id, part_id,
                current_quantity, recommended_quantity,
                priority_level, notes
            ) VALUES (
                CURRENT_DATE, NEW.warehouse_id, NEW.part_id,
                NEW.wQuantity, 50, 'MEDIUM',
                'Auto-generated: New part with low initial quantity'
            );
        END IF;
    END IF;
    
    -- If quantity drops to zero, check for backorders
    IF TG_OP = 'UPDATE' AND NEW.wQuantity = 0 AND OLD.wQuantity > 0 THEN
        -- Create critical reorder recommendation
        INSERT INTO reorder_recommendations (
            recommendation_date, warehouse_id, part_id,
            current_quantity, recommended_quantity,
            priority_level, notes
        ) VALUES (
            CURRENT_DATE, NEW.warehouse_id, NEW.part_id,
            0, 100, 'CRITICAL',
            'Auto-generated: Part out of stock'
        );
        
        -- Notify about stockout
        PERFORM pg_notify('inventory_stockout', 
            'STOCKOUT|' || NEW.warehouse_id || '|' || NEW.part_id || '|' || 
            (SELECT name FROM Part WHERE part_id = NEW.part_id));
    END IF;
    
    -- Return appropriate record
    RETURN COALESCE(NEW, OLD);
    
EXCEPTION
    WHEN OTHERS THEN
        -- Log error but don't prevent the operation
        INSERT INTO warehouse_capacity_log (
            warehouse_id, operation_type, alert_triggered, alert_type, alert_message
        ) VALUES (
            COALESCE(NEW.warehouse_id, OLD.warehouse_id),
            'ERROR',
            TRUE,
            'TRIGGER_ERROR',
            'Capacity management error: ' || SQLERRM
        );
        
        RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Create the trigger
DROP TRIGGER IF EXISTS warehouse_capacity_trigger ON WarehouseParts;
CREATE TRIGGER warehouse_capacity_trigger
    AFTER INSERT OR UPDATE OR DELETE ON WarehouseParts
    FOR EACH ROW EXECUTE FUNCTION manage_warehouse_capacity();

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_warehouse_capacity_log_warehouse ON warehouse_capacity_log(warehouse_id);
CREATE INDEX IF NOT EXISTS idx_warehouse_capacity_log_timestamp ON warehouse_capacity_log(log_timestamp);
CREATE INDEX IF NOT EXISTS idx_warehouse_capacity_log_status ON warehouse_capacity_log(capacity_status);
CREATE INDEX IF NOT EXISTS idx_warehouse_capacity_log_alerts ON warehouse_capacity_log(alert_triggered) WHERE alert_triggered = TRUE;