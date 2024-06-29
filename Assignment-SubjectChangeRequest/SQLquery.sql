CREATE PROCEDURE ProcessSubjectRequest()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE student_id VARCHAR(50);
    DECLARE subject_id VARCHAR(50);
    DECLARE current_subject VARCHAR(50);
    
    -- Cursor to iterate over each subject request
    DECLARE cur CURSOR FOR 
        SELECT sr.StudentId, sr.SubjectId
        FROM SubjectRequest sr;
    
    -- Handlers
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    -- Temp table to track latest valid subjects for each student
    CREATE TEMPORARY TABLE IF NOT EXISTS TempSubjectAllotments (
        StudentId VARCHAR(50),
        SubjectId VARCHAR(50),
        Is_Valid BIT
    );
    
    -- Loop through each subject request
    OPEN cur;
    read_loop: LOOP
        FETCH cur INTO student_id, subject_id;
        
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        -- Check if the student already has an active subject
        SELECT SubjectId INTO current_subject
        FROM TempSubjectAllotments
        WHERE StudentId = student_id AND Is_Valid = 1;
        
        IF current_subject IS NULL THEN
            -- If no current active subject, insert the requested subject as valid
            INSERT INTO TempSubjectAllotments (StudentId, SubjectId, Is_Valid)
            VALUES (student_id, subject_id, 1);
        ELSE
            -- If there is already an active subject, check if it's different from the requested one
            IF current_subject <> subject_id THEN
                -- Deactivate the current subject
                UPDATE TempSubjectAllotments
                SET Is_Valid = 0
                WHERE StudentId = student_id AND Is_Valid = 1;
                
                -- Insert the new requested subject as valid
                INSERT INTO TempSubjectAllotments (StudentId, SubjectId, Is_Valid)
                VALUES (student_id, subject_id, 1);
            END IF;
        END IF;
        
        -- Insert the request into the SubjectRequest table (to maintain a log)
        INSERT INTO SubjectAllotments (StudentId, SubjectId, Is_Valid)
        VALUES (student_id, subject_id, 1);
        
        -- Delete processed request from SubjectRequest table
        DELETE FROM SubjectRequest WHERE StudentId = student_id AND SubjectId = subject_id;
        
    END LOOP;
    
    CLOSE cur;
    
    -- Clean up temp table
    DROP TEMPORARY TABLE IF EXISTS TempSubjectAllotments;
    
END//

DELIMITER ;

CALL ProcessSubjectRequest();
