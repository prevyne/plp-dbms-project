# MySQL Inventory Tracking System Database Schema

## Description

This project provides a well-structured relational database schema designed in MySQL for managing and tracking inventory. It includes tables for products, categories, suppliers, storage locations (warehouses/stores), current stock levels per location, and a detailed transaction log for auditing all inventory movements (like purchases, sales, transfers, and adjustments).

This schema serves as a robust foundation for building an inventory management application. It is suitable for small to medium-sized businesses needing a reliable system for inventory control.

Key features include:
* Tracking products with details like SKU, description, price, and category.
* Managing suppliers and linking them to products (Many-to-Many).
* Defining multiple storage locations.
* Recording exact stock quantities for each product at each location.
* Maintaining a complete history of inventory transactions for auditing and reporting.
* Use of appropriate constraints (Primary Keys, Foreign Keys, Unique, Not Null) to ensure data integrity.
* Timestamp columns (`created_at`, `updated_at`) for tracking record changes.

## How to Setup / Import the SQL Schema

To use this schema, you need a running MySQL server instance and a MySQL client (like the command-line tool, MySQL Workbench, phpMyAdmin, etc.).

**Steps:**

1.  **Download the SQL File:** Ensure you have the `inventory_schema.sql` file from this repository.
2.  **Create a Database (Optional):** You can create a new database for this schema or use an existing one.
    ```sql
    -- Optional: Create a new database named 'inventory_db'
    CREATE DATABASE inventory_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
    ```
3.  **Select the Database:** Before running the script, select the target database.
    ```sql
    USE inventory_db;
    ```
4.  **Run the SQL Script:** Execute the contents of `inventory_schema.sql` using your MySQL client.

    * **Using the MySQL Command Line:**
        ```bash
        mysql -u <your_username> -p <database_name> < inventory_schema.sql
        ```
        Replace `<your_username>` with your MySQL username and `<database_name>` with the name of the database you created or selected (e.g., `inventory_db`). You will be prompted for your password.

    * **Using a GUI Tool (MySQL Workbench, DBeaver, etc.):**
        1.  Connect to your MySQL server.
        2.  Open the `inventory_schema.sql` file in the SQL editor.
        3.  Make sure the correct database is selected as the default schema.
        4.  Execute the entire script.

5.  **Verify:** Once the script runs successfully, you can check if all the tables (`categories`, `suppliers`, `locations`, `products`, `product_suppliers`, `inventory`, `inventory_transactions`) have been created in your database.

**Note:** The schema uses a `CHECK` constraint on the `inventory` table (`quantity >= 0`). This feature requires **MySQL version 8.0.16 or newer**. If you are using an older version, the table will still be created, but the check constraint will be ignored. You will need to enforce this rule in your application logic or using triggers.

## Entity-Relationship Diagram (ERD)

An Entity-Relationship Diagram (ERD) visually represents the database tables (entities), their attributes (columns), and the relationships between them.

Below is a link to the graphical representation of the Schema:

https://drive.google.com/file/d/17SLGDkmpW0SPxdly3iEWkv_N42FIwqpL/view?usp=sharing

---End--
