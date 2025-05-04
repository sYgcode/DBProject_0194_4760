-- Hangar Table
CREATE TABLE Hangar (
  Hangar_id INT PRIMARY KEY,
  Location VARCHAR(80) NOT NULL,
  Name VARCHAR(50) NOT NULL
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

-- Plane Table
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

-- Pilot Table
CREATE TABLE Pilot (
  Pilot_id INT PRIMARY KEY,
  Name VARCHAR(50) NOT NULL,
  License_num VARCHAR(30) NOT NULL,
  Rank VARCHAR(20) NOT NULL,
  Experience INT NOT NULL,
  Operator_id INT NOT NULL,
  FOREIGN KEY (Operator_id) REFERENCES Operator(Operator_id)
);

-- Pilot_Plane (many-to-many relationship)
CREATE TABLE Pilot_Plane (
  Assignment_date DATE NOT NULL,
  Plane_id INT NOT NULL,
  Pilot_id INT NOT NULL,
  PRIMARY KEY (Plane_id, Pilot_id),
  FOREIGN KEY (Plane_id) REFERENCES Plane(Plane_id),
  FOREIGN KEY (Pilot_id) REFERENCES Pilot(Pilot_id)
);
