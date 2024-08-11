--Expand every icu stay to 720h
--Only use first icu stay per patients
DROP TABLE IF EXISTS `mvte-318912.mv.icu_720h`;
CREATE TABLE `mvte-318912.mv.icu_720h` AS 
WITH generates_720_hrs AS (
    SELECT
        adm.subject_id,
        adm.hadm_id,
        --adm.deathtime,
        --adm.dischtime,
        icu.stay_id,
        icu.intime,
        DATETIME_ADD(icu.intime,INTERVAL 1 HOUR) AS later,
        GENERATE_ARRAY(-24, 720) AS hr_array,
        DENSE_RANK() OVER (PARTITION BY  adm.subject_id 
        ORDER BY icu.intime) AS stay_number,  

    FROM  `physionet-data.mimiciv_hosp.admissions` adm
    INNER JOIN `physionet-data.mimiciv_icu.icustays` icu
        ON
            adm.hadm_id = icu.hadm_id
    ORDER BY
        adm.subject_id,
        adm.hadm_id,
        icu.stay_id
)

, icu_stays_expands_720_hrs AS (
    SELECT subject_id,
    hadm_id,
    stay_id,
    CAST(hr AS INT64) AS hr,
    DATETIME_ADD(intime,INTERVAL CAST(hr AS INT64) HOUR) AS starttime,
    DATETIME_ADD(later,INTERVAL CAST(hr AS INT64) HOUR) AS endtime
    FROM generates_720_hrs
    CROSS JOIN 
        UNNEST(generates_720_hrs.hr_array) AS hr
)

, first_icu AS (
    SELECT 
    subject_id,
    stay_id,
    intime,
    RANK() OVER (PARTITION BY subject_id ORDER BY intime ASC) AS rank
    FROM generates_720_hrs
)


SELECT * from icu_stays_expands_720_hrs
WHERE stay_id IN (
    SELECT stay_id FROM first_icu WHERE rank = 1
)