-- ========== STAGE 4: ALTER TABLE COMMANDS ==========
-- Database modifications to support PL/pgSQL programs

-- ==========================================================
-- SEQUENCE CREATION FOR AUTO-INCREMENT FUNCTIONALITY
-- ==========================================================

-- Create sequence for order IDs (if not exists)
CREATE SEQUENCE IF NOT EXISTS order_id_seq
    START 1000
    INCREMENT 1
    MINVALUE 1
    MAXVALUE 999999999
    CACHE 1;

-- ==========================================================
-- ADD COLUMNS TO EXISTING TABLES FOR ENHANCED FUNCTIONALITY
-- ==========================================================

-- Add status tracking columns to Warehouse table
ALTER TABLE Warehouse 
ADD COLUMN IF NOT EXISTS last_inventory_check DATE,
ADD COLUMN IF NOT EXISTS utilization_percentage DECIMAL(5,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS status_notes VARCHAR(100);

-- Add metadata columns to Part table for better tracking
ALTER TABLE Part 
ADD COLUMN IF NOT EXISTS category VARCHAR(50) DEFAULT 'General',
ADD COLUMN IF NOT EXISTS critical_stock_level INT DEFAULT 10,
ADD COLUMN IF NOT EXISTS reorder_point INT DEFAULT 20;

-- Add performance tracking to employee table
ALTER TABLE employee 
ADD COLUMN IF NOT EXISTS performance_rating DECIMAL(3,1) DEFAULT 5.0,
ADD COLUMN IF NOT EXISTS last_performance_review DATE,
ADD COLUMN IF NOT EXISTS certification_level VARCHAR(20) DEFAULT 'Standard';

-- ==========================================================
-- CREATE LOGGING AND AUDIT TABLES
-- ==========================================================

-- Maintenance analysis log table
CREATE TABLE IF NOT EXISTS maintenance_analysis_log (
    log_id SERIAL PRIMARY KEY,
    analysis_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    operator_id INT,
    date_range_from DATE,
    date_range_to DATE,
    total_planes_analyzed INT,
    total_cost_analyzed DECIMAL(12,2),
    avg_cost_per_plane DECIMAL(10,2),
    FOREIGN KEY (operator_id) REFERENCES Operator(operator_id)
);

-- Fleet analysis log table
CREATE TABLE IF NOT EXISTS fleet_analysis_log (
    analysis_id SERIAL PRIMARY KEY,
    analysis_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    operation_mode VARCHAR(20),
    target_operator_id INT,
    aircraft_analyzed INT,
    pilots_analyzed INT,
    fleet_efficiency_score DECIMAL(5,2),
    avg_pilot_performance DECIMAL(5,2),
    warnings_generated INT,
    errors_encountered INT,
    analysis_duration INTERVAL,
    summary TEXT,
    recommendations TEXT,
    FOREIGN KEY (target_operator_id) REFERENCES Operator(operator_id)
);

-- Inventory analysis log table
CREATE TABLE IF NOT EXISTS inventory_analysis_log (
    analysis_id SERIAL PRIMARY KEY,
    analysis_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    management_mode VARCHAR(30),
    target_warehouse_id INT,
    warehouses_processed INT,
    parts_analyzed INT,
    efficiency_score DECIMAL(5,2),
    total_inventory_value DECIMAL(15,2),
    avg_utilization DECIMAL(5,2),
    reorders_created INT,
    total_reorder_cost DECIMAL(12,2),
    critical_stockouts INT,
    overstock_items INT,
    optimization_opportunities INT,
    cost_savings_potential DECIMAL(10,2),
    warnings_generated INT,
    processing_errors INT,
    process_duration INTERVAL,
    executive_summary TEXT,
    recommendations TEXT,
    action_items TEXT,
    FOREIGN KEY (target_warehouse_id) REFERENCES Warehouse(warehouse_id)
);

-- Maintenance log for detailed tracking
CREATE TABLE IF NOT EXISTS maintenance_log (
    log_id SERIAL PRIMARY KEY,
    log_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    maintenance_id INT,
    plane_id INT,
    action_type VARCHAR(20), -- INITIATED, IN_PROGRESS, COMPLETED, CANCELLED
    performed_by INT,
    notes TEXT,
    FOREIGN KEY (maintenance_id) REFERENCES Maintenance_Record(maintenance_id),
    FOREIGN KEY (plane_id) REFERENCES Plane(plane_id),
    FOREIGN KEY (performed_by) REFERENCES employee(employee_id)
);

-- Error log table for system errors
CREATE TABLE IF NOT EXISTS error_log (
    error_id SERIAL PRIMARY KEY,
    error_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    error_context VARCHAR(100),
    error_message TEXT,
    related_plane_id INT,
    related_employee_id INT,
    related_warehouse_id INT,
    resolved BOOLEAN DEFAULT FALSE,
    resolution_notes TEXT,
    FOREIGN KEY (related_plane_id) REFERENCES Plane(plane_id),
    FOREIGN KEY (related_employee_id) REFERENCES employee(employee_id),
    FOREIGN KEY (related_warehouse_id) REFERENCES Warehouse(warehouse_id)
);

-- Reorder recommendations table
CREATE TABLE IF NOT EXISTS reorder_recommendations (
    recommendation_id SERIAL PRIMARY KEY,
    recommendation_date DATE DEFAULT CURRENT_DATE,
    warehouse_id INT NOT NULL,
    part_id INT NOT NULL,
    current_quantity INT,
    recommended_quantity INT,
    estimated_cost DECIMAL(10,2),
    priority_level VARCHAR(10), -- LOW, MEDIUM, HIGH, CRITICAL
    notes TEXT,
    status VARCHAR(20) DEFAULT 'PENDING', -- PENDING, APPROVED, ORDERED, CANCELLED
    created_by VARCHAR(100) DEFAULT CURRENT_USER,
    FOREIGN KEY (warehouse_id) REFERENCES Warehouse(warehouse_id),
    FOREIGN KEY (part_id) REFERENCES Part(part_id)
);

-- Urgent action items table
CREATE TABLE IF NOT EXISTS urgent_action_items (
    item_id SERIAL PRIMARY KEY,
    item_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    item_type VARCHAR(30),
    warehouse_id INT,
    plane_id INT,
    priority_level VARCHAR(10), -- LOW, MEDIUM, HIGH, URGENT, CRITICAL
    description TEXT,
    assigned_to VARCHAR(100),
    status VARCHAR(20) DEFAULT 'OPEN', -- OPEN, IN_PROGRESS, COMPLETED, CANCELLED
    due_date DATE,
    completion_date TIMESTAMP,
    notes TEXT,
    FOREIGN KEY (warehouse_id) REFERENCES Warehouse(warehouse_id),
    FOREIGN KEY (plane_id) REFERENCES Plane(plane_id)
);

-- Warehouse optimization queue
CREATE TABLE IF NOT EXISTS warehouse_optimization_queue (
    optimization_id SERIAL PRIMARY KEY,
    warehouse_id INT NOT NULL,
    optimization_type VARCHAR(30),
    description TEXT,
    priority_level VARCHAR(10),
    estimated_benefit TEXT,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'PENDING',
    assigned_to VARCHAR(100),
    completion_date TIMESTAMP,
    results TEXT,
    FOREIGN KEY (warehouse_id) REFERENCES Warehouse(warehouse_id)
);

-- Optimization tasks table
CREATE TABLE IF NOT EXISTS optimization_tasks (
    task_id SERIAL PRIMARY KEY,
    task_date DATE DEFAULT CURRENT_DATE,
    task_type VARCHAR(30),
    description TEXT,
    priority VARCHAR(10),
    status VARCHAR(20) DEFAULT 'PENDING',
    assigned_to VARCHAR(100),
    due_date DATE,
    completion_date DATE
);

-- Inventory errors table
CREATE TABLE IF NOT EXISTS inventory_errors (
    error_id SERIAL PRIMARY KEY,
    error_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    warehouse_id INT,
    part_id INT,
    error_message TEXT,
    resolved BOOLEAN DEFAULT FALSE,
    resolution_date TIMESTAMP,
    FOREIGN KEY (warehouse_id) REFERENCES Warehouse(warehouse_id),
    FOREIGN KEY (part_id) REFERENCES Part(part_id)
);

-- Inventory management log
CREATE TABLE IF NOT EXISTS inventory_management_log (
    log_id SERIAL PRIMARY KEY,
    management_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    warehouse_id INT,
    total_reorders_created INT,
    total_cost_incurred DECIMAL(12,2),
    optimization_notes TEXT,
    process_status VARCHAR(20),
    FOREIGN KEY (warehouse_id) REFERENCES Warehouse(warehouse_id)
);

-- ==========================================================
-- MODIFY EXISTING TABLES FOR BETTER CONSTRAINT HANDLING
-- ==========================================================

-- Add check constraints to ensure data quality
ALTER TABLE Plane 
ADD CONSTRAINT IF NOT EXISTS chk_plane_capacity_positive 
CHECK (Capacity > 0),
ADD CONSTRAINT IF NOT EXISTS chk_max_altitude_reasonable 
CHECK (MaxAltitude BETWEEN 1000 AND 60000),
ADD CONSTRAINT IF NOT EXISTS chk_max_distance_positive 
CHECK (MaxDistance > 0);

-- Add check constraints to Pilot table
ALTER TABLE Pilot 
ADD CONSTRAINT IF NOT EXISTS chk_pilot_experience_valid 
CHECK (Experience >= 0 AND Experience <= 50);

-- Add check constraints to Warehouse table
ALTER TABLE Warehouse 
ADD CONSTRAINT IF NOT EXISTS chk_warehouse_capacity_positive 
CHECK (capacity > 0),
ADD CONSTRAINT IF NOT EXISTS chk_utilization_percentage_valid 
CHECK (utilization_percentage >= 0 AND utilization_percentage <= 150); -- Allow up to 150% for overflow scenarios

-- Add check constraints to WarehouseParts table
ALTER TABLE WarehouseParts 
ADD CONSTRAINT IF NOT EXISTS chk_warehouse_parts_quantity_non_negative 
CHECK (wQuantity >= 0);

-- Add check constraints to Maintenance_Record table
ALTER TABLE Maintenance_Record 
ADD CONSTRAINT IF NOT EXISTS chk_maintenance_cost_non_negative 
CHECK (cost >= 0);

-- ==========================================================
-- CREATE INDEXES FOR BETTER PERFORMANCE
-- ==========================================================

-- Indexes for audit and logging tables
CREATE INDEX IF NOT EXISTS idx_maintenance_analysis_date ON maintenance_analysis_log(analysis_date);
CREATE INDEX IF NOT EXISTS idx_fleet_analysis_date ON fleet_analysis_log(analysis_date);
CREATE INDEX IF NOT EXISTS idx_inventory_analysis_date ON inventory_analysis_log(analysis_date);
CREATE INDEX IF NOT EXISTS idx_maintenance_log_date ON maintenance_log(log_date);
CREATE INDEX IF NOT EXISTS idx_error_log_date ON error_log(error_date);

-- Indexes for operational tables
CREATE INDEX IF NOT EXISTS idx_reorder_recommendations_warehouse ON reorder_recommendations(warehouse_id);
CREATE INDEX IF NOT EXISTS idx_reorder_recommendations_priority ON reorder_recommendations(priority_level);
CREATE INDEX IF NOT EXISTS idx_urgent_action_items_priority ON urgent_action_items(priority_level);
CREATE INDEX IF NOT EXISTS idx_urgent_action_items_status ON urgent_action_items(status);

-- Composite indexes for common queries
CREATE INDEX IF NOT EXISTS idx_warehouse_parts_warehouse_quantity ON WarehouseParts(warehouse_id, wQuantity);
CREATE INDEX IF NOT EXISTS idx_maintenance_record_plane_date ON Maintenance_Record(plane_id, maintenance_date);
CREATE INDEX IF NOT EXISTS idx_pilot_plane_assignment_date ON Pilot_Plane(assignment_date);

-- ==========================================================
-- ADD DEFAULT VALUES FOR BETTER DATA CONSISTENCY
-- ==========================================================

-- Set default values for new columns
ALTER TABLE Warehouse 
ALTER COLUMN last_inventory_check SET DEFAULT CURRENT_DATE,
ALTER COLUMN utilization_percentage SET DEFAULT 0.0,
ALTER COLUMN status_notes SET DEFAULT 'Normal';

-- Set default values for Part categories
UPDATE Part SET category = 'Aircraft Component' WHERE category IS NULL;
UPDATE Part SET critical_stock_level = 10 WHERE critical_stock_level IS NULL;
UPDATE Part SET reorder_point = 20 WHERE reorder_point IS NULL;

-- Set default values for employee performance
UPDATE employee SET performance_rating = 5.0 WHERE performance_rating IS NULL;
UPDATE employee SET certification_level = 'Standard' WHERE certification_level IS NULL;

-- ==========================================================
-- CREATE VIEWS FOR COMMON QUERIES
-- ==========================================================

-- View for warehouse utilization monitoring
CREATE OR REPLACE VIEW warehouse_utilization_view AS
SELECT 
    w.warehouse_id,
    w.location,
    w.capacity,
    w.utilization_percentage,
    w.status_notes,
    COUNT(wp.part_id) as part_types_count,
    SUM(wp.wQuantity) as total_items,
    w.last_inventory_check,
    CASE 
        WHEN w.utilization_percentage > 90 THEN 'Critical'
        WHEN w.utilization_percentage > 75 THEN 'High'
        WHEN w.utilization_percentage < 30 THEN 'Under-utilized'
        ELSE 'Normal'
    END as utilization_status
FROM Warehouse w
LEFT JOIN WarehouseParts wp ON w.warehouse_id = wp.warehouse_id
GROUP BY w.warehouse_id, w.location, w.capacity, w.utilization_percentage, 
         w.status_notes, w.last_inventory_check;

-- View for maintenance performance tracking
CREATE OR REPLACE VIEW maintenance_performance_view AS
SELECT 
    p.plane_id,
    p.model,
    p.status,
    o.name as operator_name,
    COUNT(mr.maintenance_id) as total_maintenance_count,
    SUM(mr.cost) as total_maintenance_cost,
    AVG(mr.cost) as avg_maintenance_cost,
    MAX(mr.maintenance_date) as last_maintenance_date,
    SUM(CASE WHEN mr.completed = TRUE THEN 1 ELSE 0 END) as completed_maintenance,
    SUM(CASE WHEN mr.completed = FALSE THEN 1 ELSE 0 END) as pending_maintenance
FROM Plane p
JOIN Operator o ON p.operator_id = o.operator_id
LEFT JOIN Maintenance_Record mr ON p.plane_id = mr.plane_id
GROUP BY p.plane_id, p.model, p.status, o.name;

-- ==========================================================
-- UPDATE EXISTING DATA FOR CONSISTENCY
-- ==========================================================

-- Update existing warehouse utilization
UPDATE Warehouse w
SET utilization_percentage = (
    SELECT COALESCE((SUM(wp.wQuantity) * 100.0) / w.capacity, 0)
    FROM WarehouseParts wp 
    WHERE wp.warehouse_id = w.warehouse_id
)
WHERE capacity > 0;

-- Update status notes based on utilization
UPDATE Warehouse 
SET status_notes = CASE 
    WHEN utilization_percentage > 90 THEN 'Critical - Overloaded'
    WHEN utilization_percentage > 75 THEN 'High Utilization'
    WHEN utilization_percentage < 30 THEN 'Under-utilized'
    ELSE 'Normal'
END
WHERE utilization_percentage IS NOT NULL;

-- ==========================================================
-- GRANTS AND PERMISSIONS (if needed)
-- ==========================================================

-- Grant necessary permissions for the application user
-- GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO application_user;
-- GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO application_user;

-- ==========================================================
-- FINAL NOTES AND VALIDATION
-- ==========================================================

-- Validate all foreign key constraints are working
-- SELECT 
--     tc.table_name, 
--     tc.constraint_name, 
--     tc.constraint_type,
--     kcu.column_name,
--     ccu.table_name AS foreign_table_name,
--     ccu.column_name AS foreign_column_name 
-- FROM information_schema.table_constraints AS tc 
-- JOIN information_schema.key_column_usage AS kcu
--     ON tc.constraint_name = kcu.constraint_name
--     AND tc.table_schema = kcu.table_schema
-- JOIN information_schema.constraint_column_usage AS ccu
--     ON ccu.constraint_name = tc.constraint_name
--     AND ccu.table_schema = tc.table_schema
-- WHERE tc.constraint_type = 'FOREIGN KEY' 
-- AND tc.table_schema = 'public'
-- ORDER BY tc.table_name;

-- Check all new tables were created successfully
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name LIKE '%log%' 
OR table_name LIKE '%queue%' 
OR table_name LIKE '%action%'
ORDER BY table_name;

-- Final message
SELECT 'Stage 4 database modifications completed successfully!' as status;