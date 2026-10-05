-- ICT371 ACTIVITY 4 -- SCENARIO 5: ENGINEERING WORKSHOP TOOL LOANS 
-- QUESTION 1: Create tables and insert records 
DROP TABLE IF EXISTS tool_loans CASCADE; 
DROP TABLE IF EXISTS tools CASCADE; 
 
CREATE TABLE tools ( 
    tool_id SERIAL PRIMARY KEY, 
    tool_name VARCHAR(100), 
    available_quantity INT CHECK (available_quantity >= 0) 
); 
 
CREATE TABLE tool_loans ( 
    loan_id SERIAL PRIMARY KEY, 
    student_number VARCHAR(20), 
    tool_id INT REFERENCES tools(tool_id), 
    quantity INT, 
    status VARCHAR(20) 
); 
 
INSERT INTO tools (tool_name, available_quantity) 
VALUES 
('Hammer', 20), 
('Screwdriver', 3), 
('Electric Drill', 0);


 -- QUESTION 2: IF ELSIF ELSE 
 
DO $$ 
DECLARE 
    quantity INT; 
BEGIN 
    SELECT available_quantity INTO quantity 
    FROM tools 
    WHERE tool_id = 1; 
 
    IF quantity = 0 THEN 
        RAISE NOTICE 'Tool is unavailable'; 
 
    ELSIF quantity <= 3 THEN 
        RAISE NOTICE 'Tool has low stock'; 
 
    ELSE 
        RAISE NOTICE 'Tool is readily available'; 
    END IF; 
END $$; 

-- QUESTION 3: WHILE AND NUMERIC FOR 
 
DO $$ 
DECLARE 
    i INT := 1; 
BEGIN 
    WHILE i <= 3 LOOP 
        RAISE NOTICE 'Workshop safety reminder: %', i; 
        i := i + 1; 
    END LOOP; 
 
    FOR i IN 1..3 LOOP 
        RAISE NOTICE 'Tool inspection number: %', i; 
    END LOOP; 
END $$;

-- QUESTION 4: Create issue_tool procedure 
CREATE OR REPLACE PROCEDURE issue_tool( 
p_student VARCHAR, 
p_tool_id INT, 
p_quantity INT 
) 
LANGUAGE plpgsql 
AS $$ 
DECLARE 
available INT; 
BEGIN 
IF p_quantity <= 0 THEN 
RAISE EXCEPTION 'Invalid tool quantity'; 
END IF; 
SELECT available_quantity INTO available 
FROM tools 
WHERE tool_id = p_tool_id 
FOR UPDATE; 
IF NOT FOUND THEN 
RAISE EXCEPTION 'Tool does not exist'; 
END IF; 
IF available < p_quantity THEN 
RAISE NOTICE 'Insufficient tools available'; 
ELSE 
UPDATE tools 
SET available_quantity = 
available_quantity - p_quantity 
WHERE tool_id = p_tool_id; 
INSERT INTO tool_loans 
(student_number, tool_id, quantity, status) 
VALUES 
(p_student, p_tool_id, p_quantity, 'Borrowed'); 
RAISE NOTICE 'Tool issued successfully'; 
END IF; 
END; 
$$; 


-- QUESTION 5: Call procedure 
CALL issue_tool('MU001', 1, 5); 
CALL issue_tool('MU002', 2, 2); 
CALL issue_tool('MU003', 3, 2); 
SELECT * FROM tools; 
SELECT * FROM tool_loans; 


-- QUESTION 6: Create return_tool procedure 
CREATE OR REPLACE PROCEDURE return_tool( 
    p_loan_id INT 
) 
LANGUAGE plpgsql 
AS $$ 
DECLARE 
    v_tool_id INT; 
    v_quantity INT; 
    v_status VARCHAR; 
BEGIN 
    SELECT tool_id, quantity, status 
    INTO v_tool_id, v_quantity, v_status 
    FROM tool_loans 
    WHERE loan_id = p_loan_id 
    FOR UPDATE; 
 
    IF NOT FOUND THEN 
        RAISE NOTICE 'Loan not found'; 
 
    ELSIF v_status = 'Returned' THEN 
        RAISE NOTICE 'Tool already returned'; 
 
    ELSE 
        UPDATE tools 
        SET available_quantity = 
            available_quantity + v_quantity 
        WHERE tool_id = v_tool_id; 
 
        UPDATE tool_loans 
        SET status = 'Returned' 
        WHERE loan_id = p_loan_id; 
 
        RAISE NOTICE 'Tool returned successfully'; 
    END IF; 
END; 
$$; 
 -- Call twice for the same loan 
 
CALL return_tool(1); 
CALL return_tool(1);



-- QUESTION 7: Explicit cursor for low availability 
 
DO $$ 
DECLARE 
    tool_cursor CURSOR FOR 
        SELECT tool_name, available_quantity 
        FROM tools 
        WHERE available_quantity <= 3; 
 
    tool_record RECORD; 
BEGIN 
    OPEN tool_cursor; 
 
    LOOP 
        FETCH tool_cursor INTO tool_record; 
EXIT WHEN NOT FOUND; 
RAISE NOTICE 'Tool: %, Available quantity: %', 
tool_record.tool_name, 
tool_record.available_quantity; 
END LOOP; 
CLOSE tool_cursor; 
END $$;


-- QUESTION 8: Handle zero tool quantity 
DO $$ 
BEGIN 
CALL issue_tool('MU004', 1, 0); 
EXCEPTION 
WHEN OTHERS THEN 
RAISE NOTICE 'Error handled: %', SQLERRM; 
END $$; 

-- QUESTION 9: Final queries 
SELECT * FROM tools ORDER BY tool_id; 
SELECT * FROM tool_loans ORDER BY loan_id;
