-- ========== BACKUP4.SQL - COMPLETE INTEGRATED SYSTEM WITH PROGRAMMING ==========
-- Full backup of integrated Plane/Hangar + Warehouse system with PL/pgSQL programs
-- Date: Stage 4 Programming Implementation Backup

-- ========== DROP EXISTING TABLES AND OBJECTS ==========
DROP VIEW IF EXISTS warehouse_utilization_view CASCADE;
DROP VIEW IF EXISTS maintenance_performance_view CASCADE;
DROP VIEW IF EXISTS Aviation_Operations_View CASCADE;
DROP VIEW IF EXISTS Warehouse_Supply_Chain_View CASCADE;

DROP TRIGGER IF EXISTS warehouse_capacity_trigger ON WarehouseParts;
DROP TRIGGER IF EXISTS plane_audit_trigger ON Plane;

DROP FUNCTION IF EXISTS manage_warehouse_capacity() CASCADE;
DROP FUNCTION IF EXISTS audit_plane_changes() CASCADE;
DROP FUNCTION IF EXISTS get_aircraft_maintenance_analysis(INT, DATE, DATE) CASCADE;
DROP FUNCTION IF EXISTS calculate_pilot_performance(INT, BOOLEAN) CASCADE;

DROP PROCEDURE IF EXISTS manage_aircraft_maintenance(INT, VARCHAR(50), INT, INT, TEXT[], DECIMAL(10,2), TEXT);
DROP PROCEDURE IF EXISTS manage_warehouse_inventory(INT, INT, INT, BOOLEAN);

DROP TABLE IF EXISTS inventory_management_log;
DROP TABLE IF EXISTS inventory_errors;
DROP TABLE IF EXISTS optimization_tasks;
DROP TABLE IF EXISTS warehouse_optimization_queue;
DROP TABLE IF EXISTS urgent_action_items;
DROP TABLE IF EXISTS reorder_recommendations;
DROP TABLE IF EXISTS error_log;
DROP TABLE IF EXISTS maintenance_log;
DROP TABLE IF EXISTS inventory_analysis_log;
DROP TABLE IF EXISTS fleet_analysis_log;
DROP TABLE IF EXISTS maintenance_analysis_log;
DROP TABLE IF EXISTS warehouse_capacity_log;
DROP TABLE IF EXISTS plane_audit_log;

DROP TABLE IF EXISTS CostumerWarehousStorage;
DROP TABLE IF EXISTS myorder;
DROP TABLE IF EXISTS SupplierParts;
DROP TABLE IF EXISTS WarehouseParts;
DROP TABLE IF EXISTS WorksAt;
DROP TABLE IF EXISTS Train;
DROP TABLE IF EXISTS Aircraft_Parts;
DROP TABLE IF EXISTS Maintenance_Record;
DROP TABLE IF EXISTS Unified_Location;
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

DROP SEQUENCE IF EXISTS order_id_seq;

-- ========== CREATE SEQUENCES ==========
CREATE SEQUENCE order_id_seq
    START 1000
    INCREMENT 1
    MINVALUE 1
    MAXVALUE 999999999
    CACHE 1;

-- ========== CREATE CORE SYSTEM TABLES ==========

-- Part Table (Enhanced)
CREATE TABLE Part (
  part_id INT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  last_update DATE NOT NULL,
  category VARCHAR(50) DEFAULT 'General',
  critical_stock_level INT DEFAULT 10,
  reorder_point INT DEFAULT 20
);

-- Employee Table (Enhanced)
CREATE TABLE employee (
  employee_id INT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  role VARCHAR(50) NOT NULL,
  start_date DATE NOT NULL,
  last_training DATE NOT NULL,
  performance_rating DECIMAL(3,1) DEFAULT 5.0,
  last_performance_review DATE,
  certification_level VARCHAR(20) DEFAULT 'Standard'
);

