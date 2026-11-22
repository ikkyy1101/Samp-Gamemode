-- =============================================================================
-- Seed Data Awal: Open.mp Roleplay Framework
-- Data referensi standar faksi, item, bisnis, rumah, ATM, SPBU, dan setting server
-- =============================================================================

SET FOREIGN_KEY_CHECKS = 0;

-- 1. Versi Skema
INSERT INTO `schema_version` (`version`, `notes`) VALUES
('1.0.0', 'Inisialisasi skema modular open.mp Roleplay');

-- 2. Konfigurasi Server (Key-Value)
INSERT INTO `server_settings` (`setting_key`, `setting_value`) VALUES
('server_motd', 'Selamat datang di Open.mp Roleplay Indonesia! Patuhi aturan roleplay.'),
('tax_rate_percent', '5'),
('minimum_paycheck', '150'),
('fuel_price_per_liter', '10'),
('property_tax_interval_hours', '168'), -- 7 hari
('max_inactive_property_days', '14');

-- 3. Faksi Default
INSERT INTO `factions` (`id`, `name`, `type`, `color`, `bank`, `max_members`, `spawn_x`, `spawn_y`, `spawn_z`, `spawn_angle`, `spawn_interior`, `spawn_vw`) VALUES
(1, 'San Andreas Police Department', 1, 0x0078D7AA, 500000, 50, 1553.30, -1675.60, 16.20, 90.0, 0, 0),
(2, 'San Andreas Medical Department', 2, 0xFF6347AA, 400000, 40, 1172.80, -1323.30, 14.10, 270.0, 0, 0),
(3, 'Los Santos Government', 3, 0x107C10AA, 1000000, 30, 1481.04, -1772.31, 15.30, 0.0, 0, 0),
(4, 'San Andreas Network News', 4, 0xFF8C00AA, 250000, 25, 1658.20, -1655.40, 22.50, 180.0, 0, 0),
(5, 'Grove Street Families', 5, 0x33AA33AA, 50000, 30, 2495.30, -1690.50, 13.50, 0.0, 0, 0),
(6, 'Ballas Gangsters', 5, 0x800080AA, 50000, 30, 2000.50, -1120.20, 25.50, 0.0, 0, 0);

-- 4. Pangkat Faksi (Faction Ranks)
-- SAPD (Faksi 1)
INSERT INTO `faction_ranks` (`faction_id`, `rank_level`, `name`, `salary`) VALUES
(1, 1, 'Cadet', 350),
(1, 2, 'Officer', 450),
(1, 3, 'Sergeant', 600),
(1, 4, 'Lieutenant', 750),
(1, 5, 'Captain', 950),
(1, 6, 'Chief of Police', 1200);

-- SAMD (Faksi 2)
INSERT INTO `faction_ranks` (`faction_id`, `rank_level`, `name`, `salary`) VALUES
(2, 1, 'Volunteer Trainee', 300),
(2, 2, 'Paramedic', 420),
(2, 3, 'Doctor Specialist', 580),
(2, 4, 'Surgeon Chief', 720),
(2, 5, 'Hospital Director', 1000);

-- Pemerintah (Faksi 3)
INSERT INTO `faction_ranks` (`faction_id`, `rank_level`, `name`, `salary`) VALUES
(3, 1, 'Staff Magang', 300),
(3, 2, 'Pegawai Sipil', 450),
(3, 3, 'Kepala Dinas', 700),
(3, 4, 'Wakil Walikota', 900),
(3, 5, 'Walikota (Governor)', 1500);

-- SAN News (Faksi 4)
INSERT INTO `faction_ranks` (`faction_id`, `rank_level`, `name`, `salary`) VALUES
(4, 1, 'Intern Reporter', 280),
(4, 2, 'Journalist', 400),
(4, 3, 'Senior Broadcaster', 550),
(4, 4, 'Chief Editor', 850);

-- Geng Grove (Faksi 5) & Ballas (Faksi 6)
INSERT INTO `faction_ranks` (`faction_id`, `rank_level`, `name`, `salary`) VALUES
(5, 1, 'Outsider', 0),
(5, 2, 'Homie', 0),
(5, 3, 'Original Gangster (OG)', 0),
(5, 4, 'Boss Families', 0),
(6, 1, 'Young Thug', 0),
(6, 2, 'Shooter', 0),
(6, 3, 'High Roller', 0),
(6, 4, 'Ballas Leader', 0);

-- 5. Definisi Master Item
INSERT INTO `items` (`id`, `name`, `type`, `weight`, `max_stack`, `usable`, `model_id`) VALUES
(1, 'Roti Gandum', 1, 0.2, 10, 1, 19883),
(2, 'Burger Lezat', 1, 0.3, 5, 1, 2880),
(3, 'Air Mineral 600ml', 2, 0.6, 10, 1, 2958),
(4, 'Minuman Soda Sprunk', 2, 0.4, 10, 1, 1546),
(5, 'Kotak P3K (First Aid Kit)', 3, 1.0, 3, 1, 11736),
(6, 'Perban Medis', 3, 0.2, 10, 1, 11738),
(7, 'Jerigen Bensin (5L)', 4, 4.5, 2, 1, 1650),
(8, 'Alat Pancing (Fishing Rod)', 4, 1.5, 1, 1, 18632),
(9, 'Umpan Cacing', 4, 0.1, 50, 1, 19630),
(10, 'Smartphone Canggih', 4, 0.2, 1, 1, 18867),
(11, 'Radio Portabel Walkie-Talkie', 4, 0.5, 1, 1, 19942),
(12, 'Topeng Wajah (Mask)', 4, 0.1, 1, 1, 19036),
(13, 'Sebungkus Rokok', 4, 0.1, 5, 1, 19896),
(14, 'Pemantik Api (Zippo)', 4, 0.1, 1, 1, 19897),
(15, 'GPS Navigator Mobil', 4, 0.5, 1, 1, 18875),
(16, 'Paket Ganja (Pot)', 6, 0.05, 100, 1, 1575),
(17, 'Paket Kokain (Crack)', 6, 0.05, 100, 1, 1576);

