-- ========== TRIGGER 1: Aircraft Status Change Audit System ==========
-- This trigger automatically audits all changes to aircraft status and other critical fields
-- Demonstrates: Trigger functionality, Conditional logic, Data auditing

-- First, create the audit table to store plane changes
CREATE TABLE IF NOT EXISTS plane_audit_log (
    audit_id SERIAL PRIMARY KEY,
    plane_id INT NOT NULL,
    operation_type VARCHAR(10) NOT NULL, -- INSERT, UPDATE, DELETE
    operation_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    operation_user VARCHAR(100) DEFAULT CURRENT_USER,
    
    -- Old values (for UPDATE and DELETE)
    old_model VARCHAR(25),
    old_production_date DATE,
    old_capacity INT,
    old_max_altitude INT,
    old_max_distance INT,
    old_status VARCHAR(30),
    old_producer_id INT,
    old_hangar_id INT,
    old_operator_id INT,
    
    -- New values (for INSERT and UPDATE)
    new_model VARCHAR(25),
    new_production_date DATE,
    new_capacity INT,
    new_max_altitude INT,
    new_max_distance INT,
    new_status VARCHAR(30),
    new_producer_id INT,
    new_hangar_id INT,
    new_operator_id INT,
    
    -- Change analysis
    status_changed BOOLEAN DEFAULT FALSE,
    operator_changed BOOLEAN DEFAULT FALSE,
    hangar_changed BOOLEAN DEFAULT FALSE,
    critical_change BOOLEAN DEFAULT FALSE,
    change_summary TEXT,
    
    -- Additional metadata
    session_id VARCHAR(100) DEFAULT CURRENT_SETTING('application_name', true),
    client_addr INET DEFAULT INET_CLIENT_ADDR(),
    change_reason TEXT
);

-- Create the trigger function
CREATE OR REPLACE FUNCTION audit_plane_changes()
RETURNS TRIGGER AS $$
DECLARE
    change_description TEXT := '';
    is_critical BOOLEAN := FALSE;
    status_change BOOLEAN := FALSE;
    operator_change BOOLEAN := FALSE;
    hangar_change BOOLEAN := FALSE;
    change_count INT := 0;
    
