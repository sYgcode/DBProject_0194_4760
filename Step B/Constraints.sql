-- ========== DATABASE CONSTRAINTS ==========

-- Constraint 1: CHECK constraint on Plane table
-- Ensure plane capacity is positive and reasonable
ALTER TABLE Plane 
ADD CONSTRAINT chk_plane_capacity 
CHECK (Capacity > 0 AND Capacity <= 1000);

-- Constraint 2: CHECK constraint on Pilot table  
-- Ensure pilot experience is non-negative and reasonable
ALTER TABLE Pilot 
ADD CONSTRAINT chk_pilot_experience 
CHECK (Experience >= 0 AND Experience <= 50);

-- Constraint 3: DEFAULT constraint on Plane table
-- Set default status for new planes
ALTER TABLE Plane 
ALTER COLUMN Status SET DEFAULT 'In Maintenance';

-- Constraint 4: CHECK constraint on Hub table
-- Ensure hub capacity is positive
ALTER TABLE Hub 
ADD CONSTRAINT chk_hub_capacity 
CHECK (Capacity > 0);

-- Constraint 5: CHECK constraint on Operator table
-- Ensure fleet size is non-negative
ALTER TABLE Operator 
ADD CONSTRAINT chk_fleet_size 
CHECK (Fleet_Size >= 0);

-- Constraint 6: CHECK constraint on Plane table for dates
-- Ensure production date is not in the future
ALTER TABLE Plane 
ADD CONSTRAINT chk_production_date 
CHECK (ProductionDate <= CURDATE());

-- ========== TEST CONSTRAINT VIOLATIONS ==========

-- Test 1: Try to insert plane with invalid capacity (should fail)
-- INSERT INTO Plane VALUES (100, 'Test Model', '2023-01-01', -50, 35000, 3000, 'Operational', 1, 1, 1);

-- Test 2: Try to insert pilot with invalid experience (should fail)  
-- INSERT INTO Pilot VALUES (100, 'Test Pilot', 'T12345', 'Captain', -5, 1);

-- Test 3: Try to insert hub with invalid capacity (should fail)
-- INSERT INTO Hub VALUES (100, 'Test Hub', 'Test Location', 'TST', -100);

-- Test 4: Try to insert plane with future production date (should fail)
-- INSERT INTO Plane VALUES (101, 'Future Model', '2030-01-01', 200, 35000, 3000, 'Operational', 1, 1, 1);

-- Test 5: Try to insert operator with negative fleet size (should fail)
-- INSERT INTO Operator VALUES (100, 'Test Operator', 'Commercial', -10, 1);
