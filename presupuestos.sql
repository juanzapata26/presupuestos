-- ============================================================
--  SuperTiendaX — Script SQL completo
--  Compatible con MySQL 8+ / MariaDB
--  Autor: FinancialCare / Clase 29 - 11/03/2026
-- ============================================================

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";

-- ── DROP TABLES (orden inverso a las FK) ──────────────────────
DROP TABLE IF EXISTS `payments`;
DROP TABLE IF EXISTS `order_items`;
DROP TABLE IF EXISTS `orders`;
DROP TABLE IF EXISTS `cart`;
DROP TABLE IF EXISTS `product_images`;
DROP TABLE IF EXISTS `products`;
DROP TABLE IF EXISTS `categories`;
DROP TABLE IF EXISTS `customers`;
DROP TABLE IF EXISTS `admin_users`;
DROP TABLE IF EXISTS `users`;

-- ── 1. USERS ──────────────────────────────────────────────────
CREATE TABLE `users` (
  `id`            INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name`          VARCHAR(100) NOT NULL,
  `email`         VARCHAR(150) NOT NULL UNIQUE,
  `password_hash` VARCHAR(255) NOT NULL,
  `role`          ENUM('customer','admin','superadmin') NOT NULL DEFAULT 'customer',
  `is_active`     TINYINT(1) NOT NULL DEFAULT 1,
  `email_verified`TINYINT(1) NOT NULL DEFAULT 0,
  `reset_token`   VARCHAR(100) DEFAULT NULL,
  `reset_expires` DATETIME DEFAULT NULL,
  `created_at`    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_email` (`email`),
  INDEX `idx_role`  (`role`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── 2. ADMIN_USERS ────────────────────────────────────────────
CREATE TABLE `admin_users` (
  `id`            INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id`       INT UNSIGNED NOT NULL,
  `permissions`   JSON DEFAULT NULL COMMENT 'Permisos granulares en JSON',
  `last_login`    DATETIME DEFAULT NULL,
  `created_at`    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_user` (`user_id`),
  CONSTRAINT `fk_admin_user` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── 3. CUSTOMERS ──────────────────────────────────────────────
CREATE TABLE `customers` (
  `id`            INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id`       INT UNSIGNED NOT NULL,
  `phone`         VARCHAR(20) DEFAULT NULL,
  `address`       VARCHAR(255) DEFAULT NULL,
  `city`          VARCHAR(100) DEFAULT NULL,
  `state`         VARCHAR(100) DEFAULT NULL,
  `country`       VARCHAR(80) DEFAULT 'Colombia',
  `zip_code`      VARCHAR(20) DEFAULT NULL,
  `birthdate`     DATE DEFAULT NULL,
  `is_blocked`    TINYINT(1) NOT NULL DEFAULT 0,
  `created_at`    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_customer_user` (`user_id`),
  CONSTRAINT `fk_customer_user` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── 4. CATEGORIES ─────────────────────────────────────────────
CREATE TABLE `categories` (
  `id`            INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name`          VARCHAR(100) NOT NULL,
  `slug`          VARCHAR(110) NOT NULL UNIQUE,
  `description`   TEXT DEFAULT NULL,
  `image_url`     VARCHAR(255) DEFAULT NULL,
  `parent_id`     INT UNSIGNED DEFAULT NULL COMMENT 'Categoría padre para subcategorías',
  `is_active`     TINYINT(1) NOT NULL DEFAULT 1,
  `sort_order`    INT NOT NULL DEFAULT 0,
  `created_at`    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_slug`   (`slug`),
  INDEX `idx_parent` (`parent_id`),
  CONSTRAINT `fk_cat_parent` FOREIGN KEY (`parent_id`) REFERENCES `categories`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── 5. PRODUCTS ───────────────────────────────────────────────
CREATE TABLE `products` (
  `id`            INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `category_id`   INT UNSIGNED NOT NULL,
  `name`          VARCHAR(200) NOT NULL,
  `slug`          VARCHAR(220) NOT NULL UNIQUE,
  `description`   TEXT DEFAULT NULL,
  `short_desc`    VARCHAR(300) DEFAULT NULL,
  `price`         DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `compare_price` DECIMAL(12,2) DEFAULT NULL COMMENT 'Precio antes del descuento',
  `cost_price`    DECIMAL(12,2) DEFAULT NULL,
  `sku`           VARCHAR(80) DEFAULT NULL UNIQUE,
  `stock`         INT NOT NULL DEFAULT 0,
  `stock_alert`   INT NOT NULL DEFAULT 5 COMMENT 'Alerta stock bajo',
  `weight`        DECIMAL(8,3) DEFAULT NULL COMMENT 'kg',
  `is_active`     TINYINT(1) NOT NULL DEFAULT 1,
  `is_featured`   TINYINT(1) NOT NULL DEFAULT 0,
  `views`         INT UNSIGNED NOT NULL DEFAULT 0,
  `created_at`    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_category`  (`category_id`),
  INDEX `idx_slug`      (`slug`),
  INDEX `idx_price`     (`price`),
  INDEX `idx_stock`     (`stock`),
  INDEX `idx_featured`  (`is_featured`),
  FULLTEXT INDEX `ft_search` (`name`,`description`,`short_desc`),
  CONSTRAINT `fk_product_cat` FOREIGN KEY (`category_id`) REFERENCES `categories`(`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── 6. PRODUCT_IMAGES ─────────────────────────────────────────
CREATE TABLE `product_images` (
  `id`            INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `product_id`    INT UNSIGNED NOT NULL,
  `url`           VARCHAR(255) NOT NULL,
  `alt_text`      VARCHAR(150) DEFAULT NULL,
  `is_primary`    TINYINT(1) NOT NULL DEFAULT 0,
  `sort_order`    INT NOT NULL DEFAULT 0,
  `created_at`    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_product` (`product_id`),
  CONSTRAINT `fk_img_product` FOREIGN KEY (`product_id`) REFERENCES `products`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── 7. CART ───────────────────────────────────────────────────
CREATE TABLE `cart` (
  `id`            INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id`       INT UNSIGNED DEFAULT NULL COMMENT 'NULL = carrito de invitado',
  `session_id`    VARCHAR(100) DEFAULT NULL,
  `product_id`    INT UNSIGNED NOT NULL,
  `quantity`      INT NOT NULL DEFAULT 1,
  `added_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_user`    (`user_id`),
  INDEX `idx_session` (`session_id`),
  INDEX `idx_product` (`product_id`),
  CONSTRAINT `fk_cart_user`    FOREIGN KEY (`user_id`)    REFERENCES `users`(`id`)    ON DELETE CASCADE,
  CONSTRAINT `fk_cart_product` FOREIGN KEY (`product_id`) REFERENCES `products`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── 8. ORDERS ─────────────────────────────────────────────────
CREATE TABLE `orders` (
  `id`              INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `order_number`    VARCHAR(30) NOT NULL UNIQUE COMMENT 'ORD-YYYYMMDD-XXXXX',
  `user_id`         INT UNSIGNED DEFAULT NULL,
  `customer_name`   VARCHAR(150) NOT NULL,
  `customer_email`  VARCHAR(150) NOT NULL,
  `customer_phone`  VARCHAR(25) DEFAULT NULL,
  `shipping_address`VARCHAR(255) NOT NULL,
  `shipping_city`   VARCHAR(100) NOT NULL,
  `shipping_country`VARCHAR(80) NOT NULL DEFAULT 'Colombia',
  `shipping_zip`    VARCHAR(20) DEFAULT NULL,
  `subtotal`        DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `shipping_cost`   DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  `tax`             DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  `discount`        DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  `total`           DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `status`          ENUM('pending','paid','shipped','delivered','cancelled','refunded') NOT NULL DEFAULT 'pending',
  `notes`           TEXT DEFAULT NULL,
  `created_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_order_number` (`order_number`),
  INDEX `idx_user`         (`user_id`),
  INDEX `idx_status`       (`status`),
  INDEX `idx_created`      (`created_at`),
  CONSTRAINT `fk_order_user` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── 9. ORDER_ITEMS ────────────────────────────────────────────
CREATE TABLE `order_items` (
  `id`            INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `order_id`      INT UNSIGNED NOT NULL,
  `product_id`    INT UNSIGNED DEFAULT NULL,
  `product_name`  VARCHAR(200) NOT NULL COMMENT 'Snapshot del nombre al momento de compra',
  `product_sku`   VARCHAR(80) DEFAULT NULL,
  `quantity`      INT NOT NULL DEFAULT 1,
  `unit_price`    DECIMAL(12,2) NOT NULL,
  `subtotal`      DECIMAL(12,2) NOT NULL,
  PRIMARY KEY (`id`),
  INDEX `idx_order`   (`order_id`),
  INDEX `idx_product` (`product_id`),
  CONSTRAINT `fk_item_order`   FOREIGN KEY (`order_id`)   REFERENCES `orders`(`id`)   ON DELETE CASCADE,
  CONSTRAINT `fk_item_product` FOREIGN KEY (`product_id`) REFERENCES `products`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── 10. PAYMENTS ──────────────────────────────────────────────
CREATE TABLE `payments` (
  `id`              INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `order_id`        INT UNSIGNED NOT NULL,
  `method`          ENUM('credit_card','debit_card','pse','nequi','bancolombia','paypal','stripe','cash') NOT NULL,
  `status`          ENUM('pending','approved','rejected','refunded') NOT NULL DEFAULT 'pending',
  `amount`          DECIMAL(12,2) NOT NULL,
  `currency`        CHAR(3) NOT NULL DEFAULT 'COP',
  `transaction_id`  VARCHAR(200) DEFAULT NULL COMMENT 'ID de la pasarela de pago',
  `gateway_response`JSON DEFAULT NULL COMMENT 'Respuesta completa de la pasarela',
  `paid_at`         DATETIME DEFAULT NULL,
  `created_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_order`       (`order_id`),
  INDEX `idx_status`      (`status`),
  INDEX `idx_transaction` (`transaction_id`),
  CONSTRAINT `fk_payment_order` FOREIGN KEY (`order_id`) REFERENCES `orders`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── WISHLIST (extra profesional) ──────────────────────────────
CREATE TABLE `wishlist` (
  `id`         INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id`    INT UNSIGNED NOT NULL,
  `product_id` INT UNSIGNED NOT NULL,
  `added_at`   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_wish` (`user_id`,`product_id`),
  CONSTRAINT `fk_wish_user`    FOREIGN KEY (`user_id`)    REFERENCES `users`(`id`)    ON DELETE CASCADE,
  CONSTRAINT `fk_wish_product` FOREIGN KEY (`product_id`) REFERENCES `products`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ═══════════════════════════════════════════════════════════════
-- DATOS DE PRUEBA
-- ═══════════════════════════════════════════════════════════════

-- Admin y usuarios demo
INSERT INTO `users` (`name`,`email`,`password_hash`,`role`) VALUES
('Super Admin','admin@supertiendax.co','$2y$12$examplehashADMIN111111111111111111111111111111111111','superadmin'),
('Ana Gómez','ana@cliente.co','$2y$12$examplehashUSER111111111111111111111111111111111111','customer'),
('Carlos Ruiz','carlos@cliente.co','$2y$12$examplehashUSER222222222222222222222222222222222222','customer');

INSERT INTO `admin_users` (`user_id`,`permissions`) VALUES
(1, '{"products":true,"orders":true,"users":true,"reports":true}');

INSERT INTO `customers` (`user_id`,`phone`,`address`,`city`,`country`) VALUES
(2,'3101234567','Calle 50 # 40-20','Medellín','Colombia'),
(3,'3209876543','Carrera 7 # 15-30','Bogotá','Colombia');

-- Categorías
INSERT INTO `categories` (`name`,`slug`,`description`,`is_active`,`sort_order`) VALUES
('Electrónica','electronica','Smartphones, laptops y gadgets',1,1),
('Ropa y Accesorios','ropa-accesorios','Moda para todos',1,2),
('Hogar y Jardín','hogar-jardin','Todo para tu hogar',1,3),
('Deportes','deportes','Equipamiento deportivo',1,4),
('Libros','libros','Libros físicos y digitales',1,5);

-- Productos
INSERT INTO `products` (`category_id`,`name`,`slug`,`short_desc`,`price`,`compare_price`,`sku`,`stock`,`is_featured`) VALUES
(1,'Smartphone ProMax 15','smartphone-promax-15','128GB · 5G · Cámara 108MP',2499900,2999900,'SKU-PHONE-001',50,1),
(1,'Laptop UltraSlim 14"','laptop-ultraslim-14','Intel i7 · 16GB RAM · 512GB SSD',4199000,4799000,'SKU-LAPT-001',25,1),
(1,'Auriculares BT-Pro','auriculares-bt-pro','Noise cancelling · 30h batería',389000,450000,'SKU-AUD-001',80,0),
(2,'Camiseta Premium Fit','camiseta-premium-fit','100% algodón peinado · 6 colores',89000,NULL,'SKU-CAM-001',200,0),
(2,'Sneakers Urban X','sneakers-urban-x','Tallas 38-46 · Suela reforzada',299000,350000,'SKU-SHOE-001',60,1),
(3,'Silla Ergonómica Pro','silla-ergonomica-pro','Lumbar ajustable · Ruedas 360°',899000,1100000,'SKU-SILL-001',15,1),
(4,'Mancuernas 10kg x2','mancuernas-10kg','Recubiertas vinilo · Par',149000,NULL,'SKU-MANC-001',40,0),
(5,'Clean Code - R. Martin','clean-code-martin','Guía práctica desarrollo limpio',89000,NULL,'SKU-BOOK-001',100,0);

-- Imágenes de productos (usando placeholder)
INSERT INTO `product_images` (`product_id`,`url`,`is_primary`,`sort_order`) VALUES
(1,'https://via.placeholder.com/600x600/1a1a2e/C9A84C?text=Phone',1,0),
(2,'https://via.placeholder.com/600x600/1a1a2e/C9A84C?text=Laptop',1,0),
(3,'https://via.placeholder.com/600x600/1a1a2e/C9A84C?text=Audio',1,0),
(4,'https://via.placeholder.com/600x600/2d5a27/ffffff?text=Ropa',1,0),
(5,'https://via.placeholder.com/600x600/2d5a27/ffffff?text=Shoes',1,0),
(6,'https://via.placeholder.com/600x600/5a2d82/ffffff?text=Silla',1,0),
(7,'https://via.placeholder.com/600x600/2d4a5a/ffffff?text=Sport',1,0),
(8,'https://via.placeholder.com/600x600/5a3a1a/ffffff?text=Book',1,0);

-- Pedido de ejemplo
INSERT INTO `orders` (`order_number`,`user_id`,`customer_name`,`customer_email`,`shipping_address`,`shipping_city`,`shipping_country`,`subtotal`,`shipping_cost`,`tax`,`total`,`status`) VALUES
('ORD-20260311-00001',2,'Ana Gómez','ana@cliente.co','Calle 50 # 40-20','Medellín','Colombia',2499900,15000,474981,2989881,'paid'),
('ORD-20260311-00002',3,'Carlos Ruiz','carlos@cliente.co','Carrera 7 # 15-30','Bogotá','Colombia',388000,12000,75960,475960,'pending');

INSERT INTO `order_items` (`order_id`,`product_id`,`product_name`,`product_sku`,`quantity`,`unit_price`,`subtotal`) VALUES
(1,1,'Smartphone ProMax 15','SKU-PHONE-001',1,2499900,2499900),
(2,3,'Auriculares BT-Pro','SKU-AUD-001',1,389000,389000);

INSERT INTO `payments` (`order_id`,`method`,`status`,`amount`,`currency`,`paid_at`) VALUES
(1,'pse','approved',2989881,'COP','2026-03-11 18:30:00');

COMMIT;
