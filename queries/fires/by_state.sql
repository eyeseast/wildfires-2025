SELECT
    *
FROM
    `fires`
where
    attr_POOState = coalesce(NULLIF(:state, ''), 'US-CA')