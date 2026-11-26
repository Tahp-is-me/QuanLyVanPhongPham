CREATE DATABASE QuanLyVanPhongPham;
GO

USE QuanLyVanPhongPham;
GO

CREATE TABLE DANH_MUC (
    MaDM VARCHAR(10) PRIMARY KEY,
    TenDM NVARCHAR(100) NOT NULL,
    MoTa NVARCHAR(255) NULL
);
GO


CREATE TABLE SAN_PHAM (
    MaSP VARCHAR(10) PRIMARY KEY,
    TenSP NVARCHAR(150) NOT NULL,
    DonViTinh NVARCHAR(30) NOT NULL,
    DonGia DECIMAL(18, 2) NOT NULL CHECK (DonGia > 0),
    SoLuongTon INT NOT NULL DEFAULT 0 CHECK (SoLuongTon >= 0),
    MaDM VARCHAR(10) NOT NULL,
    CONSTRAINT FK_SANPHAM_DANHMUC FOREIGN KEY (MaDM) REFERENCES DANH_MUC(MaDM)
);
GO

CREATE TABLE KHACH_HANG (
    MaKH VARCHAR(10) PRIMARY KEY,
    HoTen NVARCHAR(100) NOT NULL,
    SoDienThoai VARCHAR(15) NULL,
    DiaChi NVARCHAR(255) NULL,
    Email VARCHAR(100) NULL
);
GO


CREATE TABLE NHAN_VIEN (
    MaNV VARCHAR(10) PRIMARY KEY,
    HoTen NVARCHAR(100) NOT NULL,
    ChucVu NVARCHAR(50) NOT NULL,
    SoDienThoai VARCHAR(15) NULL,
    NgayVaoLam DATE NOT NULL DEFAULT GETDATE()
);
GO


CREATE TABLE HOA_DON (
    MaHD VARCHAR(15) PRIMARY KEY,
    NgayLap DATETIME NOT NULL DEFAULT GETDATE(),
    TongTien DECIMAL(18, 2) NOT NULL DEFAULT 0 CHECK (TongTien >= 0),
    MaKH VARCHAR(10) NOT NULL,
    MaNV VARCHAR(10) NOT NULL,
    CONSTRAINT FK_HOADON_KHACHHANG FOREIGN KEY (MaKH) REFERENCES KHACH_HANG(MaKH),
    CONSTRAINT FK_HOADON_NHANVIEN FOREIGN KEY (MaNV) REFERENCES NHAN_VIEN(MaNV)
);
GO


CREATE TABLE CHI_TIET_HOA_DON (
    MaHD VARCHAR(15) NOT NULL,
    MaSP VARCHAR(10) NOT NULL,
    SoLuong INT NOT NULL CHECK (SoLuong > 0),
    DonGiaBan DECIMAL(18, 2) NOT NULL CHECK (DonGiaBan > 0), 
    ThanhTien AS (SoLuong * DonGiaBan) PERSISTED, 
    
    
    CONSTRAINT PK_CHITIETHOADON PRIMARY KEY (MaHD, MaSP),
    CONSTRAINT FK_CTHD_HOADON FOREIGN KEY (MaHD) REFERENCES HOA_DON(MaHD) ON DELETE CASCADE,
    CONSTRAINT FK_CTHD_SANPHAM FOREIGN KEY (MaSP) REFERENCES SAN_PHAM(MaSP)
);
GO



INSERT INTO DANH_MUC (MaDM, TenDM, MoTa) VALUES
('DM01', N'Bút viết các loại', N'Bút bi, bút chì, bút dạ quang, bút lông bảng'),
('DM02', N'Vở & Sổ tay', N'Vở kẻ ngang, vở ô ly, sổ lò xo, sổ da'),
('DM03', N'Giấy in & Photo', N'Giấy A4, A3, giấy bìa màu, giấy note'),
('DM04', N'Dụng cụ văn phòng', N'Kẹp bướm, bấm kim, kim bấm, kéo, băng keo'),
('DM05', N'File hồ sơ', N'Bìa còng, bìa lá, bìa trình ký, túi đựng hồ sơ');
GO


INSERT INTO SAN_PHAM (MaSP, TenSP, DonViTinh, DonGia, SoLuongTon, MaDM) VALUES
('SP01', N'Bút bi Thiên Long TL-027 xanh', N'Cây', 5000, 200, 'DM01'),
('SP02', N'Vở kẻ ngang Campus 200 trang', N'Quyển', 18000, 120, 'DM02'),
('SP03', N'Giấy in Double A A4 70gsm', N'Ram', 75000, 50, 'DM03'),
('SP04', N'Bấm kim số 10 Plus', N'Cái', 25000, 40, 'DM04'),
('SP05', N'Bìa lá A4 Thiên Long (xấp 10 cái)', N'Xấp', 15000, 80, 'DM05');
GO


INSERT INTO KHACH_HANG (MaKH, HoTen, SoDienThoai, DiaChi, Email) VALUES
('KH01', N'Nguyễn Minh Tuấn', '0901234567', N'123 Lê Lợi, Q.1, TP.HCM', 'tuan.nm@gmail.com'),
('KH02', N'Trần Thị Thu Hà', '0912345678', N'45 Nguyễn Huệ, Q.1, TP.HCM', 'thuha.tran@gmail.com'),
('KH03', N'Lê Hoàng Nam', '0987654321', N'78 Cách Mạng Tháng 8, Q.3, TP.HCM', 'nam.le@gmail.com'),
('KH04', N'Phạm Ngọc Lan', '0933445566', N'210 Võ Văn Tần, Q.3, TP.HCM', 'lan.pham@gmail.com'),
('KH05', N'Khách vãng lai', NULL, NULL, NULL);
GO


INSERT INTO NHAN_VIEN (MaNV, HoTen, ChucVu, SoDienThoai, NgayVaoLam) VALUES
('NV01', N'Đỗ Thanh Phong', N'Quản lý cửa hàng', '0909111222', '2024-01-15'),
('NV02', N'Vũ Thị Mai Anh', N'Thu ngân', '0909333444', '2024-06-01'),
('NV03', N'Hoàng Gia Bảo', N'Thu ngân', '0909555666', '2025-02-10'),
('NV04', N'Bùi Khánh Linh', N'Nhân viên kho', '0909777888', '2025-05-20'),
('NV05', N'Ngô Quốc Đạt', N'Thu ngân', '0909999000', '2026-01-05');
GO


INSERT INTO HOA_DON (MaHD, NgayLap, TongTien, MaKH, MaNV) VALUES
('HD001', '2026-11-10 08:30:00', 100000, 'KH01', 'NV02'),
('HD002', '2026-11-11 10:15:00', 186000, 'KH02', 'NV02'),
('HD003', '2026-11-12 14:20:00', 225000, 'KH03', 'NV03'),
('HD004', '2026-11-14 16:45:00', 80000, 'KH04', 'NV05'),
('HD005', '2026-11-15 09:10:00', 110000, 'KH05', 'NV03');
GO


INSERT INTO CHI_TIET_HOA_DON (MaHD, MaSP, SoLuong, DonGiaBan) VALUES
('HD001', 'SP01', 10, 5000),
('HD001', 'SP04', 2, 25000),
('HD002', 'SP02', 2, 18000),
('HD002', 'SP03', 2, 75000),
('HD003', 'SP03', 3, 75000),
('HD004', 'SP01', 4, 5000),
('HD004', 'SP05', 4, 15000),
('HD005', 'SP02', 5, 18000),
('HD005', 'SP01', 4, 5000);
GO