-- ============================================================
-- FULCRUM HEALTH SYSTEM
-- Database Schema
-- Phase 1 | File: schema.sql
-- ============================================================
-- WHAT THIS FILE DOES:
-- This file creates the empty tables that make up our database.
-- Think of it as building the filing cabinets before putting
-- any files inside. Run this entire file in SSMS first before
-- loading any data.
-- ============================================================


-- ============================================================
-- STEP 1: CREATE THE DATABASE
-- ============================================================
-- 💡 TIP: You only run this once. After the database exists,
-- you won't need this line again. If you run it twice by
-- accident, SQL Server will throw an error saying it already
-- exists -- that's normal, just ignore it.

CREATE DATABASE FulcrumHealthSystem;
GO

-- This tells SSMS "everything below this line should run
-- inside the FulcrumHealthSystem database."
-- 💡 TIP: Always include this line at the top of your query
-- files so SQL knows which database you're working in.
USE FulcrumHealthSystem;
GO


-- ============================================================
-- TABLE 1: patients
-- ============================================================
-- This is the CORE table. Every other table eventually traces
-- back to a patient. One row = one unique patient.
--
-- 💡 TIP: Notice patient_id is the PRIMARY KEY. This means:
--   1. Every patient_id must be unique (no duplicates)
--   2. It can never be NULL (empty)
-- Every table needs a primary key. It's how SQL uniquely
-- identifies each row.
--
-- 💡 TIP ON DATA TYPES:
--   INT        = whole numbers (1, 2, 3...)
--   VARCHAR(n) = text up to n characters long
--   DATE       = stores a date (YYYY-MM-DD format)
--   DECIMAL(x,y) = numbers with decimals (x = total digits,
--                  y = digits after the decimal point)
-- ============================================================

CREATE TABLE patients (
    patient_id      INT             PRIMARY KEY,
    first_name      VARCHAR(50)     NOT NULL,
    last_name       VARCHAR(50)     NOT NULL,
    date_of_birth   DATE            NOT NULL,
    gender          VARCHAR(10),
    race            VARCHAR(50),
    city            VARCHAR(50),
    state           VARCHAR(2),
    zip_code        VARCHAR(10),
    insurance_type  VARCHAR(50),    -- e.g. Medicare, Medicaid, Private, Uninsured
    risk_tier       VARCHAR(20)     -- e.g. Low, Medium, High
);
GO

-- 💡 TIP: NOT NULL means that column MUST have a value.
-- You can't add a patient without a first name, last name,
-- or date of birth. Other columns like race or city are
-- optional (they can be left blank/NULL in real data).


-- ============================================================
-- TABLE 2: staff
-- ============================================================
-- Doctors and other attending staff. We create this BEFORE
-- admissions because admissions will reference it.
--
-- 💡 TIP ON TABLE ORDER: When one table references another,
-- you must create the referenced table first. Think of it
-- like building a house -- foundation before walls.
-- ============================================================

CREATE TABLE staff (
    staff_id        INT             PRIMARY KEY,
    first_name      VARCHAR(50)     NOT NULL,
    last_name       VARCHAR(50)     NOT NULL,
    role            VARCHAR(50),    -- e.g. Attending Physician, Nurse, Surgeon
    department      VARCHAR(50),    -- e.g. Cardiology, Emergency, Oncology
    hire_date       DATE
);
GO


-- ============================================================
-- TABLE 3: diagnoses
-- ============================================================
-- A reference/lookup table of diagnosis codes (ICD-10).
-- ICD-10 codes are the real-world standard used in hospitals
-- worldwide to classify diseases and conditions.
--
-- 💡 TIP: Reference tables like this one are sometimes called
-- "dimension tables." They store descriptive information that
-- other tables point to. You'll hear this term a lot in data
-- work. The admissions table will store a diagnosis_code, and
-- we can JOIN to this table to get the full description.
-- ============================================================

CREATE TABLE diagnoses (
    diagnosis_code          VARCHAR(10)     PRIMARY KEY,  -- e.g. I21.0, E11.9
    diagnosis_description   VARCHAR(255)    NOT NULL,     -- e.g. Acute MI, Type 2 Diabetes
    category                VARCHAR(100)    -- e.g. Cardiovascular, Respiratory, Diabetes
);
GO


