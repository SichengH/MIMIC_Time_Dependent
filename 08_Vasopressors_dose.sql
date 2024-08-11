DROP TABLE IF EXISTS `mvte-318912.mv.pressors`;
CREATE TABLE `mvte-318912.mv.pressors` AS
WITH vaso_duration AS (
    SELECT 
    stay_id
    ,norepinephrine_equivalent_dose
    ,starttime
    ,endtime
    ,extract (MINUTE from endtime-starttime) as duration #sometimes duration is 0
    ,norepinephrine_equivalent_dose / (extract (MINUTE from endtime-starttime) + 1) as dose
    FROM `physionet-data.mimiciv_derived.norepinephrine_equivalent_dose`
    #where stay_id = 31326208
    #rder by starttime limit 1
)
, hourly AS (
    SELECT 
    main.starttime
    ,main.endtime
    ,main.hr
    ,main.stay_id
    ,CASE WHEN vaso.dose IS NOT NULL THEN vaso.dose
    ELSE 0 END AS dose
    FROM `mvte-318912.mv.icu_720h` main
    LEFT JOIN vaso_duration vaso
    ON main.stay_id = vaso.stay_id
    WHERE vaso.starttime > main.starttime
    AND vaso.starttime < main.endtime
    OR vaso.endtime > main.starttime
    AND vaso.endtime < main.endtime
)

,hourly_avg AS (
    SELECT hr,stay_id,avg(dose) as vaso_dose_per_min
    FROM hourly
    GROUP BY hr,stay_id
)

SELECT * FROM hourly_avg
