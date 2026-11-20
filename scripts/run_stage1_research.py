#!/usr/bin/env python3
"""
OKX-Dog Stage 1 量化投研与验证底座一键运行脚本
模块: scripts/run_stage1_research.py

功能:
1. 从 OKX 实盘公共历史接口拉取 Top 5 标的 (BTC/ETH/SOL/BNB/DOGE) 近 3 年 (1095 天)
   真实 4H / 1D 永续与现货 K 线及全量 8h 历史资金费率，落盘本地 SQLite 数据湖；
2. 驱动三位一体 BacktestEngine 执行 3 年组合回测、滚动样本外 Walk-Forward 检验与 ±20% 参数平原门禁；
3. 自动将全部实验结果持久化至 backtest_experiments 表，并输出清晰的 Gate 1 / Gate 2 验收报表。

用法:
  .agents/auditor_r2/venv/bin/python3 scripts/run_stage1_research.py --sync --wf
  .agents/auditor_r2/venv/bin/python3 scripts/run_stage1_research.py --wf-only
"""

from __future__ import annotations

import argparse
import asyncio
import json
import logging
import os
import sys

ROOT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
BACKEND_DIR = os.path.join(ROOT_DIR, "okx-dog-backend")
AI_DIR = os.path.join(ROOT_DIR, "okx-dog-ai")

if BACKEND_DIR not in sys.path:
    sys.path.insert(0, BACKEND_DIR)
if AI_DIR not in sys.path:
    sys.path.append(AI_DIR)

from config import settings
from database import init_db
from okx_rest import OKXRestClient
from services.data_lake_service import DataLakeService
from services.backtest_engine import BacktestEngine

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger("okx_dog.stage1")


async def main():
    parser = argparse.ArgumentParser(description="OKX-Dog Stage 1 3年数据湖同步与 Walk-Forward 样本外验证")
    parser.add_argument("--sync", action="store_true", help="同步 Top 5 永续+现货 3 年历史 K 线与 8h 资金费率")
    parser.add_argument("--wf", action="store_true", help="运行 3 年组合回测与滚动样本外 Walk-Forward 门禁")
    parser.add_argument("--days", type=int, default=1095, help="回溯天数 (默认 1095 天 ≈ 3 年)")
    parser.add_argument("--timeframes", nargs="+", default=["4h", "1d"], help="同步周期列表 (默认 4h 1d)")
    parser.add_argument("--no-spot", action="store_true", help="跳过现货 K 线同步")
    args = parser.parse_args()

    if not args.sync and not args.wf:
        args.sync = True
        args.wf = True

    await init_db()
    rest_client = OKXRestClient(is_live_mode=False)
    data_lake = DataLakeService(rest_client)
    bt_engine = BacktestEngine(data_lake)

    try:
        if args.sync:
            logger.info("=" * 70)
            logger.info(f"阶段 1.1: 同步 Top 5 标的近 {args.days} 天真实 OKX 历史数据 ({args.timeframes})")
            logger.info("=" * 70)
            sync_summary = await data_lake.sync_core_universe(
                days_back=args.days,
                timeframes=args.timeframes,
                include_spot=(not args.no_spot),
            )
            print("\n=== 数据湖同步汇总 ===")
            for sym, info in sync_summary.items():
                print(
                    f"  {sym:<16} | K线写入={info['details']} | "
                    f"真实8h资金费率={info['real_funding_rates_matched']} 条"
                )
            status = await data_lake.get_data_lake_status()
            print(f"  数据湖总计落盘 K 线: {status.total_klines} 根 ({len(status.items)} 组序列)\n")

        if args.wf:
            symbols = list(settings.CORE_TRADING_UNIVERSE)
            logger.info("=" * 70)
            logger.info("阶段 1.2: 3年真实历史基准回测 + Walk-Forward 样本外门禁检验")
            logger.info("=" * 70)

            # 1. 基线对照: 旧 EMA_BREAKOUT (4H)
            ema_bench = await bt_engine.run_portfolio_backtest(
                symbols=symbols,
                timeframe="4h",
                strategy_name="EMA_BREAKOUT",
                params={"fast_period": 20, "slow_period": 50, "atr_multiplier": 2.0},
                days_back=args.days,
                initial_balance=6000.0,
                leverage=3,
            )
            print("\n=== [基准对照] EMA_BREAKOUT (4H · 3年组合) ===")
            print(
                f"  终值=${ema_bench['final_balance']} ({ema_bench['total_return_pct']:+.2f}%, "
                f"CAGR={ema_bench['annualized_return_pct']:+.2f}%), "
                f"Sharpe={ema_bench['sharpe_ratio']}, MaxDD={ema_bench['max_drawdown_pct']}%, "
                f"PF={ema_bench['profit_factor']}, WR={ema_bench['win_rate']*100:.1f}%, "
                f"笔数={ema_bench['total_trades']}, 手续费=${ema_bench['total_fee_paid']}, "
                f"资金费=${ema_bench['total_funding_cost']}"
            )

            # 2. 主引擎 B 候选: DONCHIAN_TREND (4H & 1D Walk-Forward)
            for tf in ("4h", "1d"):
                grid = (
                    [
                        {"entry_n": en, "exit_n": ex, "atr_sl_mult": am, "trend_ema": te, "risk_pct": 0.01}
                        for en in (24, 36, 48)
                        for ex in (12, 18)
                        for am in (2.5, 3.0, 3.5)
                        for te in (0, 100)
                    ]
                    if tf == "4h"
                    else [
                        {"entry_n": en, "exit_n": ex, "atr_sl_mult": am, "trend_ema": te, "risk_pct": 0.01}
                        for en in (15, 20, 30)
                        for ex in (7, 10)
                        for am in (2.5, 3.0, 3.5)
                        for te in (0, 50)
                    ]
                )
                wf_res = await bt_engine.run_walk_forward(
                    symbols=symbols,
                    timeframe=tf,
                    strategy_name="DONCHIAN_TREND",
                    param_grid=grid,
                    days_back=args.days,
                    train_days=365,
                    test_days=90,
                    step_days=90,
                    initial_balance=6000.0,
                    leverage=3,
                )
                print(f"\n=== [Walk-Forward 样本外] DONCHIAN_TREND ({tf.upper()} · {wf_res['folds_count']} Folds) ===")
                print(
                    f"  OOS 终值=${wf_res['oos_final_balance']} ({wf_res['oos_total_return_pct']:+.2f}%, "
                    f"CAGR={wf_res['oos_cagr_pct']:+.2f}%), "
                    f"Sharpe={wf_res['oos_sharpe']}, MaxDD={wf_res['oos_max_drawdown_pct']}%, "
                    f"PF={wf_res['oos_profit_factor']}, WR={wf_res['oos_win_rate']*100:.1f}%, "
                    f"笔数={wf_res['oos_total_trades']}, 手续费=${wf_res['oos_total_fee_paid']}"
                )
                print(f"  锚点参数: {wf_res['anchor_params']} | ±20% 邻域 PF: {wf_res['neighbor_pfs']}")
                print(f"  生存门禁: {json.dumps(wf_res['plateau_score'], ensure_ascii=False)}")
                print(f"  Gate 2A 逐项判定: {json.dumps(wf_res['gate2_checks'], ensure_ascii=False)}")
                print(f"  >>> Gate 2A 总结论: {'✅ PASS' if wf_res['passed_gate2'] else '❌ 未达标 (需在 Stage 2A 迭代优化)'}")
    finally:
        await rest_client.close()


if __name__ == "__main__":
    asyncio.run(main())
