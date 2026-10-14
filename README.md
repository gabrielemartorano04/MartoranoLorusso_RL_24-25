# ⚡ Differential Filter in VHDL — Logic Networks Final Project (A.Y. 2024–2025)

Hardware design project developed for the **Logic Networks Final Project** (*Prova Finale - Progetto di Reti Logiche*) course at **Politecnico di Milano**.

* **University:** Politecnico di Milano — Department of Electronics, Information and Bioengineering (DEIB)
* **Professors:** Prof. William Fornaciari, Prof. Gianluca Palermo, Prof. Fabio Salice[span_2](start_span)[span_2](end_span)[span_3](start_span)[span_3](end_span)
* **Authors:** [Martorano Gabriele](https://github.com/gabrielemartorano04) & [Luca Lorusso](https://github.com/Luc4Lo)[span_4](start_span)[span_4](end_span)[span_5](start_span)[span_5](end_span)
* **Final Grade:** 30 / 30[span_6](start_span)[span_6](end_span)
* **Hardware Description Language:** VHDL
* **Synthesis & Simulation Toolchain:** Xilinx Vivado Webpack (Target FPGA: Xilinx Artix-7 `xc7a200tfbg484-1`, Target Clock Period: $\ge 20\text{ ns}$)[span_7](start_span)[span_7](end_span)

---

## 📋 Problem Description

The objective of the project is to design and synthesize a synchronous hardware component in VHDL (`project_reti_logiche`) that interfaces with a 64 KB Single-Port Block RAM to process a sequence of $K$ signed 8-bit samples ($W$) through a configurable **differential filter** (of **Order 3** or **Order 5**) over a 7-element sliding window, writing the resulting $K$ filtered 8-bit bytes ($R$) back into memory[span_8](start_span)[span_8](end_span)[span_9](start_span)[span_9](end_span)[span_10](start_span)[span_10](end_span).

### Memory Layout

All configuration parameters, input samples, and output results are stored sequentially in a byte-addressable memory (16-bit address space, $2^{16} = 65536\text{ bytes}$) starting from a base address `ADD` (`i_add`) provided by the testbench[span_11](start_span)[span_11](end_span)[span_12](start_span)[span_12](end_span):

| Address Offset | Symbol | Size | Description |
| :--- | :--- | :--- | :--- |
| `ADD + 0` | `K1` | 1 byte | Most Significant Byte (MSB) of sequence length $K$[span_13](start_span)[span_13](end_span)[span_14](start_span)[span_14](end_span) |
| `ADD + 1` | `K2` | 1 byte | Least Significant Byte (LSB) of sequence length $K$ ($7 \le K \le 32759$)[span_15](start_span)[span_15](end_span)[span_16](start_span)[span_16](end_span)[span_17](start_span)[span_17](end_span) |
| `ADD + 2` | `S` | 1 byte | Filter selector: `S(0) = '0'` selects **Order 3**; `S(0) = '1'` selects **Order 5**[span_18](start_span)[span_18](end_span)[span_19](start_span)[span_19](end_span) |
| `ADD + 3 .. ADD + 9` | `C0 .. C6` | 7 bytes | Signed 8-bit coefficients for the **Order 3** filter (e.g., `[0, -1, 8, 0, -8, 1, 0]`)[span_20](start_span)[span_20](end_span)[span_21](start_span)[span_21](end_span) |
| `ADD + 10 .. ADD + 16` | `C0 .. C6` | 7 bytes | Signed 8-bit coefficients for the **Order 5** filter (e.g., `[1, -9, 45, 0, -45, 9, -1]`)[span_22](start_span)[span_22](end_span)[span_23](start_span)[span_23](end_span) |
| `ADD + 17 .. ADD + 16 + K` | `W` | $K$ bytes | Input sequence of $K$ signed 8-bit words in two's complement (`[-128, +127]`)[span_24](start_span)[span_24](end_span)[span_25](start_span)[span_25](end_span) |
| `ADD + 17 + K .. ADD + 16 + 2K` | `R` | $K$ bytes | Output sequence of $K$ filtered signed 8-bit words (`[-128, +127]`)[span_26](start_span)[span_26](end_span)[span_27](start_span)[span_27](end_span)[span_28](start_span)[span_28](end_span) |

---

## 🧮 Mathematical Formulation & Hardware Approximation

### 1. Differential Filter Convolution
For each sample $i \in \{0, \dots, K-1\}$, the filter computes a weighted sum over a symmetric sliding window of radius $l$ ($l = 2$ with normalization factor $n = 12$ for **Order 3**; $l = 3$ with normalization factor $n = 60$ for **Order 5**):

$$f'(i) = \frac{1}{n} \sum_{j=-l}^{+l} C(j) \cdot f(i + j)$$[span_29](start_span)[span_29](end_span)[span_30](start_span)[span_30](end_span)

Out-of-bounds samples at the beginning and at the end of the sequence ($i + j < 0$ or $i + j \ge K$) are treated as `0` (zero-padding)[span_31](start_span)[span_31](end_span).

### 2. Division via Arithmetic Right Shifts
To avoid expensive hardware dividers, normalization by $12$ and $60$ is approximated via sums of arithmetic right shifts (`shift_right`)[span_32](start_span)[span_32](end_span)[span_33](start_span)[span_33](end_span):

* **Order 3 Filter ($\div 12 \approx \frac{1}{16} + \frac{1}{64} + \frac{1}{256} + \frac{1}{1024}$):**[span_34](start_span)[span_34](end_span)[span_35](start_span)[span_35](end_span)

  $$\text{r} = (\text{sum} \gg 4) + (\text{sum} \gg 6) + (\text{sum} \gg 8) + (\text{sum} \gg 10) + \text{corr}$$[span_36](start_span)[span_36](end_span)[span_37](start_span)[span_37](end_span)

* **Order 5 Filter ($\div 60 \approx \frac{1}{64} + \frac{1}{1024}$):**[span_38](start_span)[span_38](end_span)[span_39](start_span)[span_39](end_span)

  $$\text{r} = (\text{sum} \gg 6) + (\text{sum} \gg 10) + \text{corr}$$[span_40](start_span)[span_40](end_span)[span_41](start_span)[span_41](end_span)

Because an arithmetic right shift on a negative two's complement number rounds toward $-\infty$ (introducing a $-1$ truncation error per shift instead of rounding toward zero), a positive correction term $\text{corr}$ is added whenever $\text{sum} < 0$[span_42](start_span)[span_42](end_span)[span_43](start_span)[span_43](end_span):
* $\text{corr} = +4$ for **Order 3** (compensating 4 shifts)[span_44](start_span)[span_44](end_span)[span_45](start_span)[span_45](end_span)
* $\text{corr} = +2$ for **Order 5** (compensating 2 shifts)[span_46](start_span)[span_46](end_span)[span_47](start_span)[span_47](end_span)
* $\text{corr} = 0$ whenever $\text{sum} \ge 0$[span_48](start_span)[span_48](end_span)[span_49](start_span)[span_49](end_span)

### 3. Output Saturation
Each normalized result $\text{r}$ is clamped to the signed 8-bit representable range `[-128, +127]` before being written to memory[span_50](start_span)[span_50](end_span)[span_51](start_span)[span_51](end_span):
* If $\text{r} > 127 \implies R(i) = 127$[span_52](start_span)[span_52](end_span)[span_53](start_span)[span_53](end_span)
* If $\text{r} < -128 \implies R(i) = -128$[span_54](start_span)[span_54](end_span)[span_55](start_span)[span_55](end_span)

---

## 🔌 Component Interface & Protocol

```vhdl
entity project_reti_logiche is
    port (
        i_clk      : in  std_logic;
        i_rst      : in  std_logic;
        i_start    : in  std_logic;
        i_add      : in  std_logic_vector(15 downto 0);
        o_done     : out std_logic;
        o_mem_addr : out std_logic_vector(15 downto 0);
        i_mem_data : in  std_logic_vector(7 downto 0);
        o_mem_data : out std_logic_vector(7 downto 0);
        o_mem_we   : out std_logic;
        o_mem_en   : out std_logic
    );
end project_reti_logiche;
```

* **Asynchronous Reset (`i_rst`):** When `i_rst = '1'`, the FSM immediately resets to the `INIT` state and drives `o_done <= '0'`[span_56](start_span)[span_56](end_span)[span_57](start_span)[span_57](end_span).
* **Start / Done Handshake (`i_start`, `o_done`):** Computation begins on the rising edge of `i_clk` when `i_start = '1'`. Once all $K$ filtered bytes have been written to memory, the module asserts `o_done = '1'` and keeps it high until the testbench deasserts `i_start = '0'`. As soon as `i_start` returns to `'0'`, `o_done` is lowered to `'0'` and the module is ready for a new run without requiring an external reset[span_58](start_span)[span_58](end_span)[span_59](start_span)[span_59](end_span).

---

## 🧠 Architecture & Design Choices

The component is implemented as a synchronous **Finite State Machine (FSM)** structured around 7 states[span_60](start_span)[span_60](end_span):

1. **`INIT`**: Waits for `i_start = '1'`, initializes internal counters (`index`, `step`) and the sliding window register `w`, enables memory read access (`o_mem_en = '1'`, `o_mem_we = '0'`), and requests the first configuration byte at `i_add`[span_61](start_span)[span_61](end_span).
2. **`CONFIG`**: Sequentially reads `K1`, `K2`, and `S`. Depending on `S(0)`, fetches either the 7 coefficients of the Order 3 filter (`ADD + 3 .. ADD + 9`) or those of the Order 5 filter (`ADD + 10 .. ADD + 16`), storing them in `c0 .. c6`[span_62](start_span)[span_62](end_span)[span_63](start_span)[span_63](end_span).
3. **`READ`**: Manages the 7-byte sliding window stored in a compact **56-bit shift register** (`w : std_logic_vector(55 downto 0)`). On the first iteration, it preloads the first 4 bytes into the lower half of `w` (leaving the upper 3 bytes at `0` for left-boundary zero-padding). On subsequent iterations, `w` is shifted left by 8 bits (`shift_left`) and either loads the next sample from memory (`step = 8`) or shifts in zeros (`step = 11`) when reaching the right boundary of the sequence[span_64](start_span)[span_64](end_span)[span_65](start_span)[span_65](end_span).
4. **`FILTER`**: Splits arithmetic across two clock steps (`step = 12` and `step = 13`) to keep the critical path short and well within the $20\text{ ns}$ clock budget[span_66](start_span)[span_66](end_span)[span_67](start_span)[span_67](end_span):
   * `step = 12`: Computes the linear combination `sum` over **18-bit signed arithmetic** (`std_logic_vector(17 downto 0)`). Using 18 bits prevents overflow even in the absolute worst case ($7 \times 127 \times (-128) = -113792$, which exceeds 17-bit signed representation)[span_68](start_span)[span_68](end_span)[span_69](start_span)[span_69](end_span).
   * `step = 13`: Applies the shift-add division approximation, negative truncation compensation, and clamping to `[-128, +127]`[span_70](start_span)[span_70](end_span).
5. **`WRITE`**: Writes the 8-bit saturated result `r(7 downto 0)` to memory at address `i_add + 17 + K + index` (`o_mem_en = '1'`, `o_mem_we = '1'`) and updates `index`. Transitions back to `READ` if `index < K - 1`, or to `DONE` once the last byte is written[span_71](start_span)[span_71](end_span).
6. **`DONE`**: Disables memory signals (`o_mem_en = '0'`, `o_mem_we = '0'`), asserts `o_done = '1'`, and moves to `WAIT_START`[span_72](start_span)[span_72](end_span).
7. **`WAIT_START`**: Waits for `i_start = '0'`, lowers `o_done = '0'`, and returns to `INIT`[span_73](start_span)[span_73](end_span).

---

## 📊 Synthesis & Timing Results

The design was synthesized in **Xilinx Vivado** without errors, warnings, or inferred latches, confirming fully deterministic synchronous behavior[span_74](start_span)[span_74](end_span)[span_75](start_span)[span_75](end_span)[span_76](start_span)[span_76](end_span).

### Resource Utilization
| Resource | Used | Available | Utilization % |
| :--- | :--- | :--- | :--- |
| **Slice LUTs** | 936 | 8,000 | 11.70%[span_77](start_span)[span_77](end_span)[span_78](start_span)[span_78](end_span) |
| **Slice Registers (Flip-Flops)** | 222 | 16,000 | 1.39%[span_79](start_span)[span_79](end_span)[span_80](start_span)[span_80](end_span) |
| **Bonded IOBs (I/O Pins)** | 54 | 150 | 36.00%[span_81](start_span)[span_81](end_span)[span_82](start_span)[span_82](end_span) |
| **Inferred Latches** | 0 | — | 0.00%[span_83](start_span)[span_83](end_span) |

### Timing Summary (Target Clock = 20.000 ns)[span_84](start_span)[span_84](end_span)[span_85](start_span)[span_85](end_span)
| Metric | Value | Status |
| :--- | :--- | :--- |
| **Worst Negative Slack (WNS)** | `+7.058 ns` | Met (0 failing endpoints)[span_86](start_span)[span_86](end_span)[span_87](start_span)[span_87](end_span) |
| **Critical Path Delay** | `12.942 ns` | Met ($< 20\text{ ns}$)[span_88](start_span)[span_88](end_span)[span_89](start_span)[span_89](end_span) |
| **Worst Hold Slack (WHS)** | `+0.150 ns` | Met (0 failing endpoints)[span_90](start_span)[span_90](end_span)[span_91](start_span)[span_91](end_span) |
| **Worst Pulse Width Slack (WPWS)** | `+9.500 ns` | Met (0 failing endpoints)[span_92](start_span)[span_92](end_span)[span_93](start_span)[span_93](end_span) |

---

## 🧪 Verification & Corner Cases Tested

The component was validated in both **Pre-Synthesis (Behavioral)** and **Post-Synthesis (Functional & Timing)** simulations against official and custom corner-case scenarios (documented in `report.pdf`)[span_94](start_span)[span_94](end_span)[span_95](start_span)[span_95](end_span):

* **Order 3 & Order 5 Filter Selection:** Verified dynamic selection of filter order (`S(0) = '0'` and `S(0) = '1'`) and custom filter coefficients loaded from memory[span_96](start_span)[span_96](end_span).
* **Minimum Sequence Length ($K = 7$):** Verified boundary handling and zero-padding on the shortest valid sequence length[span_97](start_span)[span_97](end_span).
* **Maximum Sequence Length ($K = 32759$):** Verified full-memory addressing capacity ($17 + 2K \le 65536 \implies K \le 32759$)[span_98](start_span)[span_98](end_span).
* **Arithmetic Overflow & Saturation Limits:** Tested extreme combinations of coefficients (`127`) and inputs (`-128`) reaching intermediate sums of $\pm 113792$ to verify 18-bit accumulator safety and saturation to `[-128, +127]`[span_99](start_span)[span_99](end_span).
* **Multiple Consecutive Runs & Asynchronous Resets:** Verified back-to-back executions without intermediate resets, as well as mid-computation asynchronous `i_rst` assertions[span_100](start_span)[span_100](end_span).

---

## 📁 Repository Structure

```text
.
├── project_RL.vhd   # VHDL source code of the hardware component
├── report.pdf       # Full project documentation and synthesis report (Italian)
└── README.md        # Project overview
```

---

## 🚀 How to Synthesize and Simulate in Xilinx Vivado

1. Open **Xilinx Vivado** and create a new RTL Project targeting an Artix-7 FPGA (e.g., `xc7a200tfbg484-1`)[span_101](start_span)[span_101](end_span).
2. Add `project_RL.vhd` as a **Design Source**.
3. Create or import your custom VHDL testbench instantiating `project_reti_logiche` alongside the standard Vivado 64 KB Single-Port Block RAM template (`rams_sp_wf`) as a **Simulation Source**[span_102](start_span)[span_102](end_span)[span_103](start_span)[span_103](end_span).
4. **Behavioral Simulation (Pre-Synthesis):**
   * In the *Flow Navigator*, click **Simulation → Run Simulation → Run Behavioral Simulation**.
5. **Post-Synthesis Simulation:**
   * Define a clock constraint of `20 ns` (`create_clock -period 20.000 -name clk [get_ports i_clk]`)[span_104](start_span)[span_104](end_span).
   * Click **Synthesis → Run Synthesis**.
   * Once synthesis completes, click **Simulation → Run Simulation → Run Post-Synthesis Functional Simulation** (or **Timing Simulation**).
