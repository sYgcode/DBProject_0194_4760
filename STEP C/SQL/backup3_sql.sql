-- ========== BACKUP3.SQL - COMPLETE INTEGRATED SYSTEM ==========
-- Full backup of integrated Plane/Hangar + Warehouse system
-- Date: Stage C Integration Backup

-- ========== DROP EXISTING TABLES ==========
DROP TABLE IF EXISTS Aviation_Operations_View;
DROP TABLE IF EXISTS Warehouse_Supply_Chain_View;
DROP TABLE IF EXISTS Maintenance_Record;
DROP TABLE IF EXISTS Aircraft_Parts;
DROP TABLE IF EXISTS Unified_Location;
DROP TABLE IF EXISTS CostumerWarehousStorage;
DROP TABLE IF EXISTS myorder;
DROP TABLE IF EXISTS SupplierParts;
DROP TABLE IF EXISTS WarehouseParts;
DROP TABLE IF EXISTS WorksAt;
DROP TABLE IF EXISTS Train;
DROP TABLE IF EXISTS Pilot_Plane;
DROP TABLE IF EXISTS Pilot;
DROP TABLE IF EXISTS Plane;
DROP TABLE IF EXISTS Operator;
DROP TABLE IF EXISTS Hub;
DROP TABLE IF EXISTS Producer;
DROP TABLE IF EXISTS Hangar;
DROP TABLE IF EXISTS Costumer;
DROP TABLE IF EXISTS supplier;
DROP TABLE IF EXISTS Warehouse;
DROP TABLE IF EXISTS employee;
DROP TABLE IF EXISTS Part;

-- ========== CREATE AVIATION SYSTEM TABLES ==========

-- Hangar Table (Enhanced with warehouse_id)
CREATE TABLE Hangar (
  Hangar_id INT PRIMARY KEY,
  Location VARCHAR(80) NOT NULL,
  Name VARCHAR(50) NOT NULL,
  warehouse_id INT
);

-- Producer Table
CREATE TABLE Producer (
  Producer_id INT PRIMARY KEY,
  Pname VARCHAR(50) NOT NULL,
  EstDate DATE NOT NULL,
  Owner VARCHAR(50) NOT NULL
);

-- Hub Table
CREATE TABLE Hub (
  Hub_id INT PRIMARY KEY,
  Name VARCHAR(50) NOT NULL,
  Location VARCHAR(80) NOT NULL,
  IATA_code VARCHAR(10) NOT NULL,
  Capacity INT NOT NULL
);

-- ========== CREATE WAREHOUSE SYSTEM TABLES ==========

-- Part Table
CREATE TABLE Part (
  part_id INT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  last_update DATE NOT NULL
);

-- Employee Table
CREATE TABLE employee (
  employee_id INT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  role VARCHAR(50) NOT NULL,
  start_date DATE NOT NULL,
  last_training DATE NOT NULL
);

-- Warehouse Table
CREATE TABLE Warehouse (
  warehouse_id INT PRIMARY KEY,
  location VARCHAR(100) NOT NULL,
  capacity INT NOT NULL,
  open_date DATE NOT NULL
);

-- Supplier Table
CREATE TABLE supplier (
  supplier_id INT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  phone VARCHAR(20) NOT NULL
);

-- Customer Table
CREATE TABLE Costumer (
  costumer_id INT PRIMARY KEY,
  phone VARCHAR(20) NOT NULL,
  email VARCHAR(100) NOT NULL,
  registration_date DATE NOT NULL
);

-- ========== CREATE DEPENDENT TABLES ==========

-- Operator Table
CREATE TABLE Operator (
  Operator_id INT PRIMARY KEY,
  Name VARCHAR(50) NOT NULL,
  Type VARCHAR(30) NOT NULL,
  Fleet_Size INT NOT NULL,
  Hub_id INT NOT NULL,
  FOREIGN KEY (Hub_id) REFERENCES Hub(Hub_id)
);

