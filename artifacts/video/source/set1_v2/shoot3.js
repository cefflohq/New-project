const {chromium}=require('/opt/node-tools/node_modules/playwright');
const CFG="window.CEFFLO_CONFIG={environment:'local',projectRef:'local',supabaseUrl:'http://127.0.0.1:9',supabaseAnonKey:'demo',schema:'public'};";
const clean=async(pg)=>pg.evaluate(()=>{
  const kill=(txt,up)=>{for(const el of document.querySelectorAll('body *')){if(el.children.length===0&&el.textContent.trim().startsWith(txt)){let n=el;for(let i=0;i<up&&n.parentElement;i++)n=n.parentElement;n.style.display='none';}}};
  kill('Mod demo',1); kill('View live map',2);
  // live-map placeholder card: hide the card containing "Peta langsung"
  for(const el of document.querySelectorAll('body *')){if(el.children.length===0&&el.textContent.trim()==='Peta langsung'){let n=el;for(let i=0;i<4&&n.parentElement;i++){n=n.parentElement;if(n.getBoundingClientRect().width>500)break;}n.style.display='none';}}
});
(async()=>{
 const out=process.argv[2]; const base='http://127.0.0.1:8765';
 const b=await chromium.launch();
 const ctx=await b.newContext({viewport:{width:1600,height:1000},deviceScaleFactor:1.5,timezoneId:'Asia/Kuala_Lumpur'});
 await ctx.route('**/shared/config.js*',r=>r.fulfill({contentType:'application/javascript',body:CFG}));
 await ctx.addInitScript(()=>{try{sessionStorage.setItem('cefflo.vendorweb.demo','1');localStorage.setItem('cefflo.vendorweb.prefs.v1',JSON.stringify({lang:'ms'}));}catch(e){}});
 const shot=async(route,name,click)=>{const pg=await ctx.newPage();await pg.goto(`${base}/apps/vendor_web/index.html#/${route}`);await pg.waitForTimeout(2500);await clean(pg);
   if(click){await pg.getByText(click,{exact:true}).first().click({force:true,timeout:5000});await pg.waitForTimeout(2000);await clean(pg);}
   await pg.screenshot({path:`${out}/c_${name}.png`});await pg.close();};
 await shot('today','today');await shot('orders','orders');await shot('runs','runs');await shot('zones','zones');
 await shot('today','import','Import Pesanan');await shot('today','plan','Rancang Penghantaran');
 const m=await b.newContext({viewport:{width:390,height:844},deviceScaleFactor:3,isMobile:true,hasTouch:true});
 await m.route('**/shared/config.js*',r=>r.fulfill({contentType:'application/javascript',body:CFG}));
 for(const st of ['picked_up','on_the_way','delivered']){const q=await m.newPage();await q.goto(`${base}/customer/index.html?demo=1&state=${st}`);await q.waitForTimeout(2500);await clean(q);await q.screenshot({path:`${out}/c_ct_${st}.png`});await q.close();}
 await b.close();
})();
