// ============================================================
//  MSSQL TABLO OLUŞTURMA SCRIPTLERI
//  Aşağıdaki SQL'i MSSQL'de bir kere çalıştır, tablolar hazır olur.
// ============================================================
/*

CREATE TABLE Players (
    PlayerID     UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    DeviceID     NVARCHAR(255)    NOT NULL,
    Username     NVARCHAR(50)     NOT NULL,
    CountryCode  CHAR(2)          NOT NULL DEFAULT 'XX',
    AvatarSlot   TINYINT          NOT NULL DEFAULT 0,
    CreatedAt    DATETIME2        NOT NULL DEFAULT GETUTCDATE(),
    LastSeenAt   DATETIME2        NOT NULL DEFAULT GETUTCDATE(),
    IsBanned     BIT              NOT NULL DEFAULT 0,
    CONSTRAINT PK_Players PRIMARY KEY (PlayerID)
);
CREATE UNIQUE INDEX UX_Players_DeviceID ON Players(DeviceID);
CREATE UNIQUE INDEX UX_Players_Username ON Players(Username);

CREATE TABLE Registrations (
    RegID        BIGINT           NOT NULL IDENTITY(1,1),
    PlayerID     UNIQUEIDENTIFIER NOT NULL,
    FullName     NVARCHAR(100)    NOT NULL,
    Email        NVARCHAR(200)    NOT NULL,
    Phone        NVARCHAR(20)         NULL,
    PasswordHash NVARCHAR(64)         NULL,  -- SHA256 hash
    RegisteredAt DATETIME2        NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT PK_Registrations PRIMARY KEY (RegID),
    CONSTRAINT FK_Reg_Player FOREIGN KEY (PlayerID)
        REFERENCES Players(PlayerID) ON DELETE CASCADE
);
CREATE UNIQUE INDEX UX_Reg_Email    ON Registrations(Email);
CREATE UNIQUE INDEX UX_Reg_PlayerID ON Registrations(PlayerID);

CREATE TABLE Scores (
    ScoreID         BIGINT           NOT NULL IDENTITY(1,1),
    PlayerID        UNIQUEIDENTIFIER NOT NULL,
    Score           INT              NOT NULL DEFAULT 0,
    ChapterReached  TINYINT          NOT NULL DEFAULT 1,
    RoundReached    TINYINT          NOT NULL DEFAULT 1,
    CharacterID     TINYINT          NOT NULL DEFAULT 0,
    DurationSeconds SMALLINT         NOT NULL DEFAULT 0,
    CountryCode     CHAR(2)          NOT NULL DEFAULT 'XX',
    PlayedAt        DATETIME2        NOT NULL DEFAULT GETUTCDATE(),
    IsPersonalBest  BIT              NOT NULL DEFAULT 0,
    IsSuspicious    BIT              NOT NULL DEFAULT 0,
    CONSTRAINT PK_Scores        PRIMARY KEY (ScoreID),
    CONSTRAINT FK_Scores_Player FOREIGN KEY (PlayerID)
        REFERENCES Players(PlayerID) ON DELETE CASCADE
);
CREATE INDEX IX_Scores_Global  ON Scores(Score DESC)              WHERE IsPersonalBest = 1 AND IsSuspicious = 0;
CREATE INDEX IX_Scores_Country ON Scores(CountryCode, Score DESC) WHERE IsPersonalBest = 1 AND IsSuspicious = 0;

*/

// ============================================================
//  NuGet Paketleri:
//    - Newtonsoft.Json  (zaten projende var)
//    - System.Data.SqlClient
// ============================================================

using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Net;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;
using System.Web.Http;

namespace BlockJackAPI.Controllers
{
    // ============================================================
    //  MODEL SINIFLAR
    // ============================================================

    public class ScoreSubmitRequest
    {
        public string DeviceID        { get; set; }
        public string Username        { get; set; }
        public string CountryCode     { get; set; } = "XX";
        public int    Score           { get; set; }
        public byte   ChapterReached  { get; set; }
        public byte   RoundReached    { get; set; }
        public byte   CharacterID     { get; set; }
        public short  DurationSeconds { get; set; }
    }

