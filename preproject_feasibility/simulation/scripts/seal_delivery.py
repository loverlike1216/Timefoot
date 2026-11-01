from pathlib import Path
from datetime import datetime,timezone,timedelta
import hashlib,json,re,ast
ROOT=Path(__file__).resolve().parents[2]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
required=['README.md','guide.md','SIMULATION_REPORT.md','REPLAY.ps1','requirements.txt',
 'research/TECHNOLOGY_SURVEY.md','research/OPEN_SOURCE_COMPARISON.md','research/BOARD_FACTS_AND_PIN_AUDIT.md',
 'research/HARDWARE_FEASIBILITY.md','decision/ARCHITECTURE_COMPARISON.md','decision/RISK_REGISTER.md',
 'decision/BLOCKERS.md','decision/GPT_CHAT_DECISION_PACKAGE.md','evidence/EVIDENCE_INDEX.md',
 'evidence/FAILURE_AND_RCA.md','evidence/RESULT_SUMMARY.json','evidence/simulation_logs/reproducibility.json']
for p in required:assert (ROOT/p).is_file() and (ROOT/p).stat().st_size>0,p
for p in (ROOT/'simulation').rglob('*.py'):ast.parse(p.read_text(encoding='utf-8'),filename=str(p))
result=json.loads((ROOT/'evidence/RESULT_SUMMARY.json').read_text())
repeat=result['reproducibility'];assert repeat['status']=='PASS' and repeat['total_simulator_executions']==38
source=json.loads((ROOT/'evidence/environment/source_manifest.json').read_text(encoding='utf-8'))
for row in source:assert sha(Path(row['path']))==row['sha256']
for row in result['devices']:
 assert row['critical_cdc']==9 and row['pin_probe_timing']['wns']<0 and row['ooc_timing']['wns']>0
 assert row['ooc_timing']['hold_fail']==0 and row['ooc_timing']['setup_fail']==0
assert 'Fatal: NO_FULL_EMPTY_BACKPRESSURE_COVERAGE' in (ROOT/'evidence/simulation_logs/finalC/tb_pipeline_seed1_gap3/xsim.log').read_text(errors='replace')
assert not (ROOT.parent/'v1').exists() and not (ROOT.parent/'.git').exists() and not (ROOT/'.git').exists()
replay_roots=sorted((ROOT/'.work').glob('replay_*'),key=lambda p:p.name)
assert replay_roots,'Full wrapper replay not found'
rp=replay_roots[-1];replayed=json.loads((rp/'evidence/simulation_logs/reproducibility.json').read_text())
assert replayed['status']=='PASS' and replayed['total_simulator_executions']==38
assert replayed['comparisons']==repeat['comparisons'],'Fresh wrapper traces differ from delivery'
assert 'Replay evidence:' in (ROOT/'evidence/environment/replay_wrapper.log').read_text(errors='replace')
selected=[]
for folder in ['research','simulation','decision','evidence']:
 selected.extend(p for p in (ROOT/folder).rglob('*') if p.is_file() and '__pycache__' not in p.parts)
selected.extend(ROOT/p for p in ['README.md','guide.md','SIMULATION_REPORT.md','REPLAY.ps1','requirements.txt'])
selected=[p for p in selected if p.name not in ['ARTIFACT_MANIFEST.json','DELIVERY_AUDIT.json','delivery_seal_console.txt']]
secret_patterns=[re.compile(r'gh'+'p_[A-Za-z0-9]{30,}'),re.compile(r'github'+'_pat_[A-Za-z0-9_]{25,}'),
 re.compile(r'sk'+'-proj-[A-Za-z0-9_-]{20,}'),re.compile(r'-----BEGIN [A-Z ]*PRIVATE KEY-----')]
for p in selected:
 if p.suffix in ['.md','.txt','.json','.py','.ps1','.tcl','.sv','.v','.log','.jou','.rpt','.tsv','.csv']:
  s=p.read_text(encoding='utf-8',errors='replace')
  for pat in secret_patterns:assert not pat.search(s),f'Credential pattern requires review: {p}'