-- 6. Properti Rumah Contoh
INSERT INTO `houses` (`id`, `owner_char_id`, `price`, `address`, `enter_x`, `enter_y`, `enter_z`, `enter_a`, `exit_x`, `exit_y`, `exit_z`, `exit_a`, `interior`, `virtual_world`, `locked`, `level`, `storage_money`, `rent_price`) VALUES
(1, 0, 8500, '101 Grove Street, Ganton', 2495.30, -1690.50, 13.50, 0.0, 2496.05, -1695.17, 1014.74, 180.0, 3, 1, 1, 1, 0, 50),
(2, 0, 12000, '204 Atlantic Avenue, Idlewood', 1982.50, -1700.20, 13.40, 90.0, 2262.83, -1137.80, 1050.63, 270.0, 10, 2, 1, 1, 0, 75),
(3, 0, 15000, '305 North Hill, Jefferson', 2215.30, -1140.20, 25.80, 180.0, 2233.78, -1115.17, 1050.88, 0.0, 2, 3, 1, 1, 0, 100),
(4, 0, 35000, '501 Marina Coast, Verona Beach', 855.20, -1640.50, 13.50, 270.0, 140.28, 1366.49, 1083.86, 90.0, 5, 4, 1, 2, 0, 200),
(5, 0, 75000, '777 Richman Luxury Mansion', 322.50, -1188.20, 75.80, 0.0, 140.28, 1366.49, 1083.86, 90.0, 5, 5, 1, 3, 0, 500);

-- 7. Properti Bisnis Contoh
INSERT INTO `businesses` (`id`, `owner_char_id`, `type`, `name`, `price`, `enter_x`, `enter_y`, `enter_z`, `enter_a`, `exit_x`, `exit_y`, `exit_z`, `exit_a`, `interior`, `virtual_world`, `products`, `cash_vault`, `entrance_fee`, `locked`) VALUES
(1, 0, 1, '24/7 Supermarket Idlewood', 45000, 1929.50, -1776.20, 13.50, 90.0, -30.95, -89.61, 1003.55, 0.0, 18, 1, 1000, 0, 0, 0),
(2, 0, 2, 'Commerce Ammu-Nation & Gun Shop', 75000, 1368.40, -1279.80, 13.50, 90.0, 286.15, -40.63, 1001.51, 0.0, 1, 2, 500, 0, 0, 0),
(3, 0, 3, 'Binco Clothes Ganton', 35000, 2244.30, -1665.20, 15.40, 180.0, 207.74, -109.25, 1005.13, 0.0, 15, 3, 800, 0, 0, 0),
(4, 0, 4, 'The Well Stacked Pizza Co. Idlewood', 40000, 2105.20, -1806.40, 13.50, 0.0, 372.35, -131.65, 1001.49, 0.0, 5, 4, 600, 0, 0, 0),
(5, 0, 5, 'Gas Station & Convenience Idlewood', 60000, 1938.20, -1770.40, 13.40, 0.0, 0.0, 0.0, 0.0, 0.0, 0, 0, 5000, 0, 0, 0);

-- 8. Titik Lokasi GPS Navigator
INSERT INTO `gps_locations` (`id`, `category`, `name`, `pos_x`, `pos_y`, `pos_z`) VALUES
(1, 'INSTANSI', 'Kantor Polisi SAPD (Pershing Square)', 1553.30, -1675.60, 16.20),
(2, 'INSTANSI', 'Rumah Sakit SAMD (All Saints)', 1172.80, -1323.30, 14.10),
(3, 'INSTANSI', 'Balai Kota Los Santos (City Hall)', 1481.04, -1772.31, 15.30),
(4, 'PEKERJAAN', 'Depo Pembersih Jalan (Sweeper)', 1640.40, -1883.20, 13.15),
(5, 'PEKERJAAN', 'Terminal Bus Kota Los Santos', 1795.50, -1908.20, 13.57),
(6, 'PEKERJAAN', 'Depo Truk Kargo (Ocean Docks)', 2185.50, -2256.40, 13.54),
(7, 'UMUM', 'Bank Pusat Los Santos & ATM Utama', 1502.50, -1703.80, 14.04);

-- 9. Titik Mesin ATM
INSERT INTO `atms` (`id`, `pos_x`, `pos_y`, `pos_z`, `rot_z`, `interior`, `virtual_world`) VALUES
(1, 1502.50, -1703.80, 14.04, 0.0, 0, 0), -- Bank LS
(2, 1928.20, -1772.50, 13.50, 90.0, 0, 0), -- 24/7 Idlewood
(3, 1155.40, -1458.20, 15.80, 180.0, 0, 0), -- Commerce
(4, 2103.50, -1802.20, 13.50, 270.0, 0, 0), -- Pizza Idlewood
(5, 852.10, -1638.40, 13.50, 0.0, 0, 0); -- Marina Beach

-- 10. Titik SPBU (Gas Stations)
INSERT INTO `gas_stations` (`id`, `name`, `pos_x`, `pos_y`, `pos_z`, `fuel_price`) VALUES
(1, 'SPBU Idlewood', 1938.20, -1770.40, 13.40, 10),
(2, 'SPBU Mulholland', 1004.20, -938.50, 42.10, 12),
(3, 'SPBU Doherty / Willowfield', 2640.50, -2115.20, 13.50, 10);

SET FOREIGN_KEY_CHECKS = 1;
