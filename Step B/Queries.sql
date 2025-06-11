-- ========== 8 SELECT QUERIES (Non-trivial, complex) ==========

-- Query 1: Show all planes with their operator, hangar, and producer details
-- Including age calculation and production year/month breakdown
SELECT 
    p.Plane_id,
    p.Model,
    p.Status,
    p.Capacity as Plane_Capacity,
    YEAR(p.ProductionDate) as Production_Year,
    MONTH(p.ProductionDate) as Production_Month,
    DAY(p.ProductionDate) as Production_Day,
    DATEDIFF(CURDATE(), p.ProductionDate) / 365 as Age_Years,
    o.Name as Operator_Name,
    o.Type as Operator_Type,
    h.Name as Hangar_Name,
    h.Location as Hangar_Location,
    pr.Pname as Producer_Name,
    pr.Owner as Producer_Owner
FROM Plane p
JOIN Operator o ON p.Operator_id = o.Operator_id
JOIN Hangar h ON p.Hangar_id = h.Hangar_id
JOIN Producer pr ON p.Producer_id = pr.Producer_id
ORDER BY p.ProductionDate DESC;

-- Query 2: Find operators with their hub details and fleet statistics
-- Including planes count and average plane capacity
SELECT 
    o.Operator_id,
    o.Name as Operator_Name,
    o.Type,
    o.Fleet_Size,
    hub.Name as Hub_Name,
    hub.Location as Hub_Location,
    hub.IATA_code,
    hub.Capacity as Hub_Capacity,
    COUNT(p.Plane_id) as Actual_Planes_Count,
    AVG(p.Capacity) as Avg_Plane_Capacity,
    SUM(p.Capacity) as Total_Passenger_Capacity
FROM Operator o
JOIN Hub hub ON o.Hub_id = hub.Hub_id
LEFT JOIN Plane p ON o.Operator_id = p.Operator_id
GROUP BY o.Operator_id, o.Name, o.Type, o.Fleet_Size, hub.Name, hub.Location, hub.IATA_code, hub.Capacity
ORDER BY Total_Passenger_Capacity DESC;

-- Query 3: Pilot assignments with detailed information and experience analysis
-- Including assignment duration and pilot experience levels
SELECT 
    pilot.Name as Pilot_Name,
    pilot.Rank,
    pilot.Experience,
    pilot.License_num,
    CASE 
        WHEN pilot.Experience >= 10 THEN 'Senior'
        WHEN pilot.Experience >= 5 THEN 'Experienced'
        ELSE 'Junior'
    END as Experience_Level,
    p.Model as Plane_Model,
    p.Status as Plane_Status,
    pp.Assignment_date,
    YEAR(pp.Assignment_date) as Assignment_Year,
    DATEDIFF(CURDATE(), pp.Assignment_date) as Days_Since_Assignment,
    o.Name as Operator_Name
FROM Pilot pilot
JOIN Pilot_Plane pp ON pilot.Pilot_id = pp.Pilot_id
JOIN Plane p ON pp.Plane_id = p.Plane_id
JOIN Operator o ON pilot.Operator_id = o.Operator_id
WHERE pp.Assignment_date >= '2020-01-01'
ORDER BY pilot.Experience DESC, pp.Assignment_date DESC;

-- Query 4: Planes by producer with age and status analysis
-- Including production timeline and operational statistics
SELECT 
    pr.Pname as Producer_Name,
    pr.Owner,
    YEAR(pr.EstDate) as Established_Year,
    COUNT(p.Plane_id) as Total_Planes,
    COUNT(CASE WHEN p.Status = 'Operational' THEN 1 END) as Operational_Planes,
    COUNT(CASE WHEN p.Status = 'In Maintenance' THEN 1 END) as Maintenance_Planes,
    AVG(DATEDIFF(CURDATE(), p.ProductionDate) / 365) as Avg_Plane_Age,
    MIN(p.ProductionDate) as Oldest_Plane_Date,
    MAX(p.ProductionDate) as Newest_Plane_Date,
    AVG(p.MaxAltitude) as Avg_Max_Altitude,
    AVG(p.MaxDistance) as Avg_Max_Distance
FROM Producer pr
LEFT JOIN Plane p ON pr.Producer_id = p.Producer_id
GROUP BY pr.Producer_id, pr.Pname, pr.Owner, pr.EstDate
ORDER BY Total_Planes DESC;

-- Query 5: Monthly production analysis with seasonal trends
SELECT 
    YEAR(p.ProductionDate) as Production_Year,
    MONTH(p.ProductionDate) as Production_Month,
    MONTHNAME(p.ProductionDate) as Month_Name,
    COUNT(*) as Planes_Produced,
    AVG(p.Capacity) as Avg_Capacity,
    GROUP_CONCAT(DISTINCT pr.Pname ORDER BY pr.Pname) as Producers,
    GROUP_CONCAT(p.Model ORDER BY p.Model) as Models_Produced
FROM Plane p
JOIN Producer pr ON p.Producer_id = pr.Producer_id
GROUP BY YEAR(p.ProductionDate), MONTH(p.ProductionDate), MONTHNAME(p.ProductionDate)
HAVING COUNT(*) >= 1
ORDER BY Production_Year DESC, Production_Month DESC;

