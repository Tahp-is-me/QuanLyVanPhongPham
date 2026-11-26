/*
========================================================================
 DEMO / KIEM THU PHAN NGUYEN VAN PHAT - CHAY TRONG SSMS
========================================================================
 Trinh tu:
   1. Chay script QuanLiVanPhongPham.sql cua nhom CHI MOT LAN (neu DB chua co).
   2. Chay 01_Phat_StoredProcedures.sql.
   3. Trong file nay, boi den TUNG muc demo roi bam Execute (F5).
   4. Moi test duoc tach batch bang GO, dung F5 ca file cung hop le.
 LUU Y:
   - Demo B them SP99 neu chua co; demo D tao HD901 neu chua co.
   - Demo E/F co tinh gay loi va ROLLBACK; ket qua loi la MONG DOI.
   - CHI THUC HIEN TREN DATABASE THU NGHIEM.
========================================================================
*/
USE QuanLyVanPhongPham;
GO

-- ===================================================================
-- DEMO A: TIM KIEM SAN PHAM (chup man hinh ket qua SELECT)
-- ===================================================================
PRINT N'DEMO A: Tim san pham theo tu khoa';
EXEC dbo.usp_TimSanPham @TuKhoa = N'Bút';
GO

-- ===================================================================
-- DEMO B: THEM SAN PHAM (SP99) + KIEM TRA KET QUA
-- ===================================================================
PRINT N'DEMO B: Them san pham SP99';
IF NOT EXISTS (SELECT 1 FROM dbo.SAN_PHAM WHERE MaSP = 'SP99')
BEGIN
    EXEC dbo.usp_ThemSanPham
        @MaSP       = 'SP99',
        @TenSP      = N'Bút chì demo',
        @DonViTinh  = N'Cây',
        @DonGia     = 3000,
        @SoLuongTon = 50,
        @MaDM       = 'DM01';
END
ELSE
    PRINT N'SP99 da ton tai. Bo qua INSERT de co the chay lai demo.';

SELECT MaSP, TenSP, DonGia, SoLuongTon, MaDM
FROM dbo.SAN_PHAM WHERE MaSP = 'SP99';
GO

-- ===================================================================
-- DEMO C: THONG KE DOANH THU (du lieu goc: 5 hoa don, 701000 dong)
-- Neu database da duoc thay doi thi ket qua co the khac.
-- ===================================================================
PRINT N'DEMO C: Thong ke doanh thu tu 10/11 den 15/11/2026';
EXEC dbo.usp_ThongKeDoanhThu
    @TuNgay = '2026-11-10',
    @DenNgay = '2026-11-15';
GO

-- ===================================================================
-- DEMO D: COMMIT THANH CONG - BAN 2 SP01, TAO HD901
-- Du lieu goc SP01 co SoLuongTon=200, DonGia=5000.
-- Du kien lan dau: ton kho 200 -> 198, hoa don HD901 = 10000.
-- Neu HD901 da ton tai, bo qua giao dich de khong tru kho 2 lan.
-- ===================================================================
PRINT N'DEMO D: COMMIT ban 2 san pham SP01';
SELECT MaSP, DonGia, SoLuongTon AS TonKhoTruoc
FROM dbo.SAN_PHAM WHERE MaSP = 'SP01';

IF NOT EXISTS (SELECT 1 FROM dbo.HOA_DON WHERE MaHD = 'HD901')
BEGIN
    EXEC dbo.usp_BanHang
        @MaHD = 'HD901',
        @MaKH = 'KH01',
        @MaNV = 'NV02',
        @MaSP = 'SP01',
        @SoLuong = 2;
END
ELSE
    PRINT N'HD901 da ton tai. Bo qua giao dich; chon ma HD moi de demo them.';

SELECT HD.MaHD, HD.NgayLap, HD.TongTien,
       CT.MaSP, CT.SoLuong, CT.DonGiaBan, CT.ThanhTien,
       SP.SoLuongTon AS TonKhoHienTai
FROM dbo.HOA_DON AS HD
JOIN dbo.CHI_TIET_HOA_DON AS CT ON CT.MaHD = HD.MaHD
JOIN dbo.SAN_PHAM AS SP ON SP.MaSP = CT.MaSP
WHERE HD.MaHD = 'HD901';
GO

