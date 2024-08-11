DROP TABLE IF EXISTS `mvte-318912.mv.vent_status_hr`;
CREATE TABLE `mvte-318912.mv.vent_status_hr` AS 
(
WITH generate_720_hrs AS (
    SELECT * ,
    GENERATE_ARRAY(0,720) AS hr_array
    FROM `mvte-318912.mv.vent_status`
)

,expands_720_hrs as
(
SELECT *
FROM generate_720_hrs 
CROSS JOIN UNNEST(generate_720_hrs.hr_array) AS hr_starttimeref_vent  
)

,difference_starttime_to_endtime as
(
SELECT expands_720_hrs.*EXCEPT (hr_array),
CAST(FLOOR(DATETIME_DIFF(endtime,starttime,MINUTE)/60) AS INT64) AS vent_starttime_endtime_diff
FROM expands_720_hrs 
)
 
,difference_intime_to_starttime_added as
(
SELECT icu_intime.subject_id,difference_starttime_to_endtime.* ,
CAST(FLOOR(DATETIME_DIFF(starttime,intime,MINUTE)/60) AS INT64) AS icuintime_ventstartime_diff_hr 
FROM difference_starttime_to_endtime 
LEFT JOIN `physionet-data.mimiciv_icu.icustays` icu_intime
ON difference_starttime_to_endtime .stay_id = icu_intime.stay_id
)

,vent_hr_from_icuintime as
(
SELECT difference_intime_to_starttime_added.*EXCEPT(hr_starttimeref_vent,vent_starttime_endtime_diff,icuintime_ventstartime_diff_hr),
icuintime_ventstartime_diff_hr + hr_starttimeref_vent AS hr  
FROM difference_intime_to_starttime_added     
where vent_starttime_endtime_diff >= hr_starttimeref_vent   
),
vent_indicator AS (
    SELECT
        *,
        CASE
            WHEN ventilation_status LIKE "Invasive" THEN 1
            ELSE 0
        END
        AS invasive,
        CASE
            WHEN ventilation_status LIKE "Noninvasive" THEN 1
            ELSE 0
        END
        AS noninvasive,
        CASE
            WHEN ventilation_status LIKE "HighFlow" THEN 1
            ELSE 0
        END
        AS highflow
    FROM vent_hr_from_icuintime
    ORDER BY stay_id, hr
),

remove_transition_period_to_one_row AS (SELECT
    subject_id,
    stay_id,
    hr,
    IF(SUM(noninvasive) >= 1, 1, 0) AS noninvasive,
    IF(SUM(highflow) >= 1, 1, 0) AS highflow,
    IF(SUM(invasive) >= 1, 1, 0) AS invasive
    FROM vent_indicator
    GROUP BY subject_id, stay_id, hr
)

SELECT * FROM remove_transition_period_to_one_row
)
