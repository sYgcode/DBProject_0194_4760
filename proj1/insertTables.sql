-- ========== INSERT DATA ==========

-- Hangar
INSERT INTO Hangar VALUES (1, 'Los Angeles International Airport', 'Hangar A');
INSERT INTO Hangar VALUES (2, 'JFK International Airport', 'Hangar B');
INSERT INTO Hangar VALUES (3, 'Heathrow Airport', 'Hangar C');

-- Producer
INSERT INTO Producer VALUES (1, 'Boeing', '1916-07-15', 'Boeing Company');
INSERT INTO Producer VALUES (2, 'Airbus', '1970-12-18', 'Airbus Group');
INSERT INTO Producer VALUES (3, 'Embraer', '1969-08-19', 'Embraer S.A.');

-- Hub
INSERT INTO Hub VALUES (1, 'LAX Hub', 'Los Angeles', 'LAX', 200);
INSERT INTO Hub VALUES (2, 'JFK Hub', 'New York', 'JFK', 180);
INSERT INTO Hub VALUES (3, 'Heathrow Hub', 'London', 'LHR', 250);

-- Operator
INSERT INTO Operator VALUES (1, 'Delta Airlines', 'Commercial', 150, 2);
INSERT INTO Operator VALUES (2, 'British Airways', 'Commercial', 100, 3);
INSERT INTO Operator VALUES (3, 'FedEx', 'Cargo', 75, 1);

-- Plane
INSERT INTO Plane VALUES (1, '737 MAX', '2019-03-01', 210, 41000, 3550, 'Operational', 1, 1, 1);
INSERT INTO Plane VALUES (2, 'A320neo', '2020-07-10', 180, 39000, 3400, 'Operational', 2, 2, 2);
INSERT INTO Plane VALUES (3, 'E195-E2', '2021-11-25', 132, 41000, 2800, 'In Maintenance', 3, 3, 3);

-- Pilot
INSERT INTO Pilot VALUES (1, 'Alice Johnson', 'D12345', 'Captain', 12, 1);
INSERT INTO Pilot VALUES (2, 'James Smith', 'B98765', 'First Officer', 5, 2);
INSERT INTO Pilot VALUES (3, 'Sarah Lee', 'F67890', 'Captain', 8, 3);

-- Pilot_Plane
INSERT INTO Pilot_Plane VALUES ('2022-01-15', 1, 1);
INSERT INTO Pilot_Plane VALUES ('2023-03-22', 2, 2);
INSERT INTO Pilot_Plane VALUES ('2024-06-05', 3, 3);
