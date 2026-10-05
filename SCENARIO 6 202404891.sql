-- ICT371 ACTIVITY 4 -- SCENARIO 6: UNIVERSITY EVENT SEAT BOOKING 
-- QUESTION 1: Create tables and insert records 
DROP TABLE IF EXISTS bookings CASCADE; 
DROP TABLE IF EXISTS events CASCADE; 
CREATE TABLE events ( 
event_id SERIAL PRIMARY KEY, 
event_name VARCHAR(100), 
available_seats INT CHECK (available_seats >= 0) 
);

CREATE TABLE bookings ( 
    booking_id SERIAL PRIMARY KEY, 
    student_number VARCHAR(20), 
    event_id INT REFERENCES events(event_id), 
    number_of_seats INT, 
    status VARCHAR(20) 
);
 
INSERT INTO events (event_name, available_seats) 
VALUES 
('Career Fair', 100), 
('Technology Conference', 5), 
('Sports Gala', 0); 
SELECT *FROM events;

-- QUESTION 2: IF ELSIF ELSE 
 
DO $$ 
DECLARE 
    seats INT; 
BEGIN 
    SELECT available_seats INTO seats 
    FROM events 
    WHERE event_id = 1; 
 
    IF seats = 0 THEN 
        RAISE NOTICE 'Event is full'; 
 
    ELSIF seats <= 5 THEN 
        RAISE NOTICE 'Event is nearly full'; 
 
    ELSE 
        RAISE NOTICE 'Event has plenty of seats'; 
    END IF; 
END $$; 

 -- QUESTION 3: WHILE AND NUMERIC FOR 
 
DO $$ 
DECLARE 
    i INT := 1; 
BEGIN 
    WHILE i <= 3 LOOP 
        RAISE NOTICE 'Booking reminder day: %', i; 
        i := i + 1; 
    END LOOP; 
 
    FOR i IN 1..3 LOOP 
        RAISE NOTICE 'Entrance check number: %', i; 
    END LOOP; 
END $$; 

 -- QUESTION 4: Create book_seats procedure 
 
CREATE OR REPLACE PROCEDURE book_seats( 
    p_student VARCHAR, 
    p_event_id INT, 
    p_quantity INT 
) 
LANGUAGE plpgsql 
AS $$ 
DECLARE 
available INT; 
BEGIN 
IF p_quantity <= 0 THEN 
RAISE EXCEPTION 'Invalid number of seats'; 
END IF; 
SELECT available_seats INTO available 
FROM events 
WHERE event_id = p_event_id 
FOR UPDATE; 
IF NOT FOUND THEN 
RAISE EXCEPTION 'Event does not exist'; 
END IF; 
IF available < p_quantity THEN 
RAISE NOTICE 'Not enough seats available'; 
ELSE 
UPDATE events 
SET available_seats = available_seats - p_quantity 
WHERE event_id = p_event_id; 
INSERT INTO bookings 
(student_number, event_id, number_of_seats, status) 
VALUES 
(p_student, p_event_id, p_quantity, 'Booked'); 
RAISE NOTICE 'Booking successful'; 
END IF; 
END; 
$$; 

-- QUESTION 5: Call procedure 
CALL book_seats('MU001', 1, 5); 
CALL book_seats('MU002', 2, 2); 
CALL book_seats('MU003', 3, 3); 
SELECT * FROM events; 
SELECT * FROM bookings; 

-- QUESTION 6: Create cancel_booking procedure 
CREATE OR REPLACE PROCEDURE cancel_booking( 
p_booking_id INT 
) 
LANGUAGE plpgsql 
AS $$ 
DECLARE 
v_event_id INT; 
v_quantity INT; 
v_status VARCHAR; 
BEGIN 
    SELECT event_id, number_of_seats, status 
    INTO v_event_id, v_quantity, v_status 
    FROM bookings 
    WHERE booking_id = p_booking_id 
    FOR UPDATE; 
 
    IF NOT FOUND THEN 
        RAISE NOTICE 'Booking not found'; 
 
    ELSIF v_status = 'Cancelled' THEN 
        RAISE NOTICE 'Booking already cancelled'; 
 
    ELSE 
        UPDATE events 
        SET available_seats = available_seats + v_quantity 
        WHERE event_id = v_event_id; 
 
        UPDATE bookings 
        SET status = 'Cancelled' 
        WHERE booking_id = p_booking_id; 
 
        RAISE NOTICE 'Booking cancelled successfully'; 
    END IF; 
END; 
$$; 
 -- Call twice for the same booking 
 
CALL cancel_booking(1); 
CALL cancel_booking(1); 

-- QUESTION 7: Explicit cursor 
 
DO $$ 
DECLARE 
    event_cursor CURSOR FOR 
        SELECT event_name, available_seats 
        FROM events 
        WHERE available_seats <= 5; 
 
    event_record RECORD; 
BEGIN 
    OPEN event_cursor; 
 
    LOOP 
        FETCH event_cursor INTO event_record; 
        EXIT WHEN NOT FOUND; 
 
        RAISE NOTICE 'Event: %, Available seats: %', 
        event_record.event_name, 
        event_record.available_seats; 
    END LOOP; 
 
    CLOSE event_cursor; 
END $$; 

-- QUESTION 8: Handle zero seats using EXCEPTION 
DO $$ 
BEGIN 
CALL book_seats('MU004', 1, 0); 
EXCEPTION 
WHEN OTHERS THEN 
RAISE NOTICE 'Error handled: %', SQLERRM; 
END $$;

-- QUESTION 9: Final queries 
SELECT * FROM events ORDER BY event_id; 
SELECT * FROM bookings ORDER BY booking_id; 


 

 



 