links=[]
for p in [ROOT/x for x in required if x.endswith('.md')]:
 for target in re.findall(r'(?<!!)\[[^\]\n]+\]\(([^)]+)\)',p.read_text(encoding='utf-8')):
  if re.match(r'https?://',target) or target.startswith('#'):continue
  q=(p.parent/target.split('#')[0]).resolve();assert q.exists(),f'Broken link {p}: {target}'
  links.append(str(q.relative_to(ROOT)).replace('\\','/'))
now=datetime.now(timezone.utc).astimezone(timezone(timedelta(hours=8))).isoformat()
checkpoint={'evaluation_id':'TIMEFOOT_PREPROJECT_20261101','created_at':now,'formal_project_id':'NOT_ASSIGNED',
 'formal_repository':'NOT_SELECTED','formal_version':'NOT_STARTED','project_status':'CONSULTATION_ONLY',
 'workspace':str(ROOT),'current_stage':'RESEARCH_AND_SIMULATION','evaluation':'FEASIBLE_WITH_CONSTRAINTS',
 'validation_summary':'38/38 selected RTL executions PASS; full wrapper extra 38 PASS; 2443 independently decoded packets',
 'ooc':'routed positive candidate STA; no board acceptance','cdc':'9 critical per part; REVISE',
 'pin_output_sta':'FAIL -0.673/-0.304 ns','physical_hardware':'NOT_CHECKED',
 'protected':['source attachments','all failed evidence','no formal v1/repository/push/PCB/purchase/board writes'],
 'resume_from':['guide.md','decision/GPT_CHAT_DECISION_PACKAGE.md','SIMULATION_REPORT.md','evidence/EVIDENCE_INDEX.md'],
 'next_actions':['User/ChatGPT review constraints and scope','Resolve board pin/VCCO/PS facts and measurement resources',
 'Only after explicit formal approval: confirm repository, project ID, workspace and v1 scope'],
 'limitations_ref':['decision/BLOCKERS.md','decision/RISK_REGISTER.md'],'wrapper_replay_path':str(rp)}
cp=ROOT/'evidence/PREPROJECT_CHECKPOINT.json';cp.write_text(json.dumps(checkpoint,ensure_ascii=False,indent=2),encoding='utf-8');selected.append(cp)
entries=[{'path':p.relative_to(ROOT).as_posix(),'bytes':p.stat().st_size,'sha256':sha(p)} for p in sorted(set(selected))]
manifest={'scope':'delivery files; excludes .work/.Xil caches, this manifest, DELIVERY_AUDIT.json and live seal stdout to avoid recursive hashes',
 'generated_at':now,'files':entries}
mp=ROOT/'evidence/ARTIFACT_MANIFEST.json';mp.write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
audit={'status':'PASS','audited_at':now,'required_files_checked':len(required),'manifest_files':len(entries),
 'manifest_sha256':sha(mp),'local_markdown_links_checked':len(links),'source_attachments_unchanged':True,
 'python_syntax':'PASS','secret_pattern_scan':'PASS_SELECTED_PATTERNS_NOT_A_COMPLETE_PRIVACY_CERTIFICATION',
 'selected_simulations':38,'full_replay_wrapper':'PASS','extra_replay_simulations':38,
 'wrapper_replay_path':str(rp),'wrapper_trace_hashes_match_selected':True,
 'known_failures_preserved':True,'formal_version_started':False,'git_created':False,
 'hardware_acceptance':'NOT_CHECKED','cdc_acceptance':'REVISE','pin_output_sta':'FAIL',
 'note':'Delivery audit PASS certifies package consistency only; never overrides engineering failures.'}
(ROOT/'evidence/DELIVERY_AUDIT.json').write_text(json.dumps(audit,ensure_ascii=False,indent=2),encoding='utf-8')
for row in entries:assert sha(ROOT/row['path'])==row['sha256']
print(json.dumps(audit,ensure_ascii=False,indent=2))
