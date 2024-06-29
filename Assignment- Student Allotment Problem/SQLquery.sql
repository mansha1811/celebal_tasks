DELIMITER //

CREATE PROCEDURE AllocateSubjects()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE student_id INT;
    DECLARE subject_id CHAR(6);
    DECLARE preference INT;
    DECLARE remaining_seats INT;
    DECLARE total_choices INT;
    DECLARE choice_count INT;
    
    -- Cursor to iterate over each student's preferences
    DECLARE cur CURSOR FOR 
        SELECT sp.StudentId, sp.SubjectId, sp.Preference
        FROM StudentPreference sp
        ORDER BY sp.StudentId, sp.Preference;
    
    -- Handlers
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    -- Temp table to track allocated students
    CREATE TEMPORARY TABLE IF NOT EXISTS TempAllocations (
        StudentId INT,
        SubjectId CHAR(6)
    );
    
    -- Loop through each student preference
    OPEN cur;
    read_loop: LOOP
        FETCH cur INTO student_id, subject_id, preference;
        
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        -- Check if the student has already been allocated
        IF NOT EXISTS (
            SELECT 1 FROM TempAllocations WHERE StudentId = student_id
        ) THEN
            -- Check remaining seats for the subject
            SELECT RemainingSeats INTO remaining_seats
            FROM SubjectDetails
            WHERE SubjectId = subject_id;
            
            -- If seats are available, allocate the subject to the student
            IF remaining_seats > 0 THEN
                INSERT INTO TempAllocations (StudentId, SubjectId)
                VALUES (student_id, subject_id);
                
                -- Decrease remaining seats for the subject
                UPDATE SubjectDetails
                SET RemainingSeats = RemainingSeats - 1
                WHERE SubjectId = subject_id;
            END IF;
        END IF;
    END LOOP;
    
    CLOSE cur;
    
    -- Insert allocated subjects into final table
    INSERT INTO Allotments (SubjectId, StudentId)
    SELECT SubjectId, StudentId FROM TempAllocations;
    
    -- Identify unallotted students
    INSERT INTO UnallotedStudents (StudentId)
    SELECT sd.StudentId
    FROM StudentDetails sd
    LEFT JOIN TempAllocations ta ON sd.StudentId = ta.StudentId
    WHERE ta.StudentId IS NULL;
    
    -- Clean up temp table
    DROP TEMPORARY TABLE IF EXISTS TempAllocations;
    
END//

DELIMITER ;
