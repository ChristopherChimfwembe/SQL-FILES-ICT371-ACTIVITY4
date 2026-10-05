-- ICT371 ACTIVITY 4 -- SCENARIO 2: COMPUTER LABORATORY RESERVATIONS -- QUESTION 1: Create tables and insert records 
DROP TABLE IF EXISTS reservations CASCADE; 
DROP TABLE IF EXISTS lab_sessions CASCADE; 

CREATE TABLE lab_sessions ( 
session_id SERIAL PRIMARY KEY, 
session_name VARCHAR(100), 
available_workstations INT CHECK (available_workstations >= 0) 
);

CREATE TABLE reservations ( 
reservation_id SERIAL PRIMARY KEY, 
lecturer VARCHAR(100), 
session_id INT REFERENCES lab_sessions(session_id), 
workstations INT, 
status VARCHAR(20) 
); 

INSERT INTO lab_sessions (session_name, available_workstations) 
VALUES 
('Database Practical', 30), 
('Networking Practical', 5), 
('Programming Practical', 0); 

SELECT *FROM lab_sessions

-- QUESTION 2: IF ELSIF ELSE  
DO $$ 
DECLARE 
    available INT; 
BEGIN 
    SELECT available_workstations INTO available 
    FROM lab_sessions 
    WHERE session_id = 1; 
 
    IF available = 0 THEN 
        RAISE NOTICE 'Session is full'; 
 
    ELSIF available <= 5 THEN 
        RAISE NOTICE 'Session is nearly full'; 
 
    ELSE 
        RAISE NOTICE 'Session has enough workstations'; 
    END IF; 
END $$; 
 -- QUESTION 3: WHILE AND NUMERIC FOR 
 
DO $$ 
DECLARE 
    i INT := 1; 
BEGIN 
    WHILE i <= 3 LOOP 
        RAISE NOTICE 'Session preparation reminder: %', i; 
        i := i + 1; 
    END LOOP; 
 
    FOR i IN 1..3 LOOP 
        RAISE NOTICE 'Workstation check number: %', i; 
    END LOOP; 
END $$; 


-- QUESTION 4: Create reserve_workstations procedure 
 
CREATE OR REPLACE PROCEDURE reserve_workstations( 
    p_lecturer VARCHAR, 
    p_session_id INT, 
    p_quantity INT 
) 
LANGUAGE plpgsql 
AS $$ 
DECLARE 
    available INT; 
BEGIN 
    IF p_quantity <= 0 THEN 
        RAISE EXCEPTION 'Invalid workstation quantity'; 
    END IF; 
 
    SELECT available_workstations INTO available 
    FROM lab_sessions 
    WHERE session_id = p_session_id 
    FOR UPDATE;

IF NOT FOUND THEN 
RAISE EXCEPTION 'Session does not exist'; 
END IF; 
IF available < p_quantity THEN 
RAISE NOTICE 'Insufficient workstations available'; 
ELSE 
UPDATE lab_sessions 
SET available_workstations = 
available_workstations - p_quantity 
WHERE session_id = p_session_id; 
INSERT INTO reservations 
(lecturer, session_id, workstations, status) 
VALUES 
(p_lecturer, p_session_id, p_quantity, 'Reserved'); 
RAISE NOTICE 'Reservation successful'; 
END IF; 
END; 
$$; 


-- QUESTION 5: Call procedure 
CALL reserve_workstations('Mr Banda', 1, 5); 
CALL reserve_workstations('Mrs Phiri', 2, 2); 
CALL reserve_workstations('Mr Zulu', 3, 4); 
SELECT * FROM lab_sessions; 
SELECT * FROM reservations; 


-- QUESTION 6: Create cancel_reservation procedure 
CREATE OR REPLACE PROCEDURE cancel_reservation( 
p_reservation_id INT 
) 
LANGUAGE plpgsql 
AS $$ 
DECLARE 
v_session_id INT; 
v_quantity INT; 
v_status VARCHAR; 
BEGIN 
SELECT session_id, workstations, status 
INTO v_session_id, v_quantity, v_status 
FROM reservations 
WHERE reservation_id = p_reservation_id 
FOR UPDATE; 
IF NOT FOUND THEN 
RAISE NOTICE 'Reservation not found'; 
ELSIF v_status = 'Cancelled' THEN 
RAISE NOTICE 'Reservation already cancelled'; 
ELSE 
UPDATE lab_sessions 
SET available_workstations = 
available_workstations + v_quantity 
WHERE session_id = v_session_id; 
UPDATE reservations 
SET status = 'Cancelled' 
WHERE reservation_id = p_reservation_id; 
RAISE NOTICE 'Reservation cancelled successfully'; 
END IF; 
END; 
$$; -- Call twice for the same reservation 
CALL cancel_reservation(1); 
CALL cancel_reservation(1);

-- QUESTION 7: Explicit cursor 
DO $$ 
DECLARE 
session_cursor CURSOR FOR 
SELECT session_name, available_workstations 
FROM lab_sessions 
WHERE available_workstations <= 5; 
session_record RECORD; 
BEGIN 
OPEN session_cursor; 
LOOP 
FETCH session_cursor INTO session_record; 
EXIT WHEN NOT FOUND; 
RAISE NOTICE 'Session: %, Available: %', 
session_record.session_name, 
session_record.available_workstations; 
END LOOP; 
CLOSE session_cursor; 
END $$; 


-- QUESTION 8: Exception handling for zero workstations 
DO $$ 
BEGIN 
CALL reserve_workstations('Mr Tembo', 1, 0); 
EXCEPTION 
WHEN OTHERS THEN 
RAISE NOTICE 'Error handled: %', SQLERRM; 
END $$; 

-- QUESTION 9: Final queries 
SELECT * FROM lab_sessions ORDER BY session_id; 
SELECT * FROM reservations ORDER BY reservation_id;


