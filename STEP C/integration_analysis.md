# Stage C: Integration Analysis and Documentation

## System Analysis

### Original Aviation System (Plane/Hangars)
**Entities:** Hangar, Producer, Hub, Operator, Plane, Pilot
**Key Relationships:**
- Plane is produced by Producer
- Plane is stored in Hangar  
- Plane is operated by Operator
- Pilot flies for Operator
- Pilot is assigned to Plane (many-to-many)
- Operator operates from Hub

### Received Warehouse System
**Entities:** Part, Employee, Warehouse, Supplier, Customer, Train
**Key Relationships:**
- Employee works at Warehouse
- Part is stored in Warehouse with quantity
- Supplier supplies Parts with pricing
- Orders link Supplier, Part, and Warehouse
- Customer stores items in Warehouse
- Train operates from Warehouse

## Integration Strategy

### Logical Connection Points
1. **Maintenance Operations**: Aircraft require parts from warehouses for maintenance
2. **Personnel Management**: Pilots could also be warehouse employees
3. **Location Integration**: Hangars and warehouses can be co-located
4. **Service Provision**: Warehouses provide maintenance services to aircraft

### New Integrated Entities
1. **Aircraft_Parts**: Links aircraft to specific parts used
2. **Maintenance_Record**: Tracks maintenance performed by warehouse staff on aircraft
3. **Unified_Location**: Provides geographical context for both systems

## Integration Decisions Made

### 1. Bridge Table Strategy
- Created `Aircraft_Parts` table to establish many-to-many relationship between Plane and Part
- Created `Maintenance_Record` table to track service provision

### 2. Foreign Key Extensions
- Added `warehouse_id` to Hangar table (optional relationship)
- Added `employee_id` to Pilot table (optional relationship)

### 3. Data Preservation
- All original data from both systems preserved
- No destructive changes to existing schemas
- Used ALTER TABLE commands for non-breaking modifications

### 4. Perspective Design
- **Aviation Operations View**: Focuses on flight operations, crew, and maintenance status
- **Warehouse Supply Chain View**: Focuses on inventory, suppliers, and service revenue

## Combined ERD Structure

### Core Entity Groups
1. **Aviation Group**: Plane, Pilot, Operator, Producer, Hub, Hangar
2. **Warehouse Group**: Part, Employee, Warehouse, Supplier, Customer, Train  
3. **Integration Group**: Aircraft_Parts, Maintenance_Record, Unified_Location

### Key Relationships in Integrated System
- Plane → Aircraft_Parts ← Part (many-to-many through bridge)
- Plane → Maintenance_Record ← Employee (maintenance services)
- Hangar → Warehouse (facility co-location)
- Pilot → Employee (cross-system personnel)

## Perspectives Description

### Aviation Operations Perspective
**Purpose**: Provides comprehensive view for aviation operations managers
**Data Sources**: Combines 6 tables (Plane, Operator, Pilot, Hangar, Warehouse, Aircraft_Parts)
**Key Insights**: 
- Aircraft operational status and maintenance needs
- Pilot assignments and experience levels
- Warehouse support for each aircraft
- Parts inventory status per aircraft

### Warehouse Supply Chain Perspective  
**Purpose**: Provides comprehensive view for warehouse and supply chain managers
**Data Sources**: Combines 7 tables (Warehouse, Employee, Part, WarehouseParts, Supplier, SupplierParts, Maintenance_Record)
**Key Insights**:
- Inventory levels and supplier relationships
- Employee productivity and assignments
- Revenue from maintenance services
- Stock level monitoring and alerts

## Integration Benefits

1. **Operational Efficiency**: Single system for managing aircraft and their supply chain
2. **Cost Tracking**: Unified view of maintenance costs and parts consumption
3. **Resource Optimization**: Better allocation of warehouse space and personnel
4. **Predictive Maintenance**: Track parts usage patterns for better planning
5. **Unified Reporting**: Cross-departmental insights and analytics

## Technical Implementation Notes

- Used AUTO_INCREMENT for new primary keys
- Implemented proper referential integrity with foreign keys
- Added status and date fields for operational tracking
- Used BOOLEAN fields for simple state management
- Implemented DECIMAL fields for financial data precision