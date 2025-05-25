
# 1 Total greenhouse water used for all Pumpkin Sprouts planted on June 15th.

SELECT SUM(WaterUsage) AS TotalWaterUsed
FROM `Sprout` S
JOIN `plant` P ON S.plantID = P.plantID
JOIN `Greenhouse Location` GL ON S.GreenhouseLocationID = GL.LocationID
JOIN `Equipment` E ON GL.LocationID = E.GreenhouseLocationID
JOIN `Equipment Usage Log` EUL ON E.EquipmentID = EUL.EquipmentID
WHERE P.CommonName = 'Pumpkin'
  AND S.PlantDate = '2024-03-01';
  
  
  
# 2 SELECT Health report, greenhouselocationID and healthrecordID
# for all sprouts that are not alive and were planted on March 1st.
SELECT GreenHouseLocationID, HealthRecordID, `Health Report`
FROM `Health Records` HR
JOIN `MATTHEWPELTER`.`Sprout` S ON HR.SproutID = S.SproutID
WHERE HR.isAlive = 0
  AND S.PlantDate = '2024-03-01';
  
  
# 3 Employee IDs of all employees who manage greenhouse locations 3 and 5.
SELECT EmployeeID
FROM `MATTHEWPELTER`.`Greenhouse Location`
WHERE LocationID IN (3, 5);


# 4 Give me the WaterFlowSetting, SoilWaterReading, water usage, and AlertTripLevel of all the equipment that has an equipment type of shears for greenhouse locations 3 and 5.
SELECT SD.WaterFlowSetting, EUL.SoilWaterReading, EUL.WaterUsage, E.AlertTripLevel
FROM `MATTHEWPELTER`.`Equipment` E
JOIN `MATTHEWPELTER`.`Equipment Usage Log` EUL ON E.EquipmentID = EUL.EquipmentID
JOIN `MATTHEWPELTER`.`Schedule Detail` SD ON EUL.ScheduleDetailID = SD.ScheduleDetailID
WHERE E.EquipmentType = 'shears'
  AND E.GreenhouseLocationID IN (3, 5);

# 5 Give me the SoilWaterTheshold for all ScheduleDetails that are in greenhouse locations that have Sprouts which are of the red maple plant type and order the results by SoilWaterThreshold values.
SELECT SoilWaterThreshold
FROM `MATTHEWPELTER`.`Schedule Detail` SD
JOIN `MATTHEWPELTER`.`Sprout` S ON SD.ScheduleID = S.ScheduleID
JOIN `MATTHEWPELTER`.`plant` P ON S.plantID = P.plantID
WHERE P.CommonName = 'Red Maple'
ORDER BY SoilWaterThreshold;

# 6 Give me the Water consumption and plant health for all plants in greenhouse location 1 over the last 2 months
SELECT EUL.WaterUsage, HR.`Health Report`
FROM `Sprout` S
JOIN `Greenhouse Location` GL ON S.GreenhouseLocationID = GL.LocationID
JOIN `Equipment` E ON GL.LocationID = E.GreenhouseLocationID
JOIN `Equipment Usage Log` EUL ON E.EquipmentID = EUL.EquipmentID
JOIN `Health Records` HR ON S.SproutID = HR.SproutID
WHERE GL.LocationID = 1
  AND EUL.DateAndTime >= DATE_SUB(CURDATE(), INTERVAL 2 MONTH);

# 7 Provide the equipment that triggered a system alert in the past 5 weeks as well as the corresponding logs.
SELECT E.EquipmentID, EUL.LogID, EUL.Description, EUL.ErrorLevel
FROM `MATTHEWPELTER`.`Equipment` E
JOIN `MATTHEWPELTER`.`Equipment Usage Log` EUL ON E.EquipmentID = EUL.EquipmentID
WHERE EUL.ErrorLevel IS NOT NULL
  AND EUL.DateAndTime >= DATE_SUB(CURDATE(), INTERVAL 5 WEEK);


# 8 Give me all health inspectors that inspected Sprout of id 3 in the last 6 months and the total number of inspections.
SELECT HI.HealthInspectorID, COUNT(*) AS TotalInspections
FROM `MATTHEWPELTER`.`Health Inspector` HI
JOIN `MATTHEWPELTER`.`Inspects` I ON HI.HealthInspectorID = I.HealthInspectorID
WHERE I.SproutID = 3
  AND I.Date >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
