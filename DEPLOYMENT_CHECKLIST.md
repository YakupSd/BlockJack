# 🚀 Backend Deployment Checklist

> Backend arkadaşına gönder → Adım adım kontrol etsin → Build & Deploy

---

## Phase 1: Database Setup ✅

- [ ] **SQL Server'e bağlı mısın?**
  ```bash
  sqlcmd -S your_server -U your_user -P your_password
  ```

- [ ] **Veritabanı var mı?**
  ```sql
  CREATE DATABASE BlockJack;
  USE BlockJack;
  ```

- [ ] **DuelDatabaseSchema.sql çalıştırdın mı?**
  ```bash
  sqlcmd -S your_server -U your_user -P your_password -i DuelDatabaseSchema.sql
  ```

- [ ] **Tablo oluşturulmuş mu?**
  ```sql
  SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES 
  WHERE TABLE_SCHEMA = 'dbo';
  
  -- Beklenen sonuç: Friends, DuelChallenges, DuelStats, DuelLeaderboard, FriendInvites
  ```

- [ ] **Stored Procedures var mı?**
  ```sql
  SELECT ROUTINE_NAME FROM INFORMATION_SCHEMA.ROUTINES 
  WHERE ROUTINE_SCHEMA = 'dbo';
  
  -- Beklenen: sp_CancelExpiredDuels, sp_UpdateDuelStats
  ```

---

## Phase 2: ASP.NET Core Setup ✅

- [ ] **Project yapısı hazır mı?**
  ```
  YourProject/
  ├── Controllers/
  │   └── DuelloController.cs ← Ekle
  ├── Models/
  │   └── (DTO classes)
  ├── Services/
  ├── appsettings.json
  └── Program.cs
  ```

- [ ] **DuelloController.cs eklenmiş mi?**
  ```bash
  cp DuelloController.cs /path/to/YourProject/Controllers/
  ```

- [ ] **Connection String ayarlanmış mı?** (`appsettings.json`)
  ```json
  {
    "ConnectionStrings": {
      "BlockJackDb": "Server=YOUR_SERVER;Database=BlockJack;User Id=sa;Password=YOUR_PASSWORD;Encrypt=false;"
    }
  }
  ```

- [ ] **Namespace doğru mu?**
  - DuelloController namespace: `YourProject.Controllers`
  - Diğer classlar kendi dosyalarında organize edilmiş mi?

- [ ] **Dependencies installed?**
  ```bash
  dotnet add package System.Data.SqlClient
  dotnet add package Microsoft.AspNetCore.Authentication.JwtBearer
  ```

---

## Phase 3: Authentication & Authorization ✅

- [ ] **JWT Configuration (`Program.cs`)**
  ```csharp
  services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
      .AddJwtBearer(options => {
          options.TokenValidationParameters = new TokenValidationParameters {
              ValidateIssuerSigningKey = true,
              ValidateIssuer = true,
              ValidateAudience = true
          };
      });
  ```

- [ ] **[Authorize] attribute eklenmiş mi DuelloController'a?**
  ```csharp
  [ApiController]
  [Route("api/[controller]")]
  [Authorize]
  public class DuelloController : ControllerBase
  ```

- [ ] **Public endpoints (Leaderboard) exception mi?**
  ```csharp
  [HttpGet("leaderboard")]
  [AllowAnonymous]
  public async Task<IActionResult> GetLeaderboard(int page, int pageSize)
  ```

---

## Phase 4: Testing ✅

### Local Testing

- [ ] **Server başlatıldı mı?**
  ```bash
  dotnet run
  # Veya Visual Studio'da F5
  ```

- [ ] **Postman Import et**
  ```
  File → Import → Duello_API_Postman.json
  ```

- [ ] **Test Friend Search**
  ```
  POST http://localhost:5000/api/duello/friend/search
  Body: { "SearchQuery": "player", "Limit": 10 }
  Beklenen: 200 OK + Player listesi
  ```

- [ ] **Test Create Duel** (Gold check değeri görmeli)
  ```
  POST http://localhost:5000/api/duello/create
  Body: { 
    "ChallengerID": "player123",
    "ChallengedID": "player456", 
    "StakeAmount": 500 
  }
  Beklenen: 200 OK + DuelID + Seed
  ```

