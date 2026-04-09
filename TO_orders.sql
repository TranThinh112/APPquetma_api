/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

CREATE TABLE `TO_orders` (
  `maTO` varchar(50) NOT NULL,
  `danhSachGoiHang` text,
  `diaDiemGiaoHang` text,
  `trangThai` text,
  `packer` text,
  `ngayTao` text,
  `completeTime` text,
  `totalWeight` double DEFAULT '0',
  `SL` int DEFAULT '0',
  PRIMARY KEY (`maTO`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO `TO_orders` (`maTO`, `danhSachGoiHang`, `diaDiemGiaoHang`, `trangThai`, `packer`, `ngayTao`, `completeTime`, `totalWeight`, `SL`) VALUES
('TO2604070RK3I', '[]', '', 'Packing', 'a', '2026-04-07T19:50:52.786914', NULL, 0, 0);
INSERT INTO `TO_orders` (`maTO`, `danhSachGoiHang`, `diaDiemGiaoHang`, `trangThai`, `packer`, `ngayTao`, `completeTime`, `totalWeight`, `SL`) VALUES
('TO2604072IELH', '[]', NULL, 'Packing', 'Tu', '2026-04-07T20:15:29.771064', NULL, 0, 0);
INSERT INTO `TO_orders` (`maTO`, `danhSachGoiHang`, `diaDiemGiaoHang`, `trangThai`, `packer`, `ngayTao`, `completeTime`, `totalWeight`, `SL`) VALUES
('TO260407BDTPB', '[]', NULL, 'Packing', 'a', '2026-04-07T13:41:09.531822', NULL, 0, 0);
INSERT INTO `TO_orders` (`maTO`, `danhSachGoiHang`, `diaDiemGiaoHang`, `trangThai`, `packer`, `ngayTao`, `completeTime`, `totalWeight`, `SL`) VALUES
('TO260407J4LR8', '[{\"orderId\":\"SPXVN06109560083\",\"soKi\":0.98}]', 'MT', 'Packed', 'Tu', '2026-04-07T20:19:30.590607', '2026-04-07T20:23:38.007561', 0.98, 1),
('TO260407ML9TD', '[]', NULL, 'Packing', 'Tu', '2026-04-07T20:17:11.490178', NULL, 0, 0),
('TO260407XHFVE', '[]', NULL, 'Packing', 'a', '2026-04-07T13:40:17.796367', NULL, 0, 0),
('TO260407ZTUFK', '[]', '', 'Packing', 'a', '2026-04-07T20:23:48.086497', NULL, 0, 0);

