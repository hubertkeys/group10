-- Drop the database if it exists
DROP DATABASE IF EXISTS group10;
CREATE DATABASE group10;
USE group10;

-- Patients Table
DROP TABLE IF EXISTS pomba_patient;
CREATE TABLE pomba_patient(
    patientID INT(5) AUTO_INCREMENT PRIMARY KEY,
    patientName VARCHAR(150),
    patientDOB DATE,
    patientPhone VARCHAR(13),
    patientAddress VARCHAR(255)
)
AUTO_INCREMENT = 10000;

-- Procedure to insert patient details
DELIMITER //
DROP PROCEDURE IF EXISTS insert_patient;
CREATE PROCEDURE insert_patient(
    IN Name VARCHAR(150),
    IN DOB DATE,
    IN Phone VARCHAR(13),
    IN Address VARCHAR(255)
)
BEGIN
    INSERT INTO pomba_patient (patientName, patientDOB, patientPhone, patientAddress) 
    VALUES (Name, DOB, Phone, Address);
END //
DELIMITER ;

-- Doctors Table
DROP TABLE IF EXISTS zano_doctor;
CREATE TABLE zano_doctor(
    doctorsMedicalLicense INT(5) AUTO_INCREMENT PRIMARY KEY,
    doctorsName VARCHAR(150),
    doctorsGender ENUM('M','F'),
    doctorsPhone VARCHAR(13),
    doctorsQualification VARCHAR(150)
)
AUTO_INCREMENT = 20000;

-- Procedure to insert doctor details
DELIMITER //
DROP PROCEDURE IF EXISTS insert_doctor;
CREATE PROCEDURE insert_doctor(
    IN Name VARCHAR(150),
    IN Gender ENUM('M','F'),
    IN Phone VARCHAR(13),
    IN Qualification VARCHAR(150)
)
BEGIN
    INSERT INTO zano_doctor (doctorsName, doctorsGender, doctorsPhone, doctorsQualification) 
    VALUES (Name, Gender, Phone, Qualification);
END //
DELIMITER ;

-- Rooms Table
DROP TABLE IF EXISTS masela_room;
CREATE TABLE masela_room(
    roomNumber VARCHAR(5) PRIMARY KEY,
    bedCount INT,
    currentOccupancy INT DEFAULT 0,
    availabilityStatus ENUM('Available', 'Full', 'UnderMaintenance') DEFAULT 'Available',
    roomType ENUM('General', 'Private', 'ICU')
);

-- Procedure to insert room details
DELIMITER //
DROP PROCEDURE IF EXISTS insert_room;
CREATE PROCEDURE insert_room(
    IN room_number VARCHAR(5),
    IN bed_count INT,
    IN room_type ENUM('General', 'Private', 'ICU')
)
BEGIN
    INSERT INTO masela_room (roomNumber, bedCount, roomType) 
    VALUES (room_number, bed_count, room_type);
END //
DELIMITER ;

-- Admissions Table
DROP TABLE IF EXISTS moyikwa_admission;
CREATE TABLE moyikwa_admission(
    patientID INT(5),
    doctorsID INT(5),
    roomNumber VARCHAR(5),
    severityOfCondition ENUM('Mild', 'Moderate', 'Severe', 'Critical'),
    admissionDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (patientID, doctorsID),
    FOREIGN KEY (patientID) REFERENCES pomba_patient(patientID),
    FOREIGN KEY (doctorsID) REFERENCES zano_doctor(doctorsMedicalLicense),
    FOREIGN KEY (roomNumber) REFERENCES masela_room(roomNumber)
);

-- Procedure to admit patient
DELIMITER //
DROP PROCEDURE IF EXISTS admit_patient;
CREATE PROCEDURE admit_patient(
    IN patients INT(5),
    IN doctors INT(5),
    IN room VARCHAR(5),
    IN pcondition ENUM('Mild', 'Moderate', 'Severe', 'Critical')
)
BEGIN
    INSERT INTO moyikwa_admission (patientID, doctorsID, roomNumber, severityOfCondition) 
    VALUES (patients, doctors, room, pcondition);
END //
DELIMITER ;

-- Prescription Table
DROP TABLE IF EXISTS keith_prescription;
CREATE TABLE keith_prescription(
    prescriptionID INT(5) AUTO_INCREMENT PRIMARY KEY,
    patientID INT(5),
    doctorsID INT(5),
    medicationName VARCHAR(150),
    startDate DATE,
    FOREIGN KEY (patientID) REFERENCES pomba_patient(patientID),
    FOREIGN KEY (doctorsID) REFERENCES zano_doctor(doctorsMedicalLicense)
)
AUTO_INCREMENT = 40000;