- [ ] **Test Submit Result**
  ```
  POST http://localhost:5000/api/duello/submit-result
  Body: { 
    "DuelID": "<from_create>",
    "PlayerID": "player123",
    "FinalScore": 50000,
    ... (diğer stats)
  }
  Beklenen: 200 OK + kaydedildi mesajı
  ```

- [ ] **Test Leaderboard** (NO AUTH)
  ```
  GET http://localhost:5000/api/duello/leaderboard?page=1&pageSize=50
  Beklenen: 200 OK + Top 50 oyuncu
  ```

### Database Verification

- [ ] **Duel oluşturulmuş mu?**
  ```sql
  SELECT * FROM DuelChallenges;
  -- Seed değerinin Int64 olması lazım
  ```

- [ ] **Stats kaydedilmiş mi?**
  ```sql
  SELECT * FROM DuelStats;
  ```

- [ ] **Leaderboard güncellendi mi?**
  ```sql
  SELECT * FROM DuelLeaderboard;
  ```

---

## Phase 5: iOS Integration ✅

- [ ] **Backend URL iOS'a ayarlandı mı?**
  ```swift
  // FriendService.swift + DuelService.swift
  let baseApiUrl = "http://your_backend_url:5000"
  // Mock Task.sleep() çıkart, HttpClient kullan
  ```

- [ ] **Push Notification Token kaydedildi mi?**
  - PushNotificationManager → DeviceToken
  - Backend'e POST `/api/device-tokens` endpoint ekle
  ```sql
  CREATE TABLE DeviceTokens (
    TokenID GUID PRIMARY KEY,
    PlayerID NVARCHAR(50),
    Token NVARCHAR(MAX),
    Platform NVARCHAR(20), -- iOS/Android
    CreatedAt DATETIME2,
    UpdatedAt DATETIME2
  )
  ```

- [ ] **DeepLink Handler çalışıyor mu?**
  ```
  blockjack://friend?code=BLK-XXXX
  blockjack://duel?duelId=<GUID>
  ```

---

## Phase 6: Security Audit ✅

- [ ] **SQL Injection koruması?**
  - [x] Tüm queries parameterized (@parameter)
  - [ ] User input directly SQL'e eklenmemiş mi?

- [ ] **JWT Validation?**
  ```csharp
  var claimsPrincipal = User;
  var playerID = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
  if (playerID != requestPlayerID) return Unauthorized();
  ```

- [ ] **Rate Limiting?**
  ```csharp
  services.AddRateLimiter(options => {
      options.AddFixedWindowLimiter(
          policyName: "duello",
          options => {
              options.PermitLimit = 10;
              options.Window = TimeSpan.FromSeconds(60);
          }
      );
  });
  
  [HttpPost("create")]
  [RateLimiterPolicy("duello")]
  public async Task<IActionResult> CreateDuel(...)
  ```

- [ ] **Gold Transfer Atomicity?**
  ```csharp
  using (SqlConnection conn = new SqlConnection(connectionString)) {
      conn.Open();
      using (SqlTransaction trans = conn.BeginTransaction()) {
          // BEGIN TRANSACTION logic
          // Challenger debit
          // Challenged debit
          // Winner credit
          // Update duel
          trans.Commit();
      }
  }
  ```

- [ ] **Input Validation?**
  ```csharp
  if (stakeAmount <= 0 || stakeAmount > 10000)
      return BadRequest("Bahis geçersiz");
  
  if (string.IsNullOrEmpty(searchQuery) || searchQuery.Length < 3)
      return BadRequest("En az 3 karakter gerekli");
  ```

- [ ] **Error Handling?**
  - [ ] No stack traces exposed
  - [ ] Meaningful error messages
  - [ ] 500 errors logged
  ```csharp
  try { ... }
  catch (Exception ex) {
      _logger.LogError(ex, "Duel creation failed");
      return StatusCode(500, new { error = "İçsel hata" });
  }
  ```

---

## Phase 7: Performance Tuning ✅

- [ ] **Index performance test?**
  ```sql
  -- Slow query identify
  SET STATISTICS IO ON;
  SELECT * FROM DuelChallenges WHERE Status = 'pending' AND ExpiresAt < GETUTCDATE();
  SET STATISTICS IO OFF;
  ```

