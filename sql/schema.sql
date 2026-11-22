-- =============================================================================
-- Skema Database: Open.mp Roleplay Framework (MariaDB 10.6+ / MySQL 8.0+)
-- Karakter Enkripsi & Kolasi: utf8mb4 / utf8mb4_unicode_ci
-- Mesin Penyimpanan: InnoDB (Transaksi ACID & Integritas Foreign Key)
-- =============================================================================

SET FOREIGN_KEY_CHECKS = 0;

-- -----------------------------------------------------------------------------
-- 1. Tabel Versi Skema (Untuk Migrasi Otomatis)
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS `schema_version`;
CREATE TABLE `schema_version` (
    `version` VARCHAR(16) NOT NULL,
    `applied_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `notes` TEXT NULL,
    PRIMARY KEY (`version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- 2. Tabel Pengaturan Konfigurasi Server (Key-Value)
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS `server_settings`;
CREATE TABLE `server_settings` (
    `setting_key` VARCHAR(64) NOT NULL,
    `setting_value` TEXT NOT NULL,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`setting_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- 3. Tabel Akun Pengguna Master
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS `accounts`;
CREATE TABLE `accounts` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `username` VARCHAR(32) NOT NULL,
    `password_hash` VARCHAR(128) NOT NULL,
    `email` VARCHAR(128) NULL,
    `register_ip` VARCHAR(45) NOT NULL,
    `last_ip` VARCHAR(45) NOT NULL,
    `serial` VARCHAR(128) NULL,
    `admin_level` TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `admin_pin_hash` VARCHAR(128) NULL,
    `helper_level` TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `vip_level` TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `vip_expire` DATETIME NULL,
    `login_attempts` TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `last_login` DATETIME NULL,
    `banned` TINYINT(1) NOT NULL DEFAULT 0,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `idx_accounts_username` (`username`),
    KEY `idx_accounts_last_ip` (`last_ip`),
    KEY `idx_accounts_serial` (`serial`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- 4. Tabel Pemblokiran (Bans)
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS `bans`;
CREATE TABLE `bans` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `account_id` INT UNSIGNED NULL,
    `ip` VARCHAR(45) NULL,
    `serial` VARCHAR(128) NULL,
    `admin_id` INT UNSIGNED NOT NULL,
    `admin_name` VARCHAR(32) NULL,
    `reason` VARCHAR(255) NOT NULL,
    `active` TINYINT(1) NOT NULL DEFAULT 1,
    `banned_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `expire_at` DATETIME NULL,
    PRIMARY KEY (`id`),
    KEY `idx_bans_account` (`account_id`),
    KEY `idx_bans_ip` (`ip`),
    KEY `idx_bans_serial` (`serial`),
    CONSTRAINT `fk_bans_account` FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- 5. Tabel Faksi & Organisasi
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS `factions`;
CREATE TABLE `factions` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(64) NOT NULL,
    `type` TINYINT UNSIGNED NOT NULL DEFAULT 0, -- 1: Police, 2: Medic, 3: Gov, 4: News, 5: Gang
    `color` INT NOT NULL DEFAULT -1,
    `bank` INT NOT NULL DEFAULT 0,
    `max_members` INT UNSIGNED NOT NULL DEFAULT 50,
    `spawn_x` FLOAT NOT NULL DEFAULT 0.0,
    `spawn_y` FLOAT NOT NULL DEFAULT 0.0,
    `spawn_z` FLOAT NOT NULL DEFAULT 0.0,
    `spawn_angle` FLOAT NOT NULL DEFAULT 0.0,
    `spawn_interior` INT NOT NULL DEFAULT 0,
    `spawn_vw` INT NOT NULL DEFAULT 0,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- 6. Tabel Tingkatan Pangkat Faksi (Faction Ranks)
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS `faction_ranks`;
CREATE TABLE `faction_ranks` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `faction_id` INT UNSIGNED NOT NULL,
    `rank_level` TINYINT UNSIGNED NOT NULL,
    `name` VARCHAR(48) NOT NULL,
    `salary` INT NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`),
    UNIQUE KEY `idx_faction_rank_level` (`faction_id`, `rank_level`),
    CONSTRAINT `fk_faction_ranks_faction` FOREIGN KEY (`faction_id`) REFERENCES `factions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- 7. Tabel Karakter Pemain
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS `characters`;
CREATE TABLE `characters` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `account_id` INT UNSIGNED NOT NULL,
    `name` VARCHAR(24) NOT NULL,
    `gender` TINYINT UNSIGNED NOT NULL DEFAULT 1, -- 1: Laki-laki, 2: Perempuan
    `age` TINYINT UNSIGNED NOT NULL DEFAULT 20,
    `origin` VARCHAR(32) NOT NULL DEFAULT 'Los Santos',
    `skin` INT NOT NULL DEFAULT 26,
    `pos_x` FLOAT NOT NULL DEFAULT 1481.04,
    `pos_y` FLOAT NOT NULL DEFAULT -1772.31,
    `pos_z` FLOAT NOT NULL DEFAULT 15.30,
    `pos_a` FLOAT NOT NULL DEFAULT 0.0,
    `interior` INT NOT NULL DEFAULT 0,
    `virtual_world` INT NOT NULL DEFAULT 0,
    `health` FLOAT NOT NULL DEFAULT 100.0,
    `armour` FLOAT NOT NULL DEFAULT 0.0,
    `money` INT NOT NULL DEFAULT 500,
    `bank_money` INT NOT NULL DEFAULT 2500,
    `level` INT UNSIGNED NOT NULL DEFAULT 1,
    `exp` INT UNSIGNED NOT NULL DEFAULT 0,
    `playing_hours` INT UNSIGNED NOT NULL DEFAULT 0,
    `job_id` TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `faction_id` INT UNSIGNED NOT NULL DEFAULT 0,
    `faction_rank` TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `phone_number` INT UNSIGNED NULL,
    `hunger` FLOAT NOT NULL DEFAULT 100.0,
    `thirst` FLOAT NOT NULL DEFAULT 100.0,
    `stress` FLOAT NOT NULL DEFAULT 0.0,
    `injured` TINYINT(1) NOT NULL DEFAULT 0,
    `jail_time` INT NOT NULL DEFAULT 0,
    `jail_type` TINYINT NOT NULL DEFAULT 0, -- 0: None, 1: IC Police, 2: OOC Admin
    `wanted_level` TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `license_drive` TINYINT(1) NOT NULL DEFAULT 0,
    `license_weapon` TINYINT(1) NOT NULL DEFAULT 0,
    `license_fly` TINYINT(1) NOT NULL DEFAULT 0,
    `license_boat` TINYINT(1) NOT NULL DEFAULT 0,
    `spawn_point` TINYINT NOT NULL DEFAULT 0, -- 0: Balai Kota, 1: Terakhir, 2: Rumah, 3: Faksi
    `last_played` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `idx_characters_name` (`name`),
    UNIQUE KEY `idx_characters_phone` (`phone_number`),
    KEY `idx_characters_account` (`account_id`),
    CONSTRAINT `fk_characters_account` FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- 8. Tabel Kendaraan Pribadi & Faksi
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS `vehicles`;
CREATE TABLE `vehicles` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `owner_char_id` INT UNSIGNED NOT NULL DEFAULT 0,
    `faction_id` INT UNSIGNED NOT NULL DEFAULT 0,
    `job_id` TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `model` INT NOT NULL,
    `color1` INT NOT NULL DEFAULT 1,
    `color2` INT NOT NULL DEFAULT 1,
    `paintjob` INT NOT NULL DEFAULT -1,
    `pos_x` FLOAT NOT NULL,
    `pos_y` FLOAT NOT NULL,
    `pos_z` FLOAT NOT NULL,
    `pos_a` FLOAT NOT NULL,
    `interior` INT NOT NULL DEFAULT 0,
    `virtual_world` INT NOT NULL DEFAULT 0,
    `fuel` FLOAT NOT NULL DEFAULT 100.0,
    `health` FLOAT NOT NULL DEFAULT 1000.0,
    `damage_panels` INT NOT NULL DEFAULT 0,
    `damage_doors` INT NOT NULL DEFAULT 0,
    `damage_lights` INT NOT NULL DEFAULT 0,
    `damage_tires` INT NOT NULL DEFAULT 0,
    `mileage` FLOAT NOT NULL DEFAULT 0.0,
    `locked` TINYINT(1) NOT NULL DEFAULT 1,
    `plate` VARCHAR(16) NOT NULL,
    `insurance` INT UNSIGNED NOT NULL DEFAULT 3,
    `impounded` TINYINT(1) NOT NULL DEFAULT 0,
    `mods` VARCHAR(128) NOT NULL DEFAULT '0,0,0,0,0,0,0,0,0,0,0,0,0,0',
    `rental_expire` DATETIME NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `idx_vehicles_plate` (`plate`),
    KEY `idx_vehicles_owner` (`owner_char_id`),
    KEY `idx_vehicles_faction` (`faction_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- 9. Tabel Properti Rumah (Houses)
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS `houses`;
CREATE TABLE `houses` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `owner_char_id` INT UNSIGNED NOT NULL DEFAULT 0,
    `price` INT NOT NULL DEFAULT 10000,
    `address` VARCHAR(128) NOT NULL,
    `enter_x` FLOAT NOT NULL,
    `enter_y` FLOAT NOT NULL,
    `enter_z` FLOAT NOT NULL,
    `enter_a` FLOAT NOT NULL DEFAULT 0.0,
    `exit_x` FLOAT NOT NULL,
    `exit_y` FLOAT NOT NULL,
    `exit_z` FLOAT NOT NULL,
    `exit_a` FLOAT NOT NULL DEFAULT 0.0,
    `interior` INT NOT NULL DEFAULT 0,
    `virtual_world` INT NOT NULL DEFAULT 0,
    `locked` TINYINT(1) NOT NULL DEFAULT 1,
    `level` INT UNSIGNED NOT NULL DEFAULT 1,
    `storage_money` INT NOT NULL DEFAULT 0,
    `rent_price` INT NOT NULL DEFAULT 0,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_houses_owner` (`owner_char_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- 10. Tabel Properti Bisnis (Businesses)
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS `businesses`;
CREATE TABLE `businesses` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `owner_char_id` INT UNSIGNED NOT NULL DEFAULT 0,
    `type` TINYINT UNSIGNED NOT NULL DEFAULT 1, -- 1: 24/7, 2: Ammunation, 3: Clothes, 4: Resto, 5: Gas, 6: Dealer, 7: Workshop
    `name` VARCHAR(64) NOT NULL,
    `price` INT NOT NULL DEFAULT 50000,
    `enter_x` FLOAT NOT NULL,
    `enter_y` FLOAT NOT NULL,
    `enter_z` FLOAT NOT NULL,
    `enter_a` FLOAT NOT NULL DEFAULT 0.0,
    `exit_x` FLOAT NOT NULL,
    `exit_y` FLOAT NOT NULL,
    `exit_z` FLOAT NOT NULL,
    `exit_a` FLOAT NOT NULL DEFAULT 0.0,
    `interior` INT NOT NULL DEFAULT 0,
    `virtual_world` INT NOT NULL DEFAULT 0,
    `products` INT UNSIGNED NOT NULL DEFAULT 500,
    `cash_vault` INT NOT NULL DEFAULT 0,
    `entrance_fee` INT NOT NULL DEFAULT 0,
    `locked` TINYINT(1) NOT NULL DEFAULT 0,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_businesses_owner` (`owner_char_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- 11. Tabel Garasi Properti
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS `garages`;
CREATE TABLE `garages` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `house_id` INT UNSIGNED NOT NULL,
    `enter_x` FLOAT NOT NULL,
    `enter_y` FLOAT NOT NULL,
    `enter_z` FLOAT NOT NULL,
    `enter_a` FLOAT NOT NULL DEFAULT 0.0,
    `exit_x` FLOAT NOT NULL,
    `exit_y` FLOAT NOT NULL,
    `exit_z` FLOAT NOT NULL,
    `exit_a` FLOAT NOT NULL DEFAULT 0.0,
    `interior` INT NOT NULL DEFAULT 0,
    `virtual_world` INT NOT NULL DEFAULT 0,
    `locked` TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (`id`),
    KEY `idx_garages_house` (`house_id`),
    CONSTRAINT `fk_garages_house` FOREIGN KEY (`house_id`) REFERENCES `houses` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- 12. Tabel Furniture Rumah
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS `furniture`;
CREATE TABLE `furniture` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `house_id` INT UNSIGNED NOT NULL,
    `model_id` INT NOT NULL,
    `pos_x` FLOAT NOT NULL,
    `pos_y` FLOAT NOT NULL,
    `pos_z` FLOAT NOT NULL,
    `rot_x` FLOAT NOT NULL DEFAULT 0.0,
    `rot_y` FLOAT NOT NULL DEFAULT 0.0,
    `rot_z` FLOAT NOT NULL DEFAULT 0.0,
    `material` VARCHAR(128) NULL,
    PRIMARY KEY (`id`),
    KEY `idx_furniture_house` (`house_id`),
    CONSTRAINT `fk_furniture_house` FOREIGN KEY (`house_id`) REFERENCES `houses` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- 13. Tabel Definisi Master Item
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS `items`;
CREATE TABLE `items` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(48) NOT NULL,
    `type` TINYINT UNSIGNED NOT NULL DEFAULT 1, -- 1: Food, 2: Drink, 3: Med, 4: Tool, 5: Weapon, 6: Illegal
    `weight` FLOAT NOT NULL DEFAULT 0.5,
    `max_stack` INT UNSIGNED NOT NULL DEFAULT 10,
    `usable` TINYINT(1) NOT NULL DEFAULT 1,
    `model_id` INT NOT NULL DEFAULT 1210,
    PRIMARY KEY (`id`),
    UNIQUE KEY `idx_items_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- 14. Tabel Inventaris Polimorfik (Pemain, Rumah, Bagasi Kendaraan)
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS `inventory`;
CREATE TABLE `inventory` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `owner_type` TINYINT UNSIGNED NOT NULL, -- 1: Player, 2: House, 3: Vehicle Trunk
    `owner_id` INT UNSIGNED NOT NULL,
    `item_id` INT UNSIGNED NOT NULL,
    `quantity` INT UNSIGNED NOT NULL DEFAULT 1,
    `slot` TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `metadata` JSON NULL,
    PRIMARY KEY (`id`),
    KEY `idx_inventory_owner` (`owner_type`, `owner_id`),
    CONSTRAINT `fk_inventory_item` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- 15. Tabel Item Terjatuh di Dunia Game (Dropped Items)
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS `dropped_items`;
CREATE TABLE `dropped_items` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `item_id` INT UNSIGNED NOT NULL,
    `quantity` INT UNSIGNED NOT NULL DEFAULT 1,
    `pos_x` FLOAT NOT NULL,
    `pos_y` FLOAT NOT NULL,
    `pos_z` FLOAT NOT NULL,
    `interior` INT NOT NULL DEFAULT 0,
    `virtual_world` INT NOT NULL DEFAULT 0,
    `metadata` JSON NULL,
    `dropped_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `fk_dropped_item` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- 16. Tabel Sistem Telepon (Kontak, Pesan, Panggilan, Twitter)
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS `phone_contacts`;
CREATE TABLE `phone_contacts` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `char_id` INT UNSIGNED NOT NULL,
    `contact_name` VARCHAR(48) NOT NULL,
    `phone_number` INT UNSIGNED NOT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_contacts_char` (`char_id`),
    CONSTRAINT `fk_contacts_char` FOREIGN KEY (`char_id`) REFERENCES `characters` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS `phone_messages`;
CREATE TABLE `phone_messages` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `sender_number` INT UNSIGNED NOT NULL,
    `receiver_number` INT UNSIGNED NOT NULL,
    `message` VARCHAR(255) NOT NULL,
    `sent_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_msg_sender` (`sender_number`),
    KEY `idx_msg_receiver` (`receiver_number`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS `phone_calls`;
CREATE TABLE `phone_calls` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `caller_number` INT UNSIGNED NOT NULL,
    `receiver_number` INT UNSIGNED NOT NULL,
    `duration_seconds` INT UNSIGNED NOT NULL DEFAULT 0,
    `called_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS `twitter_posts`;
CREATE TABLE `twitter_posts` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `char_id` INT UNSIGNED NOT NULL,
    `handle` VARCHAR(32) NOT NULL,
    `content` VARCHAR(240) NOT NULL,
    `posted_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_twitter_char` (`char_id`),
    CONSTRAINT `fk_twitter_char` FOREIGN KEY (`char_id`) REFERENCES `characters` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- 17. Tabel Finansial & Hukum (Transaksi Bank, Tiket Tilang, Catatan Kriminal)
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS `bank_transactions`;
CREATE TABLE `bank_transactions` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `char_id` INT UNSIGNED NOT NULL,
    `type` VARCHAR(24) NOT NULL, -- DEPOSIT, WITHDRAW, TRANSFER_IN, TRANSFER_OUT, PAYCHECK
    `amount` INT NOT NULL,
    `description` VARCHAR(128) NOT NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_bank_char` (`char_id`),
    CONSTRAINT `fk_bank_char` FOREIGN KEY (`char_id`) REFERENCES `characters` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS `tickets`;
CREATE TABLE `tickets` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `char_id` INT UNSIGNED NOT NULL,
    `officer_char_id` INT UNSIGNED NOT NULL,
    `amount` INT NOT NULL,
    `reason` VARCHAR(128) NOT NULL,
    `paid` TINYINT(1) NOT NULL DEFAULT 0,
    `issued_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_tickets_char` (`char_id`),
    CONSTRAINT `fk_tickets_char` FOREIGN KEY (`char_id`) REFERENCES `characters` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS `criminal_records`;
CREATE TABLE `criminal_records` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `char_id` INT UNSIGNED NOT NULL,
    `officer_char_id` INT UNSIGNED NOT NULL,
    `crime` VARCHAR(128) NOT NULL,
    `recorded_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_crimes_char` (`char_id`),
    CONSTRAINT `fk_crimes_char` FOREIGN KEY (`char_id`) REFERENCES `characters` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS `warrants`;
CREATE TABLE `warrants` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `char_id` INT UNSIGNED NOT NULL,
    `officer_char_id` INT UNSIGNED NOT NULL,
    `reason` VARCHAR(255) NOT NULL,
    `active` TINYINT(1) NOT NULL DEFAULT 1,
    `issued_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_warrants_char` (`char_id`),
    CONSTRAINT `fk_warrants_char` FOREIGN KEY (`char_id`) REFERENCES `characters` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- 18. Tabel Lingkungan Dunia (Doors, GPS, ATM, SPBU)
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS `doors`;
CREATE TABLE `doors` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(64) NOT NULL,
    `enter_x` FLOAT NOT NULL,
    `enter_y` FLOAT NOT NULL,
    `enter_z` FLOAT NOT NULL,
    `enter_a` FLOAT NOT NULL DEFAULT 0.0,
    `exit_x` FLOAT NOT NULL,
    `exit_y` FLOAT NOT NULL,
    `exit_z` FLOAT NOT NULL,
    `exit_a` FLOAT NOT NULL DEFAULT 0.0,
    `interior` INT NOT NULL DEFAULT 0,
    `virtual_world` INT NOT NULL DEFAULT 0,
    `locked` TINYINT(1) NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS `gps_locations`;
CREATE TABLE `gps_locations` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `category` VARCHAR(32) NOT NULL, -- UMUM, PEKERJAAN, INSTANSI, BISNIS
    `name` VARCHAR(64) NOT NULL,
    `pos_x` FLOAT NOT NULL,
    `pos_y` FLOAT NOT NULL,
    `pos_z` FLOAT NOT NULL,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS `atms`;
CREATE TABLE `atms` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `pos_x` FLOAT NOT NULL,
    `pos_y` FLOAT NOT NULL,
    `pos_z` FLOAT NOT NULL,
    `rot_z` FLOAT NOT NULL DEFAULT 0.0,
    `interior` INT NOT NULL DEFAULT 0,
    `virtual_world` INT NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS `gas_stations`;
CREATE TABLE `gas_stations` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(64) NOT NULL,
    `pos_x` FLOAT NOT NULL,
    `pos_y` FLOAT NOT NULL,
    `pos_z` FLOAT NOT NULL,
    `fuel_price` INT NOT NULL DEFAULT 10,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- 19. Tabel Administrasi, Tiket Laporan & Pencapaian
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS `reports`;
CREATE TABLE `reports` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `reporter_char_id` INT UNSIGNED NOT NULL,
    `reported_char_id` INT UNSIGNED NULL,
    `category` VARCHAR(16) NOT NULL DEFAULT 'report',
    `message` TEXT NOT NULL,
    `status` VARCHAR(16) NOT NULL DEFAULT 'open',
    `handled_by_account_id` INT UNSIGNED NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `closed_at` DATETIME NULL,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS `admin_notes`;
CREATE TABLE `admin_notes` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `target_account_id` INT UNSIGNED NOT NULL,
    `admin_account_id` INT UNSIGNED NOT NULL,
    `note` TEXT NOT NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `fk_notes_account` FOREIGN KEY (`target_account_id`) REFERENCES `accounts` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS `achievements`;
CREATE TABLE `achievements` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `char_id` INT UNSIGNED NOT NULL,
    `achievement_key` VARCHAR(48) NOT NULL,
    `unlocked_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `idx_char_achievement` (`char_id`, `achievement_key`),
    CONSTRAINT `fk_achievements_char` FOREIGN KEY (`char_id`) REFERENCES `characters` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS `name_changes`;
CREATE TABLE `name_changes` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `char_id` INT UNSIGNED NOT NULL,
    `old_name` VARCHAR(24) NOT NULL,
    `new_name` VARCHAR(24) NOT NULL,
    `admin_id` INT UNSIGNED NOT NULL,
    `changed_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_name_char` (`char_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- 20. Tabel Audit Logging Komprehensif
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS `logs`;
CREATE TABLE `logs` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `type` VARCHAR(24) NOT NULL, -- ADMIN, MONEY, CHAT, PM, KILL, TRADE, VEHICLE, PROPERTY, ANTICHEAT
    `char_id` INT UNSIGNED NULL,
    `target_id` INT UNSIGNED NULL,
    `message` TEXT NOT NULL,
    `ip` VARCHAR(45) NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_logs_type` (`type`),
    KEY `idx_logs_char` (`char_id`),
    KEY `idx_logs_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;
