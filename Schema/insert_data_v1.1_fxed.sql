-- ============================================================================
--  FinCore - Seed / Demo Data
--  File    : data/insert_data.sql
--  Target  : MySQL 8.0.16+ · schema/create_tables.sql v2.1
--  Owner   : Harsita (AU25UG-019)
--
--  CHANGELOG
--    v1.0 (Harsita): initial seed for DDL v2.1 - 3,240 rows, deterministic.
--    v1.1 (review fix, Aryan): the branches INSERT listed 4 columns but its
--          SELECT produced only 3 values (the city was only embedded in the
--          name CONCAT) -> MySQL Error 1136. Added the city ELT as its own
--          SELECT item. Count comments corrected: the script produces 552
--          transactions (Branch 1 has 12 accounts, not 10, so section C
--          inserts 12 salary deposits) and 3,242 rows in total.
--
--  DATA DESIGN NOTES
--    * No RAND(): every value is a formula on n -> identical data every run.
--    * Conventions per repo smoke test: IFSC 'AUSB'+7, 'ACC1'+7 account
--      numbers, @example.com emails, 'TR'+10 transfer refs, lowercase ENUMs.
--    * Transfers follow D2: transfer_out + transfer_in pairs, shared ref.
--    * balances are the CURRENT truth; transactions cover only the last ~12
--      months of each account's life (accounts opened years earlier) - the
--      documented balance deviation, NORMALIZATION.md §7.
--    * Explicit PKs (1..N) keep every reference deterministic and readable.
--
--  RUN ORDER (the DDL is the reset button - always re-run it first):
--      mysql -u root -p < schema/create_tables.sql
--      mysql -u root -p < data/insert_data.sql
-- ============================================================================

USE fincore;

-- ----------------------------------------------------------------------------
-- 0 · Number series 1..1000 (temporary helper; dropped at the end)
-- ----------------------------------------------------------------------------
DROP TEMPORARY TABLE IF EXISTS seq;
CREATE TEMPORARY TABLE seq (n INT PRIMARY KEY);

INSERT INTO seq (n)
SELECT a.d + b.d * 10 + c.d * 100 + 1
FROM (SELECT 0 d UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3
      UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7
      UNION ALL SELECT 8 UNION ALL SELECT 9) a
CROSS JOIN (SELECT 0 d UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3
      UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7
      UNION ALL SELECT 8 UNION ALL SELECT 9) b
CROSS JOIN (SELECT 0 d UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3
      UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7
      UNION ALL SELECT 8 UNION ALL SELECT 9) c;

START TRANSACTION;

-- ----------------------------------------------------------------------------
-- 1 · BRANCHES (200) - 8 name templates x 25 cities = 200 unique names
--     (period LCM(8,25)=200, so no two branches share a name)
--     v1.1: city now has its own SELECT item (was missing -> Error 1136)
-- ----------------------------------------------------------------------------
INSERT INTO branches (branch_id, name, city, ifsc_code)
SELECT n,
       CONCAT(ELT(1 + ((n - 1) MOD 8),
                  'Main Road','City Centre','Industrial Estate','Riverside',
                  'Market','Central','Tech Park','Old Town'),
              ' Branch, ',
              ELT(1 + ((n - 1) MOD 25),
                  'Bengaluru','Mysuru','Mangaluru','Hubballi','Chennai','Coimbatore',
                  'Madurai','Salem','Erode','Mumbai','Pune','Nagpur','Nashik','Thane',
                  'New Delhi','Gurugram','Noida','Ghaziabad','Hyderabad','Warangal',
                  'Vijayawada','Visakhapatnam','Kolkata','Howrah','Patna')),
       ELT(1 + ((n - 1) MOD 25),
           'Bengaluru','Mysuru','Mangaluru','Hubballi','Chennai','Coimbatore',
           'Madurai','Salem','Erode','Mumbai','Pune','Nagpur','Nashik','Thane',
           'New Delhi','Gurugram','Noida','Ghaziabad','Hyderabad','Warangal',
           'Vijayawada','Visakhapatnam','Kolkata','Howrah','Patna'),
       CONCAT('AUSB', LPAD(n, 7, '0'))
FROM seq
WHERE n <= 200;

