-- ========== ROLLBACK EXAMPLE ==========

-- Step 1: Show current state of database
SELECT 'BEFORE UPDATE - Pilot Table' as Status;
SELECT * FROM Pilot;

SELECT 'BEFORE UPDATE - Plane Table' as Status;  
SELECT Plane_id, Model, Status FROM Plane;

-- Step 2: Start transaction and make updates
START TRANSACTION;

-- Update pilot experience
UPDATE Pilot SET Experience = Experience + 5 WHERE Pilot_id = 1;

-- Update plane status
UPDATE Plane SET Status = 'Retired' WHERE Plane_id = 1;

-- Add new pilot
INSERT INTO Pilot VALUES (10, 'Test Pilot Rollback', 'TR12345', 'Captain', 15, 1);

-- Step 3: Show database state after updates
SELECT 'AFTER UPDATE - Before Rollback - Pilot Table' as Status;
SELECT * FROM Pilot;

SELECT 'AFTER UPDATE - Before Rollback - Plane Table' as Status;
SELECT Plane_id, Model, Status FROM Plane;

-- Step 4: Execute ROLLBACK
ROLLBACK;

-- Step 5: Show database state after rollback (should be same as original)
SELECT 'AFTER ROLLBACK - Pilot Table' as Status;
SELECT * FROM Pilot;

SELECT 'AFTER ROLLBACK - Plane Table' as Status;
SELECT Plane_id, Model, Status FROM Plane;

-- ========== COMMIT EXAMPLE ==========

-- Step 1: Show current state of database
SELECT 'BEFORE UPDATE - Hub Table' as Status;
SELECT * FROM Hub;

SELECT 'BEFORE UPDATE - Operator Table' as Status;
SELECT Operator_id, Name, Fleet_Size FROM Operator;

-- Step 2: Start transaction and make updates
START TRANSACTION;

-- Update hub capacity
UPDATE Hub SET Capacity = Capacity + 50 WHERE Hub_id = 1;

-- Update operator fleet size
UPDATE Operator SET Fleet_Size = Fleet_Size + 10 WHERE Operator_id = 1;

-- Add new hub
INSERT INTO Hub VALUES (10, 'Test Hub Commit', 'Test Location', 'TST', 150);

-- Step 3: Show database state after updates
SELECT 'AFTER UPDATE - Before Commit - Hub Table' as Status;
SELECT * FROM Hub;

SELECT 'AFTER UPDATE - Before Commit - Operator Table' as Status;
SELECT Operator_id, Name, Fleet_Size FROM Operator;

-- Step 4: Execute COMMIT
COMMIT;

-- Step 5: Show database state after commit (changes should be permanent)
SELECT 'AFTER COMMIT - Hub Table' as Status;
SELECT * FROM Hub;

SELECT 'AFTER COMMIT - Operator Table' as Status;
SELECT Operator_id, Name, Fleet_Size FROM Operator;

-- ========== DEMONSTRATION OF TRANSACTION ISOLATION ==========

-- This section shows how transactions work with multiple operations

-- Transaction 1: Multiple related updates
START TRANSACTION;
UPDATE Pilot SET Rank = 'Senior Captain' WHERE Experience > 10;
UPDATE Plane SET Status = 'Operational' WHERE Status = 'In Maintenance' AND DATEDIFF(CURDATE(), ProductionDate) / 365 < 5;
-- At this point, changes are visible within this transaction but not to others
SELECT 'During Transaction - Updated Records' as Status;
SELECT COUNT(*) as Updated_Pilots FROM Pilot WHERE Rank = 'Senior Captain';
SELECT COUNT(*) as Updated_Planes FROM Plane WHERE Status = 'Operational';
COMMIT;

-- Verify final state
SELECT 'Final State After Commit' as Status;
SELECT Rank, COUNT(*) as Count FROM Pilot GROUP BY Rank;
SELECT Status, COUNT(*) as Count FROM Plane GROUP BY Status;