-- Procedure to insert prescription details
DELIMITER //
DROP PROCEDURE IF EXISTS insert_prescription;
CREATE PROCEDURE insert_prescription(
    IN patient INT(5),
    IN doctor INT(5),
    IN medication VARCHAR(150),
    IN date DATE
)
BEGIN
    INSERT INTO keith_prescription (patientID, doctorsID, medicationName, startDate) 
    VALUES (patient, doctor, medication, date);
END //
DELIMITER ;

-- Triggers to update room status on admission insert and delete
DELIMITER //

DROP TRIGGER IF EXISTS update_room_status_on_admission_insert//
CREATE TRIGGER update_room_status_on_admission_insert
AFTER INSERT ON moyikwa_admission
FOR EACH ROW
BEGIN
    DECLARE patient_count INT;
    DECLARE room_occupancy INT;
    DECLARE room_bed_count INT;
    
    -- Count the number of patients assigned to the doctor
    SELECT COUNT(*) INTO patient_count FROM moyikwa_admission WHERE doctorsID = NEW.doctorsID;
    
    -- Check if doctor has more than 2 patients
    IF patient_count > 2 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Doctor cannot have more than 2 patients';
    END IF;
    
    -- Get the number of people in the room and the number of beds
    SELECT currentOccupancy, bedCount INTO room_occupancy, room_bed_count
    FROM masela_room WHERE roomNumber = NEW.roomNumber;

    -- Check if room is full
    IF room_occupancy + 1 > room_bed_count THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'The room is full';
    END IF;
    
    -- Update room occupancy
    IF room_occupancy + 1 = room_bed_count THEN
        UPDATE masela_room SET currentOccupancy = currentOccupancy + 1, availabilityStatus = 'Full' WHERE roomNumber = NEW.roomNumber;
    ELSE
        UPDATE masela_room SET currentOccupancy = currentOccupancy + 1 WHERE roomNumber = NEW.roomNumber;
    END IF;
END //

DROP TRIGGER IF EXISTS update_room_status_on_admission_delete//
CREATE TRIGGER update_room_status_on_admission_delete
BEFORE DELETE ON moyikwa_admission
FOR EACH ROW
BEGIN
    DECLARE room_occupancy INT;
    DECLARE room_bed_count INT;
    
    -- Get current occupancy and bed count of the room
    SELECT currentOccupancy, bedCount INTO room_occupancy, room_bed_count
    FROM masela_room WHERE roomNumber = OLD.roomNumber;
    
    -- Update room occupancy
    IF room_occupancy = room_bed_count THEN
        UPDATE masela_room SET currentOccupancy = currentOccupancy - 1, availabilityStatus = 'Available' WHERE roomNumber = OLD.roomNumber;
    ELSE
        UPDATE masela_room SET currentOccupancy = currentOccupancy - 1 WHERE roomNumber = OLD.roomNumber;
    END IF;
END //

DELIMITER ;




-- PROCEDURE TO DELETE ADMISSION
DELIMITER //
DROP PROCEDURE IF EXISTS delete_admission;
CREATE PROCEDURE delete_admission(
    IN patientID INT(5),
    IN doctorID INT(5)
)
BEGIN
    DELETE FROM moyikwa_admission WHERE patientID = patientID AND doctorsID = doctorID;
END //
DELIMITER ;

-- PROCEDURE TO DELETE PRESCRIPTION
DELIMITER //
DROP PROCEDURE IF EXISTS delete_prescription;
CREATE PROCEDURE delete_prescription(
    IN prescriptionID INT(5)
)
BEGIN
    DELETE FROM keith_prescription WHERE prescriptionID = prescriptionID;
END //
DELIMITER ;

-- PROCEDURE TO DELETE PATIENT
DELIMITER //
DROP PROCEDURE IF EXISTS delete_patient;
CREATE PROCEDURE delete_patient(
    IN patientID INT(5)
)
BEGIN
    DELETE FROM pomba_patient WHERE patientID = patientID;
END //
DELIMITER ;

-- PROCEDURE TO DELETE DOCTOR
DELIMITER //
DROP PROCEDURE IF EXISTS delete_doctor;
CREATE PROCEDURE delete_doctor(
    IN doctorID INT(5)
)
BEGIN
    DELETE FROM zano_doctor WHERE doctorsMedicalLicense = doctorID;
END //
DELIMITER ;

-- PROCEDURE TO DELETE ROOM
DELIMITER //
DROP PROCEDURE IF EXISTS delete_room;
CREATE PROCEDURE delete_room(
    IN room_number VARCHAR(5)
)
BEGIN
    DELETE FROM masela_room WHERE roomNumber = room_number;
