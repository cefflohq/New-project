const {chromium}=require('/opt/node-tools/node_modules/playwright/index.js');
const {spawn}=require('child_process');
(async()=>{
 const [,,html,out,mode]=process.argv; const FPS=30, DUR=29;
 const b=await chromium.launch(); const p=await b.newPage({viewport:{width:1920,height:1080}});
 await p.goto('file://'+html); await p.evaluate(()=>document.fonts.ready); await p.waitForTimeout(500);
 if(mode==='stills'){for(const t of [1,3,5.5,9,11.8,15,17,20.5,26.5]){await p.evaluate(t=>render(t),t);await p.screenshot({path:`${out}/still_${t}.png`});}await b.close();return;}
 const ff=spawn('ffmpeg',['-y','-loglevel','error','-f','image2pipe','-framerate',String(FPS),'-c:v','mjpeg','-i','-','-c:v','libx264','-preset','medium','-crf','18','-pix_fmt','yuv420p',out]);
 for(let i=0;i<FPS*DUR;i++){await p.evaluate(t=>render(t),i/FPS);const buf=await p.screenshot({type:'jpeg',quality:92});if(!ff.stdin.write(buf))await new Promise(r=>ff.stdin.once('drain',r));}
 ff.stdin.end(); await new Promise(r=>ff.on('close',r)); await b.close();
})();
