import json
from pathlib import Path
from collections import defaultdict

def analyze():
    # 1. Analyze 100-item full run
    with open('results/baseline_final_20261001_020033/pass_rate_report.json', encoding='utf-8') as f:
        pass_report = json.load(f)

    with open('results/baseline_final_20261001_020033/tool_calls_report.json', encoding='utf-8') as f:
        tc_report = json.load(f)

    with open('Full-Duplex-Bench/v3/benchmark_data_v2.json', encoding='utf-8') as f:
        bench = json.load(f)
        if 'scenarios' in bench:
            bench_map = {s['id']: s for s in bench['scenarios']}
        else:
            bench_map = {s['id']: s for s in bench}

    # Map tc_report by scenario_id
    tc_map = {s['scenario_id']: s for s in tc_report['scenario_results']}

    print("=" * 80)
    print("100-ITEM BENCHMARK ERROR ANALYSIS")
    print("=" * 80)

    # By Chain Length (num_tools: 1, 2, 3)
    chain_stats = defaultdict(lambda: {'total': 0, 'pass': 0, 'exp_tools': 0, 'act_tools': 0, 'matched': 0, 'unmatched': 0, 'unexpected': 0})
    for sc in pass_report['scenario_results']:
        sc_id = sc['scenario_id']
        n = sc.get('num_tools', 1)
        tc_data = tc_map.get(sc_id, {}).get('metrics', {}).get('tool_selection_acc', {})
        chain_stats[n]['total'] += 1
        if sc.get('passed'):
            chain_stats[n]['pass'] += 1
        chain_stats[n]['exp_tools'] += tc_data.get('total_expected', 0)
        chain_stats[n]['act_tools'] += tc_data.get('total_actual', 0)
        chain_stats[n]['matched'] += tc_data.get('matched', 0)
        chain_stats[n]['unmatched'] += len(tc_data.get('unmatched_expected', []))
        chain_stats[n]['unexpected'] += len(tc_data.get('unexpected_calls', []))

    print("\n--- PERFORMANCE BY CHAIN LENGTH (1, 2, 3 Tool Calls) ---")
    print(f"{'Chain Len':<10} | {'Total':<6} | {'Pass Rate':<10} | {'Recall':<8} | {'Precision':<10} | {'F1':<6} | {'Missing Tools':<14} | {'Extra Tools':<12}")
    for n in sorted(chain_stats.keys()):
        s = chain_stats[n]
        pr = s['pass'] / s['total'] if s['total'] else 0
        rec = s['matched'] / s['exp_tools'] if s['exp_tools'] else 0
        prec = s['matched'] / s['act_tools'] if s['act_tools'] else 0
        f1 = (2 * rec * prec / (rec + prec)) if (rec + prec) else 0
        print(f"{n:<10} | {s['total']:<6} | {pr*100:5.1f}%    | {rec:6.3f} | {prec:8.3f}  | {f1:5.3f}| {s['unmatched']:<14} | {s['unexpected']:<12}")

    # By Disfluency Type
    disfluency_types = ['SELF_CORRECTION', 'FALSE_START', 'FILLER', 'PAUSE', 'HESITATION']
    disf_stats = defaultdict(lambda: {'total': 0, 'pass': 0, 'exp_tools': 0, 'act_tools': 0, 'matched': 0, 'unmatched': 0, 'unexpected': 0})
    
    for sc in pass_report['scenario_results']:
        sc_id = sc['scenario_id']
        meta = bench_map.get(sc_id, {})
        features = meta.get('disfluency_features', [])
        tc_data = tc_map.get(sc_id, {}).get('metrics', {}).get('tool_selection_acc', {})
        
        # If no features, could be clean
        applied_features = [f for f in disfluency_types if f in features]
        if not applied_features:
            applied_features = ['CLEAN / NONE']

        for df in applied_features:
            disf_stats[df]['total'] += 1
            if sc.get('passed'):
                disf_stats[df]['pass'] += 1
            disf_stats[df]['exp_tools'] += tc_data.get('total_expected', 0)
            disf_stats[df]['act_tools'] += tc_data.get('total_actual', 0)
            disf_stats[df]['matched'] += tc_data.get('matched', 0)
            disf_stats[df]['unmatched'] += len(tc_data.get('unmatched_expected', []))
            disf_stats[df]['unexpected'] += len(tc_data.get('unexpected_calls', []))

    print("\n--- PERFORMANCE BY DISFLUENCY TYPE ---")
    print(f"{'Disfluency':<16} | {'Total':<6} | {'Pass Rate':<10} | {'Recall':<8} | {'Precision':<10} | {'F1':<6} | {'Missing Tools':<14} | {'Extra Tools':<12}")
    for df in disfluency_types + ['CLEAN / NONE']:
        if df in disf_stats:
            s = disf_stats[df]
            pr = s['pass'] / s['total'] if s['total'] else 0
            rec = s['matched'] / s['exp_tools'] if s['exp_tools'] else 0
            prec = s['matched'] / s['act_tools'] if s['act_tools'] else 0
            f1 = (2 * rec * prec / (rec + prec)) if (rec + prec) else 0
            print(f"{df:<16} | {s['total']:<6} | {pr*100:5.1f}%    | {rec:6.3f} | {prec:8.3f}  | {f1:5.3f}| {s['unmatched']:<14} | {s['unexpected']:<12}")

    # Check the 15-item partial run specifically to answer question 6:
    # "Recall of 0.611 means tool calls are being missed; find out whether that happens mostly on chains or on corrections."
    print("\n" + "=" * 80)
    print("ANALYSIS OF THE 15-ITEM PARTIAL RUN (Recall = 0.611)")
    print("=" * 80)
    try:
        with open('logs/gemini2_5_summary_metrics.json', encoding='utf-8') as f:
            p15 = json.load(f)
        failures_15 = p15.get('failure_analysis', {})
        print("Failures in 15-item run:")
        for fid, finfo in failures_15.items():
            base_id = fid.replace('FAIL_', '').split('_speaker_')[0]
            meta = bench_map.get(base_id, {})
            print(f"  - {fid}: expected={finfo['expected']}, num_tools={meta.get('num_expected_calls', len(finfo['expected']))}, features={meta.get('disfluency_features')}, rollback={meta.get('state_rollback_test')}")
    except Exception as e:
        print("Could not load 15-item log:", e)

if __name__ == '__main__':
    analyze()
