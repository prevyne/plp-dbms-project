-- Database Schema for Inventory Tracking System
-- Target DBMS: MySQL

-- Disable foreign key checks temporarily to avoid order issues during creation
SET FOREIGN_KEY_CHECKS=0;

-- -------------------------------------
-- Table structure for `categories`
-- Purpose: To group products (e.g., Electronics, Clothing, Food)
-- -------------------------------------
DROP TABLE IF EXISTS `categories`;
CREATE TABLE `categories` (
  `category_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL,
  `description` TEXT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`category_id`),
  UNIQUE KEY `uq_category_name` (`name`) -- Category names should be unique
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -------------------------------------
-- Table structure for `suppliers`
-- Purpose: To store information about product suppliers
-- -------------------------------------
DROP TABLE IF EXISTS `suppliers`;
CREATE TABLE `suppliers` (
  `supplier_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(150) NOT NULL,
  `contact_person` VARCHAR(100) NULL,
  `email` VARCHAR(100) NULL,
  `phone` VARCHAR(30) NULL,
  `address` TEXT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`supplier_id`),
  UNIQUE KEY `uq_supplier_name` (`name`), -- Supplier names should ideally be unique
  KEY `idx_supplier_email` (`email`) -- Index for faster lookup by email
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -------------------------------------
-- Table structure for `locations`
-- Purpose: To store information about where inventory is stored (e.g., Warehouses, Stores)
-- -------------------------------------
DROP TABLE IF EXISTS `locations`;
CREATE TABLE `locations` (
  `location_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL,
  `address` TEXT NULL,
  `is_active` BOOLEAN NOT NULL DEFAULT TRUE, -- To mark if a location is currently operational
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`location_id`),
  UNIQUE KEY `uq_location_name` (`name`) -- Location names should be unique
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -------------------------------------
-- Table structure for `products`
-- Purpose: To store details about the items being tracked
-- -------------------------------------
DROP TABLE IF EXISTS `products`;
CREATE TABLE `products` (
  `product_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `sku` VARCHAR(50) NOT NULL, -- Stock Keeping Unit - should be unique
  `name` VARCHAR(150) NOT NULL,
  `description` TEXT NULL,
  `category_id` INT UNSIGNED NULL, -- Can be NULL if product doesn't fit a category
  `unit_price` DECIMAL(10, 2) NOT NULL DEFAULT 0.00, -- Selling price or standard cost
  `unit_of_measure` VARCHAR(20) NOT NULL DEFAULT 'unit', -- e.g., 'kg', 'liter', 'piece', 'box'
  `is_active` BOOLEAN NOT NULL DEFAULT TRUE, -- To mark if product is currently sold/tracked
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`product_id`),
  UNIQUE KEY `uq_product_sku` (`sku`), -- SKU must be unique
  KEY `idx_product_name` (`name`), -- Index for searching by name
  CONSTRAINT `fk_product_category`
    FOREIGN KEY (`category_id`)
    REFERENCES `categories` (`category_id`)
    ON DELETE SET NULL -- If category is deleted, set product's category to NULL
    ON UPDATE CASCADE -- If category_id changes, update it here
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -------------------------------------
-- Table structure for `product_suppliers` (Junction Table for M:M)
-- Purpose: Links Products to Suppliers (A product can have multiple suppliers, a supplier can provide multiple products)
-- -------------------------------------
DROP TABLE IF EXISTS `product_suppliers`;
CREATE TABLE `product_suppliers` (
  `product_supplier_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `product_id` INT UNSIGNED NOT NULL,
  `supplier_id` INT UNSIGNED NOT NULL,
  `supplier_product_code` VARCHAR(50) NULL, -- Supplier's specific code for this product (optional)
  `cost_price` DECIMAL(10, 2) NULL, -- Cost price from this specific supplier (optional)
  PRIMARY KEY (`product_supplier_id`),
  UNIQUE KEY `uq_product_supplier` (`product_id`, `supplier_id`), -- Ensure a product-supplier pair is unique
  CONSTRAINT `fk_ps_product`
    FOREIGN KEY (`product_id`)
    REFERENCES `products` (`product_id`)
    ON DELETE CASCADE -- If product is deleted, remove this relationship
    ON UPDATE CASCADE,
  CONSTRAINT `fk_ps_supplier`
    FOREIGN KEY (`supplier_id`)
    REFERENCES `suppliers` (`supplier_id`)
    ON DELETE CASCADE -- If supplier is deleted, remove this relationship
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------
-- Table structure for `inventory`
-- Purpose: To store the actual stock quantity of each product at each location
-- -------------------------------------
DROP TABLE IF EXISTS `inventory`;
CREATE TABLE `inventory` (
  `inventory_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `product_id` INT UNSIGNED NOT NULL,
  `location_id` INT UNSIGNED NOT NULL,
  `quantity` INT NOT NULL DEFAULT 0, -- Current stock quantity
  `reorder_level` INT UNSIGNED NULL DEFAULT 0, -- Minimum quantity before reordering
  `last_updated` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`inventory_id`),
  UNIQUE KEY `uq_inventory_product_location` (`product_id`, `location_id`), -- A product can only exist once per location in this table
  CONSTRAINT `fk_inventory_product`
    FOREIGN KEY (`product_id`)
    REFERENCES `products` (`product_id`)
    ON DELETE CASCADE -- If product is deleted, remove its inventory records
    ON UPDATE CASCADE,
  CONSTRAINT `fk_inventory_location`
    FOREIGN KEY (`location_id`)
    REFERENCES `locations` (`location_id`)
    ON DELETE CASCADE -- If location is deleted, remove its inventory records
    ON UPDATE CASCADE,
  CONSTRAINT `chk_inventory_quantity` CHECK (`quantity` >= 0) -- Ensure quantity is not negative (Requires MySQL 8.0.16+)
                                                             -- For older versions, this check must be handled by application logic or triggers.
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -------------------------------------
-- Table structure for `inventory_transactions`
-- Purpose: To log all movements of inventory (purchases, sales, transfers, adjustments)
-- -------------------------------------
DROP TABLE IF EXISTS `inventory_transactions`;
CREATE TABLE `inventory_transactions` (
  `transaction_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `product_id` INT UNSIGNED NOT NULL,
  `location_id` INT UNSIGNED NOT NULL, -- The location where the transaction occurred
  `transaction_type` ENUM('Purchase', 'Sale', 'Transfer_In', 'Transfer_Out', 'Adjustment_Add', 'Adjustment_Remove', 'Initial_Stock') NOT NULL,
  `quantity` INT UNSIGNED NOT NULL, -- The absolute quantity involved in the transaction (always positive)
  `transaction_date` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `notes` TEXT NULL,
  `related_document_id` VARCHAR(100) NULL, -- e.g., Purchase Order ID, Sales Invoice No, Transfer ID
  -- Optional: Link to a user who performed the transaction
  -- `user_id` INT UNSIGNED NULL,
  PRIMARY KEY (`transaction_id`),
  KEY `idx_transaction_product_location_date` (`product_id`, `location_id`, `transaction_date`), -- Index for reports
  CONSTRAINT `fk_transaction_product`
    FOREIGN KEY (`product_id`)
    REFERENCES `products` (`product_id`)
    ON DELETE RESTRICT -- Prevent deleting a product if it has transaction history (or set to SET NULL if preferred)
    ON UPDATE CASCADE,
  CONSTRAINT `fk_transaction_location`
    FOREIGN KEY (`location_id`)
    REFERENCES `locations` (`location_id`)
    ON DELETE RESTRICT -- Prevent deleting a location if it has transaction history
    ON UPDATE CASCADE
  -- Optional User Foreign Key Constraint:
  -- CONSTRAINT `fk_transaction_user`
  --  FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`)
  --  ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Re-enable foreign key checks
SET FOREIGN_KEY_CHECKS=1;

-- ---End---