    public class RegisterRequest
    {
        public string DeviceID { get; set; }
        public string FullName { get; set; }
        public string Email    { get; set; }
        public string Phone    { get; set; }
        public string Password { get; set; }  // Plain text, will be hashed
    }

    public class LoginRequest
    {
        public string Email    { get; set; }
        public string Password { get; set; }
    }

    public class UpdatePlayerRequest
    {
        public string DeviceID     { get; set; }
        public string Username     { get; set; }
        public string CountryCode  { get; set; }
        public byte?  AvatarSlot   { get; set; }
    }

    public class UpdateRegistrationRequest
    {
        public string DeviceID  { get; set; }
        public string FullName  { get; set; }
        public string Email     { get; set; }
        public string Phone     { get; set; }
    }

    public class UpdateStatusRequest
    {
        public string DeviceID  { get; set; }
        public bool   IsBanned  { get; set; }
    }

    // ============================================================
    //  CONTROLLER
    // ============================================================

    [RoutePrefix("api/leaderboard")]
    public class LeaderboardController : ApiController
    {
        private readonly string _conn  = "Server=SUNUCU_ADI;Database=BlockJackDB;User Id=KULLANICI;Password=SIFRE;TrustServerCertificate=True;";
        private readonly string _token = "Frm123456!";

        // ── Token doğrulama ──────────────────────────────────────
        private bool IsAuthorized()
        {
            var auth = Request.Headers.Authorization;
            return auth != null
                && auth.Scheme.ToLower() == "token"
                && auth.Parameter == _token;
        }

        // ── Badge hesaplama ──────────────────────────────────────
        private static string GetBadge(int rank) =>
            rank <= 3 ? "RARE" : rank <= 50 ? "EXPERT" : "BETA";

        // ── Password hashing ──────────────────────────────────────
        private static string HashPassword(string password)
        {
            using (var sha256 = SHA256.Create())
            {
                var bytes = Encoding.UTF8.GetBytes(password);
                var hash = sha256.ComputeHash(bytes);
                return BitConverter.ToString(hash).Replace("-", "").ToLower();
            }
        }

        // ── DeviceID → PlayerID çözümleyici ─────────────────────
        private async Task<Guid?> GetPlayerIdAsync(SqlConnection conn, string deviceId)
        {
            using (var cmd = new SqlCommand(
                "SELECT PlayerID FROM Players WHERE DeviceID = @DeviceID", conn))
            {
                cmd.Parameters.AddWithValue("@DeviceID", deviceId);
                var result = await cmd.ExecuteScalarAsync();
                return result != null ? (Guid?)((Guid)result) : null;
            }
        }


