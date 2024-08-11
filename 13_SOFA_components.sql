--Put all of the sofa components here:
--Resp: Fio2, Pao2
--Neural: GCS
--Renal: urine output and creatine 
--Cardio: vasopressor(already have) and mean bp(already have)
--Liver: bilirubin
--Coagulation: plates. 

DROP TABLE IF EXISTS `mvte-318912.mv.SOFA_components`;
CREATE TABLE `mvte-318912.mv.SOFA_components` AS 
WITH 
fio2_raw AS (
  SELECT 
  stay_id,
  charttime,
  valuenum
  FROM `physionet-data.mimiciv_icu.chartevents`
  WHERE itemid = 223835
  UNION ALL
  SELECT 
  icu.stay_id,
  lab.charttime,
  lab.valuenum
  FROM `physionet-data.mimiciv_hosp.labevents` lab
  INNER JOIN `physionet-data.mimiciv_icu.icustays` icu
  ON lab.hadm_id = icu.hadm_id
  WHERE itemid = 50816
),

fio2 AS (
  SELECT 
  stay_id,
  charttime,
  CASE
    WHEN valuenum > 0.2 AND valuenum <= 1
      THEN valuenum * 100
    -- improperly input data - looks like O2 flow in litres
    WHEN valuenum > 1 AND valuenum < 20
      THEN NULL
    WHEN valuenum >= 20 AND valuenum <= 100
      THEN valuenum
    ELSE NULL END AS fio2
    FROM fio2_raw
),

var AS (
  SELECT co.stay_id, co.hr
        -- gcs
        , MIN(gcs.gcs) AS gcs_min
        , MAX(enz.bilirubin_total) AS bilirubin_max
        , MAX(chem.creatinine) AS creatinine_max
        , MIN(cbc.platelet) AS platelet_min
        , MAX(fio2.fio2) AS fio2
    FROM `mvte-318912.mv.icu_720h` co
    LEFT JOIN `physionet-data.mimiciv_derived.gcs` gcs
        ON co.stay_id = gcs.stay_id
            AND DATETIME_ADD(co.starttime, INTERVAL 1 HOUR) < gcs.charttime
            AND DATETIME_ADD(co.endtime, INTERVAL 1 HOUR) >= gcs.charttime
    LEFT JOIN `physionet-data.mimiciv_derived.enzyme` enz
        ON co.hadm_id = enz.hadm_id
            AND DATETIME_ADD(co.starttime, INTERVAL 1 HOUR) < enz.charttime
            AND DATETIME_ADD(co.endtime, INTERVAL 1 HOUR) >= enz.charttime
    LEFT JOIN `physionet-data.mimiciv_derived.chemistry` chem
        ON co.hadm_id = chem.hadm_id
            AND DATETIME_ADD(co.starttime, INTERVAL 1 HOUR) < chem.charttime
            AND DATETIME_ADD(co.endtime, INTERVAL 1 HOUR) >= chem.charttime
    LEFT JOIN `physionet-data.mimiciv_derived.complete_blood_count` cbc
        ON co.hadm_id = cbc.hadm_id
            AND DATETIME_ADD(co.starttime, INTERVAL 1 HOUR) < cbc.charttime
            AND DATETIME_ADD(co.endtime, INTERVAL 1 HOUR) >= cbc.charttime
    LEFT JOIN fio2
        ON co.stay_id = fio2.stay_id
            AND DATETIME_ADD(co.starttime, INTERVAL 1 HOUR) < fio2.charttime
            AND DATETIME_ADD(co.endtime, INTERVAL 1 HOUR) >= fio2.charttime
    GROUP BY co.stay_id, co.hr
),

create_groups as  --basetable
(SELECT
    var.*,
    COUNT(gcs_min) OVER (PARTITION BY stay_id ORDER BY hr) AS g1,
    COUNT(bilirubin_max) OVER (PARTITION BY stay_id ORDER BY hr) AS g2,
    COUNT(creatinine_max) OVER (PARTITION BY stay_id ORDER BY hr) AS g3,
    COUNT(platelet_min) OVER (PARTITION BY stay_id ORDER BY hr) AS g4,
    COUNT(fio2) OVER (PARTITION BY stay_id ORDER BY hr) AS g5,
    FROM var
)
,forward_filling_var AS
(
SELECT 
stay_id,hr, 
MIN(gcs_min) OVER(PARTITION BY stay_id,g1 ORDER BY hr) AS gcs_min,
MAX(bilirubin_max) OVER(PARTITION BY stay_id,g2 ORDER BY hr) AS bilirubin_max,
MAX(creatinine_max) OVER(PARTITION BY stay_id,g3 ORDER BY hr) AS creatinine_max,
MIN(platelet_min) OVER(PARTITION BY stay_id,g4 ORDER BY hr) AS platelet_min,
MAX(fio2) OVER(PARTITION BY stay_id,g5 ORDER BY hr) AS fio2
FROM create_groups
)


SELECT * FROM forward_filling_var
--where stay_id = 37771457
ORDER BY stay_id