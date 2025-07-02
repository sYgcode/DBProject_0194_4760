-- ========== STAGE C: INTEGRATION SCHEMA ==========
-- Integration of Plane/Hangar System with Warehouse System

-- Step 1: Create bridge table to connect aviation and warehouse systems
-- This table links aircraft maintenance with warehouse parts

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

-- Step 2: Enhance existing tables with integration fields

-- Add warehouse reference to Hangar (hangars can have associated warehouses)
ALTER TABLE Hangar 
ADD COLUMN warehouse_id INT,
ADD FOREIGN KEY (warehouse_id) REFERENCES Warehouse(warehouse_id);

-- Add employee reference to Pilot (cross-system employee management)
ALTER TABLE Pilot 
ADD COLUMN employee_id INT,
ADD FOREIGN KEY (employee_id) REFERENCES employee(employee_id);

-- Step 3: Create maintenance tracking table
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

-- Step 4: Create unified location table for better integration
CREATE TABLE Unified_Location (
    location_id INT PRIMARY KEY AUTO_INCREMENT,
    location_name VARCHAR(100) NOT NULL,
    city VARCHAR(50) NOT NULL,
    country VARCHAR(50) NOT NULL,
    location_type VARCHAR(30) NOT NULL -- 'Airport', 'Warehouse', 'Hub'
);

-- Step 5: Insert sample integration data

-- Link some hangars to warehouses
UPDATE Hangar SET warehouse_id = 1 WHERE Hangar_id = 1;
UPDATE Hangar SET warehouse_id = 2 WHERE Hangar_id = 2;

-- Link some pilots to employees (assuming they are also warehouse employees)
UPDATE Pilot SET employee_id = 1 WHERE Pilot_id = 1;
UPDATE Pilot SET employee_id = 2 WHERE Pilot_id = 2;

-- Insert aircraft parts relationships
INSERT INTO Aircraft_Parts (plane_id, part_id, quantity_used, installation_date, next_maintenance_date, status) VALUES
(1, 1, 4, '2024-01-15', '2024-07-15', 'Active'),
(1, 2, 2, '2024-02-20', '2024-08-20', 'Active'),
(2, 1, 4, '2024-03-10', '2024-09-10', 'Active'),
(3, 2, 1, '2024-04-05', '2024-10-05', 'Needs Replacement');

-- Insert maintenance records
INSERT INTO Maintenance_Record (plane_id, employee_id, warehouse_id, maintenance_date, maintenance_type, cost, description, completed) VALUES
(1, 1, 1, '2024-01-15', 'Brake Replacement', 2500.00, 'Replaced brake pads on landing gear', TRUE),
(2, 2, 2, '2024-03-20', 'Engine Valve Service', 5200.00, 'Serviced engine valves', TRUE),
(3, 1, 1, '2024-05-10', 'Scheduled Maintenance', 1800.00, 'Routine maintenance check', FALSE);

-- Insert unified locations
INSERT INTO Unified_Location (location_name, city, country, location_type) VALUES
('Los Angeles International Airport', 'Los Angeles', 'USA', 'Airport'),
('JFK International Airport', 'New York', 'USA', 'Airport'),
('Heathrow Airport', 'London', 'UK', 'Airport'),
('Haifa Warehouse', 'Haifa', 'Israel', 'Warehouse'),
('Tel Aviv Warehouse', 'Tel Aviv', 'Israel', 'Warehouse');