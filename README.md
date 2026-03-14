# PWM Controller — Verilog

8-bit PWM generator with double-buffered registers, error detection, and edge-detected write strobes. Designed for FPGA (100 MHz input clock), with a slow clock divider that makes the output visible on an LED.

---

## Module hierarchy

```
top_pwm
├── one_period   (edge detector on wr)
└── pwm          (core PWM generator)
```

---

## Files

| File | Description |
|------|-------------|
| `rtl/top_pwm.v` | Top-level: clock divider, write-strobe edge detection, module wiring |
| `rtl/pwm.v` | Core PWM generator with double-buffered registers and error detection |
| `rtl/one_period.v` | Rising-edge detector — outputs a single-clock pulse on each rising edge of `din` |
| `sim/tb_pwm.v` | Testbench: three scenarios (normal, duty change, error condition) |

---

## How it works

### Clock divider (`top_pwm`)

The 100 MHz input clock is divided down by a 26-bit counter:

```
100 MHz → ÷10,000,000 → 10 Hz toggle → PWM clock = 10 Hz
```

With `reg_per = 10`, one full PWM period = 1 second — visible on an LED without any extra hardware.

### Write interface (`pwm`)

Registers are written by asserting `wr = 1` along with a selector signal:

| `wr` | `per` | `high` | Effect |
|------|-------|--------|--------|
| 1 | 1 | 0 | Write `di` → `reg_per` |
| 1 | 0 | 1 | Write `di` → `reg_high` |
| 0 | x | x | No write |

### Double-buffering

Values written via `di` land in the **interface registers** (`reg_per`, `reg_high`) immediately. They are only transferred to the **active registers** (`reg_per_current`, `reg_high_current`) at the end of the current period. This prevents glitches mid-cycle when changing duty cycle or period on the fly.

```
Write          Period end
  │                │
  ▼                ▼
reg_per  ──────►  reg_per_current  ──►  counter compare
reg_high ──────►  reg_high_current ──►  pwm_out
```

### PWM output

```
pwm_out = (pwm_counter < reg_high_current)
```

The counter runs from `0` to `reg_per_current − 1`. Output is high for the first `reg_high_current` ticks, low for the rest.

**Duty cycle** = `reg_high / reg_per` × 100%

### Error detection

If `reg_high > reg_per` is detected at reload time, `error_out` is asserted for `reg_per − 1` clock cycles. This is a single pulse, not a latched flag.

### Write-strobe edge detection (`one_period`)

`wr` comes from a physical button running at board speed. Without edge detection, a single press would appear as thousands of write cycles to the slow 10 Hz PWM clock. `one_period` converts any asserted `wr` into exactly one slow-clock-wide pulse.

```
wr (button):   0  0  1  1  1  1  0
wr_sync:       0  0  1  0  0  0  0
                      └── one write
```

---

## Port reference

### `top_pwm`

| Port | Dir | Width | Description |
|------|-----|-------|-------------|
| `clk` | in | 1 | 100 MHz board clock |
| `reset` | in | 1 | Synchronous active-high reset |
| `wr` | in | 1 | Write strobe (from button) |
| `high` | in | 1 | Selects `reg_high` for write |
| `per` | in | 1 | Selects `reg_per` for write |
| `di[7:0]` | in | 8 | Data input |
| `di_switch[7:0]` | out | 8 | Passthrough of `di` (for display) |
| `pwm_out` | out | 1 | PWM output signal |
| `error_out` | out | 1 | High when `reg_high > reg_per` |

### `pwm`

Same ports as `top_pwm` except `clk` is the divided slow clock, and `wr` is the edge-detected strobe.

### `one_period`

| Port | Dir | Width | Description |
|------|-----|-------|-------------|
| `clk` | in | 1 | Clock |
| `reset` | in | 1 | Synchronous active-high reset |
| `din` | in | 1 | Input signal |
| `dout` | out | 1 | Single-cycle pulse on rising edge of `din` |

---

## Testbench scenarios

The testbench (`sim/tb_pwm.v`) runs three back-to-back scenarios on a 100 MHz simulation clock:

| Scenario | `reg_per` | `reg_high` | Expected |
|----------|-----------|------------|----------|
| 1 — Normal | 10 | 4 | `pwm_out` at 40% duty, `error_out` = 0 |
| 2 — Duty change | 10 | 7 | `pwm_out` at 70% duty, reload on next period |
| 3 — Error | 8 | 12 | `error_out` pulses once, `pwm_out` continues |

To run in Vivado:

1. Add `sim/tb_pwm.v` and all `rtl/*.v` files as simulation sources.
2. Set `tb_pwm` as the top simulation module.
3. Run behavioral simulation and open the waveform viewer.
4. Add `clk`, `reset`, `wr`, `high`, `per`, `di[7:0]`, `pwm_out`, `error_out` to the waveform window.

---

## Known limitations

- `slow_clock` is generated in fabric logic, not through a dedicated clock buffer or PLL. Synthesis tools may issue a clock-domain warning. For a production design, replace the counter-based divider with an MMCM/PLL primitive, or use the divided signal as a clock enable on the main clock.
- `high` and `per` inputs are not double-synchronized into the slow clock domain. At 10 Hz this is not a practical issue, but the synchronizer instances (`high_sync_inst`, `per_sync_inst`) are stubbed out in `top_pwm.v` and should be completed for a robust design.
- The testbench drives signals on `posedge clk` without a post-edge delay, creating a race condition with the DUT sampler. Add `#1` after each `@(posedge clk)` in `write_reg` before using the testbench for regression.

---

## Parameter summary

| Parameter | Value | Notes |
|-----------|-------|-------|
| Data width | 8 bits | Max period = 255 ticks, max high = 255 ticks |
| Clock divider | 10,000,000 | Gives 10 Hz PWM clock from 100 MHz input |
| Max PWM frequency | 10 Hz ÷ `reg_per` | At `reg_per = 10` → 1 Hz output |
| Error pulse width | `reg_per − 1` cycles | Single pulse, not latched |
