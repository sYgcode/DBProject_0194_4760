-- ========== STAGE C: PERSPECTIVES (VIEWS) ==========

-- ========== PERSPECTIVE 1: AVIATION OPERATIONS VIEW ==========
-- This view provides a comprehensive perspective for aviation operations management
-- Combines plane, pilot, maintenance, and parts information

CREATE VIEW Aviation_Operations_View AS
SELECT 
    p.Plane_id,
    p.Model as Aircraft_Model,
    p.Status as Aircraft_Status,
    p.Capacity as Passenger_Capacity,
    o.Name as Operator_Name,
    o.Type as Operator_Type,
    pilot.Name as Pilot_Name,
    pilot.Rank as Pilot_Rank,
    pilot.Experience as Pilot_Experience,
    h.Name as Hangar_Name,
    h.Location as Hangar_Location,
    w.location as Warehouse_Location,
    w.capacity as Warehouse_Capacity,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM Maintenance_Record mr 
            WHERE mr.plane_id = p.Plane_id AND mr.completed = FALSE
        ) THEN 'Maintenance Pending'
        ELSE 'Operational Ready'
    END as Maintenance_Status,
    COUNT(ap.aircraft_part_id) as Parts_Count
FROM Plane p
JOIN Operator o ON p.Operator_id = o.Operator_id
LEFT JOIN Pilot pilot ON pilot.Operator_id = o.Operator_id
LEFT JOIN Hangar h ON p.Hangar_id = h.Hangar_id
LEFT JOIN Warehouse w ON h.warehouse_id = w.warehouse_id
LEFT JOIN Aircraft_Parts ap ON p.Plane_id = ap.plane_id
GROUP BY p.Plane_id, p.Model, p.Status, p.Capacity, o.Name, o.Type, 
         pilot.Name, pilot.Rank, pilot.Experience, h.Name, h.Location, 
         w.location, w.capacity;

-- ========== PERSPECTIVE 2: WAREHOUSE SUPPLY CHAIN VIEW ==========
-- This view provides a comprehensive perspective for warehouse and supply chain management
-- Combines warehouse, parts, suppliers, and maintenance service information

CREATE VIEW Warehouse_Supply_Chain_View AS
SELECT 
    w.warehouse_id,
    w.location as Warehouse_Location,
    w.capacity as Warehouse_Capacity,
    w.open_date,
    emp.name as Employee_Name,
    emp.role as Employee_Role,
    p.name as Part_Name,
    wp.wQuantity as Stock_Quantity,
    wp.last_updated as Last_Stock_Update,
    s.name as Supplier_Name,
    sp.price as Part_Price,
    sp.sQuantity as Supplier_Stock,
    COUNT(mr.maintenance_id) as Maintenance_Services_Count,
    SUM(mr.cost) as Total_Maintenance_Revenue
FROM Warehouse w
LEFT JOIN WorksAt wa ON w.warehouse_id = wa.warehouse_id
LEFT JOIN employee emp ON wa.employee_id = emp.employee_id
LEFT JOIN WarehouseParts wp ON w.warehouse_id = wp.warehouse_id
LEFT JOIN Part p ON wp.part_id = p.part_id
LEFT JOIN SupplierParts sp ON p.part_id = sp.part_id
LEFT JOIN supplier s ON sp.supplier_id = s.supplier_id
LEFT JOIN Maintenance_Record mr ON w.warehouse_id = mr.warehouse_id
GROUP BY w.warehouse_id, w.location, w.capacity, w.open_date, 
         emp.name, emp.role, p.name, wp.wQuantity, wp.last_updated, 
         s.name, sp.price, sp.sQuantity;

-- ========== QUERIES ON AVIATION OPERATIONS VIEW ==========

-- Query 1: Find all aircraft with pending maintenance and their associated warehouse details
SELECT 
    Aircraft_Model,
    Operator_Name,
    Pilot_Name,
    Hangar_Location,
    Warehouse_Location,
    Maintenance_Status,
    Parts_Count
FROM Aviation_Operations_View 
WHERE Maintenance_Status = 'Maintenance Pending'
ORDER BY Operator_Name, Aircraft_Model;

-- Query 2: Get operational statistics by operator type
SELECT 
    Operator_Type,
    COUNT(DISTINCT Plane_id) as Total_Aircraft,
    AVG(Passenger_Capacity) as Avg_Capacity,
    AVG(Pilot_Experience) as Avg_Pilot_Experience,
    COUNT(DISTINCT Warehouse_Location) as Warehouse_Locations_Used
FROM Aviation_Operations_View 
WHERE Aircraft_Status = 'Operational'
GROUP BY Operator_Type
ORDER BY Total_Aircraft DESC;

-- ========== QUERIES ON WAREHOUSE SUPPLY CHAIN VIEW ==========

-- Query 1: Analyze warehouse efficiency and maintenance service revenue
SELECT 
    Warehouse_Location,
    COUNT(DISTINCT Employee_Name) as Employee_Count,
    COUNT(DISTINCT Part_Name) as Parts_Variety,
    SUM(Stock_Quantity) as Total_Stock,
    Maintenance_Services_Count,
    COALESCE(Total_Maintenance_Revenue, 0) as Revenue
FROM Warehouse_Supply_Chain_View 
GROUP BY Warehouse_Location, Maintenance_Services_Count, Total_Maintenance_Revenue
ORDER BY Revenue DESC;

-- Query 2: Find suppliers and parts with inventory management insights
SELECT 
    Supplier_Name,
    Part_Name,
    Part_Price,
    Supplier_Stock,
    SUM(Stock_Quantity) as Total_Warehouse_Stock,
    COUNT(DISTINCT Warehouse_Location) as Warehouses_Stocking,
    CASE 
        WHEN SUM(Stock_Quantity) < 50 THEN 'Low Stock'
        WHEN SUM(Stock_Quantity) < 100 THEN 'Medium Stock' 
        ELSE 'High Stock'
    END as Stock_Level
FROM Warehouse_Supply_Chain_View 
WHERE Part_Name IS NOT NULL
GROUP BY Supplier_Name, Part_Name, Part_Price, Supplier_Stock
ORDER BY Part_Price DESC;

-- ========== SAMPLE DATA RETRIEVAL FROM VIEWS ==========

-- Display sample records from Aviation Operations View
SELECT 'Aviation Operations View Sample:' as Description;
SELECT * FROM Aviation_Operations_View LIMIT 10;

-- Display sample records from Warehouse Supply Chain View  
SELECT 'Warehouse Supply Chain View Sample:' as Description;
SELECT * FROM Warehouse_Supply_Chain_View LIMIT 10;