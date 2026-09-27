# Changelog
## Autonomous Vehicle V2V Communication Simulator

All notable changes and architectural additions to this project are documented below.

---

### [v2.0.0] - Complete NS-2 Engine & Pure Tcl/AWK/Gnuplot Suite
- **Pure Tcl Protocol Modules**:
  - Implemented `distance_vector.tcl` with Bellman-Ford equation and Poison Reverse.
  - Implemented `crc.tcl` with bitwise modulo-2 polynomial division for CRC-16 and CRC-32.
  - Implemented `sliding_window.tcl` with flow control buffer invariants and window shifting.
  - Implemented `gobackn.tcl` with discrete-event retransmission and forced loss injection.
  - Implemented `congestion.tcl` with active AIMD rate adaptation.
- **Unified Master Engine**:
  - Created `v2v_main.tcl` and `run_final.sh` supporting CLI flags (`--vehicles`, `--routing`, `--loss`, `--window`).
- **Zero-Python Simulation & Analytics Pipeline**:
  - Created `analysis/metrics_collector.awk` to parse NS-2 `.tr` traces into structured CSV datasets.
  - Created `run_experiments.sh` executing all 12 experimental scenarios.
  - Created `analysis/plot_all_graphs.gp` and `generate_graphs.sh` generating all 12 publication charts with Gnuplot.
- **Master Orchestrator**:
  - Built `run_all.sh` executing unit tests, simulations, trace parsing, and graph generation, outputting the standardized execution summary banner.
- **Complete Academic Documentation**:
  - Created `ALGORITHMS.md`, `EXPERIMENTS.md`, `RESULTS.md`, `DEMO.md`, `VIVA.md` (50+ questions), `PROJECT_REPORT.md` (16 chapters), and `FINAL_AUDIT.md`.

---

### [v1.0.0] - Foundation & Dijkstra Implementation
- Initialized NS-2 simulation framework (`basic_v2v.tcl`, `config.tcl`, `run_basic.sh`).
- Implemented `dijkstra.tcl` Link-State routing engine and verified against canonical reference graph (`dijkstra_test.tcl`).
- Created initial project roadmap (`PROJECT_PLAN.md`).
