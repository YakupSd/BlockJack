## 📊 BLOCK-JACK: SCORING ENGINE V2 (Technical Spec)

**Document Version:** 3.0 Production  
**Last Updated:** 2026-04-30  
**Status:** Ready for Implementation ✅
- **Konsept**: Logaritmik büyüme & stratejik çarpan yönetimi  
- **İlham**: Balatro (Order of Operations) & Block Blast (Spatial Logic)

# 🎯 BLOCK-JACK: SCORING ENGINE V3
## Advanced Logarithmic Progression & Strategic Multiplier Management

**Version:** 3.0 Production  
**Game Type:** Block Puzzle (Grid-based Spatial Logic)  
**Core Philosophy:** Exponential growth through color mastery & strategic placement  
**Inspired by:** Balatro (Order of Operations) + Block Blast (Spatial Mechanics) + Tetris (Line Clearing)

---

## 📋 TABLE OF CONTENTS

1. [System Overview](#1-system-overview)
2. [The Golden Formula](#2-the-golden-formula)
3. [Scoring Pipeline (5 Phases)](#3-scoring-pipeline-5-phases)
4. [Block Properties & Base Values](#4-block-properties--base-values)
5. [Color Engineering System](#5-color-engineering-system)
6. [Combo & Streak Mechanics](#6-combo--streak-mechanics)
7. [Perk Integration](#7-perk-integration)
8. [Economic Overflow System](#8-economic-overflow-system)
9. [Technical Implementation](#9-technical-implementation)
10. [UI/UX Juice Specifications](#10-uiux-juice-specifications)
11. [Balance & Tuning Guide](#11-balance--tuning-guide)
12. [Example Scenarios](#12-example-scenarios)

---

## 1) SYSTEM OVERVIEW

### Design Pillars

**🎲 Strategic Depth Over Luck**
- Every placement decision creates cascading consequences
- Color composition matters as much as shape
- Order of operations is transparent and exploitable

**📈 Logarithmic Growth Curve**
- Early game: linear, predictable scoring (learning phase)
- Mid game: combo stacking unlocks exponential potential
- Late game: perk synergies enable 10,000+ point moves

**⚖️ Risk vs Reward Balance**
- Tight placements grant neighbor bonuses but reduce future options
- Pure color runs (Flush) give massive multipliers but require planning
- X-Mult perks are powerful but fragile (one mistake breaks the chain)

---

## 2) THE GOLDEN FORMULA

### Master Equation

```
TotalScore = (BaseChips) × (1.0 + ΣAdditiveMult) × ΠMultiplicativeMult
```

**Component Breakdown:**

| Component | Source | Example |
|-----------|--------|---------|
| **BaseChips** | Block mass + neighbor density | 50 chips |
| **ΣAdditiveMult** | Line patterns + combo stack + perks | +18.0 |
| **ΠMultiplicativeMult** | X-Mult perks + streak bonus | ×3.5 |

**Example Calculation:**
```
50 chips × (1.0 + 18.0) × 3.5 = 50 × 19.0 × 3.5 = 3,325 points
```

---

## 3) SCORING PIPELINE (5 PHASES)

### Phase 1️⃣: THE SNAP (Placement Scoring)

Triggered **instantly** when a block is placed on the grid.

#### Formula:
```
BaseChips = (BlockMass × 10) + (NeighborBonus × 5) + ColorDensityBonus
```

#### Components:

**A) Block Mass (M)**
- Number of cells the block occupies
- Examples:
  - Single cell: M = 1 → 10 chips
  - L-block: M = 4 → 40 chips
  - T-block: M = 4 → 40 chips
  - Big Square (2×2): M = 4 → 40 chips

**B) Neighbor Bonus (N)**
- Number of **already-filled** cells adjacent (orthogonal only, not diagonal) to the newly placed block
- Encourages tight packing
- Formula: `N × 5 chips`
- Example:
  ```
  Grid before:    Grid after:
  [ ][X][ ]       [ ][X][ ]
  [ ][ ][ ]  →    [N][N][ ]  (2 neighbors)
  [ ][ ][ ]       [ ][ ][ ]
  
  Neighbor Bonus = 2 × 5 = 10 chips
  ```

**C) Color Density Bonus (NEW)**
- Bonus for placing a block that creates a **local color cluster** (3+ same-color cells touching)
- Encourages color strategy even before line completion
- Formula: `ClusterSize × 2 chips` (if cluster ≥ 3 cells)
- Example: Placing a blue block next to 2 existing blue cells creates a 3-cell cluster → +6 chips

**Full Example:**
```
Block: 4-cell L-block (Blue)
Neighbors: 3 filled cells touching
Color Cluster: 5 blue cells now touching

BaseChips = (4 × 10) + (3 × 5) + (5 × 2)
          = 40 + 15 + 10
          = 65 chips
```

---

### Phase 2️⃣: DETECTION (Line Clear Patterns)

Triggered when **any row or column fills completely** (8 cells).

#### Pattern Recognition Table:

| Pattern Type | Description | Additive Mult | Rarity |
|--------------|-------------|---------------|--------|
| **Mixed Line** | 3+ different colors | +1.0 | Common |
| **Duo-Tone** | Exactly 2 colors only | +2.5 | Uncommon |
| **Tri-Tone** | Exactly 3 colors in equal distribution | +3.5 | Uncommon |
| **Gradient** | All 5 colors present (rainbow) | +4.5 | Rare |
| **FLUSH** | All 8 cells same color | +8.0 | Very Rare |
| **SUPER FLUSH** | 2+ lines cleared, both Flush | +20.0 | Legendary |

#### Pattern Detection Logic:

```swift
func detectPattern(line: [Cell]) -> Pattern {
    let uniqueColors = Set(line.map { $0.color })
    
    switch uniqueColors.count {
    case 1: return .flush          // +8.0
    case 2: return .duoTone        // +2.5
    case 3: return .triTone        // +3.5
    case 5: return .gradient       // +4.5
    default: return .mixed         // +1.0
    }
}
```

---

### Phase 3️⃣: COMBO STACK (Multi-Line Clears)

Triggered when **2+ lines clear simultaneously** in a single placement.

#### Combo Multipliers:

| Lines Cleared | Bonus Name | Additive Mult | Visual |
|---------------|------------|---------------|--------|
| 2 lines | Double | +2.0 | Yellow glow |
| 3 lines | Triple | +5.0 | Orange spark |
| 4 lines | **QUAD** | +12.0 | Red explosion |
| 5+ lines | **MEGA** | +25.0 | Purple supernova |

**Stacking Rule:**
- Combo bonuses stack **additively** with pattern bonuses
- Example: 2 Flush lines cleared = (+8.0 + +8.0) + (+2.0 combo) = **+18.0 total**

---

### Phase 4️⃣: PERK MODIFIERS (Active Synergies)

Perks apply **after** base chips and detection, **before** X-Mult.

#### Perk Types:

**A) Additive Perks (+Mult)**
Add flat multiplier bonuses based on conditions.

Examples:
- **Blue Pill (Tier 3):** "Blue blocks +150% score" → If block is blue, **+1.5 Mult**
- **Momentum (Tier 2):** "4-streak gives +75% score" → **+0.75 Mult**
- **Lucky Clover (Tier 5):** "Streak limit +40, each streak level +0.2 Mult" → **+8.0 Mult** (at max streak)

**B) Scaling Perks (📈 Cumulative)**
Grow over time/actions during the run.

Examples:
- **Midas Touch (Tier 4):** "Earn +18 Gold per Flush, also +0.5 Mult per Flush this run"
  - After 10 Flushes: **+5.0 Mult** (persistent)
- **Glass Cannon (Tier 5):** "HP ≤ 3, score ×2.5"
  - Works as X-Mult in Phase 5

**C) Order Matters**
Perks apply **left-to-right** in the player's inventory.

Example Inventory:
```
[Perk 1: Blue Pill] → [Perk 2: Momentum] → [Perk 3: Lucky Clover]
```

Calculation:
```
1. Blue Pill checks: Block is blue? → +1.5 Mult
2. Momentum checks: Streak = 4? → +0.75 Mult
3. Lucky Clover: Streak = 40 → +8.0 Mult

Total Additive Mult = 1.5 + 0.75 + 8.0 = +10.25
```

---

### Phase 5️⃣: THE X-FACTOR (Multiplicative Mults)

Applied **after all additive bonuses** are summed.

#### X-Mult Sources:

**A) Streak Bonus**
- Formula: `1.1^(CurrentStreak)`
- Caps at Streak 50 → `1.1^50 ≈ ×117` (theoretical max, practically 10-20)
- Example:
  - Streak 5: `1.1^5 = ×1.61`
  - Streak 10: `1.1^10 = ×2.59`
  - Streak 20: `1.1^20 = ×6.73`

**B) Perk X-Mults**
- **Glass Cannon (Tier 5):** HP ≤ 3 → `×2.5`
- **Overkill (Tier 5):** Excess score from previous round → `×1.3`
- **Wide Load (Tier 5):** 7 blocks in storage → `×1.2` (risk management bonus)

**C) Chain Rule**
X-Mults multiply each other:
```
Total X-Mult = StreakMult × GlassCannon × Overkill × WideLoad
             = 2.59 × 2.5 × 1.3 × 1.2
             = ×10.1
```

**Full Calculation Example:**
```
BaseChips = 65
Additive Mult = 1.0 + 10.25 = 11.25
X-Mult = 10.1

TotalScore = 65 × 11.25 × 10.1 = 7,388 points
```

---

## 4) BLOCK PROPERTIES & BASE VALUES

### Block Types & Mass Values

| Block Shape | Mass (M) | Base Chips | Spawn Rate | Strategy |
|-------------|----------|------------|------------|----------|
| Single Cell | 1 | 10 | 30% | Filler, precision |
| Domino (1×2) | 2 | 20 | 25% | Gap filling |
| L-Block | 4 | 40 | 15% | Corner control |
| T-Block | 4 | 40 | 15% | Center control |
| Square (2×2) | 4 | 40 | 10% | Stability |
| Long Bar (1×4) | 4 | 40 | 5% | Line clearing |

### Color Distribution (5 Colors)

| Color | Hex Code | Spawn Weight | Strategic Role |
|-------|----------|--------------|----------------|
| Blue | #0080FF | 20% | Balanced, most common |
| Green | #00C853 | 20% | Balanced |
| Red | #FF1744 | 20% | Balanced |
| Yellow | #FFC400 | 20% | Balanced |
| Purple | #9C27B0 | 20% | Balanced (equal distribution) |

**Design Note:** Equal color distribution prevents color-scarcity frustration. Strategic depth comes from **pattern recognition**, not color luck.

---

## 5) COLOR ENGINEERING SYSTEM

### Why Color Matters

Color is the **secondary scoring dimension** beyond spatial placement.

### Color Strategies:

**1. Flush Stacking (High Risk, High Reward)**
- Goal: Fill an entire line with one color
- Reward: +8.0 Mult (vs +1.0 for Mixed)
- Risk: Requires 8 blocks of same color + perfect placement
- Best Perks: Blue/Lead Pill (amplify specific colors)

**2. Gradient Mixing (Medium Risk, Medium Reward)**
- Goal: Get all 5 colors in one line
- Reward: +4.5 Mult
- Easier than Flush, still strategic
- Best Perks: Lucky Clover (more attempts = higher chance)

**3. Duo-Tone Control (Low Risk, Consistent)**
- Goal: Alternate between 2 colors in a line
- Reward: +2.5 Mult
- Very achievable with planning
- Best Perks: Sculptor (rotate blocks to match color needs)

---

## 6) COMBO & STREAK MECHANICS

### Combo System (Same-Turn Multi-Clears)

**Definition:** Number of lines cleared in a **single block placement**.

**Scaling:**
- 2 lines: +2.0 Mult
- 3 lines: +5.0 Mult
- 4 lines: +12.0 Mult (QUAD)
- 5+ lines: +25.0 Mult (MEGA - theoretically possible with special block shapes)

**Example:**
```
Player places an L-block that completes:
- 1 horizontal row (Flush: +8.0)
- 1 vertical column (Duo-Tone: +2.5)
- Combo bonus (2 lines): +2.0

Total Additive Mult from this move: +12.5
```

### Streak System (Cross-Turn Success Chain)

**Definition:** Number of **consecutive successful moves** without a failed placement.

**Success Criteria:**
- Move clears at least 1 line = Success
- Move places block but clears nothing = **Streak breaks**, resets to 0

**Streak X-Mult:**
- Formula: `1.1^Streak`
- Caps at Streak 50 (Lucky Clover Tier 5 increases base cap from 10 to 50)

**Streak Milestone Bonuses:**

| Streak Level | X-Mult | Visual Feedback |
|--------------|--------|-----------------|
| 5 | ×1.61 | Yellow border |
| 10 | ×2.59 | Orange glow |
| 15 | ×4.18 | Red pulse |
| 20 | ×6.73 | Purple aura |
| 25+ | ×10.8+ | Rainbow explosion |

---

## 7) PERK INTEGRATION

### Perk Timing in Pipeline

```
Phase 1: BaseChips calculated
    ↓
Phase 2: Line patterns detected → +Mult added
    ↓
Phase 3: Combo bonuses → +Mult added
    ↓
Phase 4: PERKS APPLY (left-to-right)
    ├─→ Additive perks add to ΣMult
    └─→ Scaling perks add cumulative values
    ↓
Phase 5: X-Mult perks multiply final score
    ↓
Economic Overflow (if score > target)
```

### Perk Interaction Examples

**Scenario 1: Blue Pill + Glass Cannon Combo**

Player state:
- HP = 1
- Block placed: 4-cell blue L-block
- Line cleared: Blue Flush

Calculation:
```
BaseChips = 40 (mass) + 15 (neighbors) = 55

Phase 2 (Detection):
  Flush pattern → +8.0 Mult

Phase 4 (Perks):
  Blue Pill (Tier 3): Blue blocks +150% → +1.5 Mult
  
  Total Additive: 1.0 + 8.0 + 1.5 = 10.5

Phase 5 (X-Mult):
  Glass Cannon (Tier 5): HP = 1 → ×2.5

FinalScore = 55 × 10.5 × 2.5 = 1,444 points
```

**Scenario 2: Momentum + Lucky Clover Stack**

Player state:
- Current Streak: 40 (max with Lucky Clover Tier 5)
- 4th successful move in a row (Momentum triggers)

Calculation:
```
BaseChips = 50

Phase 4 (Perks):
  Momentum (Tier 3): 4-streak → +1.0 Mult (double score at 4th)
  Lucky Clover (Tier 5): Streak 40 → +8.0 Mult (0.2 per level)
  
  Total Additive: 1.0 + 1.0 + 8.0 = 10.0

Phase 5 (X-Mult):
  Streak bonus: 1.1^40 = ×45.3 (!)

FinalScore = 50 × 10.0 × 45.3 = 22,650 points (!!!)
```

---

## 8) ECONOMIC OVERFLOW SYSTEM

### The Blind (Round Target)

Each round has a target score (The Blind) that must be reached to progress.

**Target Scaling Formula:**
```
Target = BaseTarget × (1.2^RoundNumber)
```

Example progression:
- Round 1: 500 points
- Round 5: 1,244 points
- Round 10: 3,096 points
- Round 20: 19,173 points

### Overflow Rewards (Excess Score Economy)

When `TotalScore > Target`, excess converts to currency.

**Interest Tiers:**

| Excess % | Reward | Example |
|----------|--------|---------|
| 25-49% over | +2 Gold | Target 1,000, scored 1,300 → +2 Gold |
| 50-99% over | +5 Gold | Target 1,000, scored 1,800 → +5 Gold |
| 100-199% over | +10 Gold | Target 1,000, scored 2,500 → +10 Gold |
| 200%+ over | +20 Gold | Target 1,000, scored 3,500 → +20 Gold |
| 500%+ over | +20 Gold + 10% chance for 1 Diamond | Target 1,000, scored 5,000+ |

**Overkill Perk Synergy:**
- **Overkill (Tier 5):** Carries over 75% of excess score to next round
- Example:
  ```
  Round 1 target: 1,000
  Scored: 2,000 (1,000 excess)
  
  Round 2 starts with: 750 bonus chips (75% of 1,000)
  → Massive head start!
  ```

---

## 9) TECHNICAL IMPLEMENTATION

### Core Architecture

```swift
// MARK: - Score Context (Mutable State Container)

struct ScoreContext {
    var baseChips: Double = 0
    var additiveMult: Double = 0  // Sum of all +Mult
    var multiplicativeMult: Double = 1.0  // Product of all ×Mult
    
    var finalScore: Int {
        Int(baseChips * (1.0 + additiveMult) * multiplicativeMult)
    }
    
    mutating func addMult(_ value: Double) {
        additiveMult += value
    }
    
    mutating func multiplyMult(_ value: Double) {
        multiplicativeMult *= value
    }
}
```

### Event-Driven Scoring

```swift
// MARK: - Game Events

enum GameEvent {
    case blockPlaced(block: Block, neighbors: Int, colorCluster: Int)
    case lineCleared(pattern: LinePattern, combo: Int)
    case streakIncreased(newStreak: Int)
    case roundCompleted(score: Int, target: Int)
}

// MARK: - Perk Protocol

protocol PerkEffect {
    var name: String { get }
    var tier: Int { get }
    func apply(to context: inout ScoreContext, event: GameEvent)
}
```

### Example Perk Implementation

```swift
struct BluePillPerk: PerkEffect {
    let name = "Blue Pill"
    let tier: Int
    
    func apply(to context: inout ScoreContext, event: GameEvent) {
        guard case .blockPlaced(let block, _, _) = event else { return }
        
        if block.color == .blue {
            let bonus = tierBonus(tier)
            context.addMult(bonus)
        }
    }
    
    private func tierBonus(_ tier: Int) -> Double {
        switch tier {
        case 1: return 0.5   // +50%
        case 2: return 1.0   // +100% (2×)
        case 3: return 1.5   // +150% (2.5×)
        case 4: return 2.0   // +200% (3×)
        case 5: return 3.0   // +300% (4×)
        default: return 0
        }
    }
}
```

### Score Engine (Main Calculator)

```swift
class ScoreEngine {
    private var perks: [PerkEffect] = []
    private var currentStreak: Int = 0
    
    func calculateScore(for event: GameEvent) -> Int {
        var context = ScoreContext()
        
        // Phase 1: Base Chips
        if case .blockPlaced(let block, let neighbors, let cluster) = event {
            context.baseChips = Double(block.mass * 10 + neighbors * 5 + cluster * 2)
        }
        
        // Phase 2 & 3: Detection + Combo
        if case .lineCleared(let pattern, let combo) = event {
            context.addMult(pattern.multValue)
            context.addMult(comboBonus(combo))
        }
        
        // Phase 4: Apply Perks (order matters!)
        for perk in perks {
            perk.apply(to: &context, event: event)
        }
        
        // Phase 5: X-Mult (Streak)
        if case .streakIncreased(let streak) = event {
            currentStreak = streak
            context.multiplyMult(pow(1.1, Double(streak)))
        }
        
        return context.finalScore
    }
    
    private func comboBonus(_ lines: Int) -> Double {
        switch lines {
        case 2: return 2.0
        case 3: return 5.0
        case 4: return 12.0
        case 5...: return 25.0
        default: return 0
        }
    }
}
```

---

## 10) UI/UX JUICE SPECIFICATIONS

### Visual Feedback Pipeline

Every scoring phase must have **immediate, clear visual feedback**.

#### Phase 1: THE SNAP (Block Placement)

**Animation Sequence:**
1. Block touches grid → **Haptic: Light**
2. BaseChips number appears above block → **Fade in + Float up** (0.3s)
3. Neighbor bonus sparkles → **Particle burst** from adjacent cells (0.2s)
4. Color cluster glow → **Pulsing halo** around connected same-color cells (0.4s)

**UI Elements:**
```swift
Text("+\(baseChips)")
    .font(.system(size: 20, weight: .bold, design: .rounded))
    .foregroundStyle(.white)
    .shadow(color: .black.opacity(0.5), radius: 4)
    .offset(y: animationOffset)
    .opacity(animationOpacity)
```

#### Phase 2: DETECTION (Line Clear)

**Pattern-Specific Animations:**

| Pattern | Color | Glow Intensity | Duration | Haptic |
|---------|-------|----------------|----------|--------|
| Mixed | White | Low | 0.3s | Light |
| Duo-Tone | Yellow | Medium | 0.5s | Medium |
| Gradient | Rainbow | High | 0.7s | Medium |
| Flush | Neon Cyan | Ultra | 1.0s | Heavy |

**Animation:**
```swift
// Line clear flash
RoundedRectangle(cornerRadius: 8)
    .fill(pattern.glowColor)
    .frame(height: 8)
    .scaleEffect(x: lineFlashScale, y: 1.0)
    .opacity(lineFlashOpacity)
    .animation(.spring(response: 0.4), value: lineFlashScale)
```

**Mult Counter Update:**
```swift
Text("+\(Int(additiveMult))")
    .font(.system(size: 28, weight: .bold))
    .foregroundStyle(
        LinearGradient(
            colors: [.purple, .pink],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
    .scaleEffect(multPulseScale)
    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: multPulseScale)
```

#### Phase 3: COMBO STACK

**Combo Tier Animations:**

**2-Line (Double):**
- Screen shake: **2px amplitude**
- Yellow ring explosion from center
- Haptic: **Medium**
- SFX: "Ding-ding"

**3-Line (Triple):**
- Screen shake: **4px amplitude**
- Orange fireworks burst
- Haptic: **Heavy**
- SFX: "Whoosh-boom"

**4-Line (QUAD):**
- Screen shake: **8px amplitude**
- Red lightning bolts across screen
- Haptic: **Heavy** (2 pulses)
- SFX: "KABOOM"
- Slow-mo: **0.5× speed** for 0.3s

**5+ Line (MEGA):**
- Screen shake: **12px amplitude**
- Purple supernova (fullscreen white flash)
- Haptic: **Heavy** (sustained 0.5s)
- SFX: "ULTIMATE"
- Slow-mo: **0.3× speed** for 0.5s
- Camera zoom out **10%** then back

#### Phase 4: PERK MODIFIERS

**Order Visualization:**

```
[Perk 1] ──→ [Perk 2] ──→ [Perk 3]
   ✓            ✓            ✓
  +1.5         +0.75        +8.0
```

**Animation:**
- Light beam travels left-to-right across perks (0.2s per perk)
- Active perk glows **neon blue**
- Mult counter increments **smoothly** (counting animation)
- Each perk activation: **Haptic: Light**

**Code:**
```swift
ForEach(Array(perks.enumerated()), id: \.offset) { index, perk in
    PerkCardView(perk: perk)
        .overlay(
            Rectangle()
                .fill(Color.cyan.opacity(isPerkActive(index) ? 0.3 : 0))
                .animation(.easeInOut(duration: 0.2), value: isPerkActive(index))
        )
}
```

#### Phase 5: THE X-FACTOR

**The Explosion Moment:**

When X-Mult applies:
1. **0.0s:** Screen freezes for 0.1s
2. **0.1s:** Score counter turns **GOLD**
3. **0.2s:** Numbers start **counting up rapidly**
4. **0.3s:** Camera **zooms in 5%**
5. **0.5s:** **EXPLOSION EFFECT:**
   - Fullscreen golden particles
   - Screen shake **10px**
   - Haptic: **Heavy** (long)
6. **1.0s:** Final score **SLAMS** into place
7. **1.2s:** Return to normal

**Final Score Animation:**
```swift
Text("\(finalScore)")
    .font(.system(size: 48, weight: .black, design: .rounded))
    .foregroundStyle(
        LinearGradient(
            colors: [.yellow, .orange, .red],
            startPoint: .leading,
            endPoint: .trailing
        )
    )
    .shadow(color: .orange, radius: 20)
    .scaleEffect(scoreSlam ? 1.2 : 1.0)
    .animation(.spring(response: 0.4, dampingFraction: 0.5), value: scoreSlam)
```

---

## 11) BALANCE & TUNING GUIDE

### Design Goals by Game Stage

| Stage | Rounds | Avg Score/Move | Player Focus | Perk Tiers |
|-------|--------|----------------|--------------|------------|
| Early | 1-5 | 50-200 | Learn patterns | Tier 1-2 |
| Mid | 6-15 | 200-1,000 | Combo stacking | Tier 3 |
| Late | 16-30 | 1,000-5,000 | Perk synergies | Tier 4-5 |
| End | 31+ | 5,000-20,000+ | Mastery | Tier 5 max |

### Tuning Knobs

**If game feels too easy:**
- Reduce Flush mult from +8.0 to +6.0
- Increase Blind targets by 20%
- Cap streak bonus at Streak 30 instead of 50

**If game feels too hard:**
- Increase neighbor bonus from ×5 to ×8
- Add Tier 0 starter perks (always active, weaker)
- Give +1 free revive at Round 10

**If scoring feels unclear:**
- Add "Score Breakdown" popup after each move
- Highlight which perk contributed most mult
- Slow down number animations

---

## 12) EXAMPLE SCENARIOS

### Scenario A: Perfect Flush Chain (Early Game Power Spike)

**Setup:**
- Round 3
- Target: 800 points
- Player has: Blue Pill (Tier 2)
- Current streak: 0

**Move 1:**
- Place 4-cell blue L-block
- Completes 1 row: **Blue Flush**
- Neighbors: 2

**Calculation:**
```
BaseChips = (4 × 10) + (2 × 5) = 50

Detection:
  Flush → +8.0

Perks:
  Blue Pill (Tier 2) → +1.0 (blue blocks 2×)

Total Additive: 1.0 + 8.0 + 1.0 = 10.0
X-Mult: 1.0 (no streak yet)

Score = 50 × 10.0 × 1.0 = 500 points
```

**Result:** 500/800 target reached, streak starts at 1.

---

### Scenario B: QUAD Combo Explosion (Mid Game)

**Setup:**
- Round 12
- Target: 3,500 points
- Player has: Lucky Clover (Tier 3), Momentum (Tier 2)
- Current streak: 10

**Move 1:**
- Place Long Bar (1×4) vertically
- Completes **4 lines** simultaneously:
  - 3 horizontal rows (all Duo-Tone)
  - 1 vertical column (Gradient)

**Calculation:**
```
BaseChips = (4 × 10) + (8 × 5) = 80  (8 neighbors!)

Detection:
  Row 1 (Duo-Tone) → +2.5
  Row 2 (Duo-Tone) → +2.5
  Row 3 (Duo-Tone) → +2.5
  Column (Gradient) → +4.5
  
Combo:
  4-line QUAD → +12.0

Perks:
  Lucky Clover (Tier 3) → +3.0 (15 streak limit, 0.2 per)
  Momentum (Tier 2) → +0.75 (this is 4th successful move)

Total Additive: 1.0 + 12.0 + 12.0 + 4.0 = 29.0

X-Mult:
  Streak 10 → 1.1^10 = 2.59

Score = 80 × 29.0 × 2.59 = 6,008 points
```

**Result:** Exceeds target by 72% → earns **+5 Gold** + advances to Round 13.

---

### Scenario C: Glass Cannon Desperation (Late Game)

**Setup:**
- Round 25
- Target: 15,000 points
- Player has: Glass Cannon (Tier 5), Overkill (Tier 4)
- **HP = 1** (one hit from death!)
- Current streak: 18
- Overkill bonus from previous round: +500 chips

**Move 1:**
- Place 2×2 Square (Red)
- Completes 2 lines: both **Red Flush**
- Neighbors: 5

**Calculation:**
```
BaseChips = (4 × 10) + (5 × 5) + 500 (Overkill) = 565

Detection:
  Flush 1 → +8.0
  Flush 2 → +8.0
  Super Flush bonus → +20.0

Combo:
  2-line Double → +2.0

Total Additive: 1.0 + 38.0 = 39.0

X-Mult:
  Streak 18 → 1.1^18 = 5.56
  Glass Cannon (HP=1) → ×2.5

  Total X: 5.56 × 2.5 = 13.9

Score = 565 × 39.0 × 13.9 = 306,471 points (!!)
```

**Result:** **Massive overkill** (2,043% over target!) → earns **+20 Gold + Diamond drop chance!**

---

## 🎯 CONCLUSION

This scoring system achieves:

✅ **Strategic Depth:** Color composition, placement density, and perk order all matter.  
✅ **Exponential Scaling:** Combo stacking + streak bonuses create explosive moments.  
✅ **Clear Feedback:** Every phase has distinct visual/audio cues.  
✅ **Replayability:** 11 perks × 5 tiers = 55 upgrade paths to explore.  
✅ **Balance:** Early game teaches basics, late game rewards mastery.

**Next Steps:**
1. Implement `ScoreEngine` in Swift
2. Build UI animation library for each phase
3. Playtest and tune multiplier values
4. Add analytics to track average scores per round

---

**Document Version:** 3.0 Production  
**Last Updated:** 2026-04-30  
**Status:** Ready for Implementation ✅