- [ ] **Pagination implementation?**
  ```sql
  SELECT * FROM DuelLeaderboard
  ORDER BY DuelsWon DESC
  OFFSET @pageSize * (@page - 1) ROWS
  FETCH NEXT @pageSize ROWS ONLY;
  ```

- [ ] **Caching strategy?**
  - [ ] Redis/MemoryCache for Leaderboard
  - [ ] TTL: 1 hour
  - [ ] Invalidate on new duel completion

- [ ] **Stored procedure for stats?**
  ```sql
  EXEC sp_UpdateDuelStats @PlayerID = 'player123';
  ```

---

## Phase 8: Monitoring & Logging ✅

- [ ] **Application Insights setup?**
  ```csharp
  builder.Services.AddApplicationInsightsTelemetry();
  ```

- [ ] **Structured logging?**
  ```csharp
  _logger.LogInformation("Duel created: {DuelID}", duelId);
  _logger.LogWarning("Gold transfer failed for duel {DuelID}", duelId);
  _logger.LogError(ex, "Database error in {Method}", nameof(CreateDuel));
  ```

- [ ] **Health check endpoint?**
  ```csharp
  [HttpGet("health")]
  [AllowAnonymous]
  public IActionResult Health() => Ok(new { status = "healthy" });
  ```

---

## Phase 9: Production Deployment ✅

- [ ] **Environment configuration?**
  ```
  appsettings.Development.json
  appsettings.Staging.json
  appsettings.Production.json
  ```

- [ ] **Database backup strategy?**
  ```sql
  -- Daily automated backup
  BACKUP DATABASE BlockJack TO DISK = 'C:\Backups\BlockJack_$(DATE).bak'
  ```

- [ ] **SSL/HTTPS enabled?**
  ```csharp
  app.UseHttpsRedirection();
  ```

- [ ] **CORS configured?**
  ```csharp
  services.AddCors(options => options.AddPolicy("BlockJack", 
      builder => builder.WithOrigins("https://yourdomain.com")));
  app.UseCors("BlockJack");
  ```

- [ ] **API Documentation (Swagger)?**
  ```csharp
  services.AddSwaggerGen();
  app.UseSwagger();
  app.UseSwaggerUI();
  ```

---

## Common Issues & Solutions

### Issue 1: "Connection timeout"
```
Solution: 
1. SQL Server çalışıyor mu? (Services)
2. Connection string server name doğru mu?
3. Firewall port 1433 açık mı?
```

### Issue 2: "PlayerID not found"
```
Solution:
1. Players tablosu var mı?
2. TestData ekle:
   INSERT INTO Players VALUES ('player123', 'TEST_USER', 1000, 0, GETUTCDATE());
```

### Issue 3: "401 Unauthorized"
```
Solution:
1. JWT token geçerli mi?
2. Token expire süresini uzat (test için)
3. Postman'de Bearer token set et
```

### Issue 4: "Gold transfer fails"
```
Solution:
1. Players.Gold BIGINT mi INT mi?
2. Transaction logleri kontrol et
3. Seed değeri valid Int64 mı?
```

### Issue 5: "Seed consistency issue"
```
Solution:
1. Seed generation: Int64.random(in: 100_000...999_999_999)
2. Seed iOS'a kaydedildi mi?
3. LCG formula doğru mu?
   state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
```

---

## Final Checklist Before GO-LIVE

- [ ] All endpoints tested locally ✅
- [ ] Database backups working ✅
- [ ] SSL certificates installed ✅
- [ ] Rate limiting enabled ✅
- [ ] JWT secrets secure (no hardcode) ✅
- [ ] Logging monitoring active ✅
- [ ] iOS app connects to live server ✅
- [ ] Push notifications working ✅
- [ ] Load test passed (1000 duels/min) ✅
- [ ] Rollback plan documented ✅

---

## Support Channel

**Sorun olursa:**
1. DuelloController.cs satır no'yu söyle
2. Error message tam olarak yaz
3. Request/Response JSON'ı yapıştır
4. SQL query result'ını göster

---

> 🎮 **Duello Backend System v1.0**
> Ready to make PvP competitive! 🚀

