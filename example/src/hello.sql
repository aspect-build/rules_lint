select
  *
from
  employee e,
  salary s
where
  e.emp_id   = s.emp_id
  and rownum = 1
order by
  s.salary desc