END //
DELIMITER ;






-- PROCEDURE TO UPDATE PATIENT
DELIMITER //
DROP PROCEDURE IF EXISTS update_patient;
CREATE PROCEDURE update_patient(
    IN patientID INT(5),
    IN Name VARCHAR(150),
    IN DOB DATE,
    IN Phone VARCHAR(13),
    IN Address VARCHAR(255)
)
BEGIN
    UPDATE pomba_patient 
    SET patientName = Name, patientDOB = DOB, patientPhone = Phone, patientAddress = Address 
    WHERE patientID = patientID;
END //
DELIMITER ;

-- PROCEDURE TO UPDATE DOCTOR
DELIMITER //
DROP PROCEDURE IF EXISTS update_doctor;
CREATE PROCEDURE update_doctor(
    IN doctorID INT(5),
    IN Name VARCHAR(150),
    IN Gender ENUM('M','F'),
    IN Phone VARCHAR(13),
    IN Qualification VARCHAR(150)
)
BEGIN
    UPDATE zano_doctor 
    SET doctorsName = Name, doctorsGender = Gender, doctorsPhone = Phone, doctorsQualification = Qualification 
    WHERE doctorsMedicalLicense = doctorID;
END //
DELIMITER ;

-- PROCEDURE TO UPDATE ROOM
DELIMITER //
DROP PROCEDURE IF EXISTS update_room;
CREATE PROCEDURE update_room(
    IN room_number VARCHAR(5),
    IN bed_count INT,
    IN availability_status ENUM('Available', 'Full', 'UnderMaintenance'),
    IN room_type ENUM('General', 'Private', 'ICU')
)
BEGIN
    UPDATE masela_room 
    SET bedCount = bed_count, availabilityStatus = availability_status, roomType = room_type 
    WHERE roomNumber = room_number;
END //
DELIMITER ;

-- PROCEDURE TO UPDATE ADMISSION
DELIMITER //
DROP PROCEDURE IF EXISTS update_admission;
CREATE PROCEDURE update_admission(
    IN patientID INT(5),
    IN doctorID INT(5),
    IN room VARCHAR(5),
    IN pcondition ENUM('Mild', 'Moderate', 'Severe', 'Critical')
)
BEGIN
    UPDATE moyikwa_admission 
    SET roomNumber = room, severityOfCondition = pcondition 
    WHERE patientID = patientID AND doctorsID = doctorID;
END //
DELIMITER ;

-- PROCEDURE TO UPDATE PRESCRIPTION
DELIMITER //
DROP PROCEDURE IF EXISTS update_prescription;
CREATE PROCEDURE update_prescription(
    IN prescriptionID INT(5),
    IN medication VARCHAR(150),
    IN startDate DATE
)
BEGIN
    UPDATE keith_prescription 
    SET medicationName = medication, startDate = startDate 
    WHERE prescriptionID = prescriptionID;
END //
DELIMITER ;






-- PROCEDURE TO GET PATIENTS BY DOCTOR
DELIMITER //
DROP PROCEDURE IF EXISTS get_patients_by_doctor;
CREATE PROCEDURE get_patients_by_doctor(
    IN doctorID INT(5)
)
BEGIN
    SELECT pomba_patient.patientID, pomba_patient.patientName, pomba_patient.patientDOB, pomba_patient.patientPhone, pomba_patient.patientAddress
    FROM pomba_patient
    INNER JOIN moyikwa_admission ON pomba_patient.patientID = moyikwa_admission.patientID
    WHERE moyikwa_admission.doctorsID = doctorID;
END //
DELIMITER ;


-- PROCEDURE TO CHECK DOCTOR AVAILABILITY
DELIMITER //
DROP PROCEDURE IF EXISTS check_doctor_availability;
CREATE PROCEDURE check_doctor_availability(
    IN doctorID INT(5)
)
BEGIN
    DECLARE patient_count INT;
    DECLARE doctor_exists INT;
    
    -- Check if the doctor ID exists
    SELECT COUNT(*) INTO doctor_exists FROM zano_doctor WHERE doctorsMedicalLicense = doctorID;
    
    IF doctor_exists = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Doctor ID does not exist';
    ELSE
        -- Count the number of patients assigned to the doctor
        SELECT COUNT(*) INTO patient_count FROM moyikwa_admission WHERE doctorsID = doctorID;
        
        -- Check if doctor has less than or equal to 2 patients
        IF patient_count <= 2 THEN
            SELECT 'Available' AS Availability;
        ELSE
            SELECT 'Unavailable' AS Availability;
        END IF;
    END IF;
END //
DELIMITER ;


