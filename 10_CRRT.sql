DROP TABLE IF EXISTS `mvte-318912.mv.crrt`;
CREATE TABLE `mvte-318912.mv.crrt` AS 
WITH crrt_settings AS
(
  SELECT  ce.stay_id,
          ce.charttime,
          MIN(ce.itemid) as itemid,
          MIN(ce.value) as value,
          MIN(ce.valuenum) as valuenum,
          max(
          CASE
                    WHEN ce.itemid IN ( 224144, -- Blood Flow (ml/min)
                                        224191  -- Hourly Patient Fluid Removal    
                                      ) THEN 1
                    ELSE 0
          END ) AS rrt
  FROM     `physionet-data.mimiciv_icu.chartevents` ce
  WHERE    ce.value IS NOT NULL and ce.itemid IN (224144, 224191) 
  AND      ce.valuenum IS NOT NULL AND  ce.valuenum >0
  GROUP BY stay_id,
           charttime, 
           ce.value,
           ce.valuenum )

,hr_table AS
(
  SELECT      crrt_settings.stay_id,
              itemid,
              value,
              charttime,
              rrt,
              cast(floor(datetime_diff(charttime, intime, minute) / 60) AS int64 ) AS hr
  FROM       `physionet-data.mimiciv_icu.icustays` icu
  INNER JOIN crrt_settings
  ON         icu.stay_id = crrt_settings.stay_id ) 

SELECT distinct stay_id,hr,rrt
FROM hr_table
WHERE hr >=0 
ORDER BY stay_id, hr