-- ----------------------------------------------------------------------------
-- 2 · CUSTOMERS (200) - names from 40x40 pools; the n DIV 40 offset breaks the
--     40-period so all 200 full names differ. Phones/emails unique by formula.
--     Customer 1 = Divya Hegde, the engineered "whale" for Q5.
-- ----------------------------------------------------------------------------
INSERT INTO customers (customer_id, full_name, dob, phone, email, address)
SELECT n,
       CONCAT(fn, ' ', ln),
       DATE_ADD('1962-01-05', INTERVAL (n * 97 MOD 15000) DAY),
       CONCAT('9', LPAD(n * 719, 9, '0')),
       CONCAT(LOWER(fn), '.', LOWER(ln), n, '@example.com'),
       CONCAT((n * 13 MOD 400) + 1, ', ',
              ELT(1 + ((n - 1) MOD 25),
                  'Bengaluru','Mysuru','Mangaluru','Hubballi','Chennai','Coimbatore',
                  'Madurai','Salem','Erode','Mumbai','Pune','Nagpur','Nashik','Thane',
                  'New Delhi','Gurugram','Noida','Ghaziabad','Hyderabad','Warangal',
                  'Vijayawada','Visakhapatnam','Kolkata','Howrah','Patna'),
              ' ', 400000 + (n * 137 MOD 99999))
FROM (SELECT n,
             ELT(1 + (n * 7 MOD 40),
                 'Arjun','Priya','Rahul','Sneha','Vikram','Ananya','Karthik','Divya',
                 'Rohit','Meera','Sanjay','Kavya','Amit','Lakshmi','Farhan','Ishita',
                 'Naveen','Pooja','Rajesh','Anita','Suresh','Deepa','Manoj','Rekha',
                 'Girish','Nidhi','Vikas','Shreya','Prakash','Archana','Mohan','Vandana',
                 'Dinesh','Sunitha','Ravi','Geetha','Ajay','Rohini','Murali','Chaitra') AS fn,
             ELT(1 + ((n * 11 + n DIV 40) MOD 40),
                 'Sharma','Iyer','Patel','Reddy','Nair','Rao','Menon','Gupta',
                 'Joshi','Kulkarni','Shetty','Hegde','Pillai','Krishnan','Subramanian',
                 'Chandra','Das','Bose','Khan','Sheikh','Ansari','Sinha','Verma','Khanna',
                 'Kapoor','Malhotra','Bansal','Agarwal','Chauhan','Yadav','Singh','Kaur',
                 'Bhat','Nayak','Pai','Shenoy','Kamath','Desai','Shah','Mehta') AS ln
      FROM seq
      WHERE n <= 200) c;

-- ----------------------------------------------------------------------------
-- 3 · EMPLOYEES (200) - 50 branches x 4 staff. id = 1 (mod 4) is the branch
--     manager (manager_id NULL = top of chain); the other three report to
--     them. manager_id is always LOWER than employee_id, so the v2.1 trigger
--     never fires and FK insert order is safe (ORDER BY n).
-- ----------------------------------------------------------------------------
INSERT INTO employees (employee_id, full_name, branch_id, designation,
                       manager_id, hire_date)
SELECT n,
       CONCAT(fn, ' ', ln),
       ((n - 1) DIV 4) + 1,
       ELT(1 + ((n - 1) MOD 4), 'manager','loan_officer','teller','cashier'),
       CASE WHEN (n - 1) MOD 4 = 0 THEN NULL
            ELSE ((n - 1) DIV 4) * 4 + 1 END,
       DATE_ADD('2005-06-01', INTERVAL (n * 173 MOD 6000) DAY)
FROM (SELECT n,
             ELT(1 + (n * 13 MOD 40),
                 'Arjun','Priya','Rahul','Sneha','Vikram','Ananya','Karthik','Divya',
                 'Rohit','Meera','Sanjay','Kavya','Amit','Lakshmi','Farhan','Ishita',
                 'Naveen','Pooja','Rajesh','Anita','Suresh','Deepa','Manoj','Rekha',
                 'Girish','Nidhi','Vikas','Shreya','Prakash','Archana','Mohan','Vandana',
                 'Dinesh','Sunitha','Ravi','Geetha','Ajay','Rohini','Murali','Chaitra') AS fn,
             ELT(1 + ((n * 17 + n DIV 40) MOD 40),
                 'Sharma','Iyer','Patel','Reddy','Nair','Rao','Menon','Gupta',
                 'Joshi','Kulkarni','Shetty','Hegde','Pillai','Krishnan','Subramanian',
                 'Chandra','Das','Bose','Khan','Sheikh','Ansari','Sinha','Verma','Khanna',
                 'Kapoor','Malhotra','Bansal','Agarwal','Chauhan','Yadav','Singh','Kaur',
                 'Bhat','Nayak','Pai','Shenoy','Kamath','Desai','Shah','Mehta') AS ln
      FROM seq
      WHERE n <= 200) e
