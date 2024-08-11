DROP TABLE IF EXISTS `mvte-318912.mv.pressors`;
CREATE TABLE `mvte-318912.mv.pressors` AS 
WITH four_vasopressors_itemid_amount_rate AS (
  SELECT stay_id, 
        linkorderid,
        rate as vaso_rate,
        amount as vaso_amount,
        starttime,
        endtime,
        itemid
FROM `physionet-data.mimiciv_icu.inputevents`
WHERE itemid IN (221906,221289, 229617,221662,221749)
) -- norepinephrine,epinephrine,dopamine,phenylephrine

, add_label_column_to_four_vasopressors_from_d_items_table AS
(
    SELECT four_vasopressors_itemid_amount_rate.*, d.*EXCEPT(itemid) 
        FROM four_vasopressors_itemid_amount_rate 
    LEFT JOIN `physionet-data.mimiciv_icu.d_items` d
        ON four_vasopressors_itemid_amount_rate.itemid = d.itemid
)

 ,  generate_720_hrs AS 
    (
        SELECT * ,
        GENERATE_ARRAY(0,720) AS hr_array  
        FROM  add_label_column_to_four_vasopressors_from_d_items_table
    )
 ,  expands_720_hrs AS  
    (
        SELECT *  
        FROM generate_720_hrs 
        CROSS JOIN UNNEST(generate_720_hrs.hr_array) AS hr_starttimeref_vasop   
    )

, difference_starttime_to_endtime AS 
    (
    SELECT expands_720_hrs.*EXCEPT (hr_array),
    CAST(FLOOR(DATETIME_DIFF(endtime,starttime,MINUTE)/60) AS INT64) AS vaso_starttime_endtime_diff  
    FROM expands_720_hrs 
    )

, difference_intime_to_starttime_added as
    (
    SELECT difference_starttime_to_endtime.*,  
    CAST(FLOOR(DATETIME_DIFF(starttime,intime,MINUTE)/60) AS INT64) AS icuintime_vasostartime_diff_hr 
    FROM difference_starttime_to_endtime 
    LEFT JOIN `physionet-data.mimiciv_icu.icustays` icu_intime
    ON difference_starttime_to_endtime.stay_id = icu_intime.stay_id
    )
    ,vaso_hr_from_icuintime as
    (
    SELECT difference_intime_to_starttime_added.*EXCEPT(hr_starttimeref_vasop, vaso_starttime_endtime_diff, icuintime_vasostartime_diff_hr,linkorderid,itemid,abbreviation,linksto,
    category,unitname,param_type,lownormalvalue,highnormalvalue)
    ,icuintime_vasostartime_diff_hr + hr_starttimeref_vasop AS hr 
    FROM difference_intime_to_starttime_added
    where vaso_starttime_endtime_diff >= hr_starttimeref_vasop 
    )  

, vaso_indicator AS (SELECT
    stay_id,
    hr,
    label,
    CASE WHEN label IS NOT NULL THEN 1 ELSE 0 END AS vaso,
    FROM 
    vaso_hr_from_icuintime 
)

,remove_duplicate_hrs AS (SELECT
    stay_id,
    hr,
    IF(SUM(vaso) >= 1, 1, 0) AS vasopressor,
    FROM vaso_indicator
    WHERE hr >=0 
    GROUP BY stay_id, hr
)

SELECT * FROM  
remove_duplicate_hrs
ORDER BY stay_id, hr


