DROP TABLE IF EXISTS `mvte-318912.mv.treat_limit`;
CREATE TABLE `mvte-318912.mv.treat_limit` AS 
WITH code AS
(
  SELECT  ce.stay_id,ce.charttime,ce.value
  FROM     `physionet-data.mimiciv_icu.chartevents` ce
  WHERE    ce.value IS NOT NULL and ce.itemid IN (223758,228687)
)

,hr_table AS
(
  SELECT      code.stay_id,
              value as code_status,
              charttime,
              cast(floor(datetime_diff(charttime, intime, minute) / 60) AS int64 ) AS hr
  FROM       `physionet-data.mimiciv_icu.icustays` icu
  INNER JOIN code
  ON         icu.stay_id = code.stay_id ) 


,create_groups AS (
  select icu.stay_id,icu.hr, h.*EXCEPT(stay_id,hr),
  COUNT(h.code_status) OVER (PARTITION BY icu.stay_id ORDER BY icu.hr) AS g1
  FROM  `mvte-318912.mv.icu_720h` icu
  LEFT JOIN 
  hr_table h
  ON  icu.stay_id  = h.stay_id
  AND icu.hr  = h.hr
)

,forward_filling_code as
(
SELECT stay_id,hr, 
MAX(create_groups.code_status) OVER(PARTITION BY stay_id,g1 ORDER BY hr) AS code_status,
FROM create_groups
)

,code_per_hr AS (
  SELECT stay_id,hr,
  MAX(code_status) AS code_status,
  FROM forward_filling_code
  GROUP BY stay_id, hr
)

SELECT * from code_per_hr