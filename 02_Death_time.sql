--if patient die, all rows become 1
DROP TABLE IF EXISTS `mvte-318912.mv.deathtime`;
CREATE TABLE `mvte-318912.mv.deathtime` AS 
  WITH combine_deathtime AS(
    SELECT adm.subject_id,adm.hadm_id,
    COALESCE(adm.deathtime, pt.dod) AS deathtime 
    FROM `physionet-data.mimiciv_hosp.admissions` adm
    LEFT JOIN `physionet-data.mimiciv_hosp.patients` pt
  ON adm.subject_id = pt.subject_id 
  )
  SELECT DISTINCT
    main.*,
    d.deathtime,
    CASE WHEN d.deathtime < main.endtime 
    THEN 1 ELSE 0 END AS death_outcome
    FROM `mvte-318912.mv.icu_720h` main
    LEFT JOIN combine_deathtime d
    ON main.subject_id = d.subject_id
    AND main.hadm_id = d.hadm_id
    --WHERE deathtime < endtime
    --AND deathtime > starttime

