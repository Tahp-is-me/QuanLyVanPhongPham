USE QuanLyVanPhongPham;
GO

SET NOCOUNT ON;
GO
-- Cau 1. Hien thi danh sach tat ca san pham.
SELECT MaSP, TenSP, DonViTinh, DonGia, SoLuongTon, MaDM
FROM SAN_PHAM
ORDER BY MaSP;
GO

-- Cau 2. Tim cac san pham co don gia tu 10.000 den 50.000 dong.
SELECT MaSP, TenSP, DonGia, SoLuongTon
FROM SAN_PHAM
WHERE DonGia BETWEEN 10000 AND 50000
ORDER BY DonGia;
GO

-- Cau 3. Tim cac san pham co so luong ton duoi 100.
SELECT MaSP, TenSP, SoLuongTon
FROM SAN_PHAM
WHERE SoLuongTon < 100
ORDER BY SoLuongTon ASC;
GO

-- Cau 4. Tim san pham theo ten (vi du: ten co chua chu 'but').
SELECT MaSP, TenSP, DonGia, SoLuongTon
FROM SAN_PHAM
WHERE TenSP LIKE N'%bút%'
ORDER BY TenSP;
GO

-- Cau 5. Tim hoa don duoc lap trong khoang tu ngay 10/11/2026 den het ngay 15/11/2026.
-- Dung dieu kien < ngay tiep theo de khong bo sot hoa don co gio trong ngay 15/11.
SELECT MaHD, NgayLap, TongTien, MaKH, MaNV
FROM HOA_DON
WHERE NgayLap >= '2026-11-10'
  AND NgayLap <  '2026-11-16'
ORDER BY NgayLap;
GO

-- II. TRUY VAN KET NOI NHIEU BANG (JOIN)
-- Cau 6. Hien thi san pham kem ten danh muc.
SELECT
    SP.MaSP,
    SP.TenSP,
    DM.TenDM,
    SP.DonViTinh,
    SP.DonGia,
    SP.SoLuongTon
FROM SAN_PHAM AS SP
INNER JOIN DANH_MUC AS DM
    ON SP.MaDM = DM.MaDM
ORDER BY DM.MaDM, SP.MaSP;
GO

-- Cau 7. Hien thi hoa don kem ten khach hang va nhan vien lap hoa don.
SELECT
    HD.MaHD,
    HD.NgayLap,
    KH.HoTen AS TenKhachHang,
    NV.HoTen AS TenNhanVien,
    HD.TongTien
FROM HOA_DON AS HD
INNER JOIN KHACH_HANG AS KH
    ON HD.MaKH = KH.MaKH
INNER JOIN NHAN_VIEN AS NV
    ON HD.MaNV = NV.MaNV
ORDER BY HD.NgayLap;
GO

-- Cau 8. Hien thi chi tiet tung hoa don: khach hang, nhan vien,
-- ten san pham, so luong, don gia ban va thanh tien.
SELECT
    HD.MaHD,
    HD.NgayLap,
    KH.HoTen AS TenKhachHang,
    NV.HoTen AS TenNhanVien,
    SP.TenSP,
    CT.SoLuong,
    CT.DonGiaBan,
    CT.ThanhTien
FROM HOA_DON AS HD
INNER JOIN KHACH_HANG AS KH
    ON HD.MaKH = KH.MaKH
INNER JOIN NHAN_VIEN AS NV
    ON HD.MaNV = NV.MaNV
INNER JOIN CHI_TIET_HOA_DON AS CT
    ON HD.MaHD = CT.MaHD
INNER JOIN SAN_PHAM AS SP
    ON CT.MaSP = SP.MaSP
ORDER BY HD.MaHD, SP.MaSP;
GO

-- Cau 9. Xem lich su mua hang cua mot khach hang cu the (vi du KH01).
SELECT
    KH.MaKH,
    KH.HoTen,
    HD.MaHD,
    HD.NgayLap,
    HD.TongTien
FROM KHACH_HANG AS KH
INNER JOIN HOA_DON AS HD
    ON KH.MaKH = HD.MaKH
WHERE KH.MaKH = 'KH01'
ORDER BY HD.NgayLap DESC;
GO

-- III. THONG KE VA TONG HOP (GROUP BY, HAVING)
-- Cau 10. Dem so luong san pham trong moi danh muc.
SELECT
    DM.MaDM,
    DM.TenDM,
    COUNT(SP.MaSP) AS SoLuongSanPham
FROM DANH_MUC AS DM
LEFT JOIN SAN_PHAM AS SP
    ON DM.MaDM = SP.MaDM
GROUP BY DM.MaDM, DM.TenDM
ORDER BY DM.MaDM;
GO

-- Cau 11. Thong ke so hoa don va tong doanh thu theo tung ngay.
SELECT
    CAST(NgayLap AS DATE) AS Ngay,
    COUNT(*) AS SoHoaDon,
    SUM(TongTien) AS TongDoanhThu
FROM HOA_DON
GROUP BY CAST(NgayLap AS DATE)
ORDER BY Ngay;
GO

-- Cau 12. Thong ke doanh thu theo thang va nam.
SELECT
    YEAR(NgayLap) AS Nam,
    MONTH(NgayLap) AS Thang,
    COUNT(*) AS SoHoaDon,
    SUM(TongTien) AS DoanhThu
FROM HOA_DON
GROUP BY YEAR(NgayLap), MONTH(NgayLap)
ORDER BY Nam, Thang;
GO