-- Plane Table (Enhanced with foreign keys)
CREATE TABLE Plane (
  Plane_id INT PRIMARY KEY,
  Model VARCHAR(25) NOT NULL,
  ProductionDate DATE NOT NULL,
  Capacity INT NOT NULL,
  MaxAltitude INT NOT NULL,
  MaxDistance INT NOT NULL,
  Status VARCHAR(30) NOT NULL,
  Producer_id INT NOT NULL,
  Hangar_id INT NOT NULL,
  Operator_id INT NOT NULL,
  FOREIGN KEY (Producer_id) REFERENCES Producer(Producer_id),
  FOREIGN KEY (Hangar_id) REFERENCES Hangar(Hangar_id),
  FOREIGN KEY (Operator_id) REFERENCES Operator(Operator_id)
);

-- Pilot Table (Enhanced with employee_id)
CREATE TABLE Pilot (
  Pilot_id INT PRIMARY KEY,
  Name VARCHAR(50) NOT NULL,
  License_num VARCHAR(30) NOT NULL,
  Rank VARCHAR(20) NOT NULL,
  Experience INT NOT NULL,
  Operator_id INT NOT NULL,
  employee_id INT,
  FOREIGN KEY (Operator_id) REFERENCES Operator(Operator_id),
  FOREIGN KEY (employee_id) REFERENCES employee(employee_id)
);

-- Add warehouse foreign key to Hangar
ALTER TABLE Hangar 
ADD FOREIGN KEY (warehouse_id) REFERENCES Warehouse(warehouse_id);

-- ========== CREATE RELATIONSHIP TABLES ==========

-- Pilot_Plane Table
CREATE TABLE Pilot_Plane (
  Assignment_date DATE NOT NULL,
  Plane_id INT NOT NULL,
  Pilot_id INT NOT NULL,
  PRIMARY KEY (Plane_id, Pilot_id),
  FOREIGN KEY (Plane_id) REFERENCES Plane(Plane_id),
  FOREIGN KEY (Pilot_id) REFERENCES Pilot(Pilot_id)
);

-- Train Table
CREATE TABLE Train (
  train_id INT PRIMARY KEY,
  model VARCHAR(50) NOT NULL,
  year INT NOT NULL,
  last_check DATE NOT NULL,
  next_check DATE NOT NULL,
  warehouse_id INT NOT NULL,
  FOREIGN KEY (warehouse_id) REFERENCES Warehouse(warehouse_id)
);

-- WorksAt Table
CREATE TABLE WorksAt (
  warehouse_id INT NOT NULL,
  employee_id INT NOT NULL,
  PRIMARY KEY (warehouse_id, employee_id),
  FOREIGN KEY (warehouse_id) REFERENCES Warehouse(warehouse_id),
  FOREIGN KEY (employee_id) REFERENCES employee(employee_id)
);

-- WarehouseParts Table
CREATE TABLE WarehouseParts (
  wQuantity INT NOT NULL,
  last_updated DATE NOT NULL,
  part_id INT NOT NULL,
  warehouse_id INT NOT NULL,
  PRIMARY KEY (part_id, warehouse_id),
  FOREIGN KEY (part_id) REFERENCES Part(part_id),
  FOREIGN KEY (warehouse_id) REFERENCES Warehouse(warehouse_id)
);

-- SupplierParts Table
CREATE TABLE SupplierParts (
  price DECIMAL(10,2) NOT NULL,
  sQuantity INT NOT NULL,
  supplier_id INT NOT NULL,
  part_id INT NOT NULL,
  PRIMARY KEY (supplier_id, part_id),
  FOREIGN KEY (supplier_id) REFERENCES supplier(supplier_id),
  FOREIGN KEY (part_id) REFERENCES Part(part_id)
);

-- Order Table
CREATE TABLE myorder (
  order_id INT PRIMARY KEY,
  amount INT NOT NULL,
  order_date DATE NOT NULL,
  arrival_date DATE NOT NULL,
  part_id INT NOT NULL,
  supplier_id INT NOT NULL,
  warehouse_id INT NOT NULL,
  FOREIGN KEY (part_id) REFERENCES Part(part_id),
  FOREIGN KEY (supplier_id) REFERENCES supplier(supplier_id),
  FOREIGN KEY (warehouse_id) REFERENCES Warehouse(warehouse_id)
);

-- Customer Warehouse Storage Table
CREATE TABLE CostumerWarehousStorage (
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  warehouse_id INT NOT NULL,
  costumer_id INT NOT NULL,
  PRIMARY KEY (warehouse_id, costumer_id),
  FOREIGN KEY (warehouse_id) REFERENCES Warehouse(warehouse_id),
  FOREIGN KEY (costumer_id) REFERENCES Costumer(costumer_id)
);