BEGIN
    -- Handle INSERT operations
    IF TG_OP = 'INSERT' THEN
        INSERT INTO plane_audit_log (
            plane_id, operation_type,
            new_model, new_production_date, new_capacity, new_max_altitude,
            new_max_distance, new_status, new_producer_id, new_hangar_id, new_operator_id,
            change_summary, critical_change
        ) VALUES (
            NEW.plane_id, 'INSERT',
            NEW.model, NEW.production_date, NEW.capacity, NEW.max_altitude,
            NEW.max_distance, NEW.status, NEW.producer_id, NEW.hangar_id, NEW.operator_id,
            'New aircraft added: ' || NEW.model || ' (Status: ' || NEW.status || ')',
            TRUE -- New aircraft is always considered critical
        );
        
        -- Notify relevant parties of new aircraft
        PERFORM pg_notify('aircraft_changes', 
            'NEW_AIRCRAFT|' || NEW.plane_id || '|' || NEW.model || '|' || NEW.status);
        
        RETURN NEW;
    END IF;
    
    -- Handle DELETE operations
    IF TG_OP = 'DELETE' THEN
        INSERT INTO plane_audit_log (
            plane_id, operation_type,
            old_model, old_production_date, old_capacity, old_max_altitude,
            old_max_distance, old_status, old_producer_id, old_hangar_id, old_operator_id,
            change_summary, critical_change
        ) VALUES (
            OLD.plane_id, 'DELETE',
            OLD.model, OLD.production_date, OLD.capacity, OLD.max_altitude,
            OLD.max_distance, OLD.status, OLD.producer_id, OLD.hangar_id, OLD.operator_id,
            'Aircraft removed: ' || OLD.model || ' (Was: ' || OLD.status || ')',
            TRUE -- Aircraft deletion is always critical
        );
        
        -- Notify of aircraft deletion
        PERFORM pg_notify('aircraft_changes', 
            'AIRCRAFT_DELETED|' || OLD.plane_id || '|' || OLD.model);
        
        RETURN OLD;
    END IF;
    
    -- Handle UPDATE operations (most complex case)
    IF TG_OP = 'UPDATE' THEN
        -- Check what changed and build change description
        
        -- Status change (most critical)
        IF OLD.status != NEW.status THEN
            status_change := TRUE;
            is_critical := TRUE;
            change_count := change_count + 1;
            change_description := change_description || 
                'Status: ' || OLD.status || ' → ' || NEW.status || '; ';
            
            -- Special handling for critical status changes
            IF NEW.status = 'Retired' THEN
                change_description := change_description || '[AIRCRAFT RETIRED] ';
                is_critical := TRUE;
                
                -- Auto-update related pilot assignments
                UPDATE Pilot_Plane 
                SET assignment_date = CURRENT_DATE - INTERVAL '1 day'  -- Mark as ended
                WHERE plane_id = NEW.plane_id;
                
            ELSIF NEW.status = 'In Maintenance' AND OLD.status = 'Operational' THEN
                change_description := change_description || '[MAINTENANCE REQUIRED] ';
                
            ELSIF NEW.status = 'Operational' AND OLD.status = 'In Maintenance' THEN
                change_description := change_description || '[MAINTENANCE COMPLETED] ';
            END IF;
        END IF;
        
        -- Operator change
        IF OLD.operator_id != NEW.operator_id THEN
            operator_change := TRUE;
            is_critical := TRUE;
            change_count := change_count + 1;
            change_description := change_description || 
                'Operator: ' || OLD.operator_id || ' → ' || NEW.operator_id || '; ';
        END IF;
        
        -- Hangar change
        IF OLD.hangar_id != NEW.hangar_id THEN
            hangar_change := TRUE;
            change_count := change_count + 1;
            change_description := change_description || 
                'Hangar: ' || OLD.hangar_id || ' → ' || NEW.hangar_id || '; ';
        END IF;
        
        -- Capacity change (could affect safety)
        IF OLD.capacity != NEW.capacity THEN
            is_critical := TRUE;
            change_count := change_count + 1;
            change_description := change_description || 
                'Capacity: ' || OLD.capacity || ' → ' || NEW.capacity || '; ';
        END IF;
        
        -- Model change (unusual, might indicate data correction)
        IF OLD.model != NEW.model THEN
            is_critical := TRUE;
            change_count := change_count + 1;
            change_description := change_description || 
                'Model: ' || OLD.model || ' → ' || NEW.model || '; ';
        END IF;
        
        -- Production date change (data correction)
        IF OLD.production_date != NEW.production_date THEN
            change_count := change_count + 1;
            change_description := change_description || 
                'Production Date: ' || OLD.production_date || ' → ' || NEW.production_date || '; ';
        END IF;
        
        -- Max altitude change
        IF OLD.max_altitude != NEW.max_altitude THEN
            change_count := change_count + 1;
            change_description := change_description || 
                'Max Altitude: ' || OLD.max_altitude || ' → ' || NEW.max_altitude || '; ';
        END IF;
        
        -- Max distance change
        IF OLD.max_distance != NEW.max_distance THEN
            change_count := change_count + 1;
            change_description := change_description || 
                'Max Distance: ' || OLD.max_distance || ' → ' || NEW.max_distance || '; ';
        END IF;
        
        -- Producer change (very unusual)
        IF OLD.producer_id != NEW.producer_id THEN
            is_critical := TRUE;
            change_count := change_count + 1;
            change_description := change_description || 
                'Producer: ' || OLD.producer_id || ' → ' || NEW.producer_id || '; ';
        END IF;
        
        -- Only log if there were actual changes
        IF change_count > 0 THEN
            INSERT INTO plane_audit_log (
                plane_id, operation_type,
                -- Old values
                old_model, old_production_date, old_capacity, old_max_altitude,
                old_max_distance, old_status, old_producer_id, old_hangar_id, old_operator_id,
                -- New values
                new_model, new_production_date, new_capacity, new_max_altitude,
                new_max_distance, new_status, new_producer_id, new_hangar_id, new_operator_id,
                -- Change tracking
                status_changed, operator_changed, hangar_changed, critical_change,
                change_summary
            ) VALUES (
                NEW.plane_id, 'UPDATE',
                -- Old values
                OLD.model, OLD.production_date, OLD.capacity, OLD.max_altitude,
                OLD.max_distance, OLD.status, OLD.producer_id, OLD.hangar_id, OLD.operator_id,
                -- New values
                NEW.model, NEW.production_date, NEW.capacity, NEW.max_altitude,
                NEW.max_distance, NEW.status, NEW.producer_id, NEW.hangar_id, NEW.operator_id,
                -- Change tracking
                status_change, operator_change, hangar_change, is_critical,
                'Changes (' || change_count || '): ' || change_description
            );
            
            -- Send notifications for critical changes
            IF is_critical THEN
                PERFORM pg_notify('critical_aircraft_changes', 
                    'CRITICAL|' || NEW.plane_id || '|' || NEW.model || '|' || change_description);
            END IF;
            
            -- Send notifications for status changes
            IF status_change THEN
                PERFORM pg_notify('aircraft_status_changes', 
                    'STATUS_CHANGE|' || NEW.plane_id || '|' || OLD.status || '|' || NEW.status);
            END IF;
        END IF;
        
        RETURN NEW;
    END IF;
    
    -- Should never reach here, but handle gracefully
    RETURN COALESCE(NEW, OLD);
    
EXCEPTION
    WHEN OTHERS THEN
        -- Log audit failures but don't prevent the operation
        INSERT INTO plane_audit_log (
            plane_id, operation_type, change_summary, critical_change
        ) VALUES (
            COALESCE(NEW.plane_id, OLD.plane_id),
            TG_OP,
            'AUDIT_ERROR: ' || SQLERRM,
            TRUE
        );
        
        -- Return appropriate record
        RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Create the trigger
DROP TRIGGER IF EXISTS plane_audit_trigger ON Plane;
CREATE TRIGGER plane_audit_trigger
    AFTER INSERT OR UPDATE OR DELETE ON Plane
    FOR EACH ROW EXECUTE FUNCTION audit_plane_changes();

-- Create indexes for better performance on audit table
CREATE INDEX IF NOT EXISTS idx_plane_audit_plane_id ON plane_audit_log(plane_id);
CREATE INDEX IF NOT EXISTS idx_plane_audit_timestamp ON plane_audit_log(operation_timestamp);
CREATE INDEX IF NOT EXISTS idx_plane_audit_operation ON plane_audit_log(operation_type);
CREATE INDEX IF NOT EXISTS idx_plane_audit_critical ON plane_audit_log(critical_change) WHERE critical_change = TRUE;