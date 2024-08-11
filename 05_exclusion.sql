-- Exclude do not intubate
-- Exclude arrive intubated patients, invasive vent 24hr before intime to icu.
DROP TABLE IF EXISTS `mvte-318912.mv.exclusion`;
CREATE TABLE `mvte-318912.mv.exclusion` AS
WITH DNI as 
(
SELECT stay_id, value,itemid  
FROM `physionet-data.mimiciv_icu.chartevents`
WHERE (value LIKE '%DNI (do not intubate)%' AND itemid = 223758) 
OR (value LIKE '%DNR / DNI%' AND itemid = 223758) 
OR (value LIKE 'Comfort measures only' AND itemid = 223758)
OR (value LIKE '%DNI (do not intubate)%' AND itemid = 228687) 
OR (value LIKE '%DNAR (Do Not Attempt Resuscitation) [DNR] / DNI%' AND itemid = 228687)
OR (value LIKE 'Comfort measures only' AND itemid = 228687) 
)

, invasive_24hr_before_icu as
(
SELECT * ,
FROM `mvte-318912.mv.vent_status_hr`
where invasive = 1  
AND hr >= -24     
AND hr <=-1     
)

SELECT 
stay_id
FROM DNI
UNION ALL
SELECT 
stay_id
FROM invasive_24hr_before_icu