-- ========== CREATE INTEGRATION TABLES ==========

-- Aircraft Parts Bridge Table
CREATE TABLE Aircraft_Parts (
  aircraft_part_id INT PRIMARY KEY AUTO_INCREMENT,
  plane_id INT NOT NULL,
  part_id INT NOT NULL,
  quantity_used INT NOT NULL,
  installation_date DATE NOT NULL,
  next_maintenance_date DATE,
  status VARCHAR(30) DEFAULT 'Active',
  FOREIGN KEY (plane_id) REFERENCES Plane(Plane_id),
  FOREIGN KEY (part_id) REFERENCES Part(part_id)
);

-- Maintenance Record Table
CREATE TABLE Maintenance_Record (
  maintenance_id INT PRIMARY KEY AUTO_INCREMENT,
  plane_id INT NOT NULL,
  employee_id INT NOT NULL,
  warehouse_id INT NOT NULL,
  maintenance_date DATE NOT NULL,
  maintenance_type VARCHAR(50) NOT NULL,
  cost DECIMAL(10,2),
  description TEXT,
  completed BOOLEAN DEFAULT FALSE,
  FOREIGN KEY (plane_id) REFERENCES Plane(Plane_id),
  FOREIGN KEY (employee_id) REFERENCES employee(employee_id),
  FOREIGN KEY (warehouse_id) REFERENCES Warehouse(warehouse_id)
);

-- Unified Location Table
CREATE TABLE Unified_Location (
  location_id INT PRIMARY KEY AUTO_INCREMENT,
  location_name VARCHAR(100) NOT NULL,
  city VARCHAR(50) NOT NULL,
  country VARCHAR(50) NOT NULL,
  location_type VARCHAR(30) NOT NULL
);

-- ========== INSERT BASE DATA ==========

-- Warehouse System Data
INSERT INTO Part (part_id, name, last_update) VALUES
(1, 'Brake Pad', '2025-01-01'),
(2, 'Engine Valve', '2025-02-15');

INSERT INTO employee (employee_id, name, role, start_date, last_training) VALUES
(1, 'Alice Cohen', 'Technician', '2023-06-01', '2024-12-01'),
(2, 'Bob Levy', 'Manager', '2022-04-15', '2024-11-10');

INSERT INTO Warehouse (warehouse_id, location, capacity, open_date) VALUES
(1, 'Haifa', 1000, '2020-01-01'),
(2, 'Tel Aviv', 800, '2021-03-10');

INSERT INTO supplier (supplier_id, name, phone) VALUES
(1, 'TrainSupplies Ltd.', '03-1234567'),
(2, 'Global Parts Inc.', '03-7654321');

INSERT INTO Costumer (costumer_id, phone, email, registration_date) VALUES
(1, '050-1111111', 'john@example.com', '2023-05-20'),
(2, '050-2222222', 'sara@example.com', '2023-08-30');

-- Aviation System Data
INSERT INTO Hangar VALUES (1, 'Los Angeles International Airport', 'Hangar A', 1);
INSERT INTO Hangar VALUES (2, 'JFK International Airport', 'Hangar B', 2);
INSERT INTO Hangar VALUES (3, 'Heathrow Airport', 'Hangar C', NULL);

INSERT INTO Producer VALUES (1, 'Boeing', '1916-07-15', 'Boeing Company');
INSERT INTO Producer VALUES (2, 'Airbus', '1970-12-18', 'Airbus Group');
INSERT INTO Producer VALUES (3, 'Embraer', '1969-08-19', 'Embraer S.A.');

INSERT INTO Hub VALUES (1, 'LAX Hub', 'Los Angeles', 'LAX', 200);
INSERT INTO Hub VALUES (2, 'JFK Hub', 'New York', 'JFK', 180);
INSERT INTO Hub VALUES (3, 'Heathrow Hub', 'London', 'LHR', 250);

INSERT INTO Operator VALUES (1, 'Delta Airlines', 'Commercial', 150, 2);
INSERT INTO Operator VALUES (2, 'British Airways', 'Commercial', 100, 3);
INSERT INTO Operator VALUES (3, 'FedEx', 'Cargo', 75, 1);

