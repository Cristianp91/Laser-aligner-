<!doctype html>
<html lang="it">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">
<title>LaserAligner – Single File</title>
<meta name="apple-mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
<meta name="apple-mobile-web-app-title" content="LaserAligner">
<style>
/* ...[CSS e UI Apple-like compatti]... */
:root{--bg:#0b0c0d;--card:rgba(255,255,255,0.08);--txt:#fff;--muted:#b7bbc0;--accent:#0a84ff}
*{box-sizing:border-box}html,body{height:100%}body{margin:0;font:16px -apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Ubuntu,'Helvetica Neue',Arial,sans-serif;background:var(--bg);color:var(--txt)}
.app{display:flex;flex-direction:column;height:100%}.header{padding:14px 18px;font-weight:700;font-size:18px;backdrop-filter:saturate(180%) blur(20px);background:rgba(18,18,18,0.8);position:sticky;top:0;z-index:10}
.tabs{display:flex;gap:8px;padding:10px 12px 0}.tab{flex:1;text-align:center;padding:10px 12px;border-radius:12px;background:var(--card);color:var(--muted);font-weight:600}.tab.active{background:#1c1c1e;color:#fff;border:1px solid #2c2c2e}
.content{padding:12px;flex:1;overflow:auto}.card{background:var(--card);border:1px solid #2c2c2e;border-radius:16px;padding:14px;margin-bottom:12px}
h2{margin:0 0 8px 0;font-size:18px}.sub{color:var(--muted);font-size:14px}button.primary{width:100%;padding:12px 14px;border:0;border-radius:12px;background:var(--accent);color:#fff;font-weight:700}
.row{display:flex;gap:10px;align-items:center}label{color:#d0d3d7}select,input[type=range]{width:100%}.grid-2{display:grid;grid-template-columns:1fr 1fr;gap:10px}
canvas{touch-action:none}.badge{display:inline-block;padding:4px 8px;border-radius:999px;background:#1c1c1e;border:1px solid #2c2c2e;color:#d0d3d7;font-size:12px;font-weight:600}
.suggest{display:flex;flex-direction:column;gap:8px}.screw{display:flex;justify-content:space-between;align-items:center;font-size:14px}
hr{border:0;border-top:1px solid #2c2c2e;margin:8px 0}.footer{padding:10px 12px;color:#9aa0a6;text-align:center}
input[type=range]{-webkit-appearance:none;height:28px;background:transparent}
input[type=range]::-webkit-slider-runnable-track{height:4px;background:#2c2c2e;border-radius:999px}
input[type=range]::-webkit-slider-thumb{-webkit-appearance:none;width:22px;height:22px;border-radius:50%;margin-top:-9px;background:#fff;border:2px solid #000}
</style>
</head>
<body>
<div class="app">
  <div class="header">LaserAligner</div>
  <div class="tabs">
    <div class="tab active" data-tab="guida">Guida</div>
    <div class="tab" data-tab="allinea">Allinea</div>
    <div class="tab" data-tab="diagnostica">Diagnostica</div>
    <div class="tab" data-tab="viti">Viti</div>
  </div>
  <div class="content">
    <section id="guida" class="view">
      <div class="card"><h2>Impostazioni iniziali</h2><div class="sub">Potenza bassa (3–8%), pulse brevi. Lente e ugello <b>fuori</b> finché non arrivi al centraggio finale. Stessa altezza Z per near/far.</div></div>
      <div class="card"><h2>Sequenza</h2><div class="sub">1) <b>M1→M2</b> (near/far lungo X) → sovrapponi e poi centra.<br>2) <b>M2→M3</b> (near/far lungo Y) → sovrapponi e poi centra.<br>3) <b>Nozzle</b>: centra nel foro col solo M3. Lente menisco convesso verso il basso, poi 4 angoli.</div></div>
      <div class="card"><h2>Regole d’oro</h2><div class="sub">Micro-giri (≈1/16). Non inseguire il centro prima della sovrapposizione. Se sbaglia solo un angolo front-right: sospetta M2 fuori squadra o leggero racking.</div></div>
    </section>
    <section id="allinea" class="view" style="display:none">
      <div class="card">
        <div class="grid-2">
          <div><label>Stage</label><select id="stage"><option value="m1m2">M1 → M2</option><option value="m2m3" selected>M2 → M3</option><option value="nozzle">Nozzle</option></select></div>
          <div><label>Tolleranza</label><input type="range" id="tol" min="0.01" max="0.06" step="0.005" value="0.02"><div class="sub"><span id="tolVal">0.02</span></div></div>
        </div>
      </div>
      <div class="card"><canvas id="board" width="400" height="400"></canvas><div class="sub">Tocca per segnare <b>near</b>, poi <b>far</b> (se richiesto). Trascina per affinare. Bersaglio = centro.</div></div>
      <div class="card">
        <button class="primary" id="calc">Calcola suggerimento</button>
        <div id="suggest" class="card" style="margin-top:12px"></div>
        <div class="grid-2" style="margin-top:10px"><button id="reset">Reset</button><button id="verify">Verifica</button></div>
      </div>
    </section>
    <section id="diagnostica" class="view" style="display:none">
      <div class="card"><h2>Test 4 angoli</h2><div class="sub">Con nastro sull'ugello (lente fuori), fai 4 pulse ai 4 angoli del piano e tocca dove ha colpito.</div></div>
      <div class="card">
        <canvas id="corners" width="360" height="240"></canvas>
        <div class="grid-2" style="margin-top:8px">
          <span class="badge">FL</span><span id="pFL" class="sub"></span>
          <span class="badge">FR</span><span id="pFR" class="sub"></span>
          <span class="badge">BR</span><span id="pBR" class="sub"></span>
          <span class="badge">BL</span><span id="pBL" class="sub"></span>
        </div>
      </div>
      <div class="card"><button class="primary" id="analyze">Analizza pattern</button><div id="diag" class="card" style="margin-top:12px"></div></div>
    </section>
    <section id="viti" class="view" style="display:none">
      <div class="card"><h2>Mappa viti (CW micro-giro)</h2><div class="sub">Dai un micro-giro <b>CW</b> a una vite e annota come si muove il punto sullo specchio successivo. Salva in locale.</div></div>
      <div class="card"><label>Specchio</label><select id="mirrorSel"><option value="M1">M1</option><option value="M2" selected>M2</option><option value="M3">M3</option></select></div>
      <div id="screws" class="card"></div>
      <div class="card sub">Suggerimento: mappa almeno 2 viti per specchio per risultati migliori.</div>
    </section>
  </div>
  <div class="footer">Single-file • Installa su Home: Condividi → Aggiungi alla schermata Home</div>
</div>
<script>
const state={stage:'m2m3',tol:0.02,target:{x:0.5,y:0.5},near:null,far:null,screws:JSON.parse(localStorage.getItem('LA_screws')||'{}')||{}};
const def=[{name:'Vite A',cw:[0.00,-0.015]},{name:'Vite B',cw:[0.015,0.000]},{name:'Vite C',cw:[-0.015,0.000]}];
['M1','M2','M3'].forEach(m=>{if(!state.screws[m]) state.screws[m]=JSON.parse(JSON.stringify(def));});
function save(){localStorage.setItem('LA_screws',JSON.stringify(state.screws));}
document.querySelectorAll('.tab').forEach(t=>t.addEventListener('click',()=>{document.querySelectorAll('.tab').forEach(x=>x.classList.remove('active'));t.classList.add('active');const id=t.dataset.tab;document.querySelectorAll('.view').forEach(v=>v.style.display='none');document.getElementById(id).style.display='block';if(id==='viti') renderScrews();if(id==='allinea') drawBoard();if(id==='diagnostica') drawCorners();}));
const board=document.getElementById('board');const bctx=board.getContext('2d',{alpha:false});
function nx(x){return x*board.width}function ny(y){return y*board.height}function dn(x){return x/board.width}function dm(y){return y/board.height}
function drawBoard(){bctx.fillStyle='#1c1c1e';bctx.fillRect(0,0,board.width,board.height);const r=Math.min(board.width,board.height)/2*0.9;const cx=board.width/2,cy=board.height/2;bctx.strokeStyle='#3a3a3c';bctx.lineWidth=2;bctx.beginPath();bctx.arc(cx,cy,r,0,Math.PI*2);bctx.stroke();bctx.setLineDash([4,4]);bctx.beginPath();bctx.moveTo(cx-r,cy);bctx.lineTo(cx+r,cy);bctx.moveTo(cx,cy-r);bctx.lineTo(cx,cy+r);bctx.stroke();bctx.setLineDash([]);bctx.fillStyle='rgba(48,209,88,0.25)';bctx.beginPath();bctx.arc(nx(state.target.x),ny(state.target.y),7,0,Math.PI*2);bctx.fill();if(state.near) drawPoint(state.near,'#0a84ff');if(state.stage!=='nozzle'&&state.far) drawPoint(state.far,'#ff9f0a');}
function drawPoint(p,c){bctx.fillStyle=c;bctx.strokeStyle='#fff';bctx.lineWidth=2;bctx.beginPath();bctx.arc(nx(p.x),ny(p.y),7,0,Math.PI*2);bctx.fill();bctx.stroke();}
let dragging=null;
board.addEventListener('pointerdown',e=>{const rect=board.getBoundingClientRect();const x=(e.clientX-rect.left)/rect.width;const y=(e.clientY-rect.top)/rect.height;const p={x:clamp(x),y:clamp(y)};if(!state.near) state.near=p; else if(state.stage!=='nozzle'&&!state.far) state.far=p; else state.near=p; dragging=(dist(p,state.near)<0.03)?'near':(dist(p,state.far||{x:999,y:999})<0.03?'far':null); drawBoard();});
board.addEventListener('pointermove',e=>{if(!dragging) return; const rect=board.getBoundingClientRect();const x=(e.clientX-rect.left)/rect.width;const y=(e.clientY-rect.top)/rect.height;if(dragging==='near') state.near={x:clamp(x),y:clamp(y)};if(dragging==='far') state.far={x:clamp(x),y:clamp(y)}; drawBoard();});
board.addEventListener('pointerup',()=>dragging=null);
function clamp(v){return Math.max(0.02,Math.min(0.98,v))}function dist(a,b){if(!a||!b) return 999; const dx=a.x-b.x,dy=a.y-b.y;return Math.hypot(dx,dy);}
const stageSel=document.getElementById('stage');stageSel.addEventListener('change',()=>{state.stage=stageSel.value;if(state.stage==='nozzle'){state.far=null;} drawBoard();});
document.getElementById('tol').addEventListener('input',e=>{state.tol=+e.target.value;document.getElementById('tolVal').textContent=state.tol.toFixed(3);});
document.getElementById('reset').addEventListener('click',()=>{state.near=null;state.far=null;drawBoard();suggestBox('Azzerato','Segna di nuovo i punti.',[],false);});
document.getElementById('verify').addEventListener('click',()=>{calcSuggest(true);});
document.getElementById('calc').addEventListener('click',()=>{calcSuggest(false);});
function suggestBox(title,detail,adjustments,isGood){const el=document.getElementById('suggest');let html=`<div class="suggest"><div><span class="badge">${isGood?'OK':'TIP'}</span> <b>${title}</b></div><div class="sub">${detail}</div>`;if(adjustments&&adjustments.length){html+="<hr>";adjustments.forEach(a=>{const sign=a.turns>=0?"↻ CW":"↺ CCW";html+=`<div class="screw"><div>${a.name}</div><div class="sub">${Math.abs(a.turns).toFixed(1)} × micro-giri ${sign}</div></div>`;});} html+="</div>"; el.innerHTML=html;}
function vecLen(v){return Math.hypot(v.x,v.y)}function norm(v){const L=vecLen(v)||1e-6;return{x:v.x/L,y:v.y/L}}function dot(a,b){return a.x*b.x+a.y*b.y}function sub(a,b){return{x:a.x-b.x,y:a.y-b.y}}function add(a,b){return{x:a.x+b.x,y:a.y+b.y}}function scl(a,k){return{x:a.x*k,y:a.y*k}}
function recommendAdjustments(error,mount){const e=error;const L=vecLen(e);if(L<1e-6) return [];const en=norm(e);const ranked=mount.map(s=>({s,score:dot(en,norm({x:s.cw[0],y:s.cw[1]}))})).sort((a,b)=>b.score-a.score);const results=[];if(ranked[0]){const scale=Math.max(0.5,Math.min(3.0,L/0.05));results.push({name:ranked[0].s.name,turns:+1.0*scale});} if(L>0.03&&ranked[1]){const scale2=Math.max(0.5,Math.min(2.0,L/0.07));results.push({name:ranked[1].s.name,turns:+0.5*scale2});} if(L>0.06&&ranked[2]){results.push({name:ranked[2].s.name,turns:-0.5});} return results;}
function calcSuggest(){const tol=state.tol,stage=state.stage;const mounts={M1:state.screws['M1'],M2:state.screws['M2'],M3:state.screws['M3']}; if(stage==='nozzle'){if(!state.near){suggestBox('Segna il punto','Dai un pulse con ugello montato, lente FUORI. Tocca dove ha colpito.',[],false);return;} const delta=sub(state.target,state.near); if(vecLen(delta)<tol){suggestBox('Centrato','Colpo centrato nell\\'ugello. Rimonta la lente (convesso in basso) e fai il collaudo finale.',[],true);return;} const adj=recommendAdjustments(delta,mounts.M3);suggestBox('Centra con M3','Usa micro-giri (~1/16). Ricontrolla dopo ogni correzione.',adj,false);return;} if(!state.near||!state.far){suggestBox('Servono due punti','Segna il colpo VICINO e LONTANO (near/far) alla stessa altezza Z.',[],false);return;} const separation=sub(state.far,state.near); if(vecLen(separation)>=tol){const which=(stage==='m1m2')?'M1':'M2'; const adj=recommendAdjustments(scl(separation,-1),mounts[which]);suggestBox('Fai coincidere near/far',`Regola ${which} finché i due punti coincidono. Micro-giri, poi ripeti il test.`,adj,false);return;} const overlapped=scl(add(state.near,state.far),0.5); const centerDelta=sub(state.target,overlapped); if(vecLen(centerDelta)<tol){suggestBox('Step completato','Near/far coincidono ed è centrato. Passa allo step successivo.',[],true);} else {const which=(stage==='m1m2')?'M1':'M2'; const adj=recommendAdjustments(centerDelta,mounts[which]);suggestBox('Centra dopo la sovrapposizione','Mantieni la sovrapposizione near/far e porta il punto al centro.',adj,false);}}
const corners=document.getElementById('corners');const cctx=corners.getContext('2d',{alpha:false});const cornerPts={FL:null,FR:null,BR:null,BL:null};
function drawCorners(){cctx.fillStyle='#1c1c1e';cctx.fillRect(0,0,corners.width,corners.height);cctx.strokeStyle='#3a3a3c';cctx.lineWidth=2;cctx.strokeRect(6,6,corners.width-12,corners.height-12);Object.entries(cornerPts).forEach(([k,p])=>{if(p){cctx.fillStyle='#0a84ff';cctx.beginPath();cctx.arc(p.x*corners.width,p.y*corners.height,6,0,Math.PI*2);cctx.fill();}else{cctx.fillStyle='#9aa0a6';cctx.font='12px -apple-system';const pos=labelPos(k);cctx.fillText(k,pos.x*corners.width-8,pos.y*corners.height-8);}});['FL','FR','BR','BL'].forEach(k=>{const el=document.getElementById('p'+k);el.textContent=cornerPts[k]?`(${cornerPts[k].x.toFixed(2)}, ${cornerPts[k].y.toFixed(2)})`:'—';});}
function labelPos(k){const m=0.12;return{FL:{x:m,y:m},FR:{x:1-m,y:m},BR:{x:1-m,y:1-m},BL:{x:m,y:1-m}}[k];}
let dragC=null;corners.addEventListener('pointerdown',e=>{const r=corners.getBoundingClientRect();const x=(e.clientX-r.left)/r.width,y=(e.clientY-r.top)/r.height;const keys=['FL','FR','BR','BL'];let placed=false;for(const k of keys){const p=cornerPts[k];if(p&&Math.hypot(x-p.x,y-p.y)<0.05){dragC=k;placed=true;break;}} if(!placed){let best='FL',bd=999;for(const k of keys){const lp=labelPos(k);const d=Math.hypot(x-lp.x,y-lp.y);if(d<bd){bd=d;best=k;}} cornerPts[best]={x:clamp(x),y:clamp(y)};dragC=best;} drawCorners();});
corners.addEventListener('pointermove',e=>{if(!dragC) return; const r=corners.getBoundingClientRect();const x=(e.clientX-r.left)/r.width,y=(e.clientY-r.top)/r.height;cornerPts[dragC]={x:clamp(x),y:clamp(y)};drawCorners();});
corners.addEventListener('pointerup',()=>dragC=null);
document.getElementById('analyze').addEventListener('click',()=>{const need=['FL','FR','BR','BL'];if(!need.every(k=>cornerPts[k])){setDiag('Segna tutti e quattro i punti: FL, FR, BR, BL.');return;} const fl=cornerPts.FL,fr=cornerPts.FR,br=cornerPts.BR,bl=cornerPts.BL;const avg={x:(fl.x+fr.x+br.x+bl.x)/4,y:(fl.y+fr.y+br.y+bl.y)/4};const difFR={x:fr.x-avg.x,y:fr.y-avg.y};if(Math.abs(difFR.y)>0.06&&difFR.y<0&&Math.abs(difFR.x)>0.02&&difFR.x>0){setDiag('Solo FR alto/destra: probabile M2 leggermente fuori squadra (yaw/pitch) o racking del gantry lato destro. Verifica il ponte e ripeti M2→M3 vicino (Y basso).');return;} const leftAvgY=(fl.y+bl.y)/2,rightAvgY=(fr.y+br.y)/2; if(Math.abs(leftAvgY-rightAvgY)>0.06){setDiag('Colonna sinistra vs destra con altezze diverse: ponte non parallelo o guide Y non co-planari. Squadra il gantry, controlla ruote/cinghie.');return;} const devs=[fl,fr,br,bl].map(p=>Math.hypot(p.x-0.5,p.y-0.5)); if(Math.max(...devs)-Math.min(...devs)<0.02){setDiag('Tutti i punti simili ma decentrati: allineamento parallelo ma centrale da rifinire. Ricentra con M3 (nozzle).');return;} setDiag('Pattern non standard: ricontrolla altezza Z, verso lente (convesso in basso), cinghie/pulegge e rifai M1→M2 → M2→M3 → Nozzle.');});
function setDiag(t){document.getElementById('diag').innerHTML=`<div class='sub'>${t}</div>`;}
const mirrorSel=document.getElementById('mirrorSel');const screwsDiv=document.getElementById('screws');mirrorSel.addEventListener('change',renderScrews);
function renderScrews(){const m=mirrorSel.value;const arr=state.screws[m];screwsDiv.innerHTML=arr.map((s,i)=>`<div class="card"><div class="row" style="justify-content:space-between"><b>${s.name}</b><span class="sub">CW</span></div><div class="row"><span class="sub">X</span><input type="range" min="-0.08" max="0.08" step="0.001" value="${s.cw[0]}" data-k="x" data-i="${i}"><span class="sub">${s.cw[0].toFixed(3)}</span></div><div class="row"><span class="sub">Y</span><input type="range" min="-0.08" max="0.08" step="0.001" value="${s.cw[1]}" data-k="y" data-i="${i}"><span class="sub">${s.cw[1].toFixed(3)}</span></div></div>`).join('');screwsDiv.querySelectorAll('input[type=range]').forEach(inp=>{inp.addEventListener('input',e=>{const i=+e.target.dataset.i;const k=e.target.dataset.k;const val=+e.target.value;if(k==='x') state.screws[m][i].cw[0]=val; else state.screws[m][i].cw[1]=val; e.target.nextElementSibling.textContent=val.toFixed(3); save();});});}
renderScrews(); drawBoard(); drawCorners(); document.getElementById('tolVal').textContent=state.tol.toFixed(3); stageSel.value=state.stage;
</script>
</body>
</html>
