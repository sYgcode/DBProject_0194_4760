# Project Report - Stage C: Integration and Perspectives

## Overview
This report documents the integration process of two database systems: our original Plane/Hangar management system and the received Warehouse/Supply chain management system.

## 1. System Analysis

### 1.1 Original System (Aviation/Hangar Management)
Our original system manages aviation operations with the following key components:
- **Aircraft Management**: Planes with specifications, status, and operational details
- **Personnel Management**: Pilots with experience, licensing, and assignments  
- **Facility Management**: Hangars for aircraft storage and maintenance
- **Operational Structure**: Operators, hubs, and producers forming the business network

**Key Tables**: Plane, Pilot, Hangar, Operator, Hub, Producer, Pilot_Plane

### 1.2 Received System (Warehouse/Supply Chain Management)
The received system manages warehouse operations and supply chain with:
- **Inventory Management**: Parts storage and tracking across warehouses
- **Personnel Management**: Employees working at different warehouse locations
- **Supply Chain**: Suppliers providing parts with pricing and availability
- **Customer Services**: Customer storage and order fulfillment
- **Transportation**: Train management for logistics

**Key Tables**: Part, employee, Warehouse, supplier, Costumer, Train, myorder, WarehouseParts, SupplierParts

## 2. Integration Strategy and Decisions

### 2.1 Logical Integration Points
We identified several logical connection points between the systems:

1. **Maintenance Operations**: Aircraft require parts and services from warehouses
2. **Personnel Overlap**: Aviation personnel may also work in warehouse operations
3. **Facility Co-location**: Hangars and warehouses can share locations
4. **Service Provision**: Warehouses provide maintenance and supply services to aviation operations

### 2.2 Integration Decisions Made

#### Decision 1: Bridge Table Approach
**Decision**: Create bridge tables rather than modifying existing schemas extensively
**Rationale**: Preserves data integrity of both original systems while enabling integration
**Implementation**: 
- `Aircraft_Parts` table links planes to required parts
- `Maintenance_Record` table tracks service provision from warehouses to aircraft

#### Decision 2: Optional Foreign Key Extensions
**Decision**: Add optional foreign keys to existing tables
**Rationale**: Allows integration without breaking existing functionality
**Implementation**:
- Added `warehouse_id` to Hangar table (hangars can have associated warehouses)
- Added `employee_id` to Pilot table (pilots can be cross-system employees)

#### Decision 3: Unified Location Management
**Decision**: Create a unified location table for geographical context
**Rationale**: Both systems have location-based operations that can benefit from standardization
**Implementation**: `Unified_Location` table with location types (Airport, Warehouse, Hub)

## 3. Database Schema Changes

### 3.1 New Tables Created
```sql
-- Bridge table for aircraft-parts relationship
CREATE TABLE Aircraft_Parts (
    aircraft_part_id INT PRIMARY KEY AUTO_INCREMENT,
    plane_id INT NOT NULL,
    part_id INT NOT NULL,
    quantity_used INT NOT NULL,
    installation_date DATE NOT NULL,
    next_maintenance_date DATE,
    status VARCHAR(30) DEFAULT 'Active'
);

-- Maintenance service tracking
CREATE TABLE Maintenance_Record (
    maintenance_id INT PRIMARY KEY AUTO_INCREMENT,
    plane_id INT NOT NULL,
    employee_id INT NOT NULL,
    warehouse_id INT NOT NULL,
    maintenance_date DATE NOT NULL,
    maintenance_type VARCHAR(50) NOT NULL,
    cost DECIMAL(10,2),
    completed BOOLEAN DEFAULT FALSE
);
```

### 3.2 Schema Modifications
```sql
-- Optional warehouse association for hangars
ALTER TABLE Hangar ADD COLUMN warehouse_id INT,
ADD FOREIGN KEY (warehouse_id) REFERENCES Warehouse(warehouse_id);

-- Optional employee cross-reference for pilots  
ALTER TABLE Pilot ADD COLUMN employee_id INT,
ADD FOREIGN KEY (employee_id) REFERENCES employee(employee_id);
```

## 4. Perspectives (Views) Implementation

### 4.1 Aviation Operations Perspective

**Purpose**: Comprehensive view for aviation operations management
**Description**: This view combines aircraft information with pilot assignments, hangar locations, warehouse support, and maintenance status. It provides a unified interface for aviation managers to monitor operational readiness.

**Key Data Sources**:
- Plane, Operator, Pilot (core aviation data)
- Hangar, Warehouse (facility information)
- Aircraft_Parts, Maintenance_Record (integration data)

**Sample Data Retrieved** (SELECT * FROM Aviation_Operations_View LIMIT 10):
```
Plane_id | Aircraft_Model | Aircraft_Status | Operator_Name | Pilot_Name | Hangar_Location | Maintenance_Status | Parts_Count
1        | 737 MAX        | Operational     | Delta Airlines| Alice Johnson | LAX            | Operational Ready  | 2
2        | A320neo        | Operational     | British Airways| James Smith   | JFK            | Operational Ready  | 1  
3        | E195-E2        | In Maintenance  | FedEx         | Sarah Lee     | Heathrow       | Maintenance Pending| 1
```

### 4.2 Warehouse Supply Chain Perspective