-- Query 6: Hub utilization and operator distribution analysis
SELECT 
    h.Hub_id,
    h.Name as Hub_Name,
    h.Location,
    h.IATA_code,
    h.Capacity as Hub_Capacity,
    COUNT(DISTINCT o.Operator_id) as Number_of_Operators,
    COUNT(DISTINCT p.Plane_id) as Total_Planes,
    SUM(o.Fleet_Size) as Total_Fleet_Size,
    AVG(pilot.Experience) as Avg_Pilot_Experience,
    GROUP_CONCAT(DISTINCT o.Type) as Operator_Types
FROM Hub h
LEFT JOIN Operator o ON h.Hub_id = o.Hub_id
LEFT JOIN Plane p ON o.Operator_id = p.Operator_id
LEFT JOIN Pilot pilot ON o.Operator_id = pilot.Operator_id
GROUP BY h.Hub_id, h.Name, h.Location, h.IATA_code, h.Capacity
ORDER BY Total_Planes DESC;

-- Query 7: Complex assignment history with time-based analysis
SELECT 
    YEAR(pp.Assignment_date) as Assignment_Year,
    QUARTER(pp.Assignment_date) as Assignment_Quarter,
    COUNT(*) as Total_Assignments,
    COUNT(DISTINCT pp.Pilot_id) as Unique_Pilots,
    COUNT(DISTINCT pp.Plane_id) as Unique_Planes,
    AVG(pilot.Experience) as Avg_Pilot_Experience,
    GROUP_CONCAT(DISTINCT pilot.Rank) as Pilot_Ranks,
    GROUP_CONCAT(DISTINCT p.Status) as Plane_Statuses
FROM Pilot_Plane pp
JOIN Pilot pilot ON pp.Pilot_id = pilot.Pilot_id
JOIN Plane p ON pp.Plane_id = p.Plane_id
WHERE pp.Assignment_date BETWEEN '2020-01-01' AND CURDATE()
GROUP BY YEAR(pp.Assignment_date), QUARTER(pp.Assignment_date)
ORDER BY Assignment_Year DESC, Assignment_Quarter DESC;

-- Query 8: Comprehensive fleet analysis by operator type
SELECT 
    o.Type as Operator_Type,
    COUNT(DISTINCT o.Operator_id) as Number_of_Operators,
    COUNT(DISTINCT p.Plane_id) as Total_Planes,
    COUNT(DISTINCT pilot.Pilot_id) as Total_Pilots,
    AVG(p.Capacity) as Avg_Plane_Capacity,
    AVG(p.MaxAltitude) as Avg_Max_Altitude,
    AVG(pilot.Experience) as Avg_Pilot_Experience,
    SUM(CASE WHEN p.Status = 'Operational' THEN 1 ELSE 0 END) as Operational_Count,
    GROUP_CONCAT(DISTINCT h.IATA_code) as Hub_Codes,
    ROUND(AVG(DATEDIFF(CURDATE(), p.ProductionDate) / 365), 2) as Avg_Fleet_Age
FROM Operator o
LEFT JOIN Plane p ON o.Operator_id = p.Operator_id
LEFT JOIN Pilot pilot ON o.Operator_id = pilot.Operator_id
LEFT JOIN Hub h ON o.Hub_id = h.Hub_id
GROUP BY o.Type
ORDER BY Total_Planes DESC;

-- ========== 3 DELETE QUERIES ==========

-- Delete Query 1: Remove pilot assignments older than 3 years
DELETE FROM Pilot_Plane 
WHERE Assignment_date < DATE_SUB(CURDATE(), INTERVAL 3 YEAR);

-- Delete Query 2: Remove planes that are in maintenance and older than 10 years
DELETE FROM Plane 
WHERE Status = 'In Maintenance' 
AND DATEDIFF(CURDATE(), ProductionDate) / 365 > 10;

-- Delete Query 3: Remove operators with no planes assigned
DELETE FROM Operator 
WHERE Operator_id NOT IN (
    SELECT DISTINCT Operator_id 
    FROM Plane 
    WHERE Operator_id IS NOT NULL
);

-- ========== 3 UPDATE QUERIES ==========

-- Update Query 1: Update plane status based on age
UPDATE Plane 
SET Status = 'Retired'
WHERE DATEDIFF(CURDATE(), ProductionDate) / 365 > 15 
AND Status != 'Retired';

-- Update Query 2: Increase experience for pilots with recent assignments
UPDATE Pilot 
SET Experience = Experience + 1
WHERE Pilot_id IN (
    SELECT DISTINCT Pilot_id 
    FROM Pilot_Plane 
    WHERE Assignment_date >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
);

-- Update Query 3: Update operator fleet size based on actual plane count
UPDATE Operator o
SET Fleet_Size = (
    SELECT COUNT(*) 
    FROM Plane p 
    WHERE p.Operator_id = o.Operator_id
)
WHERE EXISTS (
    SELECT 1 
    FROM Plane p 
    WHERE p.Operator_id = o.Operator_id
);