GROUP BY HI.HealthInspectorID;

# 9 Which plant species have the highest average water usage, grouped by greenhouse location. Only show average water greater than 10 liters.
SELECT P.Species, GL.LocationID, AVG(EUL.WaterUsage) AS AvgWaterUsage
FROM `MATTHEWPELTER`.`plant` P
JOIN `MATTHEWPELTER`.`Sprout` S ON P.plantID = S.plantID
JOIN `MATTHEWPELTER`.`Greenhouse Location` GL ON S.GreenhouseLocationID = GL.LocationID
JOIN `MATTHEWPELTER`.`Equipment` E ON GL.LocationID = E.GreenhouseLocationID
JOIN `MATTHEWPELTER`.`Equipment Usage Log` EUL ON E.EquipmentID = EUL.EquipmentID
GROUP BY P.Species, GL.LocationID
HAVING AVG(EUL.WaterUsage) > 10;

# 10 Give me the total water usage for all greenhouse locations managed by employees with a LicenseGrade of ‘A’.
SELECT SUM(EUL.WaterUsage) AS TotalWaterUsage
FROM `MATTHEWPELTER`.`Employee` E
JOIN `MATTHEWPELTER`.`Greenhouse Location` GL ON E.EmployeeID = GL.EmployeeID
JOIN `MATTHEWPELTER`.`Equipment` Eq ON GL.LocationID = Eq.GreenhouseLocationID
JOIN `MATTHEWPELTER`.`Equipment Usage Log` EUL ON Eq.EquipmentID = EUL.EquipmentID
WHERE E.LicenseGrade = 'A';


# 11 Determine the greenhouse locations that have plants and he ones that do not have plants.
SELECT GL.LocationID, GL.Description AS GreenhouseDescription, P.CommonName AS PlantName
FROM `Greenhouse Location` GL
LEFT JOIN `Sprout` S ON GL.LocationID = S.GreenhouseLocationID
LEFT JOIN `plant` P ON S.plantID = P.plantID
ORDER BY GL.LocationID;

# 12 Please report to me a ranking of the plants by how much water they consume.
SELECT  *, RANK() OVER(ORDER BY WaterAmount ASC) AS waterusage FROM watering_schedules ORDER BY waterusage ASC;

# 13 The company is trying to reduce it's power consumption. Please give me a list of all the ScheduleDetailIDs which have a power wattage that is greater than the power wattage used by the soil mixer.
 SELECT ScheduleDetailID FROM `Schedule Detail` WHERE PowerWattage > (SELECT PowerWattage FROM `Schedule Detail` WHERE EquipmentType ='Soil Mixer');

# Additional index
# Since we are frequently joining the equipment table with the greenhouse location table, it would be efficient to establish an index on the LocationID column in the equipment table to speed up the join on statement.




# PROCEDURE
DELIMITER //

CREATE PROCEDURE InsertPlantHealthRecord(
    IN p_SproutID INT,
    IN p_HealthInspectorID INT,
    IN p_ChlorophyllIndex INT,
    IN p_isAlive TINYINT,
    IN p_HealthReport VARCHAR(255),
    OUT p_HealthRecordID INT
)
BEGIN
    INSERT INTO `MATTHEWPELTER`.`Health Records` (SproutID, HealthInspectorID, ChlorophyllIndex, isAlive, `Health Report`)
    VALUES (p_SproutID, p_HealthInspectorID, p_ChlorophyllIndex, p_isAlive, p_HealthReport);

    SET p_HealthRecordID = LAST_INSERT_ID();
END //

DELIMITER ;


# Trigger 
DELIMITER //

CREATE TRIGGER AfterPlantHealthUpdate
AFTER INSERT ON `MATTHEWPELTER`.`Health Records`
FOR EACH ROW
BEGIN
    IF NEW.isAlive = 0 OR NEW.ChlorophyllIndex < 15 THEN
        UPDATE `Sprout`
        SET Status = 'Needs Immediate Attention'
        WHERE SproutID = NEW.SproutID;
    END IF;
END //

DELIMITER ;