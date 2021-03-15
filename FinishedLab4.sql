--1. Create a new table named Customers_Statistics with the following columns:
--Customer_id, Customer_Last_Name, Number_of_Orders, Number_of_Items
--Complete the table definition by choosing the appropriate data types, primary and foreign keys.
create table Customers_Statistics(
    CUSTOMER_ID int not null,
    CUSTOMER_LAST_NAME char not null,
    NUMBER_OF_ORDERS int not null,
    NUMER_OF_ITEMS int not null,
    primary key (CUSTOMER_ID),
    foreign key (CUSTOMER_ID) references customers(CUSTOMER_ID));

--2. Now write a query that selects for every customer the number of orders he has places and the number of items he has bought, 
--including zeros for customers with no orders.
select c.CUSTOMER_ID, c.CUSTOMER_LAST_NAME, count(o.ORDER_ID) as NumORDERS, sum(ORDER_QTY) as NumITEMS
    from CUSTOMERS c inner join ORDERS o on c.CUSTOMER_ID = o.CUSTOMER_ID
                     inner join ORDER_DETAILS od on o.ORDER_ID = od.ORDER_ID
    group by c.CUSTOMER_ID, c.CUSTOMER_LAST_NAME
    order by c.CUSTOMER_ID;

--3. Using the query above populate the table Customers_Statistics
--Hint: Use the statement INSERT INTO …. SELECT
--Extra: What is going to happen if you rollback? 
insert into Customers_Statistics
    select c.CUSTOMER_ID, c.CUSTOMER_LAST_NAME, count(o.ORDER_ID) as NumORDERS, sum(ORDER_QTY) as NumITEMS
    from CUSTOMERS c inner join ORDERS o on c.CUSTOMER_ID = o.CUSTOMER_ID
                     inner join ORDER_DETAILS od on o.ORDER_ID = od.ORDER_ID
    group by c.CUSTOMER_ID, c.CUSTOMER_LAST_NAME;

--4. Now add a new column to the table called Customer_Status that is a string of maximum length 20;  Extra: What is going to happen if you rollback?
alter table CUSTOMERS_STATISTICS
    add Customer_Status varchar(20);
--5. Now let’s update the table so that Customer_Status has the following values:
--‘ok’ when the number of orders is 0 or 1
--‘good’ when the number of orders is 2  or more
--‘great’ when the number of orders is > 5 and the number of items is >5
update CUSTOMERS_STATISTICS 
    set CUSTOMER_STATUS = case 
        when(NUMBER_OF_ORDERS < 2) then 'Ok'
        when(NUMBER_OF_ORDERS > 2) then 'Good'
        when(NUMBER_OF_ORDERS > 4) then 'Great'
    end;

--6. Delete from the table Customers_Statistics all the customers that have not placed any orders
delete from CUSTOMERS_STATISTICS where NUMBER_OF_ORDERS < 1;

--7. Modify the table and change the column definition of Number_of_Items to a column that cannot be NULL
update CUSTOMERS_STATISTICS set NUMBER_OF_ITEMS = 0
    where NUMBER_OF_ITEMS is null;
--8. Modify the table and change the column definition of Number_of_Orders to a column that has a default value 0
alter table CUSTOMERS_STATISTICS
    modify NUMBER_OF_ORDERS default 0;
    
--9. Update the records of table Customer_Statistics and set the last names of all customers with id larger than 20 to ‘Keenan’.
update customers_statistics
  set customer_last_name = 'Keenan'
  where customer_id > 20;
  
--10. Drop the foreign key constraint you created earlier (the one that says that Customer_Id of Customer_Statistics references Customer_Id of Customers). If you did not create the FK create it first and then drop it.
alter table customers_statistics
drop constraint SYS_C00727485;

--11. Insert a new record with Customer_Id = 100, Customer_Last_Name= ‘Polychronopoulou’ (or anything else!) and 0 for orders and items. Don’t forget to commit! Extra: Could you have done that without dropping the FK?
insert into customers_statistics (customer_id, customer_last_name, number_of_orders, numer_of_items, customer_status)
values (100, 'Gill-Fisher', 0, 0, null); 
 

--12. Write a merge statement to merge the data of the tables Customers and Customer_Statistics. You should modify the data of table Customer_Statistics by:
--Compare the records using customer_id
--If the ids are the same but the last names are different then update table Customer Statistics to match Customers
--If the ids exist In Customers and not exist in Customer_Statistics then insert the customer with 0 values for items and orders
merge into CUSTOMERS_STATISTICS cs
    using CUSTOMERS c on (cs.CUSTOMER_ID = c.CUSTOMER_ID)
    when matched then
        update set cs.CUSTOMER_LAST_NAME = c.CUSTOMER_LAST_NAME
    when not matched then
        insert (Customer_ID, Customer_Last_Name, Number_Of_Orders, Numer_Of_Items)
        values (c.CUSTOMER_ID, c.CUSTOMER_LAST_NAME, 0, 0);

--13. A. Create a view that holds only the customers that have a Customer_Status ‘ok’.
create view CustOk as 
    select * 
from customers_statistics
    where customer_status = 'Ok';
--      B. Now update one of the customers names using the view. Do you see this change  transferred to Customers table? 
update CustOkCali
    set CUSTOMER_LAST_NAME = 'zzzz'
where CUSTOMER_ID = 25;

--     C. Now create a view that holds the customers that have a Customer_Status ‘ok’ and are from California, using the WITH CHECK option. Now update again one  of the customers names using the view. Do you see this change  transferred to Customers table? Now update the state, can you do that?  
create view CustOkCali
    as select s.Customer_ID, s.Customer_Last_Name, c.Customer_State, s.Customer_Status
from Customers_Statistics s inner join Customers c on s.Customer_ID = c.Customer_Id
    where s.Customer_Status = 'Ok' and c.customer_state = 'CA'
with check option;

--14. Truncate table Customers_Statistics. Can you still see the table definition? What about the data?
truncate table customers_statistics;
--can see table but no data

--15. Drop table Customers_Statistics. Can you still see the table definition?
drop table customers_statistics;
--can no longer see customer definition 


--16. Functions:
--a. Create a function that has the Customer_id as input and returns a number that represents the total cost of orders for this customer. Notice that you will need to multiply the Order_Qty from table order_details and the Unit_Price from table items to get the total cost of each order.
create or replace function CustomerTotal(cust_id in number)
    return number is cost_total number(10, 2);
    begin
        select sum(sum(ORDER_QTY*UNIT_PRICE)) into cost_total
        from CUSTOMERS natural join ORDERS natural join ORDER_DETAILS
            natural join ITEMS
        where CUSTOMER_ID = cust_id
        group by ORDER_ID;
        return(cost_total);
    end;
--b. Now use the function: Write a select statement that selects all the customers and the total cost of the orders they have ever made.
select CUSTOMER_ID, CustomerTotal(CUSTOMER_ID)
    from CUSTOMERS;

--17. Procedure:
create procedure remove_cust (customer_id number) as
begin
    delete from order_details;
    delete from orders;
    delete from customers
    where customers.customer_id = remove_cust.customer_id;
    end;
--d. ROLLBACK; and all these changes will be undone!
execute remove_cust(1);