-- ============================================================
-- TABLE 4: admissions
-- ============================================================
-- Every time a patient is admitted to the hospital.
-- One patient can have MANY admissions over time.
-- This is called a one-to-many relationship.
--
-- 💡 TIP ON FOREIGN KEYS: Notice FOREIGN KEY references below.
-- A foreign key is a column in this table that points to the
-- primary key of another table. It's how tables are linked.
--
--   patient_id here --> patient_id in patients table
--   staff_id here   --> staff_id in staff table
--
-- This means you CANNOT add an admission for a patient_id
-- that doesn't exist in the patients table. SQL enforces
-- this automatically -- this is called referential integrity.
-- It prevents orphan records (admissions with no patient).
-- ============================================================

CREATE TABLE admissions (
    admission_id            INT             PRIMARY KEY,
    patient_id              INT             NOT NULL,
    staff_id                INT,
    diagnosis_code          VARCHAR(10),
    department              VARCHAR(50),    -- e.g. Cardiology, Emergency, ICU
    admission_date          DATE            NOT NULL,
    discharge_date          DATE,
    length_of_stay          INT,            -- calculated in days
    admission_type          VARCHAR(20),    -- Emergency, Elective, Urgent
    primary_diagnosis       VARCHAR(255),

    -- 💡 TIP: FOREIGN KEY syntax tells SQL Server that
    -- patient_id in THIS table must match a patient_id
    -- that already exists in the patients table.
    FOREIGN KEY (patient_id)     REFERENCES patients(patient_id),
    FOREIGN KEY (staff_id)       REFERENCES staff(staff_id),
    FOREIGN KEY (diagnosis_code) REFERENCES diagnoses(diagnosis_code)
);
GO


-- ============================================================
-- TABLE 5: billing
-- ============================================================
-- One billing record per admission. Tracks charges, what
-- insurance covered, and what the patient owes.
--
-- 💡 TIP: Notice DECIMAL(10,2) for money columns. This means
-- up to 10 digits total, with 2 after the decimal point.
-- e.g. 12345678.99 -- always use DECIMAL for money, never
-- FLOAT. Float can cause tiny rounding errors which are a
-- big problem in financial data.
-- ============================================================

CREATE TABLE billing (
    billing_id          INT             PRIMARY KEY,
    admission_id        INT             NOT NULL,
    patient_id          INT             NOT NULL,
    total_charges       DECIMAL(10,2),
    insurance_covered   DECIMAL(10,2),
    patient_balance     DECIMAL(10,2),
    payment_status      VARCHAR(20),    -- Paid, Pending, Overdue, Written Off

    FOREIGN KEY (admission_id) REFERENCES admissions(admission_id),
    FOREIGN KEY (patient_id)   REFERENCES patients(patient_id)
);
GO


-- ============================================================
-- TABLE 6: readmissions
-- ============================================================
-- Tracks patients who were readmitted within 30 days of
-- being discharged. 30-day readmission rate is one of the
-- most important metrics hospitals track -- it affects their
-- funding and reputation.
--
-- 💡 TIP: Notice this table has TWO references back to
-- admissions -- the original admission AND the new one.
-- This is perfectly fine. A table can have multiple
-- foreign keys pointing to the same table.
-- ============================================================

CREATE TABLE readmissions (
    readmission_id          INT         PRIMARY KEY,
    original_admission_id   INT         NOT NULL,   -- the first stay
    new_admission_id        INT         NOT NULL,   -- the return stay
    patient_id              INT         NOT NULL,
    readmission_date        DATE,
    reason                  VARCHAR(255),
    days_since_discharge    INT,        -- should be 30 or fewer to count

    FOREIGN KEY (original_admission_id) REFERENCES admissions(admission_id),
    FOREIGN KEY (new_admission_id)      REFERENCES admissions(admission_id),
    FOREIGN KEY (patient_id)            REFERENCES patients(patient_id)
);
GO


-- ============================================================
-- ✅ SCHEMA COMPLETE
-- ============================================================
-- You now have 6 empty tables:
--   1. patients       - who the patients are
--   2. staff          - attending physicians and staff
--   3. diagnoses      - ICD-10 code reference list
--   4. admissions     - every hospital stay
--   5. billing        - charges per admission
--   6. readmissions   - return visits within 30 days
--
-- NEXT STEP:
-- Run seed_data.sql to populate these tables with
-- realistic synthetic data.
--
-- 💡 FINAL TIP: If you ever want to start fresh and rebuild
-- the database from scratch, you can run:
--   DROP DATABASE FulcrumHealthSystem;
-- Then run this file again. Useful during learning when
-- you make mistakes (and you will -- everyone does).
-- ============================================================
