-- Obtain last value or avg value for vital signs (time-dependent) from mimic-derived vitalsign table on an hourly view,
 -- as part of data imputations.
 -- (Use floor to obtain vital sign - because)
 --from vital signs: https://github.com/MIT-LCP/mimic-code/blob/main/mimic-iv/concepts/measurement/vitalsign.sql

DROP TABLE IF EXISTS `mvte-318912.mv.vital`;
CREATE TABLE `mvte-318912.mv.vital` AS (
  WITH difference_intime_to_charttime AS
  (
      SELECT
    vs.* EXCEPT(stay_id, subject_id),
    icu.stay_id,
    CAST(
        FLOOR(DATETIME_DIFF(charttime, intime, minute) / 60) AS INT64
    ) AS hr
    FROM `physionet-data.mimiciv_icu.icustays` icu
    INNER JOIN `physionet-data.mimiciv_derived.vitalsign` vs
      ON icu.stay_id = vs.stay_id
  )

  ,create_groups as  --basetable
(SELECT
    --*,
    b.stay_id, b.hr, v.*EXCEPT(stay_id,hr),
    COUNT(v.heart_rate) OVER (PARTITION BY b.stay_id ORDER BY b.hr) AS g1,
    COUNT(v.sbp) OVER (PARTITION BY b.stay_id ORDER BY b.hr) AS g2,
    COUNT(v.dbp) OVER (PARTITION BY b.stay_id ORDER BY b.hr) AS g3,
    COUNT(v.mbp) OVER (PARTITION BY b.stay_id ORDER BY b.hr) AS g4,
    COUNT(v.sbp_ni) OVER (PARTITION BY b.stay_id ORDER BY b.hr) AS g5,
    COUNT(v.dbp_ni) OVER (PARTITION BY b.stay_id ORDER BY b.hr) AS g6,
    COUNT(v.mbp_ni) OVER (PARTITION BY b.stay_id ORDER BY b.hr) AS g7,
    COUNT(v.resp_rate) OVER (PARTITION BY b.stay_id ORDER BY b.hr) AS g8,
    COUNT(v.temperature) OVER (PARTITION BY b.stay_id ORDER BY b.hr) AS g9,
    COUNT(v.spo2) OVER (PARTITION BY b.stay_id ORDER BY b.hr) AS g10,
    COUNT(v.glucose) OVER (PARTITION BY b.stay_id ORDER BY b.hr) AS g11
    FROM  `mvte-318912.mv.icu_720h` b
    LEFT JOIN 
    difference_intime_to_charttime v
    ON  b.stay_id  = v.stay_id
    AND b.hr  = v.hr
)

,forward_filling_vital as
(
SELECT stay_id,hr, 
MAX(heart_rate) OVER(PARTITION BY stay_id,g1 ORDER BY hr) AS heart_rate,
MAX(sbp) OVER(PARTITION BY stay_id,g2 ORDER BY hr) AS sbp,
MAX(dbp) OVER(PARTITION BY stay_id,g3 ORDER BY hr) AS dbp,
MAX(mbp) OVER(PARTITION BY stay_id,g4 ORDER BY hr) AS mbp,
MAX(sbp_ni) OVER(PARTITION BY stay_id,g5 ORDER BY hr) AS sbp_ni,
MAX(dbp_ni) OVER(PARTITION BY stay_id,g6 ORDER BY hr) AS dbp_ni,
MAX(mbp_ni) OVER(PARTITION BY stay_id,g7 ORDER BY hr) AS mbp_ni,
MAX(resp_rate) OVER(PARTITION BY stay_id,g8 ORDER BY hr) AS resp_rate,
MAX(temperature) OVER(PARTITION BY stay_id,g9 ORDER BY hr) AS temperature,
MAX(spo2) OVER(PARTITION BY stay_id,g10 ORDER BY hr) AS spo2,
MAX(glucose) OVER(PARTITION BY stay_id,g11 ORDER BY hr) AS glucose
FROM create_groups
)

,vital_per_hr AS (
  SELECT stay_id,hr,
  MAX(heart_rate) AS heart_rate,
  MAX(sbp) AS sbp,
  MIN(dbp) AS dbp,
  MIN(mbp) AS mbp,
  MAX(sbp_ni) AS sbp_ni,
  MIN(dbp_ni) AS dbp_ni,
  MIN(mbp_ni) AS mbp_ni,
  MAX(resp_rate) AS resp_rate,
  MAX(temperature) AS temperature,
  MIN(spo2) AS spo2,
  MAX(glucose) AS glucose
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
