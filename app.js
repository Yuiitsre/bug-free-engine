(() => {
"use strict";
const $=id=>document.getElementById(id);
const windows={}; let z=40,active=null,drag=null,resize=null,locked=false;

const apps={
 explorer:{title:"File Explorer",icon:"📁",w:820,h:540},
 browser:{title:"Microsoft Edge",icon:"🌐",w:900,h:600},
 notepad:{title:"Notepad",icon:"📝",w:730,h:520},
 settings:{title:"Settings",icon:"⚙️",w:860,h:570},
 calculator:{title:"Calculator",icon:"🧮",w:410,h:590},
 store:{title:"Microsoft Store",icon:"▣",w:760,h:520},
 photos:{title:"Photos",icon:"🌄",w:800,h:560},
 terminal:{title:"Windows Terminal",icon:"›_",w:720,h:470},
 clock:{title:"Clock",icon:"◷",w:540,h:460},
 paint:{title:"Paint",icon:"🎨",w:820,h:560},
 taskmgr:{title:"Task Manager",icon:"▥",w:760,h:500},
 about:{title:"About Windows 11 Demo",icon:"ⓘ",w:580,h:420}
};
const fileData=[
["Desktop","🖥️","Folder"],["Documents","📂","Folder"],["Downloads","📥","Folder"],["Pictures","🖼️","Folder"],
["Music","🎵","Folder"],["Videos","🎬","Folder"],["Project Notes.txt","📝","12 KB"],["Windows UI Demo","📦","Folder"],
["Readme.pdf","📄","840 KB"],["wallpaper.png","🌌","3.2 MB"],["design-assets","🎨","Folder"],["backup.zip","🗜️","92 MB"]
];

function bring(win){
 if(!win)return;
 win.style.zIndex=++z;
 document.querySelectorAll(".window").forEach(x=>x.classList.remove("active"));
 win.classList.add("active"); active=win; updateTaskbar();
}
function updateTaskbar(){
 document.querySelectorAll(".task-btn[data-open]").forEach(b=>{
  const w=windows[b.dataset.open];
  b.classList.toggle("running",!!w&&!w.classList.contains("minimized"));
 });
}
function openApp(id){
 closePanels();
 const win=windows[id]||createWindow(id);
 win.classList.remove("minimized"); bring(win); updateTaskbar();
 if(id==="clock") refreshClock(win);
}
function closeApp(id){
 if(!windows[id])return;
 windows[id].remove(); delete windows[id];
 if(active&&active.dataset.app===id)active=null;
 updateTaskbar();
}
function minimizeApp(id){
 if(!windows[id])return;
 windows[id].classList.add("minimized"); updateTaskbar();
}
function toggleMax(win){
 if(win.classList.contains("maximized")){
  win.classList.remove("maximized");
  const r=JSON.parse(win.dataset.restore||"null");
  if(r){win.style.left=r.left;win.style.top=r.top;win.style.width=r.width;win.style.height=r.height}
  win.querySelector(".win-max").textContent="□";
 }else{
  win.dataset.restore=JSON.stringify({left:win.style.left,top:win.style.top,width:win.style.width,height:win.style.height});
  win.classList.add("maximized"); win.querySelector(".win-max").textContent="❐";
 }
 bring(win);
}
function createWindow(id){
 const m=apps[id], win=document.createElement("section");
 win.className="window"; win.dataset.app=id; win.style.width=m.w+"px";win.style.height=m.h+"px";
 win.style.left=Math.max(8,Math.round((innerWidth-m.w)/2 + Object.keys(windows).length%5*22-70))+"px";
 win.style.top=Math.max(8,Math.round((innerHeight-m.h)/2 + Object.keys(windows).length%5*16-50))+"px";
 win.innerHTML='<header class="titlebar"><span class="app-mark">'+m.icon+'</span><span class="window-title">'+m.title+'</span><div class="window-controls"><button class="win-control win-min">—</button><button class="win-control win-max">□</button><button class="win-control close win-close">×</button></div></header><div class="window-body"></div><span class="resize-handle resize-e"></span><span class="resize-handle resize-s"></span><span class="resize-handle resize-se"></span>';
 $("windowLayer").appendChild(win); windows[id]=win; renderApp(id,win.querySelector(".window-body"));
 const bar=win.querySelector(".titlebar");
 bar.addEventListener("mousedown",e=>{if(!e.target.closest(".win-control"))startDrag(e,win)});
 bar.addEventListener("dblclick",e=>{if(!e.target.closest(".win-control"))toggleMax(win)});
 win.addEventListener("mousedown",()=>bring(win));
 win.querySelector(".win-close").onclick=()=>closeApp(id);
 win.querySelector(".win-min").onclick=()=>minimizeApp(id);
 win.querySelector(".win-max").onclick=()=>toggleMax(win);
 win.querySelector(".resize-e").onmousedown=e=>startResize(e,win,"e");
 win.querySelector(".resize-s").onmousedown=e=>startResize(e,win,"s");
 win.querySelector(".resize-se").onmousedown=e=>startResize(e,win,"se");
 bring(win); return win;
}
function startDrag(e,win){
 if(win.classList.contains("maximized"))return;
 const r=win.getBoundingClientRect(); drag={win,dx:e.clientX-r.left,dy:e.clientY-r.top};
 addEventListener("mousemove",moveDrag); addEventListener("mouseup",stopDrag,{once:true});
}
function moveDrag(e){
 if(!drag)return; const w=drag.win,maxX=Math.max(0,innerWidth-w.offsetWidth-6),maxY=Math.max(0,innerHeight-w.offsetHeight-75);
 w.style.left=Math.max(0,Math.min(maxX,e.clientX-drag.dx))+"px";
 w.style.top=Math.max(0,Math.min(maxY,e.clientY-drag.dy))+"px";
}
function stopDrag(){removeEventListener("mousemove",moveDrag);drag=null}
function startResize(e,win,mode){
 e.preventDefault();e.stopPropagation(); if(win.classList.contains("maximized"))return;
 const r=win.getBoundingClientRect(); resize={win,mode,x:e.clientX,y:e.clientY,w:r.width,h:r.height};
 addEventListener("mousemove",moveResize);addEventListener("mouseup",stopResize,{once:true});
}
function moveResize(e){
 if(!resize)return;const s=resize,w=s.win;
 if(s.mode==="e"||s.mode==="se")w.style.width=Math.max(360,s.w+e.clientX-s.x)+"px";
 if(s.mode==="s"||s.mode==="se")w.style.height=Math.max(260,s.h+e.clientY-s.y)+"px";
}
function stopResize(){removeEventListener("mousemove",moveResize);resize=null}

function renderApp(id,b){
 if(id==="explorer")renderExplorer(b); else if(id==="browser")renderBrowser(b); else if(id==="notepad")renderNotepad(b);
 else if(id==="settings")renderSettings(b); else if(id==="calculator")renderCalculator(b); else if(id==="terminal")renderTerminal(b);
 else if(id==="clock")renderClock(b); else if(id==="taskmgr")renderTaskMgr(b); else if(id==="photos")renderPhotos(b);
 else if(id==="paint")renderPaint(b); else renderPlaceholder(b,id);
}
function renderExplorer(b){
 b.innerHTML='<div class="toolbar"><button class="small-btn">‹</button><button class="small-btn">›</button><button class="small-btn">↑</button><div class="address">⌂ Home › This PC › Deepanshu</div><button class="small-btn">⋯</button></div><div class="explorer"><aside class="side"><div class="side-item active">🏠 Home</div><div class="side-item">⭐ Quick access</div><div class="side-item">🖥️ Desktop</div><div class="side-item">📂 Documents</div><div class="side-item">📥 Downloads</div><div class="side-item">🖼️ Pictures</div><div class="side-item">🎵 Music</div><div class="side-item">🎬 Videos</div><div class="side-item">💾 Local Disk (C:)</div></aside><section class="file-area"><div class="file-head"><b>Home</b><small>12 items</small></div><div class="file-grid">'+fileData.map(f=>'<button class="file-card"><span class="fi">'+f[1]+'</span><b>'+f[0]+'</b><small>'+f[2]+'</small></button>').join("")+'</div></section></div>';
}
function renderBrowser(b){
 b.innerHTML='<div class="browser"><div class="edge-tabs"><span class="edge-tab">New tab</span><button>＋</button><span style="margin-left:auto">⋯</span></div><div class="edge-nav"><button>‹</button><button>›</button><button>↻</button><input id="edgeAddress" class="edge-address" value="https://www.example.com"><button>☆</button></div><div class="edge-page"><div class="hero"><small style="color:#6a7787">Microsoft Edge · local demo</small><h1 id="edgeTitle">Build. Explore. Create.</h1><p>This browser surface is simulated entirely in the page. Use the address bar, window controls, and taskbar just as you would in a desktop shell.</p><div class="hero-cards"><div class="hero-card"><b>Search the web</b><small>Enter a URL or query above.</small></div><div class="hero-card"><b>Quick links</b><small>Open apps from Start.</small></div><div class="hero-card"><b>Window controls</b><small>Drag, resize and maximize.</small></div></div><div style="margin-top:26px;padding:16px;background:#f2f6fb;border-radius:12px;font-size:11px"><b>Demo page</b><div style="margin-top:5px;color:#657286">No network is required for this demo.</div></div></div></div></div>';
 b.querySelector("#edgeAddress").addEventListener("keydown",e=>{if(e.key==="Enter"){const q=e.target.value||"New tab";b.querySelector("#edgeTitle").textContent=q.replace(/^https?:\\/\\//,"").slice(0,45);toast("Edge","Loaded “"+q+"” in the demo.")}});
}
function renderNotepad(b){
 b.innerHTML='<div class="notepad"><div class="note-menu"><button>File</button><button>Edit</button><button>View</button><span style="flex:1"></span><small style="color:var(--muted);font-size:9px">UTF‑8 · 100%</small></div><textarea class="editor" spellcheck="false">Windows 11 Desktop Demo
========================

A detailed browser-based desktop shell prototype.

Try:
- Open Start and Search
- Drag, resize and maximize windows
- Use Quick Settings and Notifications
- Right-click the desktop
- Open File Explorer, Edge, Settings and Calculator
- Open Task View
- Lock and unlock the desktop

Built with plain HTML, CSS and JavaScript.</textarea></div>';
}
function renderSettings(b){
 b.innerHTML='<div class="settings"><aside class="settings-nav"><h2>Settings</h2><div class="setting-nav active">🖥️ System</div><div class="setting-nav">♧ Bluetooth & devices</div><div class="setting-nav">🌐 Network & internet</div><div class="setting-nav">🎨 Personalization</div><div class="setting-nav">▣ Apps</div><div class="setting-nav">👥 Accounts</div><div class="setting-nav">◒ Time & language</div><div class="setting-nav">♿ Accessibility</div><div class="setting-nav">🔐 Privacy & security</div><div class="setting-nav">⬆ Windows Update</div></aside><main class="settings-main"><h1>System</h1><p>Display, sound, notifications, power, storage and multitasking.</p>'+[
 ["Display","Brightness, night light, scale and display resolution.","›"],["Sound","Output device, volume and audio settings.","›"],["Notifications","Control notifications from apps and system services.","toggle"],["Power & battery","Battery saver, screen and sleep controls.","›"],["Storage","Manage local storage and temporary files.","›"],["Multitasking","Snap windows and multiple desktops.","toggle"]
 ].map(x=>'<div class="setting-card"><div class="setting-row"><div><b>'+x[0]+'</b><p>'+x[1]+'</p></div>'+(x[2]==="toggle"?'<button class="toggle on"></button>':'<button class="tab active">'+x[2]+'</button>')+'</div></div>').join("")+'</main></div>';
 b.querySelectorAll(".toggle").forEach(t=>t.onclick=()=>t.classList.toggle("on"));
}
function renderCalculator(b){
 const keys=["MC","MR","M+","M-","⌫","CE","C","÷","7","8","9","×","4","5","6","−","1","2","3","+","±","0",".","="];
 b.innerHTML='<div class="calc"><div class="calc-display"><div class="calc-expr"></div><div class="calc-value">0</div></div><div class="calc-grid">'+keys.map(k=>'<button class="calc-key '+(["÷","×","−","+"].includes(k)?"op ":"")+(k==="="?"eq":"")+'" data-k="'+k+'">'+k+'</button>').join("")+'</div></div>';
 let cur="0",mem=null,op=null,reset=false;const val=b.querySelector(".calc-value"),ex=b.querySelector(".calc-expr");
 const calc=(a,c,o)=>o==="+"?a+c:o==="−"?a-c:o==="×"?a*c:o==="÷"?(c===0?NaN:a/c):c;
 const press=k=>{
  if("0123456789.".includes(k)){if(reset||cur==="0"){cur=k==="."?"0.":k;reset=false}else if(k==="."&&!cur.includes("."))cur+="."}
  else if(["+","−","×","÷"].includes(k)){mem=mem===null?+cur:calc(mem,+cur,op);op=k;ex.textContent=String(mem)+" "+k;reset=true}
  else if(k==="="&&op!==null){const a=mem;cur=String(calc(mem,+cur,op));ex.textContent=String(a)+" "+op+" =";mem=null;op=null;reset=true}
  else if(k==="C"){cur="0";mem=null;op=null;ex.textContent=""} else if(k==="CE"){cur="0"} else if(k==="⌫"){cur=cur.length>1?cur.slice(0,-1):"0"} else if(k==="±")cur=String(+cur*-1);
  if(!Number.isFinite(+cur))cur="Error";val.textContent=cur;
 };
 b.querySelectorAll(".calc-key").forEach(x=>x.onclick=()=>press(x.dataset.k));
 addEventListener("keydown",e=>{if(windows.calculator!==undefined&&active===windows.calculator&&/[0-9.+\-*/=]/.test(e.key)){const map={"*":"×","/":"÷","-":"−","+":"+"};press(map[e.key]||e.key);e.preventDefault()}});
}
function renderTerminal(b){
 b.innerHTML='<div style="height:100%;padding:14px;background:#0a0d10;color:#d7e5db;font:12px/1.5 Consolas,monospace;overflow:auto"><div>Microsoft Windows [Version 11.0.26100.1]</div><div>(c) Microsoft Corporation. All rights reserved.</div><br><div>PS C:\\Users\\Deepanshu&gt; <span id="termEcho">help</span></div><div style="color:#9dc6a7;margin:6px 0">help &nbsp; dir &nbsp; cls &nbsp; ver &nbsp; whoami &nbsp; start</div><div>PS C:\\Users\\Deepanshu&gt; <input id="termInput" style="width:60%;background:none;border:0;outline:0;color:#fff;font:inherit"></div></div>';
 const input=b.querySelector("#termInput");input.focus();input.onkeydown=e=>{if(e.key!=="Enter")return;const cmd=input.value.trim().toLowerCase();b.querySelector("#termEcho").textContent=cmd||"";if(cmd==="ver")toast("Terminal","Windows 11 Demo build 26100.1");if(cmd==="whoami")toast("Terminal","Deepanshu");if(cmd==="start")openApp("explorer");input.value=""};
}
function renderClock(b){
 b.innerHTML='<div style="height:100%;padding:30px;text-align:center;background:#111a27"><div class="clock-main" style="font-size:52px;font-weight:300;margin-top:10px"></div><div class="clock-date-main" style="color:var(--muted);font-size:12px;margin-top:6px"></div><div style="display:grid;grid-template-columns:1fr 1fr;gap:9px;margin-top:30px"><div class="setting-card"><b>Focus session</b><p>25 min</p></div><div class="setting-card"><b>Next alarm</b><p>07:30 AM</p></div></div></div>';
 refreshClock(windows.clock);
}
function refreshClock(w){
 if(!w)return;const now=new Date(),time=now.toLocaleTimeString([],{hour:"2-digit",minute:"2-digit"}),date=now.toLocaleDateString([],{weekday:"long",month:"long",day:"numeric",year:"numeric"});
 const a=w.querySelector(".clock-main"),d=w.querySelector(".clock-date-main");if(a)a.textContent=time;if(d)d.textContent=date;
}
function renderTaskMgr(b){
 const rows=[["Windows Explorer","142 MB","0.4%"],["Microsoft Edge","428 MB","3.1%"],["Desktop Window Manager","116 MB","1.0%"],["Notepad","28 MB","0.1%"],["Windows Security","92 MB","0.2%"]];
 b.innerHTML='<div style="height:100%;padding:15px;background:#111925"><div style="display:flex;justify-content:space-between;margin-bottom:12px"><div><b style="font-size:18px">Task Manager</b><small style="display:block;color:var(--muted);font-size:10px">Processes</small></div><button class="tab active">Run new task</button></div><div style="display:grid;grid-template-columns:1fr 90px 75px;background:#182333;padding:8px;font-size:9px;color:var(--muted)"><span>Name</span><span>Memory</span><span>CPU</span></div>'+rows.map(r=>'<div style="display:grid;grid-template-columns:1fr 90px 75px;padding:10px 8px;border-bottom:1px solid var(--soft);font-size:10px"><span>'+r[0]+'</span><span>'+r[1]+'</span><span>'+r[2]+'</span></div>').join("")+'</div>';
}
function renderPhotos(b){
 const imgs=["🌅","🌌","🏔️","🌊","🌲","🌆","🌧️","🌤️"];b.innerHTML='<div style="height:100%;padding:16px;overflow:auto;background:#111a27"><div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:12px"><div><b style="font-size:18px">Photos</b><small style="display:block;color:var(--muted);font-size:10px">Your memories</small></div><button class="tab active">Import</button></div><div style="display:grid;grid-template-columns:repeat(4,1fr);gap:8px">'+imgs.map(x=>'<button style="height:140px;border-radius:12px;border:1px solid var(--soft);background:linear-gradient(145deg,#1a2b3f,#0b1623);font-size:45px">'+x+'</button>').join("")+'</div></div>';
}
function renderPaint(b){b.innerHTML='<div class="placeholder"><div class="placeholder-inner"><div class="placeholder-icon">🎨</div><h2>Paint</h2><p>Canvas, brushes and drawing tools are represented by this lightweight local preview surface.</p></div></div>'}
function renderPlaceholder(b,id){
 const m=apps[id];b.innerHTML='<div class="placeholder"><div class="placeholder-inner"><div class="placeholder-icon">'+m.icon+'</div><h2>'+m.title+'</h2><p>This application surface is part of the desktop simulation. Its shell, window controls, taskbar integration and layout are functional.</p><div class="setting-card" style="text-align:left;margin-top:17px"><b>Demo feature</b><p>Fully local, dependency-free UI prototype.</p></div></div></div>';
}

function toast(title,msg){
 const x=document.createElement("div");x.className="toast";x.innerHTML="<b>"+title+"</b><span>"+msg+"</span>";$("toastStack").appendChild(x);setTimeout(()=>x.remove(),3600);
}
function closePanels(){["startMenu","searchPanel","quickPanel","notificationsPanel","taskView"].forEach(id=>$(id).classList.add("hidden"))}
function togglePanel(id){const el=$(id),show=el.classList.contains("hidden");closePanels();$("contextMenu").classList.add("hidden");if(show)el.classList.remove("hidden")}

$("startBtn").onclick=()=>togglePanel("startMenu");
$("searchBtn").onclick=()=>{togglePanel("searchPanel");setTimeout(()=>$("globalSearch").focus(),30)};
$("taskViewBtn").onclick=()=>{closePanels();renderTaskView();$("taskView").classList.remove("hidden")};
$("closeTaskView").onclick=()=>$("taskView").classList.add("hidden");
["wifiTray","soundTray","batteryTray"].forEach(id=>$(id).onclick=()=>togglePanel("quickPanel"));
$("notifyTray").onclick=()=>togglePanel("notificationsPanel");
$("timeTray").onclick=()=>openApp("clock");
document.querySelectorAll("[data-open]").forEach(b=>b.addEventListener("click",e=>{e.stopPropagation();openApp(b.dataset.open)}));

document.querySelectorAll(".desktop-icon").forEach(i=>{
 i.onclick=e=>{e.stopPropagation();document.querySelectorAll(".desktop-icon").forEach(x=>x.classList.remove("selected"));i.classList.add("selected")};
 i.ondblclick=()=>openApp(i.dataset.open);
});
$("desktop").onclick=e=>{if(!e.target.closest(".desktop-icon"))document.querySelectorAll(".desktop-icon").forEach(x=>x.classList.remove("selected"))};

function search(q){
 const all=Object.entries(apps).map(([id,a])=>({id,title:a.title,icon:a.icon,type:"App"})).concat([
  {id:"notes",title:"Project Notes.txt",icon:"📝",type:"File",open:"notepad"},
  {id:"downloads",title:"Downloads",icon:"📥",type:"Folder",open:"explorer"},
  {id:"windows",title:"Windows 11 Desktop Demo",icon:"⊞",type:"System",open:"about"}
 ]);
 const s=q.trim().toLowerCase(),res=(s?all.filter(x=>(x.title+x.type).toLowerCase().includes(s)):all.slice(0,8)).slice(0,9);
 $("searchResults").innerHTML=res.length?res.map(x=>'<button class="search-result" data-open="'+(x.open||x.id)+'"><span class="result-icon">'+x.icon+'</span><div><b>'+x.title+'</b><small>'+x.type+'</small></div></button>').join(""):'<div style="padding:12px;color:var(--muted);font-size:11px">No results found.</div>';
 $("searchResults").querySelectorAll("[data-open]").forEach(x=>x.onclick=()=>{openApp(x.dataset.open);closePanels()});
}
$("globalSearch").oninput=e=>search(e.target.value);
$("startSearch").oninput=e=>{search(e.target.value);$("startMenu").classList.add("hidden");$("searchPanel").classList.remove("hidden")};
search("");

document.querySelectorAll(".quick-tile").forEach(t=>t.onclick=()=>{t.classList.toggle("on");const s=t.querySelector("small");if(s)s.textContent=t.classList.contains("on")?"On":"Off"});
$("volume").oninput=e=>$("volumeValue").textContent=e.target.value;
$("brightness").oninput=e=>{const v=+e.target.value;$("brightnessValue").textContent=v;$("desktop").style.filter="brightness("+(0.62+v/285)+")"};

$("desktop").oncontextmenu=e=>{
 if(e.target.closest(".window,#taskbar,.flyout,#startMenu"))return;
 e.preventDefault();closePanels();const c=$("contextMenu");c.style.left=Math.min(e.clientX,innerWidth-213)+"px";c.style.top=Math.min(e.clientY,innerHeight-240)+"px";c.classList.remove("hidden");
};
$("contextMenu").onclick=e=>{const b=e.target.closest("[data-context]");if(!b)return;$("contextMenu").classList.add("hidden");const a=b.dataset.context;if(a==="display"||a==="personalize")openApp("settings");else if(a==="terminal")openApp("terminal");else if(a==="about")openApp("about");else if(a==="refresh"){document.querySelectorAll(".desktop-icon").forEach(x=>x.classList.remove("selected"));toast("Desktop","Desktop refreshed.")}else toast("Desktop","New item menu opened in the demo.")};

function renderTaskView(){
 const items=Object.entries(windows);$("taskGrid").innerHTML=items.length?items.map(([id,w])=>'<button class="task-thumb" data-task="'+id+'"><div class="thumbbar"></div><div class="thumbapp">'+apps[id].icon+'</div><div class="thumbname">'+apps[id].title+'</div></button>').join(""):'<div style="color:var(--muted);font-size:11px">No open windows.</div>';
 $("taskGrid").querySelectorAll("[data-task]").forEach(b=>b.onclick=()=>{$("taskView").classList.add("hidden");openApp(b.dataset.task)});
}

function lock(){
 closePanels();$("contextMenu").classList.add("hidden");locked=true;$("lockScreen").classList.remove("hidden");updateLock();
}
function unlock(){locked=false;$("lockScreen").classList.add("hidden")}
$("lockBtn").onclick=lock;$("powerBtn").onclick=()=>{closePanels();toast("Power","Shutdown is simulated; the browser cannot power off your PC.")};
$("lockScreen").onclick=unlock;
addEventListener("keydown",e=>{
 if(locked){if(e.key==="Enter"||e.key===" ")unlock();return}
 if(e.key==="Escape"){closePanels();$("contextMenu").classList.add("hidden")}
 if(e.ctrlKey&&e.altKey&&e.key.toLowerCase()==="t"){openApp("terminal");e.preventDefault()}
 if(e.altKey&&e.key===" "){togglePanel("searchPanel");e.preventDefault()}
});
function updateClock(){
 const now=new Date();$("trayTime").textContent=now.toLocaleTimeString([],{hour:"2-digit",minute:"2-digit"});$("trayDate").textContent=now.toLocaleDateString([],{day:"2-digit",month:"2-digit",year:"numeric"});refreshClock(windows.clock);if(locked)updateLock();
}
function updateLock(){const n=new Date();$("lockTime").textContent=n.toLocaleTimeString([],{hour:"2-digit",minute:"2-digit"});$("lockDate").textContent=n.toLocaleDateString([],{weekday:"long",month:"long",day:"numeric"})}
setInterval(updateClock,1000);updateClock();
setTimeout(()=>toast("Windows 11 Demo","Right-click the desktop or open Start to explore."),800);
})();