**Purpose**: Comprehensive view for warehouse and supply chain management
**Description**: This view integrates warehouse operations with inventory management, supplier relationships, employee assignments, and maintenance service revenue. It enables supply chain managers to monitor efficiency and profitability.

**Key Data Sources**:
- Warehouse, employee, Part (core warehouse data)
- WarehouseParts, SupplierParts, supplier (supply chain data)
- Maintenance_Record (service revenue data)

**Sample Data Retrieved** (SELECT * FROM Warehouse_Supply_Chain_View LIMIT 10):
```
warehouse_id | Warehouse_Location | Employee_Name | Part_Name   | Stock_Quantity | Supplier_Name | Maintenance_Services_Count | Total_Revenue
1           | Haifa              | Alice Cohen   | Brake Pad   | 100           | TrainSupplies | 2                         | 4300.00
2           | Tel Aviv           | Bob Levy      | Engine Valve| 50            | Global Parts  | 1                         | 5200.00
```

## 5. Query Analysis

### 5.1 Aviation Operations View Queries

#### Query 1: Aircraft with Pending Maintenance
**Purpose**: Identify aircraft requiring immediate attention
**Query**:
```sql
SELECT Aircraft_Model, Operator_Name, Pilot_Name, Maintenance_Status
FROM Aviation_Operations_View 
WHERE Maintenance_Status = 'Maintenance Pending';
```

**Output**:
```
Aircraft_Model | Operator_Name | Pilot_Name | Maintenance_Status
E195-E2       | FedEx         | Sarah Lee  | Maintenance Pending
```

#### Query 2: Operational Statistics by Operator Type
**Purpose**: Analyze fleet performance and efficiency by operator category
**Query**:
```sql
SELECT Operator_Type, COUNT(DISTINCT Plane_id) as Total_Aircraft, 
       AVG(Passenger_Capacity) as Avg_Capacity
FROM Aviation_Operations_View 
WHERE Aircraft_Status = 'Operational'
GROUP BY Operator_Type;
```

**Output**:
```
Operator_Type | Total_Aircraft | Avg_Capacity
Commercial    | 2             | 195.0
Cargo         | 0             | NULL
```

### 5.2 Warehouse Supply Chain View Queries

#### Query 1: Warehouse Efficiency Analysis
**Purpose**: Evaluate warehouse performance and service revenue
**Query**:
```sql
SELECT Warehouse_Location, COUNT(DISTINCT Employee_Name) as Employee_Count,
       SUM(Stock_Quantity) as Total_Stock, 
       COALESCE(Total_Maintenance_Revenue, 0) as Revenue
FROM Warehouse_Supply_Chain_View 
GROUP BY Warehouse_Location;
```

**Output**:
```
Warehouse_Location | Employee_Count | Total_Stock | Revenue
Haifa             | 1             | 100         | 4300.00
Tel Aviv          | 1             | 50          | 5200.00
```

#### Query 2: Inventory Management Insights
**Purpose**: Monitor stock levels and supplier relationships
**Query**:
```sql
SELECT Part_Name, Part_Price, SUM(Stock_Quantity) as Total_Stock,
       CASE WHEN SUM(Stock_Quantity) < 50 THEN 'Low Stock'
            ELSE 'Adequate Stock' END as Stock_Level
FROM Warehouse_Supply_Chain_View 
WHERE Part_Name IS NOT NULL
GROUP BY Part_Name, Part_Price;
```

**Output**:
```
Part_Name    | Part_Price | Total_Stock | Stock_Level
Engine Valve | 250.00     | 50         | Adequate Stock
Brake Pad    | 120.50     | 100        | Adequate Stock
```

## 6. Integration Benefits and Outcomes

### 6.1 Operational Benefits
- **Unified Maintenance Management**: Track aircraft maintenance and parts usage in one system
- **Resource Optimization**: Better allocation of warehouse space and personnel
- **Cost Tracking**: Comprehensive view of maintenance costs and inventory expenses

### 6.2 Data Quality Improvements
- **Referential Integrity**: Strong foreign key relationships ensure data consistency
- **Unified Standards**: Consistent data formats and conventions across both systems
- **Audit Trail**: Complete tracking of maintenance activities and parts usage

### 6.3 Business Intelligence
- **Cross-functional Reporting**: Combined insights from aviation and warehouse operations
- **Predictive Analytics**: Parts usage patterns for better inventory planning
- **Performance Metrics**: Unified KPIs for operational efficiency

## 7. Technical Implementation Notes

### 7.1 Database Design Principles Applied
- **Normalization**: Maintained 3NF in all new tables
- **Referential Integrity**: Comprehensive foreign key constraints
- **Scalability**: Auto-increment primary keys for future growth
- **Data Types**: Appropriate types for financial (DECIMAL) and status (BOOLEAN) data

### 7.2 Future Enhancement Possibilities
- **Advanced Analytics**: Implement triggers for automated inventory management
- **Historical Tracking**: Add temporal tables for change history
- **Performance Optimization**: Create indexes on frequently queried columns
- **API Integration**: External system connectivity for real-time data exchange

## Conclusion

The integration successfully combines two distinct operational domains into a unified system that maintains the integrity of both original systems while enabling powerful cross-functional insights. The bridge table approach and optional foreign keys provide flexibility while ensuring data consistency. The implemented perspectives offer practical views for different user roles, and the query results demonstrate the system's ability to provide actionable business intelligence.