ORDER BY n;

-- ----------------------------------------------------------------------------
-- 4 · ACCOUNTS (250)
--     Engineered distribution for Q1/Q4/Q5:
--       n 1-3   -> customer 1 (Divya Hegde), all at Branch 1, big balances
--       n 4-90  -> customers 2-30, three accounts each
--       n 91-210-> customers 31-150, one each
--       n 211-250 -> customers 151-170, two each; the SECOND account of each
--                    (n 241-250) is DORMANT: opened recently, never transacted
-- ----------------------------------------------------------------------------
INSERT INTO accounts (account_id, account_number, customer_id, branch_id,
                      account_type, balance, opened_on)
SELECT n,
       CONCAT('ACC1', LPAD(n, 7, '0')),
       CASE WHEN n <= 3   THEN 1
            WHEN n <= 90  THEN ((n - 4) MOD 29) + 2
            WHEN n <= 210 THEN n - 60
            ELSE 151 + ((n - 211) MOD 20) END,
       CASE WHEN n <= 3 THEN 1 ELSE ((n - 1) MOD 25) + 1 END,
       ELT(1 + n MOD 10, 'savings','savings','savings','current','savings',
                         'fixed_deposit','savings','current','savings','fixed_deposit'),
       CASE WHEN n = 1 THEN 8500000.00
            WHEN n = 2 THEN 6500000.00
            WHEN n = 3 THEN 4500000.00
            WHEN n >= 241 THEN 2000.00 + (n MOD 5) * 1000.00   -- dormant: funded at opening only
            ELSE ROUND(((n * 7919) MOD 945000) + 5000, 2) END,
       CASE WHEN n >= 241 THEN DATE_ADD('2026-08-20', INTERVAL (n - 241) DAY)
            ELSE DATE_ADD('2012-01-01', INTERVAL (n * 211 MOD 4800) DAY) END
FROM seq
WHERE n <= 250;

-- ----------------------------------------------------------------------------
-- 5 · TRANSACTIONS (552)
--     A · 480 organic deposits/withdrawals over the last 12 months,
--         accounts 1-240, fixed deposits excluded (FDs take no teller traffic)
-- ----------------------------------------------------------------------------
INSERT INTO transactions (txn_id, account_id, txn_type, amount, txn_date)
SELECT s.n,
       a.account_id,
       ELT(1 + s.n MOD 3, 'deposit','deposit','withdrawal'),
       ROUND(1000 + (s.n * 7919 MOD 149000), 2),
       DATE_ADD('2025-10-01', INTERVAL (s.n * 89 MOD 360) DAY)
         + INTERVAL (s.n MOD 24) HOUR + INTERVAL (s.n * 7 MOD 60) MINUTE
FROM seq s
JOIN accounts a ON a.account_id = ((s.n * 7) MOD 240) + 1
WHERE s.n <= 600
  AND a.account_type <> 'fixed_deposit';

--     B · 30 transfers, D2 style: out-leg + in-leg share transfer_ref,
--         amount and timestamp. Reconciliation (README §13) returns empty.
INSERT INTO transactions (txn_id, account_id, txn_type, amount, txn_date, transfer_ref)
SELECT 600 + n, ((n * 11) MOD 200) + 1, 'transfer_out',
       ROUND(2000 + (n * 4591 MOD 48000), 2),
       DATE_ADD('2026-01-05', INTERVAL (n * 29 MOD 240) DAY) + INTERVAL 11 HOUR,
       CONCAT('TR', LPAD(n, 10, '0'))
FROM seq WHERE n <= 30;

INSERT INTO transactions (txn_id, account_id, txn_type, amount, txn_date, transfer_ref)
SELECT 630 + n, (((n * 11) MOD 200) + 25) MOD 200 + 1, 'transfer_in',
       ROUND(2000 + (n * 4591 MOD 48000), 2),
       DATE_ADD('2026-01-05', INTERVAL (n * 29 MOD 240) DAY) + INTERVAL 11 HOUR,
       CONCAT('TR', LPAD(n, 10, '0'))
FROM seq WHERE n <= 30;

