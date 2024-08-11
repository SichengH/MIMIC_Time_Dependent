-- from sepsis3 mimiciv throughout icu stay rather than just on admission compared to mimic-iii
-- https://github.com/MIT-LCP/mimic-code/blob/main/mimic-iv/concepts/sepsis/sepsis3.sql

DROP TABLE IF EXISTS `mvte-318912.mv.sepsis3`;
CREATE TABLE `mvte-318912.mv.sepsis3` AS 
WITH sepsis3_onset AS
(SELECT
    `physionet-data.mimiciv_icu.icustays`.*,
    `physionet-data.mimiciv_derived.sepsis3`.* EXCEPT(stay_id, subject_id),
    CAST(
        FLOOR(
            DATETIME_DIFF(suspected_infection_time, intime, MINUTE) / 60
        ) AS INT64
    ) AS hr
    FROM `physionet-data.mimiciv_icu.icustays`
    INNER JOIN `physionet-data.mimiciv_derived.sepsis3`
        ON
            `physionet-data.mimiciv_icu.icustays`.stay_id = `physionet-data.mimiciv_derived.sepsis3`.stay_id
            AND `physionet-data.mimiciv_icu.icustays`.subject_id = `physionet-data.mimiciv_derived.sepsis3`.subject_id
)

SELECT

    stay_id,
    hr,
    --convert true to 1 (string to int)
    CAST(sepsis3 AS INT64) AS sepsis3 

FROM sepsis3_onset
WHERE hr >= 0
ORDER BY stay_id, hr