-- ===================================================================
-- DEMO E: ROLLBACK SAU KHI UPDATE TON KHO VA INSERT HOA DON
-- @MoPhongLoi=1 de gay loi SAU khi cap nhat va them hoa don.
-- Dung ma hoa don ngau nhien cho phep chay lap lai an toan.
-- Du kien: ton kho truoc == ton kho sau; hoa don demo = 0 dong.
-- ===================================================================
PRINT N'DEMO E: ROLLBACK sau khi thay doi du lieu';
DECLARE @TonTruocE INT =
    (SELECT SoLuongTon FROM dbo.SAN_PHAM WHERE MaSP='SP01');
DECLARE @MaHDE VARCHAR(15) =
    'HDX' + LEFT(REPLACE(CONVERT(VARCHAR(36), NEWID()), '-', ''), 12);

BEGIN TRY
    EXEC dbo.usp_BanHang
        @MaHD = @MaHDE,
        @MaKH = 'KH01',
        @MaNV = 'NV02',
        @MaSP = 'SP01',
        @SoLuong = 1,
        @MoPhongLoi = 1;
END TRY
BEGIN CATCH
    PRINT N'Loi co chu dich: ' + ERROR_MESSAGE();
END CATCH;

SELECT @MaHDE AS MaHoaDonDemo,
       @TonTruocE AS TonKhoTruoc,
       (SELECT SoLuongTon FROM dbo.SAN_PHAM WHERE MaSP='SP01') AS TonKhoSau,
       (SELECT COUNT(*) FROM dbo.HOA_DON WHERE MaHD=@MaHDE) AS SoHoaDonConLai,
       (SELECT COUNT(*) FROM dbo.CHI_TIET_HOA_DON WHERE MaHD=@MaHDE) AS SoChiTietConLai;
GO

-- ===================================================================
-- DEMO F: ROLLBACK DO KHONG DU HANG (khong tao hoa don)
-- ===================================================================
PRINT N'DEMO F: ROLLBACK do khong du hang';
DECLARE @TonTruocF INT =
    (SELECT SoLuongTon FROM dbo.SAN_PHAM WHERE MaSP='SP01');
DECLARE @MaHDF VARCHAR(15) =
    'HDY' + LEFT(REPLACE(CONVERT(VARCHAR(36), NEWID()), '-', ''), 12);

BEGIN TRY
    EXEC dbo.usp_BanHang
        @MaHD = @MaHDF,
        @MaKH = 'KH01',
        @MaNV = 'NV02',
        @MaSP = 'SP01',
        @SoLuong = 999999;
END TRY
BEGIN CATCH
    PRINT N'Loi co chu dich: ' + ERROR_MESSAGE();
END CATCH;

SELECT @TonTruocF AS TonKhoTruoc,
       (SELECT SoLuongTon FROM dbo.SAN_PHAM WHERE MaSP='SP01') AS TonKhoSau,
       (SELECT COUNT(*) FROM dbo.HOA_DON WHERE MaHD=@MaHDF) AS SoHoaDonConLai;
GO

-- ===================================================================
-- DEMO G: TU CHOI MA HOA DON TRUNG (HD001 co san trong file nhom)
-- ===================================================================
PRINT N'DEMO G: Khong cho tao hoa don trung ma';
DECLARE @TonTruocG INT =
    (SELECT SoLuongTon FROM dbo.SAN_PHAM WHERE MaSP='SP01');
BEGIN TRY
    EXEC dbo.usp_BanHang
        @MaHD='HD001', @MaKH='KH01', @MaNV='NV02',
        @MaSP='SP01', @SoLuong=1;
END TRY
BEGIN CATCH
    PRINT N'Loi co chu dich: ' + ERROR_MESSAGE();
END CATCH;
SELECT @TonTruocG AS TonKhoTruoc,
       (SELECT SoLuongTon FROM dbo.SAN_PHAM WHERE MaSP='SP01') AS TonKhoSau,
       (SELECT COUNT(*) FROM dbo.HOA_DON WHERE MaHD='HD001') AS SoHD001HienCo;
GO

-- ===================================================================
-- KIEM TRA TINH NHAT QUAN CUA CAC HOA DON: TONG = TONG CHI TIET
-- ===================================================================
PRINT N'KIEM TRA: TongTien hoa don va tong ThanhTien chi tiet';
SELECT HD.MaHD,
       HD.TongTien,
       SUM(CT.ThanhTien) AS TongChiTiet,
       CASE WHEN HD.TongTien = SUM(CT.ThanhTien)
            THEN N'Khop' ELSE N'Khong khop' END AS KetQua
FROM dbo.HOA_DON AS HD
INNER JOIN dbo.CHI_TIET_HOA_DON AS CT ON CT.MaHD=HD.MaHD
GROUP BY HD.MaHD, HD.TongTien
ORDER BY HD.MaHD;
GO