--     C · 12 corporate salary-stream deposits at Branch 1 (v1.1: Branch 1 has
--         12 accounts, not 10) - makes Branch 1 the clear #1 in the deposit
--         league (Q2)
INSERT INTO transactions (txn_id, account_id, txn_type, amount, txn_date)
SELECT 660 + ROW_NUMBER() OVER (ORDER BY a.account_id),
       a.account_id, 'deposit',
       ROUND(500000 + (a.account_id * 791 MOD 450000), 2),
       DATE_ADD('2026-05-04', INTERVAL (a.account_id * 11 MOD 120) DAY) + INTERVAL 9 HOUR
FROM accounts a
WHERE a.branch_id = 1;

-- ----------------------------------------------------------------------------
-- 6 · LOANS (200) - product-realistic rates/tenures; 141 active / 48 closed /
--     11 defaulted (n MOD 17 = 0 -> defaulted, n MOD 4 = 0 -> closed)
-- ----------------------------------------------------------------------------
INSERT INTO loans (loan_id, customer_id, branch_id, loan_type, principal,
                   interest_rate, tenure_months, start_date, status)
SELECT n,
       ((n * 3) MOD 160) + 1,
       ((n - 1) MOD 25) + 1,
       ELT(1 + n MOD 4, 'home','vehicle','personal','education'),
       ROUND(50000 + (n * 3571 MOD 4450000), 2),
       ELT(1 + n MOD 4, 8.50, 9.25, 12.50, 10.75),
       ELT(1 + n MOD 4, 240, 60, 36, 48),
       DATE_ADD('2023-01-10', INTERVAL (n * 53 MOD 1200) DAY),
       CASE WHEN n MOD 17 = 0 THEN 'defaulted'
            WHEN n MOD 4  = 0 THEN 'closed'
            ELSE 'active' END
FROM seq
WHERE n <= 200;

-- ----------------------------------------------------------------------------
-- 7 · LOAN_PAYMENTS (1,200) - first 6 EMIs of every loan; due = start +
--     (k-1) months. Overdue is DERIVED, never stored (D6):
--       * instalments not yet due        -> paid_date NULL
--       * defaulted loans stopped paying -> NULL from instalment 2 (55 rows)
--       * 16 active loans have ONE engineered missed EMI (loan_id MOD 9 = 0)
--       * closed loans fully paid, several EARLY (legal since v2 removed
--         chk_payment_dates)
-- ----------------------------------------------------------------------------
INSERT INTO loan_payments (payment_id, loan_id, instalment_no, due_date,
                           paid_date, amount)
SELECT (d.loan_id - 1) * 6 + d.k,
       d.loan_id, d.k, d.due_date,
       CASE
         WHEN d.due_date >= CURRENT_DATE               THEN NULL
         WHEN d.status = 'defaulted' AND d.k >= 2      THEN NULL
         WHEN d.status = 'closed'
              THEN DATE_SUB(d.due_date, INTERVAL (d.loan_id MOD 5) DAY)
         WHEN d.loan_id MOD 9 = 0
              AND d.k = (d.loan_id MOD 6) + 1          THEN NULL
         ELSE DATE_SUB(d.due_date, INTERVAL ((d.loan_id + d.k) MOD 7) DAY)
       END,
       d.emi
FROM (SELECT l.loan_id, l.status, s.n AS k,
             DATE_ADD(l.start_date, INTERVAL (s.n - 1) MONTH) AS due_date,
             ROUND(l.principal / l.tenure_months * 1.15, 2)   AS emi
      FROM loans l
      CROSS JOIN seq s
      WHERE s.n <= 6) d;

-- ----------------------------------------------------------------------------
-- 8 · BENEFICIARIES (200)
--     160 external payees (D3): accounts at other banks - deliberately no FK
-- ----------------------------------------------------------------------------
INSERT INTO beneficiaries (beneficiary_id, customer_id, name, account_no,
                           ifsc_code, added_on)
SELECT s.n,
       ((s.n - 1) MOD 170) + 1,
       c2.full_name,
       CONCAT('5010', LPAD(s.n * 811, 8, '0')),
       ELT(1 + s.n MOD 6, 'HDFC0000123','ICIC0004567','SBIN0001234',
                         'UTIB0000765','KKBK0007890','AXIS0004321'),
       DATE_ADD('2025-01-05', INTERVAL (s.n * 37 MOD 500) DAY)
FROM seq s
JOIN customers c2 ON c2.customer_id = ((s.n * 29 MOD 200) + 1)
WHERE s.n <= 160;

--     40 internal payees: account_no AND ifsc_code both resolve inside
--     this database (the D3 counter-case - same table, both worlds)
-- ----------------------------------------------------------------------------
INSERT INTO beneficiaries (beneficiary_id, customer_id, name, account_no,
                           ifsc_code, added_on)
