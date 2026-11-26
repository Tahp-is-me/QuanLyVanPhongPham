/*
========================================================================
 DO AN CO SO DU LIEU - QUAN LY BAN HANG VAN PHONG PHAM
 PHAN 1 - NGUYEN VAN PHAT (Stored Procedures + Transaction)
========================================================================
 YEU CAU:
   1) Phai chay QuanLiVanPhongPham.sql cua nhom truoc de tao du 6 bang.
   2) Chay TOAN BO file nay trong SSMS de tao/cap nhat 4 thu tuc.
   3) Sau do chay file 02_Phat_Demo_KiemThu.sql theo tung muc.
   4) SQL Server 2016 SP1 tro len (su dung CREATE OR ALTER).
 LUU Y: File nay CHI TAO THU TUC, khong them/sua/xoa du lieu mau.
========================================================================
*/
USE QuanLyVanPhongPham;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/* ================================================================
   1. TIM SAN PHAM THEO MA HOAC TEN
   - @TuKhoa = NULL hoac chuoi rong: xem tat ca san pham.
   - Ket hop DANH_MUC de hien thi ten danh muc.
   ================================================================ */
CREATE OR ALTER PROCEDURE dbo.usp_TimSanPham
    @TuKhoa NVARCHAR(150) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SET @TuKhoa = NULLIF(LTRIM(RTRIM(@TuKhoa)), N'');

    SELECT
        SP.MaSP,
        SP.TenSP,
        DM.TenDM,
        SP.DonViTinh,
        SP.DonGia,
        SP.SoLuongTon
    FROM dbo.SAN_PHAM AS SP
    INNER JOIN dbo.DANH_MUC AS DM ON DM.MaDM = SP.MaDM
    WHERE @TuKhoa IS NULL
       OR SP.TenSP LIKE N'%' + @TuKhoa + N'%'
       OR SP.MaSP  LIKE N'%' + @TuKhoa + N'%'
    ORDER BY SP.MaSP;
END;
GO

/* ================================================================
   2. THEM SAN PHAM MOI
   - Kiem tra tham so dau vao, ma san pham, ma danh muc.
   - Gia > 0; so luong ton >= 0 (dung voi CHECK cua CSDL).
   - INSERT la 1 cau lenh nguyen tu, khong can transaction rieng.
   ================================================================ */
CREATE OR ALTER PROCEDURE dbo.usp_ThemSanPham
    @MaSP       VARCHAR(10),
    @TenSP      NVARCHAR(150),
    @DonViTinh  NVARCHAR(30),
    @DonGia     DECIMAL(18,2),
    @SoLuongTon INT,
    @MaDM       VARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;

    IF NULLIF(LTRIM(RTRIM(@MaSP)), '') IS NULL
        THROW 50001, N'Ma san pham khong duoc de trong.', 1;
    IF NULLIF(LTRIM(RTRIM(@TenSP)), N'') IS NULL
        THROW 50002, N'Ten san pham khong duoc de trong.', 1;
    IF NULLIF(LTRIM(RTRIM(@DonViTinh)), N'') IS NULL
        THROW 50003, N'Don vi tinh khong duoc de trong.', 1;
    IF @DonGia IS NULL OR @DonGia <= 0
        THROW 50004, N'Don gia phai lon hon 0.', 1;
    IF @SoLuongTon IS NULL OR @SoLuongTon < 0
        THROW 50005, N'So luong ton phai >= 0.', 1;
    IF NULLIF(LTRIM(RTRIM(@MaDM)), '') IS NULL
        THROW 50006, N'Ma danh muc khong duoc de trong.', 1;
    IF NOT EXISTS (SELECT 1 FROM dbo.DANH_MUC WHERE MaDM = @MaDM)
        THROW 50007, N'Ma danh muc khong ton tai.', 1;
    IF EXISTS (SELECT 1 FROM dbo.SAN_PHAM WHERE MaSP = @MaSP)
        THROW 50008, N'Ma san pham da ton tai.', 1;

    -- PK/FK/CHECK van tiep tuc bao ve du lieu neu co tranh chap dong thoi.
    INSERT INTO dbo.SAN_PHAM
        (MaSP, TenSP, DonViTinh, DonGia, SoLuongTon, MaDM)
    VALUES
        (@MaSP, @TenSP, @DonViTinh, @DonGia, @SoLuongTon, @MaDM);

    SELECT MaSP, TenSP, DonViTinh, DonGia, SoLuongTon, MaDM
    FROM dbo.SAN_PHAM
    WHERE MaSP = @MaSP;
END;
GO

/* ================================================================
   3. THONG KE DOANH THU THEO NGAY
   - Su dung HOA_DON.TongTien dung theo CSDL nhom.
   - Hai tham so co the NULL de lay toan bo khoang thoi gian.
   - Bao cao theo ngay, khong gom cac ngay khong phat sinh hoa don.
   ================================================================ */
CREATE OR ALTER PROCEDURE dbo.usp_ThongKeDoanhThu
    @TuNgay  DATE = NULL,
    @DenNgay DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @TuNgay IS NOT NULL AND @DenNgay IS NOT NULL AND @TuNgay > @DenNgay
        THROW 50009, N'Tu ngay phai nho hon hoac bang den ngay.', 1;

    SELECT
        CONVERT(DATE, HD.NgayLap) AS NgayBan,
        COUNT(*) AS SoHoaDon,
        SUM(HD.TongTien) AS TongDoanhThu
    FROM dbo.HOA_DON AS HD
    WHERE (@TuNgay IS NULL OR HD.NgayLap >= @TuNgay)
      AND (@DenNgay IS NULL OR CONVERT(DATE, HD.NgayLap) <= @DenNgay)
    GROUP BY CONVERT(DATE, HD.NgayLap)
    ORDER BY NgayBan;
