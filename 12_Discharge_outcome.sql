DROP TABLE IF EXISTS `mvte-318912.mv.discharge_outcome`;
CREATE TABLE `mvte-318912.mv.discharge_outcome` AS 
WITH difference_intime_to_dischtime AS (
    SELECT
        stay_id,
        CAST(
            FLOOR(DATETIME_DIFF(adm.dischtime, icu.intime, MINUTE) / 60) AS INT64
        ) AS hr
    FROM `physionet-data.mimiciv_icu.icustays` icu
    LEFT JOIN `physionet-data.mimiciv_hosp.admissions` adm
    ON icu.hadm_id = adm.hadm_id
)

, disch_outcome_table AS (
    SELECT
        hr.stay_id,
        hr.hr,
        CASE
            WHEN diff.hr IS NULL THEN 0  
            ELSE 1 END AS discharge_outcome
    FROM `mvte-318912.mv.icu_720h` hr
    LEFT JOIN difference_intime_to_dischtime diff
    ON hr.stay_id = diff.stay_id
    AND hr.hr = diff.hr
)

SELECT * FROM disch_outcome_table