SELECT 160 + (a.account_id - 40),
       a.customer_id,
       c2.full_name,
       b.account_number,
       CONCAT('AUSB', LPAD(b.branch_id, 7, '0')),
       DATE_ADD('2025-07-01', INTERVAL (a.account_id MOD 100) DAY)
FROM accounts a
JOIN accounts b   ON b.account_id = 1 + (a.account_id * 17 MOD 40)
JOIN customers c2 ON c2.customer_id = b.customer_id
WHERE a.account_id BETWEEN 41 AND 80;

-- ----------------------------------------------------------------------------
-- 9 · CARDS (240) - debit for accounts 1-200 + credit for accounts 1-40.
--     5 expired (expiry in the past), 9 blocked, rest active.
-- ----------------------------------------------------------------------------
INSERT INTO cards (card_id, account_id, card_number, card_type,
                   expiry_date, status, issued_on)
SELECT a.account_id,
       a.account_id,
       CONCAT('4591', LPAD(a.account_id * 998877, 12, '0')),
       'debit',
       CASE WHEN a.account_id MOD 37 = 0
            THEN DATE_SUB('2026-09-01', INTERVAL (a.account_id * 7 MOD 150) DAY)
            ELSE DATE_ADD('2026-10-01', INTERVAL (a.account_id * 13 MOD 1000) DAY) END,
       CASE WHEN a.account_id MOD 37 = 0 THEN 'expired'
            WHEN a.account_id MOD 23 = 0 THEN 'blocked'
            ELSE 'active' END,
       DATE_ADD(a.opened_on, INTERVAL 15 DAY)
FROM accounts a
WHERE a.account_id <= 200;

INSERT INTO cards (card_id, account_id, card_number, card_type,
                   expiry_date, status, issued_on)
SELECT 200 + a.account_id,
       a.account_id,
       CONCAT('5242', LPAD(a.account_id * 1234567, 12, '0')),
       'credit',
       DATE_ADD('2027-03-01', INTERVAL (a.account_id * 19 MOD 720) DAY),
       CASE WHEN a.account_id MOD 31 = 0 THEN 'blocked' ELSE 'active' END,
       DATE_ADD(a.opened_on, INTERVAL 60 DAY)
FROM accounts a
WHERE a.account_id <= 40;

COMMIT;

DROP TEMPORARY TABLE seq;

-- ============================================================================
--  SELF-CHECK - expected results shown as comments (v1.1 corrected)
-- ============================================================================
SELECT (SELECT COUNT(*) FROM branches)      AS branches,       -- 200
       (SELECT COUNT(*) FROM customers)     AS customers,      -- 200
       (SELECT COUNT(*) FROM employees)     AS employees,      -- 200
       (SELECT COUNT(*) FROM accounts)      AS accounts,       -- 250
       (SELECT COUNT(*) FROM transactions)  AS transactions,   -- 552
       (SELECT COUNT(*) FROM loans)         AS loans,          -- 200
       (SELECT COUNT(*) FROM loan_payments) AS loan_payments,  -- 1200
       (SELECT COUNT(*) FROM beneficiaries) AS beneficiaries,  -- 200
       (SELECT COUNT(*) FROM cards)         AS cards;          -- 240

-- D2 reconciliation (README §13): must return ZERO rows
SELECT transfer_ref FROM transactions
WHERE transfer_ref IS NOT NULL
GROUP BY transfer_ref HAVING COUNT(*) <> 2;

-- Q1: multi-account customers -> 50
SELECT COUNT(*) AS multi_account_customers
FROM (SELECT customer_id FROM accounts
      GROUP BY customer_id HAVING COUNT(*) > 1) x;

-- Q4: dormant accounts -> 46 as written (10 engineered + 36 fixed deposits
--     that never transact); see review note on filtering account_type
SELECT COUNT(*) AS dormant_accounts
FROM accounts a
LEFT JOIN transactions t ON t.account_id = a.account_id
WHERE t.txn_id IS NULL;

-- Q2 preview: top 3 branches by deposits (Branch 1 should lead ~5x)
SELECT b.name, SUM(t.amount) AS deposits
FROM branches b
JOIN accounts a     ON a.branch_id = b.branch_id
JOIN transactions t ON t.account_id = a.account_id
WHERE t.txn_type = 'deposit'
GROUP BY b.branch_id, b.name
ORDER BY deposits DESC
LIMIT 3;
