--Part 01
--Create a table called Employees_Archives that has the same columns as employees table and it also has a column that is called “Deletion_Date”
create table EMPLOYEE_ARCHIVE(
                    EMPLOYEE_ID int not null,
                    FIRST_NAME varchar(50) not null,
                    LAST_NAME varchar(50) not null,
                    EMAIL varchar(50) not null,
                    PHONE_NUMBER varchar(100),
                    HIRE_DATE date not null,
                    JOB_ID varchar(25) not null,
                    SALARY number(8,2) not null,
                    COMMISSION_PCT number(8,2) null,
                    MANAGER_ID number(6,0) null,
                    DEPARTMENT_ID number(4,0) null,
                    SPOUCE number(6,0) null,
                    DELETIONDATE date not null);
                    
--Create a Trigger on table Employees so that every time a record is deleted this same record is inserted in table Employees_Archives with the current date as Deletion_Date
create or replace trigger newTrig
    after delete on EMPLOYEES
    for each row
begin
    insert into EMPLOYEE_ARCHIVES values 
                            ( :old.EMPLOYEE_ID, :old.FIRST_NAME, :old.LAST_NAME, :old.EMAIL,
                              :old.PHONE_NUMBER, :old.HIRE_DATE, :old.JOB_ID, :old.SALARY, 
                              :old.COMMISSION_PCT, :old.MANAGER_ID, :old.DEPARTMENT_ID, :old.SPOUCE, sysdate );
end;
       
--Now give an example of execution. Insert a new employee into table Employees and then delete it. Is the record inserted correctly into table Employees_Archive? What will happen if you delete more than one records at the same time?
insert into EMPLOYEES
            (EMPLOYEE_ID, FIRST_NAME, LAST_NAME, EMAIL, PHONE_NUMBER, HIRE_DATE,
            JOB_ID, SALARY, COMMISSION_PCT, MANAGER_ID, DEPARTMENT_ID, SPOUCE)
        values
        (207, 'testy', 'testy', 'testy', '100.200.3000', to_date('01-JAN-1998', 'dd-mon-yyyy',
        'PU_CLERK', 4000, null, 205, 50, null);

delete from EMPLOYEES
    where EMPLOYEE_ID = 207;
    
--Part 02
--Create a function that has the Employee_id as input and returns a number that represents the total number of Positions (counted by unique job_ids) that this employee has had. Notice that you will need to take into account both his/her current job_id in employees table as well as the previous positions in Job_History.
create function GET_JOBS(EMPLOYEE_NUM in number)
    return number
    is TOTAL_JOBS number;
    begin
    select count(JOB_ID) 
    into TOTAL_JOBS
    from (select JOB_HISTORY.JOB_ID, JOB_HISTORY.EMPLOYEE_ID
          from JOB_HISTORY
         )
    where EMPLOYEE_ID = employee_num
    group by EMPLOYEE_ID;
    return TOTAL_JOBS;
    end;
    /
--Now use the function: Write a select statement that selects all the employees and the total number of positions they have ever had.
select get_jobs(105) 
    from dual;

--Part 03
--Write a select statement that selects the second highest salary. 
select max(SALARY) 
    from EMPLOYEES
where salary < (select max(SALARY) 
                        from EMPLOYEES);

--Part 04
--Write a procedure that has as input the location_id. Then the procedure should delete the corresponding location from table locations.
create or replace procedure REMOVE_LOCATION(X number)
   is
    begin 
        update DEPARTMENTS 
        set X = null
        where DEPARTMENTS.X = X;
        delete 
        from locations
        where X = X;
        end;
    /
--Notice that location_id is a foreign key on table departments. Therefore, the location cannot be deleted if there are departments in this location. 
--To delete it should first update the corresponding department and assign this department to an undefined location. Since mo undefined location record exists you need to create one.
--Now execute the procedure to delete an example location (one with departments associated).
begin 
    REMOVE_LOCATION('2500');
end;
/
--ROLLBACK; and all these changes will be undone!
rollback;

--Part 05 
--Write a procedure that has as input the department_id. Then the procedure should search through all the employees of this department 
--and if their commission percentage is empty or is 0.15 or less, then update it to either 1/10000*employee salary (if originally empty) or to 0.1 + 1/10000*employee salary if it was originally 0.15 or less.  
create or replace procedure COMMISH(x in number) as

    cursor c is select EMPLOYEE_ID, SALARY, COMMISSION_PCT, DEPARTMENT_ID from EMPLOYEES where x = DEPARTMENT_ID;
    COMMISH number(5,2);
    begin

    for i in c
    loop 
        COMMISH := i.COMMISSION_PCT;
        if i.COMMISSION_PCT is null then
                COMMISH := (1/100000)*i.SALARY;
        elsif i.COMMISSION_PCT <= 0.15 then
                COMMISH := 0.1 + (1/100000)*i.SALARY;
        end if;
        update EMPLOYEES set COMMISSION_PCT = COMMISH where DEPARTMENT_ID=i.DEPARTMENT_ID and EMPLOYEE_ID=i.EMPLOYEE_ID;
    end loop;
end;
/

--Give an example of execution.
execute COMMISH(90);

--What will happen if you ROLLBACK;
-- if rolled back the procedure would be gone. 

--Part 06

--Use the metadata tables for users to count how many tables, how many indexes and how many views you have created in your database.
select count(*) from USER_TABLES;
select count(*) from USER_VIEWS;
select count(*) from USER_INDEXES;
--Write an anonymous block with dynamic SQL to drop all the NON-Unique indexes in your database.
BEGIN
    FOR record IN (SELECT INDEX_NAME FROM USER_INDEXES 
                   WHERE UNIQUENESS LIKE 'NONUNIQUE')
    LOOP
        EXECUTE IMMEDIATE 'DROP INDEX ' || record.INDEX_NAME;
    END LOOP;
END;
/