INSERT INTO Plane VALUES (1, '737 MAX', '2019-03-01', 210, 41000, 3550, 'Operational', 1, 1, 1);
INSERT INTO Plane VALUES (2, 'A320neo', '2020-07-10', 180, 39000, 3400, 'Operational', 2, 2, 2);
INSERT INTO Plane VALUES (3, 'E195-E2', '2021-11-25', 132, 41000, 2800, 'In Maintenance', 3, 3, 3);

INSERT INTO Pilot VALUES (1, 'Alice Johnson', 'D12345', 'Captain', 12, 1, 1);
INSERT INTO Pilot VALUES (2, 'James Smith', 'B98765', 'First Officer', 5, 2, 2);
INSERT INTO Pilot VALUES (3, 'Sarah Lee', 'F67890', 'Captain', 8, 3, NULL);

INSERT INTO Pilot_Plane VALUES ('2022-01-15', 1, 1);
INSERT INTO Pilot_Plane VALUES ('2023-03-22', 2, 2);
INSERT INTO Pilot_Plane VALUES ('2024-06-05', 3, 3);

-- Warehouse Relationship Data
INSERT INTO WorksAt (warehouse_id, employee_id) VALUES (1, 1), (2, 2);

INSERT INTO WarehouseParts (wQuantity, last_updated, part_id, warehouse_id) VALUES
(100, '2025-04-01', 1, 1),
(50, '2025-03-15', 2, 2);

INSERT INTO SupplierParts (price, sQuantity, supplier_id, part_id) VALUES
(120.50, 300, 1, 1),
(250.00, 150, 2, 2);

INSERT INTO myorder (order_id, amount, order_date, arrival_date, part_id, supplier_id, warehouse_id) VALUES
(1, 50, '2025-04-10', '2025-04-15', 1, 1, 1),
(2, 30, '2025-04-20', '2025-04-25', 2, 2, 2);

INSERT INTO CostumerWarehousStorage VALUES ('2025-01-01', '2025-06-01', 1, 1);
INSERT INTO CostumerWarehousStorage VALUES ('2025-02-01', '2025-07-01', 2, 2);

INSERT INTO Train VALUES (1, 'Model A', 2020, '2025-01-10', '2025-07-10', 1);
INSERT INTO Train VALUES (2, 'Model B', 2021, '2025-02-15', '2025-08-15', 2);

-- ========== INSERT INTEGRATION DATA ==========

INSERT INTO Aircraft_Parts (plane_id, part_id, quantity_used, installation_date, next_maintenance_date, status) VALUES
(1, 1, 4, '2024-01-15', '2024-07-15', 'Active'),
(1, 2, 2, '2024-02-20', '2024-08-20', 'Active'),
(2, 1, 4, '2024-03-10', '2024-09-10', 'Active'),
(3, 2, 1, '2024-04-05', '2024-10-05', 'Needs Replacement');

INSERT INTO Maintenance_Record (plane_id, employee_id, warehouse_id, maintenance_date, maintenance_type, cost, description, completed) VALUES
(1, 1, 1, '2024-01-15', 'Brake Replacement', 2500.00, 'Replaced brake pads on landing gear', TRUE),
(2, 2, 2, '2024-03-20', 'Engine Valve Service', 5200.00, 'Serviced engine valves', TRUE),
(3, 1, 1, '2024-05-10', 'Scheduled Maintenance', 1800.00, 'Routine maintenance check', FALSE);

INSERT INTO Unified_Location (location_name, city, country, location_type) VALUES
('Los Angeles International Airport', 'Los Angeles', 'USA', 'Airport'),
('JFK International Airport', 'New York', 'USA', 'Airport'),
('Heathrow Airport', 'London', 'UK', 'Airport'),
('Haifa Warehouse', 'Haifa', 'Israel', 'Warehouse'),
('Tel Aviv Warehouse', 'Tel Aviv', 'Israel', 'Warehouse');

-- ========== CREATE VIEWS ==========

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
        WHEN EXISTS (SELECT 1 FROM Maintenance_Record mr WHERE mr.plane_id = p.Plane_id AND mr.completed = FALSE) 
        THEN 'Maintenance Pending'
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