END;
GO

/* ================================================================
   4. BAN HANG - GIAO DICH NGUYEN TU
   Cong viec trong CUNG 1 TRANSACTION:
      (1) Kiem tra du lieu va khoa ban ghi san pham.
      (2) Tru ton kho.
      (3) Tao HOA_DON.
      (4) Tao CHI_TIET_HOA_DON.
      (5) COMMIT neu tat ca thanh cong; neu loi thi ROLLBACK.

   @MoPhongLoi = 1 chi danh cho DEMO hoc tap:
      Chu dong gay loi SAU khi da UPDATE / INSERT de kiem tra
      ROLLBACK co tra lai ton kho va xoa hoa don tam hay khong.
   Khong truyen @MoPhongLoi trong nghiep vu ban hang binh thuong.
   ================================================================ */
CREATE OR ALTER PROCEDURE dbo.usp_BanHang
    @MaHD       VARCHAR(15),
    @MaKH       VARCHAR(10),
    @MaNV       VARCHAR(10),
    @MaSP       VARCHAR(10),
    @SoLuong    INT,
    @MoPhongLoi BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NULLIF(LTRIM(RTRIM(@MaHD)), '') IS NULL
        THROW 50010, N'Ma hoa don khong duoc de trong.', 1;
    IF NULLIF(LTRIM(RTRIM(@MaKH)), '') IS NULL
        THROW 50011, N'Ma khach hang khong duoc de trong.', 1;
    IF NULLIF(LTRIM(RTRIM(@MaNV)), '') IS NULL
        THROW 50012, N'Ma nhan vien khong duoc de trong.', 1;
    IF NULLIF(LTRIM(RTRIM(@MaSP)), '') IS NULL
        THROW 50013, N'Ma san pham khong duoc de trong.', 1;
    IF @SoLuong IS NULL OR @SoLuong <= 0
        THROW 50014, N'So luong ban phai lon hon 0.', 1;

    DECLARE @DonGia DECIMAL(18,2);
    DECLARE @TongTien DECIMAL(18,2);

    BEGIN TRY
        BEGIN TRANSACTION;

        -- HOLDLOCK giu khoa den cuoi transaction de tranh trung MaHD.
        IF EXISTS (
            SELECT 1 FROM dbo.HOA_DON WITH (UPDLOCK, HOLDLOCK)
            WHERE MaHD = @MaHD
        )
            THROW 50015, N'Ma hoa don da ton tai.', 1;

        IF NOT EXISTS (SELECT 1 FROM dbo.KHACH_HANG WHERE MaKH = @MaKH)
            THROW 50016, N'Khach hang khong ton tai.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.NHAN_VIEN WHERE MaNV = @MaNV)
            THROW 50017, N'Nhan vien khong ton tai.', 1;

        -- Khoa cap nhat va giu khoa cho den COMMIT/ROLLBACK.
        SELECT @DonGia = SP.DonGia
        FROM dbo.SAN_PHAM AS SP WITH (UPDLOCK, HOLDLOCK)
        WHERE SP.MaSP = @MaSP;

        IF @DonGia IS NULL
            THROW 50018, N'San pham khong ton tai.', 1;

        -- Dieu kien trong UPDATE giup khong bao gio ban am kho.
        UPDATE dbo.SAN_PHAM
        SET SoLuongTon = SoLuongTon - @SoLuong
        WHERE MaSP = @MaSP AND SoLuongTon >= @SoLuong;

        IF @@ROWCOUNT <> 1
            THROW 50019, N'Khong du so luong ton kho de ban.', 1;

        SET @TongTien = @DonGia * CONVERT(DECIMAL(18,2), @SoLuong);

        INSERT INTO dbo.HOA_DON (MaHD, NgayLap, TongTien, MaKH, MaNV)
        VALUES (@MaHD, GETDATE(), @TongTien, @MaKH, @MaNV);

        INSERT INTO dbo.CHI_TIET_HOA_DON (MaHD, MaSP, SoLuong, DonGiaBan)
        VALUES (@MaHD, @MaSP, @SoLuong, @DonGia);

        -- Chi dung de chung minh atomicity trong demo (khong dung production).
        IF @MoPhongLoi = 1
            THROW 50020, N'Loi demo sau khi thay doi du lieu - can ROLLBACK.', 1;

        COMMIT TRANSACTION;

        -- Tra ve hoa don vua tao va ton kho con lai.
        SELECT
            HD.MaHD, HD.NgayLap, HD.MaKH, HD.MaNV,
            CT.MaSP, CT.SoLuong, CT.DonGiaBan, CT.ThanhTien,
            HD.TongTien, SP.SoLuongTon AS TonKhoConLai
        FROM dbo.HOA_DON AS HD
        JOIN dbo.CHI_TIET_HOA_DON AS CT ON CT.MaHD = HD.MaHD
        JOIN dbo.SAN_PHAM AS SP ON SP.MaSP = CT.MaSP
        WHERE HD.MaHD = @MaHD;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;

        -- Chuyen nguyen thong bao loi ve SSMS / ung dung goi thu tuc.
        THROW;
    END CATCH;
END;
GO

-- KIEM TRA: sau khi chay file, SSMS can hien thi 4 dong.
SELECT name AS TenStoredProcedure
FROM sys.procedures
WHERE name IN (
    'usp_TimSanPham', 'usp_ThemSanPham',
    'usp_ThongKeDoanhThu', 'usp_BanHang'
)
ORDER BY name;
GO
