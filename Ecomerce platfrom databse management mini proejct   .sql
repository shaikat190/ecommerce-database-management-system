SET SERVEROUTPUT ON;

--------------------------------------------------
-- 1. CREATE TRANSACTION LOG TABLE
--------------------------------------------------

CREATE TABLE TRANSACTION_LOG (
    LOG_ID NUMBER PRIMARY KEY,
    TRANSACTION_ID VARCHAR2(10),
    OPERATION VARCHAR2(10),
    DATA_ITEM VARCHAR2(20),
    SEQ_NO NUMBER


--------------------------------------------------
-- 2. CREATE CONFLICT LOG TABLE
--------------------------------------------------

CREATE TABLE CONFLICT_LOG (
    CONFLICT_ID NUMBER PRIMARY KEY,
    T1 VARCHAR2(10),
    OP1 VARCHAR2(10),
    T2 VARCHAR2(10),
    OP2 VARCHAR2(10),
    DATA_ITEM VARCHAR2(20),
    CONFLICT_TYPE VARCHAR2(5)
);

--------------------------------------------------
-- 3. INSERT SAMPLE TRANSACTIONS
--------------------------------------------------

INSERT INTO TRANSACTION_LOG
VALUES (1, 'T1', 'READ', 'A', 1);

INSERT INTO TRANSACTION_LOG
VALUES (2, 'T1', 'WRITE', 'A', 2);

INSERT INTO TRANSACTION_LOG
VALUES (3, 'T2', 'READ', 'A', 3);

INSERT INTO TRANSACTION_LOG
VALUES (4, 'T2', 'WRITE', 'B', 4);

INSERT INTO TRANSACTION_LOG
VALUES (5, 'T1', 'READ', 'B', 5);

INSERT INTO TRANSACTION_LOG
VALUES (6, 'T2', 'WRITE', 'A', 6);

COMMIT;

--------------------------------------------------
-- 4. DISPLAY TRANSACTION LOG
--------------------------------------------------

SELECT *
FROM TRANSACTION_LOG
ORDER BY SEQ_NO;

--------------------------------------------------
-- 5. CONFLICT ANALYZER PROCEDURE
--------------------------------------------------

CREATE OR REPLACE PROCEDURE ANALYZE_CONFLICTS
IS
    V_CONFLICT_ID NUMBER := 0;
    V_CONFLICT_TYPE VARCHAR2(5);
BEGIN

    -- Remove previous conflict records
    DELETE FROM CONFLICT_LOG;

    FOR R IN
    (
        SELECT
            A.TRANSACTION_ID AS T1,
            A.OPERATION AS OP1,
            B.TRANSACTION_ID AS T2,
            B.OPERATION AS OP2,
            A.DATA_ITEM AS ITEM
        FROM TRANSACTION_LOG A
        JOIN TRANSACTION_LOG B
          ON A.DATA_ITEM = B.DATA_ITEM
         AND A.TRANSACTION_ID <> B.TRANSACTION_ID
         AND A.SEQ_NO < B.SEQ_NO
        WHERE A.OPERATION = 'WRITE'
           OR B.OPERATION = 'WRITE'
        ORDER BY A.SEQ_NO, B.SEQ_NO
    )
    LOOP

        --------------------------------------------------
        -- DETERMINE CONFLICT TYPE
        --------------------------------------------------

        IF R.OP1 = 'READ' AND R.OP2 = 'WRITE' THEN
            V_CONFLICT_TYPE := 'RW';

        ELSIF R.OP1 = 'WRITE' AND R.OP2 = 'READ' THEN
            V_CONFLICT_TYPE := 'WR';

        ELSIF R.OP1 = 'WRITE' AND R.OP2 = 'WRITE' THEN
            V_CONFLICT_TYPE := 'WW';

        ELSE
            V_CONFLICT_TYPE := 'NONE';
        END IF;

        --------------------------------------------------
        -- STORE CONFLICT
        --------------------------------------------------

        IF V_CONFLICT_TYPE <> 'NONE' THEN

            V_CONFLICT_ID := V_CONFLICT_ID + 1;

            INSERT INTO CONFLICT_LOG
            VALUES (
                V_CONFLICT_ID,
                R.T1,
                R.OP1,
                R.T2,
                R.OP2,
                R.ITEM,
                V_CONFLICT_TYPE
            );

        END IF;

    END LOOP;

    COMMIT;

    DBMS_OUTPUT.PUT_LINE(
        'Conflict analysis completed successfully.'
    );

END;
/

--------------------------------------------------
-- 6. RUN CONFLICT ANALYZER
--------------------------------------------------

BEGIN
    ANALYZE_CONFLICTS;
END;
/

--------------------------------------------------
-- 7. DISPLAY CONFLICT REPORT
--------------------------------------------------

SELECT
    CONFLICT_ID,
    T1,
    OP1,
    T2,
    OP2,
    DATA_ITEM,
    CONFLICT_TYPE
FROM CONFLICT_LOG
ORDER BY CONFLICT_ID;

--------------------------------------------------
-- 8. DISPLAY TOTAL NUMBER OF CONFLICTS
--------------------------------------------------

DECLARE
    TOTAL_CONFLICTS NUMBER;
BEGIN

    SELECT COUNT(*)
    INTO TOTAL_CONFLICTS
    FROM CONFLICT_LOG;

    DBMS_OUTPUT.PUT_LINE(
        '===================================='
    );

    DBMS_OUTPUT.PUT_LINE(
        'TOTAL CONFLICTS: ' || TOTAL_CONFLICTS
    );

    DBMS_OUTPUT.PUT_LINE(
        '===================================='
    );

END;
/