        // ============================================================
        //  1. POST /api/leaderboard/submit
        //     Skor gönder — rekor kırıldıysa liste otomatik güncellenir
        // ============================================================
        [HttpPost, Route("submit")]
        public async Task<IHttpActionResult> Submit([FromBody] ScoreSubmitRequest req)
        {
            if (!IsAuthorized())
                return Content(HttpStatusCode.Unauthorized, "Yetkisiz istek");

            if (req == null)                          return BadRequest("Veri bulunamadı.");
            if (string.IsNullOrEmpty(req.DeviceID))   return BadRequest("DeviceID zorunlu");
            if (string.IsNullOrEmpty(req.Username))   return BadRequest("Username zorunlu");
            if (req.Score < 0)                        return BadRequest("Score negatif olamaz");

            bool isSuspicious  = req.DurationSeconds < 30 && req.Score > 50000;
            bool isPersonalBest = false;
            int  globalRank = 1, localRank = 1;
            string country = (req.CountryCode ?? "XX").ToUpper();

            using (var conn = new SqlConnection(_conn))
            {
                await conn.OpenAsync();

                // ── 1. Oyuncuyu bul veya oluştur (upsert) ───────
                Guid? existingId = await GetPlayerIdAsync(conn, req.DeviceID);
                Guid  playerId;

                if (existingId == null)
                {
                    playerId = Guid.NewGuid();
                    using (var cmd = new SqlCommand(@"
                        INSERT INTO Players (PlayerID, DeviceID, Username, CountryCode)
                        VALUES (@PID, @DeviceID, @Username, @CC)", conn))
                    {
                        cmd.Parameters.AddWithValue("@PID",      playerId);
                        cmd.Parameters.AddWithValue("@DeviceID", req.DeviceID);
                        cmd.Parameters.AddWithValue("@Username", req.Username);
                        cmd.Parameters.AddWithValue("@CC",       country);
                        await cmd.ExecuteNonQueryAsync();
                    }
                }
                else
                {
                    playerId = existingId.Value;
                    using (var cmd = new SqlCommand(@"
                        UPDATE Players
                        SET LastSeenAt = GETUTCDATE(), CountryCode = @CC
                        WHERE PlayerID = @PID", conn))
                    {
                        cmd.Parameters.AddWithValue("@CC",  country);
                        cmd.Parameters.AddWithValue("@PID", playerId);
                        await cmd.ExecuteNonQueryAsync();
                    }
                }

                // ── 2. Mevcut personal best'i kontrol et ────────
                long oldScoreId    = 0;
                int  oldScoreValue = -1;

                using (var cmd = new SqlCommand(@"
                    SELECT ScoreID, Score FROM Scores
                    WHERE PlayerID = @PID AND IsPersonalBest = 1", conn))
                {
                    cmd.Parameters.AddWithValue("@PID", playerId);
                    using (var r = await cmd.ExecuteReaderAsync())
                    {
                        if (r.Read())
                        {
                            oldScoreId    = r.GetInt64(0);
                            oldScoreValue = r.GetInt32(1);
                        }
                    }
                }

                isPersonalBest = (oldScoreId == 0 || req.Score > oldScoreValue);

                // ── 3. Eski best'i sıfırla (rekor kırıldıysa) ───
                // KRİTİK: Bu adım olmazsa listede oyuncu çift görünür
                if (isPersonalBest && oldScoreId > 0)
                {
                    using (var cmd = new SqlCommand(
                        "UPDATE Scores SET IsPersonalBest = 0 WHERE ScoreID = @SID", conn))
                    {
                        cmd.Parameters.AddWithValue("@SID", oldScoreId);
                        await cmd.ExecuteNonQueryAsync();
                    }
                }

                // ── 4. Yeni skoru kaydet ─────────────────────────
                using (var cmd = new SqlCommand(@"
                    INSERT INTO Scores
                        (PlayerID, Score, ChapterReached, RoundReached, CharacterID,
                         DurationSeconds, CountryCode, IsPersonalBest, IsSuspicious)
                    VALUES
                        (@PID, @Score, @Chapter, @Round, @CharID,
                         @Duration, @Country, @IsBest, @IsSusp)", conn))
                {
                    cmd.Parameters.AddWithValue("@PID",      playerId);
                    cmd.Parameters.AddWithValue("@Score",    req.Score);
                    cmd.Parameters.AddWithValue("@Chapter",  req.ChapterReached);
                    cmd.Parameters.AddWithValue("@Round",    req.RoundReached);
                    cmd.Parameters.AddWithValue("@CharID",   req.CharacterID);
                    cmd.Parameters.AddWithValue("@Duration", req.DurationSeconds);
                    cmd.Parameters.AddWithValue("@Country",  country);
                    cmd.Parameters.AddWithValue("@IsBest",   isPersonalBest ? 1 : 0);
                    cmd.Parameters.AddWithValue("@IsSusp",   isSuspicious   ? 1 : 0);
                    await cmd.ExecuteNonQueryAsync();
                }

                // ── 5. Güncel sıraları hesapla ───────────────────
                const string rankBase = @"
                    SELECT COUNT(*) FROM Scores s
                    INNER JOIN Players p ON s.PlayerID = p.PlayerID
                    WHERE s.IsPersonalBest = 1
                      AND s.IsSuspicious   = 0
                      AND p.IsBanned       = 0
                      AND s.Score > @Score";

                using (var cmd = new SqlCommand(rankBase, conn))
                {
                    cmd.Parameters.AddWithValue("@Score", req.Score);
                    globalRank = (int)await cmd.ExecuteScalarAsync() + 1;
                }

                using (var cmd = new SqlCommand(rankBase + " AND s.CountryCode = @CC", conn))
                {
                    cmd.Parameters.AddWithValue("@Score", req.Score);
                    cmd.Parameters.AddWithValue("@CC",    country);
                    localRank = (int)await cmd.ExecuteScalarAsync() + 1;
                }
            }

            return Ok(new {
                IsPersonalBest = isPersonalBest,
                GlobalRank     = globalRank,
                LocalRank      = localRank
            });
        }


        // ============================================================
        //  2. GET /api/leaderboard/global?limit=10
        //     Global Top N listesi
        // ============================================================
        [HttpGet, Route("global")]
        public async Task<IHttpActionResult> GetGlobal(int limit = 10)
        {
            if (!IsAuthorized()) return Content(HttpStatusCode.Unauthorized, "Yetkisiz istek");
            if (limit < 1 || limit > 100) return BadRequest("limit 1-100 arası olmalı");

            var list = new List<object>();

            using (var conn = new SqlConnection(_conn))
            {
                await conn.OpenAsync();
                using (var cmd = new SqlCommand(@"
                    SELECT TOP (@Limit)
                        p.Username, p.CountryCode,
                        s.Score, s.ChapterReached, s.CharacterID
                    FROM Scores s
                    INNER JOIN Players p ON s.PlayerID = p.PlayerID
                    WHERE s.IsPersonalBest = 1
                      AND s.IsSuspicious   = 0
                      AND p.IsBanned       = 0
                    ORDER BY s.Score DESC", conn))
                {
                    cmd.Parameters.AddWithValue("@Limit", limit);
                    using (var r = await cmd.ExecuteReaderAsync())
                    {
                        int rank = 1;
                        while (r.Read())
                        {
                            int curRank = rank++;
                            list.Add(new {
                                Rank        = curRank,
                                Username    = r["Username"].ToString(),
                                CountryCode = r["CountryCode"].ToString(),
                                Score       = (int)r["Score"],
                                Chapter     = (byte)r["ChapterReached"],
                                CharacterID = (byte)r["CharacterID"],
                                Badge       = GetBadge(curRank)
                            });
                        }
                    }
                }
            }

            return Ok(list);
        }


        // ============================================================
        //  3. GET /api/leaderboard/local?country=TR&limit=10
        //     Ülke bazlı Top N listesi
        // ============================================================
        [HttpGet, Route("local")]
        public async Task<IHttpActionResult> GetLocal(string country, int limit = 10)
        {
            if (!IsAuthorized()) return Content(HttpStatusCode.Unauthorized, "Yetkisiz istek");
            if (string.IsNullOrWhiteSpace(country)) return BadRequest("country zorunlu");
            if (limit < 1 || limit > 100) return BadRequest("limit 1-100 arası olmalı");

            var list = new List<object>();

            using (var conn = new SqlConnection(_conn))
            {
                await conn.OpenAsync();
                using (var cmd = new SqlCommand(@"
                    SELECT TOP (@Limit)
                        p.Username, p.CountryCode,
                        s.Score, s.ChapterReached, s.CharacterID
                    FROM Scores s
                    INNER JOIN Players p ON s.PlayerID = p.PlayerID
                    WHERE s.IsPersonalBest = 1
                      AND s.IsSuspicious   = 0
                      AND p.IsBanned       = 0
                      AND s.CountryCode    = @Country
                    ORDER BY s.Score DESC", conn))
                {
                    cmd.Parameters.AddWithValue("@Limit",   limit);
                    cmd.Parameters.AddWithValue("@Country", country.ToUpper());
                    using (var r = await cmd.ExecuteReaderAsync())
                    {
                        int rank = 1;
                        while (r.Read())
                        {
                            int curRank = rank++;
                            list.Add(new {
                                Rank        = curRank,
                                Username    = r["Username"].ToString(),
                                CountryCode = r["CountryCode"].ToString(),
                                Score       = (int)r["Score"],
                                Chapter     = (byte)r["ChapterReached"],
                                CharacterID = (byte)r["CharacterID"],
                                Badge       = GetBadge(curRank)
                            });
                        }
                    }
                }
            }

            return Ok(list);
        }


        // ============================================================
        //  4. GET /api/leaderboard/me
        //     Header: X-Device-ID: <uuid>
        //     Oyuncunun kendi sırası
        // ============================================================
        [HttpGet, Route("me")]
        public async Task<IHttpActionResult> GetMyRank()
        {
            if (!IsAuthorized()) return Content(HttpStatusCode.Unauthorized, "Yetkisiz istek");

            string deviceId = Request.Headers.TryGetValues("X-Device-ID", out var vals)
                ? vals.FirstOrDefault() : null;

            if (string.IsNullOrWhiteSpace(deviceId))
                return BadRequest("X-Device-ID header zorunlu");

            using (var conn = new SqlConnection(_conn))
            {
                await conn.OpenAsync();

                string username = null, cc = null;
                int myScore = 0; byte chapter = 0;

                using (var cmd = new SqlCommand(@"
                    SELECT p.Username, p.CountryCode, s.Score, s.ChapterReached
                    FROM Players p
                    INNER JOIN Scores s ON s.PlayerID = p.PlayerID
                    WHERE p.DeviceID = @DeviceID
                      AND s.IsPersonalBest = 1", conn))
                {
                    cmd.Parameters.AddWithValue("@DeviceID", deviceId);
                    using (var r = await cmd.ExecuteReaderAsync())
                    {
                        if (!r.Read())
                            return Content(HttpStatusCode.NotFound, "Bu cihaza ait skor bulunamadı");

                        username = r["Username"].ToString();
                        cc       = r["CountryCode"].ToString();
                        myScore  = (int)r["Score"];
                        chapter  = (byte)r["ChapterReached"];
                    }
                }

                const string rankBase = @"
                    SELECT COUNT(*) FROM Scores s
                    INNER JOIN Players p ON s.PlayerID = p.PlayerID
                    WHERE s.IsPersonalBest = 1
                      AND s.IsSuspicious   = 0
                      AND p.IsBanned       = 0
                      AND s.Score > @Score";

                int globalRank, localRank;

                using (var cmd = new SqlCommand(rankBase, conn))
                {
                    cmd.Parameters.AddWithValue("@Score", myScore);
                    globalRank = (int)await cmd.ExecuteScalarAsync() + 1;
                }

                using (var cmd = new SqlCommand(rankBase + " AND s.CountryCode = @CC", conn))
                {
                    cmd.Parameters.AddWithValue("@Score", myScore);
                    cmd.Parameters.AddWithValue("@CC",    cc);
                    localRank = (int)await cmd.ExecuteScalarAsync() + 1;
                }

                return Ok(new {
                    Username    = username,
                    CountryCode = cc,
                    Score       = myScore,
                    Chapter     = chapter,
                    GlobalRank  = globalRank,
                    LocalRank   = localRank,
                    Badge       = GetBadge(globalRank)
                });
            }
        }


        // ============================================================
        //  5. POST /api/leaderboard/register
        //     Kayıt formu — isteğe bağlı, oyuncu doldurmak isterse
        // ============================================================
        [HttpPost, Route("register")]
        public async Task<IHttpActionResult> Register([FromBody] RegisterRequest req)
        {
            if (!IsAuthorized()) return Content(HttpStatusCode.Unauthorized, "Yetkisiz istek");
            if (req == null)                        return BadRequest("Veri bulunamadı.");
            if (string.IsNullOrEmpty(req.DeviceID)) return BadRequest("DeviceID zorunlu");
            if (string.IsNullOrEmpty(req.FullName)) return BadRequest("FullName zorunlu");
            if (string.IsNullOrEmpty(req.Email))    return BadRequest("Email zorunlu");
            if (string.IsNullOrEmpty(req.Password)) return BadRequest("Password zorunlu");

            string passwordHash = HashPassword(req.Password);

            using (var conn = new SqlConnection(_conn))
            {
                await conn.OpenAsync();

                Guid? playerId = await GetPlayerIdAsync(conn, req.DeviceID);
                if (playerId == null)
                    return Content(HttpStatusCode.NotFound, "Oyuncu bulunamadı. Önce skor gönderin.");

                // Daha önce kayıt var mı?
                using (var cmd = new SqlCommand(
                    "SELECT COUNT(*) FROM Registrations WHERE PlayerID = @PID", conn))
                {
                    cmd.Parameters.AddWithValue("@PID", playerId.Value);
                    if ((int)await cmd.ExecuteScalarAsync() > 0)
                        return Content(HttpStatusCode.Conflict,
                            "Bu oyuncu zaten kayıtlı. Güncellemek için /update-registration kullanın.");
                }

                // Email unique kontrolü
                using (var cmd = new SqlCommand(
                    "SELECT COUNT(*) FROM Registrations WHERE Email = @Email", conn))
                {
                    cmd.Parameters.AddWithValue("@Email", req.Email);
                    if ((int)await cmd.ExecuteScalarAsync() > 0)
                        return Content(HttpStatusCode.Conflict, "Bu email zaten kayıtlı.");
                }

                using (var cmd = new SqlCommand(@"
                    INSERT INTO Registrations (PlayerID, FullName, Email, Phone, PasswordHash)
                    VALUES (@PID, @FullName, @Email, @Phone, @PasswordHash)", conn))
                {
                    cmd.Parameters.AddWithValue("@PID",          playerId.Value);
                    cmd.Parameters.AddWithValue("@FullName",     req.FullName);
                    cmd.Parameters.AddWithValue("@Email",        req.Email);
                    cmd.Parameters.AddWithValue("@Phone",        (object)req.Phone ?? DBNull.Value);
                    cmd.Parameters.AddWithValue("@PasswordHash", passwordHash);
                    await cmd.ExecuteNonQueryAsync();
                }
            }

            return Ok(new { detail = "success" });
        }


        // ============================================================
        //  6. POST /api/leaderboard/login
        //     Email ve şifre ile giriş
        // ============================================================
        [HttpPost, Route("login")]
        public async Task<IHttpActionResult> Login([FromBody] LoginRequest req)
        {
            if (!IsAuthorized()) return Content(HttpStatusCode.Unauthorized, "Yetkisiz istek");
            if (req == null)                     return BadRequest("Veri bulunamadı.");
            if (string.IsNullOrEmpty(req.Email)) return BadRequest("Email zorunlu");
            if (string.IsNullOrEmpty(req.Password)) return BadRequest("Password zorunlu");

            string passwordHash = HashPassword(req.Password);

            using (var conn = new SqlConnection(_conn))
            {
                await conn.OpenAsync();

                Guid playerId = Guid.Empty;
                string fullName = null, username = null, countryCode = null;

                using (var cmd = new SqlCommand(@"
                    SELECT r.PlayerID, r.FullName, p.Username, p.CountryCode
                    FROM Registrations r
                    INNER JOIN Players p ON r.PlayerID = p.PlayerID
                    WHERE r.Email = @Email AND r.PasswordHash = @PasswordHash", conn))
                {
                    cmd.Parameters.AddWithValue("@Email",        req.Email);
                    cmd.Parameters.AddWithValue("@PasswordHash", passwordHash);
                    using (var r = await cmd.ExecuteReaderAsync())
                    {
                        if (!r.Read())
                            return Content(HttpStatusCode.Unauthorized, "Geçersiz email veya şifre");

                        playerId   = r.GetGuid(0);
                        fullName   = r.GetString(1);
                        username   = r.GetString(2);
                        countryCode = r.GetString(3);
                    }
                }

                return Ok(new {
                    PlayerID   = playerId,
                    FullName   = fullName,
                    Username   = username,
                    Email      = req.Email,
                    CountryCode = countryCode
                });
            }
        }


        // ============================================================
        //  7. PUT /api/leaderboard/update-player
        //     Oyuncu bilgilerini güncelle (username, ülke, avatar)
        // ============================================================
        [HttpPut, Route("update-player")]
        public async Task<IHttpActionResult> UpdatePlayer([FromBody] UpdatePlayerRequest req)
        {
            if (!IsAuthorized()) return Content(HttpStatusCode.Unauthorized, "Yetkisiz istek");
            if (req == null || string.IsNullOrEmpty(req.DeviceID))
                return BadRequest("DeviceID zorunlu");

            using (var conn = new SqlConnection(_conn))
            {
                await conn.OpenAsync();

                Guid? playerId = await GetPlayerIdAsync(conn, req.DeviceID);
                if (playerId == null)
                    return Content(HttpStatusCode.NotFound, "Oyuncu bulunamadı.");

                // Sadece gönderilen alanları güncelle
                var setParts = new List<string> { "LastSeenAt = GETUTCDATE()" };

                using (var cmd = new SqlCommand())
                {
                    cmd.Connection = conn;
                    cmd.Parameters.AddWithValue("@PID", playerId.Value);

                    if (!string.IsNullOrEmpty(req.Username))
                    {
                        setParts.Add("Username = @Username");
                        cmd.Parameters.AddWithValue("@Username", req.Username);
                    }
                    if (!string.IsNullOrEmpty(req.CountryCode))
                    {
                        setParts.Add("CountryCode = @CC");
                        cmd.Parameters.AddWithValue("@CC", req.CountryCode.ToUpper());
                    }
                    if (req.AvatarSlot.HasValue)
                    {
                        setParts.Add("AvatarSlot = @Avatar");
                        cmd.Parameters.AddWithValue("@Avatar", req.AvatarSlot.Value);
                    }

                    cmd.CommandText = $"UPDATE Players SET {string.Join(", ", setParts)} WHERE PlayerID = @PID";
                    await cmd.ExecuteNonQueryAsync();
                }
            }

            return Ok(new { detail = "success" });
        }


        // ============================================================
        //  7. PUT /api/leaderboard/update-registration
        //     Kayıt bilgilerini güncelle (ad, email, telefon)
        // ============================================================
        [HttpPut, Route("update-registration")]
        public async Task<IHttpActionResult> UpdateRegistration([FromBody] UpdateRegistrationRequest req)
        {
            if (!IsAuthorized()) return Content(HttpStatusCode.Unauthorized, "Yetkisiz istek");
            if (req == null || string.IsNullOrEmpty(req.DeviceID))
                return BadRequest("DeviceID zorunlu");

            using (var conn = new SqlConnection(_conn))
            {
                await conn.OpenAsync();

                Guid? playerId = await GetPlayerIdAsync(conn, req.DeviceID);
                if (playerId == null)
                    return Content(HttpStatusCode.NotFound, "Oyuncu bulunamadı.");

                // Kayıt var mı kontrol et
                using (var checkCmd = new SqlCommand(
                    "SELECT COUNT(*) FROM Registrations WHERE PlayerID = @PID", conn))
                {
                    checkCmd.Parameters.AddWithValue("@PID", playerId.Value);
                    if ((int)await checkCmd.ExecuteScalarAsync() == 0)
                        return Content(HttpStatusCode.NotFound,
                            "Kayıt bulunamadı. Önce /register ile kayıt oluşturun.");
                }

                var setParts = new List<string>();

                using (var cmd = new SqlCommand())
                {
                    cmd.Connection = conn;
                    cmd.Parameters.AddWithValue("@PID", playerId.Value);

                    if (!string.IsNullOrEmpty(req.FullName))
                    {
                        setParts.Add("FullName = @FullName");
                        cmd.Parameters.AddWithValue("@FullName", req.FullName);
                    }
                    if (!string.IsNullOrEmpty(req.Email))
                    {
                        setParts.Add("Email = @Email");
                        cmd.Parameters.AddWithValue("@Email", req.Email);
                    }
                    if (req.Phone != null) // boş string de geçerli (telefonu silmek için)
                    {
                        setParts.Add("Phone = @Phone");
                        cmd.Parameters.AddWithValue("@Phone",
                            string.IsNullOrEmpty(req.Phone) ? (object)DBNull.Value : req.Phone);
                    }

                    if (setParts.Count == 0)
                        return BadRequest("Güncellenecek alan bulunamadı.");

                    cmd.CommandText = $"UPDATE Registrations SET {string.Join(", ", setParts)} WHERE PlayerID = @PID";
                    await cmd.ExecuteNonQueryAsync();
                }
            }

            return Ok(new { detail = "success" });
        }


        // ============================================================
        //  8. DELETE /api/leaderboard/delete-player
        //     Oyuncuyu ve tüm verilerini sil (ON DELETE CASCADE çalışır)
        //     Header: X-Device-ID: <uuid>
        // ============================================================
        [HttpDelete, Route("delete-player")]
        public async Task<IHttpActionResult> DeletePlayer()
        {
            if (!IsAuthorized()) return Content(HttpStatusCode.Unauthorized, "Yetkisiz istek");

            string deviceId = Request.Headers.TryGetValues("X-Device-ID", out var vals)
                ? vals.FirstOrDefault() : null;

            if (string.IsNullOrWhiteSpace(deviceId))
                return BadRequest("X-Device-ID header zorunlu");

            using (var conn = new SqlConnection(_conn))
            {
                await conn.OpenAsync();

                Guid? playerId = await GetPlayerIdAsync(conn, deviceId);
                if (playerId == null)
                    return Content(HttpStatusCode.NotFound, "Oyuncu bulunamadı.");

                // ON DELETE CASCADE sayesinde Scores ve Registrations otomatik silinir
                using (var cmd = new SqlCommand(
                    "DELETE FROM Players WHERE PlayerID = @PID", conn))
                {
                    cmd.Parameters.AddWithValue("@PID", playerId.Value);
                    await cmd.ExecuteNonQueryAsync();
                }
            }

            return Ok(new { detail = "Player and all related data deleted." });
        }


        // ============================================================
        //  9. DELETE /api/leaderboard/delete-scores
        //     Oyuncunun tüm skorlarını sil (hesabı kalmaya devam eder)
        //     Header: X-Device-ID: <uuid>
        // ============================================================
        [HttpDelete, Route("delete-scores")]
        public async Task<IHttpActionResult> DeleteScores()
        {
            if (!IsAuthorized()) return Content(HttpStatusCode.Unauthorized, "Yetkisiz istek");

            string deviceId = Request.Headers.TryGetValues("X-Device-ID", out var vals)
                ? vals.FirstOrDefault() : null;

            if (string.IsNullOrWhiteSpace(deviceId))
                return BadRequest("X-Device-ID header zorunlu");

            using (var conn = new SqlConnection(_conn))
            {
                await conn.OpenAsync();

                Guid? playerId = await GetPlayerIdAsync(conn, deviceId);
                if (playerId == null)
                    return Content(HttpStatusCode.NotFound, "Oyuncu bulunamadı.");

                using (var cmd = new SqlCommand(
                    "DELETE FROM Scores WHERE PlayerID = @PID", conn))
                {
                    cmd.Parameters.AddWithValue("@PID", playerId.Value);
                    int deleted = await cmd.ExecuteNonQueryAsync();
                    return Ok(new { detail = $"{deleted} skor silindi." });
                }
            }
        }
    }
}
