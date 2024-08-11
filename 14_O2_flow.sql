DROP TABLE IF EXISTS `mvte-318912.mv.o2_flow`;
CREATE TABLE `mvte-318912.mv.o2_flow` AS (
  WITH difference_intime_to_charttime AS
  (
      SELECT
    c.charttime,
    c.valuenum AS o2_flow,
    c.itemid,
    icu.stay_id,
    CAST(
        FLOOR(DATETIME_DIFF(charttime, intime, minute) / 60) AS INT64
    ) AS hr
    FROM `physionet-data.mimiciv_icu.icustays` icu
    INNER JOIN `physionet-data.mimiciv_icu.chartevents` c
      ON icu.stay_id = c.stay_id
    WHERE c.itemid IN (224691,223834,227582)
) -- Flow rate (224691) count = 187k, unit = L/min, 
  -- O2 Flow (223834) count = 500k, unit = L/min
  -- Bipap O2 Flow (227582) 


  ,create_groups as  --basetable
(SELECT
    --*,
    b.stay_id, b.hr, v.*EXCEPT(stay_id,hr),
    COUNT(v.o2_flow) OVER (PARTITION BY b.stay_id ORDER BY b.hr) AS g1,
    FROM  `mvte-318912.mv.icu_720h` b
    LEFT JOIN 
    difference_intime_to_charttime v
    ON  b.stay_id  = v.stay_id
    AND b.hr  = v.hr
)

,forward_filling_vital as
(
SELECT stay_id,hr, 
MAX(o2_flow) OVER(PARTITION BY stay_id,g1 ORDER BY hr) AS o2_flow,
FROM create_groups
)

,vital_per_hr AS (
  SELECT stay_id,hr,
  MAX(o2_flow) AS o2_flow,
  FROM forward_filling_vital
  GROUP BY stay_id, hr
)

SELECT * FROM 
vital_per_hr
--WHERE stay_id = 33693326
order by stay_id,hr 
-- where stay_id = 34729559
--order by stay_id, hr
)