-- Cau 13. Thong ke so hoa don va doanh thu theo tung nhan vien.
SELECT
    NV.MaNV,
    NV.HoTen,
    COUNT(HD.MaHD) AS SoHoaDon,
    COALESCE(SUM(HD.TongTien), 0) AS TongDoanhThu
FROM NHAN_VIEN AS NV
LEFT JOIN HOA_DON AS HD
    ON NV.MaNV = HD.MaNV
GROUP BY NV.MaNV, NV.HoTen
ORDER BY TongDoanhThu DESC;
GO

-- Cau 14. Tim cac khach hang co tong tien mua hang tu 100.000 dong tro len.
SELECT
    KH.MaKH,
    KH.HoTen,
    COUNT(HD.MaHD) AS SoLanMua,
    SUM(HD.TongTien) AS TongTienMua
FROM KHACH_HANG AS KH
INNER JOIN HOA_DON AS HD
    ON KH.MaKH = HD.MaKH
GROUP BY KH.MaKH, KH.HoTen
HAVING SUM(HD.TongTien) >= 100000
ORDER BY TongTienMua DESC;
GO

-- Cau 15. Thong ke so luong hang da ban theo tung san pham.
SELECT
    SP.MaSP,
    SP.TenSP,
    COALESCE(SUM(CT.SoLuong), 0) AS TongSoLuongDaBan
FROM SAN_PHAM AS SP
LEFT JOIN CHI_TIET_HOA_DON AS CT
    ON SP.MaSP = CT.MaSP
GROUP BY SP.MaSP, SP.TenSP
ORDER BY TongSoLuongDaBan DESC;
GO

-- IV. SAN PHAM BAN CHAY VA CAC THONG KE BO SUNG
-- Cau 16. Top 5 san pham ban chay nhat theo so luong.
SELECT TOP 5
    SP.MaSP,
    SP.TenSP,
    SUM(CT.SoLuong) AS TongSoLuongBan
FROM SAN_PHAM AS SP
INNER JOIN CHI_TIET_HOA_DON AS CT
    ON SP.MaSP = CT.MaSP
GROUP BY SP.MaSP, SP.TenSP
ORDER BY TongSoLuongBan DESC, SP.MaSP ASC;
GO

-- Cau 17. Thong ke doanh thu mang lai boi tung san pham.
SELECT
    SP.MaSP,
    SP.TenSP,
    SUM(CT.SoLuong) AS TongSoLuongBan,
    SUM(CT.ThanhTien) AS DoanhThuSanPham
FROM SAN_PHAM AS SP
INNER JOIN CHI_TIET_HOA_DON AS CT
    ON SP.MaSP = CT.MaSP
GROUP BY SP.MaSP, SP.TenSP
ORDER BY DoanhThuSanPham DESC;
GO

-- Cau 18. Liet ke cac san pham chua phat sinh ban hang.
SELECT
    SP.MaSP,
    SP.TenSP,
    SP.SoLuongTon
FROM SAN_PHAM AS SP
LEFT JOIN CHI_TIET_HOA_DON AS CT
    ON SP.MaSP = CT.MaSP
WHERE CT.MaSP IS NULL
ORDER BY SP.MaSP;
GO

-- Cau 19. Thong ke doanh thu theo danh muc san pham.
SELECT
    DM.MaDM,
    DM.TenDM,
    COALESCE(SUM(CT.ThanhTien), 0) AS DoanhThu
FROM DANH_MUC AS DM
LEFT JOIN SAN_PHAM AS SP
    ON DM.MaDM = SP.MaDM
LEFT JOIN CHI_TIET_HOA_DON AS CT
    ON SP.MaSP = CT.MaSP
GROUP BY DM.MaDM, DM.TenDM
ORDER BY DoanhThu DESC;
GO

-- Cau 20. Thong ke tong quan: tong so khach hang, nhan vien,
-- san pham, hoa don va tong doanh thu.
SELECT
    (SELECT COUNT(*) FROM KHACH_HANG) AS TongSoKhachHang,
    (SELECT COUNT(*) FROM NHAN_VIEN) AS TongSoNhanVien,
    (SELECT COUNT(*) FROM SAN_PHAM) AS TongSoSanPham,
    (SELECT COUNT(*) FROM HOA_DON) AS TongSoHoaDon,
    (SELECT COALESCE(SUM(TongTien), 0) FROM HOA_DON) AS TongDoanhThu;
GO

-- V. DOI CHIEU TONG TIEN HOA DON VOI CHI TIET
-- Cau 21. Kiem tra tong tien luu trong HOA_DON co khop voi
-- tong thanh tien cua cac dong CHI_TIET_HOA_DON hay khong.
-- Neu truy van khong tra ve dong nao thi cac hoa don hien co deu khop.
SELECT
    HD.MaHD,
    HD.TongTien AS TongTienHoaDon,
    COALESCE(SUM(CT.ThanhTien), 0) AS TongThanhTienChiTiet,
	COUNT(CT.MaSP) AS SoDongChiTiet,
    HD.TongTien - COALESCE(SUM(CT.ThanhTien), 0) AS ChenhLech
FROM HOA_DON AS HD
LEFT JOIN CHI_TIET_HOA_DON AS CT
    ON HD.MaHD = CT.MaHD
GROUP BY HD.MaHD, HD.TongTien
HAVING HD.TongTien <> COALESCE(SUM(CT.ThanhTien), 0) OR COUNT(CT.MaSP) = 0
ORDER BY HD.MaHD;
GO