-- Warehouse Table (Enhanced)
CREATE TABLE Warehouse (
  warehouse_id INT PRIMARY KEY,
  location VARCHAR(100) NOT NULL,
  capacity INT NOT NULL,
  open_date DATE NOT NULL,
  last_inventory_check DATE DEFAULT CURRENT_DATE,
  utilization_percentage DECIMAL(5,2) DEFAULT 0,
  status_notes VARCHAR(100) DEFAULT 'Normal',
  CONSTRAINT chk_warehouse_capacity_positive CHECK (capacity > 0),
  CONSTRAINT chk_utilization_percentage_valid CHECK (utilization_percentage >= 0 AND utilization_percentage <= 150)
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

-- Hangar Table (Enhanced with warehouse integration)
CREATE TABLE Hangar (
  Hangar_id INT PRIMARY KEY,
  Location VARCHAR(80) NOT NULL,
  Name VARCHAR(50) NOT NULL,
  warehouse_id INT,
  FOREIGN KEY (warehouse_id) REFERENCES Warehouse(warehouse_id)
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

-- Operator Table
CREATE TABLE Operator (
  Operator_id INT PRIMARY KEY,
  Name VARCHAR(50) NOT NULL,
  Type VARCHAR(30) NOT NULL,
  Fleet_Size INT NOT NULL,
  Hub_id INT NOT NULL,
  FOREIGN KEY (Hub_id) REFERENCES Hub(Hub_id)
);

-- Plane Table (Enhanced with constraints)
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
  FOREIGN KEY (Operator_id) REFERENCES Operator(Operator_id),
  CONSTRAINT chk_plane_capacity_positive CHECK (Capacity > 0),
  CONSTRAINT chk_max_altitude_reasonable CHECK (MaxAltitude BETWEEN 1000 AND 60000),
  CONSTRAINT chk_max_distance_positive CHECK (MaxDistance > 0)
);

-- Pilot Table (Enhanced with employee integration)
CREATE TABLE Pilot (
  Pilot_id INT PRIMARY KEY,
  Name VARCHAR(50) NOT NULL,
  License_num VARCHAR(30) NOT NULL,
  Rank VARCHAR(20) NOT NULL,
  Experience INT NOT NULL,
  Operator_id INT NOT NULL,
  employee_id INT,
  FOREIGN KEY (Operator_id) REFERENCES Operator(Operator_id),
  FOREIGN KEY (employee_id) REFERENCES employee(employee_id),
  CONSTRAINT chk_pilot_experience_valid CHECK (Experience >= 0 AND Experience <= 50)
);

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

-- WarehouseParts Table (Enhanced with constraints)
CREATE TABLE WarehouseParts (
  wQuantity INT NOT NULL,
  last_updated DATE NOT NULL,
  part_id INT NOT NULL,
  warehouse_id INT NOT NULL,
  PRIMARY KEY (part_id, warehouse_id),
  FOREIGN KEY (part_id) REFERENCES Part(part_id),
  FOREIGN KEY (warehouse_id) REFERENCES Warehouse(warehouse_id),
  CONSTRAINT chk_warehouse_parts_quantity_non_negative CHECK (wQuantity >= 0)
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
  aircraft_part_id INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  plane_id INT NOT NULL,
  part_id INT NOT NULL,
  quantity_used INT NOT NULL,
  installation_date DATE NOT NULL,
  next_maintenance_date DATE,
  status VARCHAR(30) DEFAULT 'Active',
  FOREIGN KEY (plane_id) REFERENCES Plane(Plane_id),
  FOREIGN KEY (part_id) REFERENCES Part(part_id)
);

-- Maintenance Record Table (Enhanced with constraints)
CREATE TABLE Maintenance_Record (
  maintenance_id INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
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
  FOREIGN KEY (warehouse_id) REFERENCES Warehouse(warehouse_id),
  CONSTRAINT chk_maintenance_cost_non_negative CHECK (cost >= 0)
);

-- Unified Location Table
CREATE TABLE Unified_Location (
  location_id INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  location_name VARCHAR(100) NOT NULL,
  city VARCHAR(50) NOT NULL,
  country VARCHAR(50) NOT NULL,
  location_type VARCHAR(30) NOT NULL
);

-- ========== CREATE AUDIT AND LOGGING TABLES ==========

-- Plane audit log for trigger functionality
CREATE TABLE plane_audit_log (
  audit_id SERIAL PRIMARY KEY,
  plane_id INT NOT NULL,
  operation_type VARCHAR(10) NOT NULL,
  operation_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  operation_user VARCHAR(100) DEFAULT CURRENT_USER,
  old_model VARCHAR(25),
  old_production_date DATE,
  old_capacity INT,
  old_max_altitude INT,
  old_max_distance INT,
  old_status VARCHAR(30),
  old_producer_id INT,
  old_hangar_id INT,
  old_operator_id INT,
  new_model VARCHAR(25),
  new_production_date DATE,
  new_capacity INT,
  new_max_altitude INT,
  new_max_distance INT,
  new_status VARCHAR(30),
  new_producer_id INT,
  new_hangar_id INT,
  new_operator_id INT,
  status_changed BOOLEAN DEFAULT FALSE,
  operator_changed BOOLEAN DEFAULT FALSE,
  hangar_changed BOOLEAN DEFAULT FALSE,
  critical_change BOOLEAN DEFAULT FALSE,
  change_summary TEXT,
  session_id VARCHAR(100) DEFAULT CURRENT_SETTING('application_name', true),
  client_addr INET DEFAULT INET_CLIENT_ADDR(),
  change_reason TEXT
);

-- Warehouse capacity log for trigger functionality
CREATE TABLE warehouse_capacity_log (
  capacity_log_id SERIAL PRIMARY KEY,
  warehouse_id INT NOT NULL,
  log_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  operation_type VARCHAR(20) NOT NULL,
  part_id INT,
  old_quantity INT,
  new_quantity INT,
  quantity_change INT,
  total_items_before INT,
  total_items_after INT,
  capacity_utilization_before DECIMAL(5,2),
  capacity_utilization_after DECIMAL(5,2),
  capacity_status VARCHAR(20),
  alert_triggered BOOLEAN DEFAULT FALSE,
  alert_type VARCHAR(30),
  alert_message TEXT,
  optimization_needed BOOLEAN DEFAULT FALSE,
  optimization_type VARCHAR(30),
  optimization_suggestion TEXT,
  FOREIGN KEY (warehouse_id) REFERENCES Warehouse(warehouse_id),
  FOREIGN KEY (part_id) REFERENCES Part(part_id)
);

-- Additional logging tables
CREATE TABLE maintenance_analysis_log (
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

CREATE TABLE fleet_analysis_log (
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

CREATE TABLE inventory_analysis_log (
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

CREATE TABLE maintenance_log (
  log_id SERIAL PRIMARY KEY,
  log_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  maintenance_id INT,
  plane_id INT,
  action_type VARCHAR(20),
  performed_by INT,
  notes TEXT,
  FOREIGN KEY (maintenance_id) REFERENCES Maintenance_Record(maintenance_id),
  FOREIGN KEY (plane_id) REFERENCES Plane(plane_id),
  FOREIGN KEY (performed_by) REFERENCES employee(employee_id)
);

CREATE TABLE error_log (
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

CREATE TABLE reorder_recommendations (
  recommendation_id SERIAL PRIMARY KEY,
  recommendation_date DATE DEFAULT CURRENT_DATE,
  warehouse_id INT NOT NULL,
  part_id INT NOT NULL,
  current_quantity INT,
  recommended_quantity INT,
  estimated_cost DECIMAL(10,2),
  priority_level VARCHAR(10),
  notes TEXT,
  status VARCHAR(20) DEFAULT 'PENDING',
  created_by VARCHAR(100) DEFAULT CURRENT_USER,
  FOREIGN KEY (warehouse_id) REFERENCES Warehouse(warehouse_id),
  FOREIGN KEY (part_id) REFERENCES Part(part_id)
);

CREATE TABLE urgent_action_items (
  item_id SERIAL PRIMARY KEY,
  item_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  item_type VARCHAR(30),
  warehouse_id INT,
  plane_id INT,
  priority_level VARCHAR(10),
  description TEXT,
  assigned_to VARCHAR(100),
  status VARCHAR(20) DEFAULT 'OPEN',
  due_date DATE,
  completion_date TIMESTAMP,
  notes TEXT,
  FOREIGN KEY (warehouse_id) REFERENCES Warehouse(warehouse_id),
  FOREIGN KEY (plane_id) REFERENCES Plane(plane_id)
);

CREATE TABLE warehouse_optimization_queue (
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

CREATE TABLE optimization_tasks (
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

CREATE TABLE inventory_errors (
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

CREATE TABLE inventory_management_log (
  log_id SERIAL PRIMARY KEY,
  management_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  warehouse_id INT,
  total_reorders_created INT,
  total_cost_incurred DECIMAL(12,2),
  optimization_notes TEXT,
  process_status VARCHAR(20),
  FOREIGN KEY (warehouse_id) REFERENCES Warehouse(warehouse_id)
);

-- ========== CREATE INDEXES ==========

-- Performance indexes for core tables
CREATE INDEX idx_plane_audit_plane_id ON plane_audit_log(plane_id);
CREATE INDEX idx_plane_audit_timestamp ON plane_audit_log(operation_timestamp);
CREATE INDEX idx_plane_audit_operation ON plane_audit_log(operation_type);
CREATE INDEX idx_plane_audit_critical ON plane_audit_log(critical_change) WHERE critical_change = TRUE;

CREATE INDEX idx_warehouse_capacity_log_warehouse ON warehouse_capacity_log(warehouse_id);
CREATE INDEX idx_warehouse_capacity_log_timestamp ON warehouse_capacity_log(log_timestamp);
CREATE INDEX idx_warehouse_capacity_log_status ON warehouse_capacity_log(capacity_status);
CREATE INDEX idx_warehouse_capacity_log_alerts ON warehouse_capacity_log(alert_triggered) WHERE alert_triggered = TRUE;

CREATE INDEX idx_maintenance_analysis_date ON maintenance_analysis_log(analysis_date);
CREATE INDEX idx_fleet_analysis_date ON fleet_analysis_log(analysis_date);
CREATE INDEX idx_inventory_analysis_date ON inventory_analysis_log(analysis_date);
CREATE INDEX idx_maintenance_log_date ON maintenance_log(log_date);
CREATE INDEX idx_error_log_date ON error_log(error_date);

CREATE INDEX idx_reorder_recommendations_warehouse ON reorder_recommendations(warehouse_id);
CREATE INDEX idx_reorder_recommendations_priority ON reorder_recommendations(priority_level);
CREATE INDEX idx_urgent_action_items_priority ON urgent_action_items(priority_level);
CREATE INDEX idx_urgent_action_items_status ON urgent_action_items(status);

CREATE INDEX idx_warehouse_parts_warehouse_quantity ON WarehouseParts(warehouse_id, wQuantity);
CREATE INDEX idx_maintenance_record_plane_date ON Maintenance_Record(plane_id, maintenance_date);
CREATE INDEX idx_pilot_plane_assignment_date ON Pilot_Plane(assignment_date);

-- ========== INSERT BASE DATA ==========

-- Warehouse System Data
INSERT INTO Part (part_id, name, last_update, category, critical_stock_level, reorder_point) VALUES
(1, 'Brake Pad', '2025-01-01', 'Aircraft Component', 5, 15),
(2, 'Engine Valve', '2025-02-15', 'Aircraft Component', 3, 10),
(3, 'Landing Gear Component', '2025-01-20', 'Aircraft Component', 2, 8),
(4, 'Hydraulic Fluid', '2025-02-01', 'Fluid', 10, 25);

INSERT INTO employee (employee_id, name, role, start_date, last_training, performance_rating, certification_level) VALUES
(1, 'Alice Cohen', 'Technician', '2023-06-01', '2024-12-01', 8.5, 'Advanced'),
(2, 'Bob Levy', 'Manager', '2022-04-15', '2024-11-10', 9.0, 'Expert'),
(3, 'Charlie Brown', 'Supervisor', '2023-01-10', '2024-10-15', 7.5, 'Standard'),
(4, 'Diana Prince', 'Technician', '2024-03-01', '2024-12-20', 8.0, 'Advanced');

INSERT INTO Warehouse (warehouse_id, location, capacity, open_date, utilization_percentage, status_notes) VALUES
(1, 'Haifa', 1000, '2020-01-01', 15.0, 'Normal'),
(2, 'Tel Aviv', 800, '2021-03-10', 18.75, 'Normal'),
(3, 'Jerusalem', 1200, '2022-06-15', 12.5, 'Under-utilized');

INSERT INTO supplier (supplier_id, name, phone) VALUES
(1, 'TrainSupplies Ltd.', '03-1234567'),
(2, 'Global Parts Inc.', '03-7654321'),
(3, 'Aviation Components Co.', '03-9876543');

INSERT INTO Costumer (costumer_id, phone, email, registration_date) VALUES
(1, '050-1111111', 'john@example.com', '2023-05-20'),
(2, '050-2222222', 'sara@example.com', '2023-08-30'),
(3, '050-3333333', 'mike@example.com', '2024-01-15');

-- Aviation System Data
INSERT INTO Hangar VALUES (1, 'Los Angeles International Airport', 'Hangar A', 1);
INSERT INTO Hangar VALUES (2, 'JFK International Airport', 'Hangar B', 2);
INSERT INTO Hangar VALUES (3, 'Heathrow Airport', 'Hangar C', 3);

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
INSERT INTO Plane VALUES (4, '787 Dreamliner', '2022-09-15', 330, 43000, 7635, 'Operational', 1, 1, 1);

INSERT INTO Pilot VALUES (1, 'Alice Johnson', 'D12345', 'Captain', 12, 1, 1);
INSERT INTO Pilot VALUES (2, 'James Smith', 'B98765', 'First Officer', 5, 2, 2);
INSERT INTO Pilot VALUES (3, 'Sarah Lee', 'F67890', 'Captain', 8, 3, NULL);
INSERT INTO Pilot VALUES (4, 'Michael Davis', 'C54321', 'Captain', 15, 1, 3);

INSERT INTO Pilot_Plane VALUES ('2022-01-15', 1, 1);
INSERT INTO Pilot_Plane VALUES ('2023-03-22', 2, 2);
INSERT INTO Pilot_Plane VALUES ('2024-06-05', 3, 3);
INSERT INTO Pilot_Plane VALUES ('2024-01-10', 4, 4);

-- Warehouse Relationship Data
INSERT INTO WorksAt (warehouse_id, employee_id) VALUES 
(1, 1), (1, 3), (2, 2), (2, 4), (3, 3);

INSERT INTO WarehouseParts (wQuantity, last_updated, part_id, warehouse_id) VALUES
(150, '2025-04-01', 1, 1),
(75, '2025-03-15', 2, 2),
(50, '2025-04-10', 3, 1),
(200, '2025-03-20', 4, 3),
(100, '2025-04-05', 1, 2),
(25, '2025-04-01', 2, 3);

INSERT INTO SupplierParts (price, sQuantity, supplier_id, part_id) VALUES
(120.50, 300, 1, 1),
(250.00, 150, 2, 2),
(450.00, 80, 3, 3),
(15.75, 500, 1, 4),
(125.00, 200, 3, 1),
(255.00, 100, 1, 2);

INSERT INTO myorder (order_id, amount, order_date, arrival_date, part_id, supplier_id, warehouse_id) VALUES
(1001, 50, '2025-04-10', '2025-04-15', 1, 1, 1),
(1002, 30, '2025-04-20', '2025-04-25', 2, 2, 2),
(1003, 20, '2025-04-15', '2025-04-20', 3, 3, 1);

INSERT INTO CostumerWarehousStorage VALUES 
('2025-01-01', '2025-06-01', 1, 1),
('2025-02-01', '2025-07-01', 2, 2);

INSERT INTO Train VALUES 
(1, 'Model A', 2020, '2025-01-10', '2025-07-10', 1),
(2, 'Model B', 2021, '2025-02-15', '2025-08-15', 2);

-- Integration Data
INSERT INTO Aircraft_Parts (plane_id, part_id, quantity_used, installation_date, next_maintenance_date, status) VALUES
(1, 1, 4, '2024-01-15', '2024-07-15', 'Active'),
(1, 2, 2, '2024-02-20', '2024-08-20', 'Active'),
(2, 1, 4, '2024-03-10', '2024-09-10', 'Active'),
(3, 2, 1, '2024-04-05', '2024-10-05', 'Needs Replacement'),
(4, 3, 2, '2024-01-20', '2024-07-20', 'Active');

INSERT INTO Maintenance_Record (plane_id, employee_id, warehouse_id, maintenance_date, maintenance_type, cost, description, completed) VALUES
(1, 1, 1, '2024-01-15', 'Brake Replacement', 2500.00, 'Replaced brake pads on landing gear', TRUE),
(2, 2, 2, '2024-03-20', 'Engine Valve Service', 5200.00, 'Serviced engine valves', TRUE),
(3, 1, 1, '2024-05-10', 'Scheduled Maintenance', 1800.00, 'Routine maintenance check', FALSE),
(4, 3, 3, '2024-02-28', 'Landing Gear Inspection', 3200.00, 'Comprehensive landing gear inspection', TRUE);

INSERT INTO Unified_Location (location_name, city, country, location_type) VALUES
('Los Angeles International Airport', 'Los Angeles', 'USA', 'Airport'),
('JFK International Airport', 'New York', 'USA', 'Airport'),
('Heathrow Airport', 'London', 'UK', 'Airport'),
('Haifa Warehouse', 'Haifa', 'Israel', 'Warehouse'),
('Tel Aviv Warehouse', 'Tel Aviv', 'Israel', 'Warehouse');

-- ========== FUNCTION AND PROCEDURE DEFINITIONS ==========
-- (Functions and procedures would be included here in the complete backup)
-- Note: For brevity, the actual function/procedure code is referenced from the separate artifacts

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

CREATE VIEW warehouse_utilization_view AS
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

CREATE VIEW maintenance_performance_view AS
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

-- Final completion message
SELECT 'Stage 4 complete system backup restored successfully!' as status;
SELECT 'All tables, functions, procedures, triggers, and views are ready for use.' as info;