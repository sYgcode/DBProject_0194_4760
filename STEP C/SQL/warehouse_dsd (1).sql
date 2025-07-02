-- ========== WAREHOUSE SYSTEM DSD (Database Schema Diagram) ==========
-- Reverse engineered from received SQL files

-- PRIMARY TABLES (Entities)

CREATE TABLE Part (
    part_id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    last_update DATE NOT NULL
);

CREATE TABLE employee (
    employee_id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    role VARCHAR(50) NOT NULL,
    start_date DATE NOT NULL,
    last_training DATE NOT NULL
);

CREATE TABLE Warehouse (
    warehouse_id INT PRIMARY KEY,
    location VARCHAR(100) NOT NULL,
    capacity INT NOT NULL,
    open_date DATE NOT NULL
);

CREATE TABLE supplier (
    supplier_id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(20) NOT NULL
);

CREATE TABLE Costumer (
    costumer_id INT PRIMARY KEY,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(100) NOT NULL,
    registration_date DATE NOT NULL
);

CREATE TABLE Train (
    train_id INT PRIMARY KEY,
    model VARCHAR(50) NOT NULL,
    year INT NOT NULL,
    last_check DATE NOT NULL,
    next_check DATE NOT NULL,
    warehouse_id INT NOT NULL,
    FOREIGN KEY (warehouse_id) REFERENCES Warehouse(warehouse_id)
);

-- RELATIONSHIP TABLES (Many-to-Many and Associative Entities)

CREATE TABLE WorksAt (
    warehouse_id INT NOT NULL,
    employee_id INT NOT NULL,
    PRIMARY KEY (warehouse_id, employee_id),
    FOREIGN KEY (warehouse_id) REFERENCES Warehouse(warehouse_id),
    FOREIGN KEY (employee_id) REFERENCES employee(employee_id)
);

CREATE TABLE WarehouseParts (
    wQuantity INT NOT NULL,
    last_updated DATE NOT NULL,
    part_id INT NOT NULL,
    warehouse_id INT NOT NULL,
    PRIMARY KEY (part_id, warehouse_id),
    FOREIGN KEY (part_id) REFERENCES Part(part_id),
    FOREIGN KEY (warehouse_id) REFERENCES Warehouse(warehouse_id)
);

CREATE TABLE SupplierParts (
    price DECIMAL(10,2) NOT NULL,
    sQuantity INT NOT NULL,
    supplier_id INT NOT NULL,
    part_id INT NOT NULL,
    PRIMARY KEY (supplier_id, part_id),
    FOREIGN KEY (supplier_id) REFERENCES supplier(supplier_id),
    FOREIGN KEY (part_id) REFERENCES Part(part_id)
);

CREATE TABLE CostumerWarehousStorage (
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    warehouse_id INT NOT NULL,
    costumer_id INT NOT NULL,
    PRIMARY KEY (warehouse_id, costumer_id),
    FOREIGN KEY (warehouse_id) REFERENCES Warehouse(warehouse_id),
    FOREIGN KEY (costumer_id) REFERENCES Costumer(costumer_id)
);

-- TRANSACTIONAL TABLES

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

-- ========== COMBINED INTEGRATED DSD ==========
-- Shows the complete integrated system

-- Original Aviation Tables (unchanged core structure)
-- Hangar, Producer, Hub, Operator, Plane, Pilot, Pilot_Plane

-- Warehouse System Tables (as above)
-- Part, employee, Warehouse, supplier, Costumer, Train, etc.

-- New Integration Tables

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

CREATE TABLE Unified_Location (
    location_id INT PRIMARY KEY AUTO_INCREMENT,
    location_name VARCHAR(100) NOT NULL,
    city VARCHAR(50) NOT NULL,
    country VARCHAR(50) NOT NULL,
    location_type VARCHAR(30) NOT NULL
);

-- Enhanced Tables with Integration Foreign Keys
-- ALTER TABLE Hangar ADD COLUMN warehouse_id INT;
-- ALTER TABLE Pilot ADD COLUMN employee_id INT;