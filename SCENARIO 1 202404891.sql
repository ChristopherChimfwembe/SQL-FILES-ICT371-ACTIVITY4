-- SCENARIO 1: UNIVERSITY LIBRARY BOOK LOANS

-- QUESTION 1: Create tables and insert records

DROP TABLE IF EXISTS book_loans CASCADE;
DROP TABLE IF EXISTS books CASCADE;

CREATE TABLE books (
    book_id SERIAL PRIMARY KEY,
    book_name VARCHAR(100),
    available_copies INT CHECK (available_copies >= 0)
);
CREATE TABLE book_loans (
    loan_id SERIAL PRIMARY KEY,
    student_number VARCHAR(20),
    book_id INT REFERENCES books(book_id),
    quantity INT,
    loan_status VARCHAR(20)
);

INSERT INTO books (book_name, available_copies)
VALUES
('Database Systems', 10),
('Computer Networks', 3),
('Programming in Java', 0);
SELECT *FROM books;

-- QUESTION 2: IF ELSIF ELSE

DO $$
DECLARE
    copies INT;
BEGIN
    SELECT available_copies INTO copies
    FROM books
    WHERE book_id = 1;

    IF copies = 0 THEN
        RAISE NOTICE 'Book is unavailable';

    ELSIF copies <= 3 THEN
        RAISE NOTICE 'Book has low copies';

    ELSE
        RAISE NOTICE 'Book is sufficiently stocked';
    END IF;
END $$;

-- QUESTION 3: WHILE LOOP AND NUMERIC FOR LOOP

DO $$
DECLARE
    i INT := 1;
BEGIN
    WHILE i <= 3 LOOP
        RAISE NOTICE 'Overdue reminder number: %', i;
        i := i + 1;
    END LOOP;

    FOR i IN 1..3 LOOP
        RAISE NOTICE 'Library shelf number: %', i;
    END LOOP;
END $$;

-- QUESTION 4: Create borrow_book procedure

CREATE OR REPLACE PROCEDURE borrow_book(
    p_student VARCHAR,
    p_book_id INT,
    p_quantity INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    copies INT;
BEGIN
    IF p_quantity <= 0 THEN
        RAISE EXCEPTION 'Invalid quantity';
    END IF;

    SELECT available_copies INTO copies
    FROM books
    WHERE book_id = p_book_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Book does not exist';
    END IF;

    IF copies < p_quantity THEN
        RAISE NOTICE 'Not enough copies available';
    ELSE
        UPDATE books
        SET available_copies = available_copies - p_quantity
        WHERE book_id = p_book_id;

        INSERT INTO book_loans
        (student_number, book_id, quantity, loan_status)
        VALUES
        (p_student, p_book_id, p_quantity, 'Borrowed');

        RAISE NOTICE 'Book borrowed successfully';
    END IF;
END;
$$;

-- QUESTION 5: Call procedure for two valid loans
-- and one request exceeding available copies

CALL borrow_book('MU001', 1, 2);
CALL borrow_book('MU002', 2, 1);
CALL borrow_book('MU003', 3, 2);

SELECT * FROM books;
SELECT * FROM book_loans;

-- QUESTION 6: Create return_book procedure

CREATE OR REPLACE PROCEDURE return_book(
    p_loan_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_book_id INT;
    v_quantity INT;
    v_status VARCHAR;
BEGIN
    SELECT book_id, quantity, loan_status
    INTO v_book_id, v_quantity, v_status
    FROM book_loans
    WHERE loan_id = p_loan_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE NOTICE 'Loan not found';

    ELSIF v_status = 'Returned' THEN
        RAISE NOTICE 'Loan already returned';

    ELSE
        UPDATE books
        SET available_copies = available_copies + v_quantity
        WHERE book_id = v_book_id;

        UPDATE book_loans
        SET loan_status = 'Returned'
        WHERE loan_id = p_loan_id;

        RAISE NOTICE 'Book returned successfully';
    END IF;
END;
$$;

-- Call twice for the same loan

CALL return_book(1);
CALL return_book(1);

-- QUESTION 7: Explicit cursor to display books
-- with few copies remaining

DO $$
DECLARE
    book_cursor CURSOR FOR
        SELECT book_name, available_copies
        FROM books
        WHERE available_copies <= 3;

    book_record RECORD;
BEGIN
    OPEN book_cursor;

    LOOP
        FETCH book_cursor INTO book_record;
        EXIT WHEN NOT FOUND;

        RAISE NOTICE 'Book: %, Copies remaining: %',
        book_record.book_name,
        book_record.available_copies;
    END LOOP;

    CLOSE book_cursor;
END $$;

-- QUESTION 8: Handle invalid quantity using EXCEPTION

DO $$
BEGIN
    CALL borrow_book('MU004', 1, 0);

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error handled: %', SQLERRM;
END $$;

-- QUESTION 9: Display final records

SELECT * FROM books ORDER BY book_id;

SELECT * FROM book_loans ORDER BY loan_id;
















