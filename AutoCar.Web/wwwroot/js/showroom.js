(() => {
    'use strict';
    const panel = document.querySelector('#showroom-chat');
    if (panel) {
        const toggle = document.querySelector('#chat-toggle'), input = document.querySelector('#chat-input');
        const log = document.querySelector('#chat-messages'), form = document.querySelector('#chat-form');
        const history = []; let busy = false;
        const close = () => { panel.hidden = true; toggle.setAttribute('aria-expanded', 'false'); toggle.focus(); };
        toggle.addEventListener('click', () => { panel.hidden = !panel.hidden; toggle.setAttribute('aria-expanded', String(!panel.hidden)); if (!panel.hidden) input.focus(); });
        document.querySelector('#chat-close').addEventListener('click', close);
        panel.addEventListener('keydown', e => { if (e.key === 'Escape') close(); });
        const bubble = (text, role) => { const p = document.createElement('p'); p.className = `chat-bubble ${role || ''}`; p.textContent = text; log.append(p); log.scrollTop = log.scrollHeight; return p; };
        document.querySelectorAll('.chat-suggestions button').forEach(b => b.addEventListener('click', () => { if (!busy) { input.value = b.textContent; form.requestSubmit(); } }));
        form.addEventListener('submit', async e => {
            e.preventDefault(); const message = input.value.trim(); if (!message || busy) return;
            busy = true; input.value = ''; form.querySelector('button').disabled = true;
            bubble(message, 'user'); const pending = bubble('Đang tìm câu trả lời…');
            try {
                const response = await fetch('/showroom-chat', {
                    method: 'POST', headers: { 'Content-Type': 'application/json', 'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').content },
                    body: JSON.stringify({ message, carId: Number(location.pathname.match(/^\/xe\/(\d+)/)?.[1]) || null, history: history.slice(-8) }),
                    signal: AbortSignal.timeout(150000)
                });
                if (response.status === 429) throw new Error('Bạn đã gửi nhiều câu hỏi. Vui lòng thử lại sau một phút.');
                const data = await response.json();
                pending.textContent = data.reply || 'Không thể trả lời lúc này. Vui lòng thử lại.';
                if (response.ok) history.push({ role: 'user', text: message }, { role: 'assistant', text: data.reply.slice(0, 3000) });
            } catch (error) { pending.textContent = error.message.includes('một phút') ? error.message : 'Kết nối tạm gián đoạn. Vui lòng thử lại.'; }
            finally { busy = false; form.querySelector('button').disabled = false; log.scrollTop = log.scrollHeight; }
        });
    }

    const viewer = document.querySelector('.car360'); if (!viewer) return;
    const canvas = viewer.querySelector('canvas'), ctx = canvas.getContext('2d'); if (!ctx) return;
    const slider = viewer.querySelector('input'), output = viewer.querySelector('output'), play = viewer.querySelector('[data-spin-play]');
    let angle = 35, zoom = 1, running = false, drag = null, frame = 0, previous = 0;
    const faces = [], colors = ['#a9bdba', '#a9b6c9', '#c5b8a4'];
    const paint = colors[Number(viewer.dataset.seed) % colors.length];
    // Closed polygon mesh: actual 3D geometry projected with a perspective camera.
    function box(x, y, z, w, h, d, color) {
        const v = [[x,y,z],[x+w,y,z],[x+w,y+h,z],[x,y+h,z],[x,y,z+d],[x+w,y,z+d],[x+w,y+h,z+d],[x,y+h,z+d]];
        [[0,1,2,3],[4,7,6,5],[0,4,5,1],[3,2,6,7],[0,3,7,4],[1,5,6,2]].forEach(ids => faces.push({ vertices: ids.map(i => v[i]), color }));
    }
    const tall = /suv|crossover/i.test(viewer.dataset.style), roof = tall ? 1.6 : 1.35;
    box(-2.25,.46,-.91,4.5,.65,1.82,paint);
    // Tapered cabin and windshield, separate from lower body.
    const cabin = [[-1.3,1.1,-.83],[1.2,1.1,-.83],[.65,roof,-.68],[-.8,roof,-.68],[-1.3,1.1,.83],[1.2,1.1,.83],[.65,roof,.68],[-.8,roof,.68]];
    [[0,1,2,3],[4,7,6,5],[1,5,6,2],[0,3,7,4]].forEach(ids => faces.push({vertices:ids.map(i=>cabin[i]),color:'#243e48'}));
    faces.push({vertices:[3,2,6,7].map(i=>cabin[i]),color:paint});
    for (const side of [-1,1]) {
        box(-.15,1.08,side*.84-.015,.09,roof-1.08,.03,paint);
        box(.92,1.0,side*1.0-.07,.3,.13,.14,paint);
        box(-1.0,.9,side*.92-.012,.24,.045,.025,'#e2e8e5');
        box(.5,.9,side*.92-.012,.24,.045,.025,'#e2e8e5');
        for (const x of [-1.4,1.4]) {
            const z = side*.94, n = 20;
            for (let i=0;i<n;i++) {
                const a=i/n*Math.PI*2,b=(i+1)/n*Math.PI*2;
                faces.push({vertices:[[x+Math.cos(a)*.43,.45+Math.sin(a)*.43,z-.13],[x+Math.cos(b)*.43,.45+Math.sin(b)*.43,z-.13],[x+Math.cos(b)*.43,.45+Math.sin(b)*.43,z+.13],[x+Math.cos(a)*.43,.45+Math.sin(a)*.43,z+.13]],color:'#202526'});
            }
            for (const [radius,color] of [[.43,'#202526'],[.28,'#b8c2c7'],[.12,'#4b555b']])
                faces.push({vertices:Array.from({length:n},(_,i)=>[x+Math.cos(i/n*2*Math.PI)*radius,.45+Math.sin(i/n*2*Math.PI)*radius,z+side*.135]),color});
        }
    }
    box(2.255,.7,-.58,.015,.23,1.16,'#283336');
    for(const z of [-.83,.47]) {box(2.26,.91,z,.02,.14,.36,'#f5f4dc');box(-2.28,.9,z,.02,.14,.36,'#9d3636');}
    function draw() {
        const w=canvas.clientWidth,h=canvas.clientHeight,dpr=Math.min(devicePixelRatio||1,2);
        if(canvas.width!==Math.round(w*dpr)||canvas.height!==Math.round(h*dpr)){canvas.width=Math.round(w*dpr);canvas.height=Math.round(h*dpr);}
        ctx.setTransform(dpr,0,0,dpr,0,0);ctx.clearRect(0,0,w,h);
        ctx.fillStyle='#233a2920';ctx.beginPath();ctx.ellipse(w/2,h*.74,w*.34,h*.08,0,0,Math.PI*2);ctx.fill();
        const a=angle*Math.PI/180,scale=Math.min(w/6.8,h/3.8)*zoom;
        function rotate([x,y,z]){const rx=x*Math.cos(a)-z*Math.sin(a),rz=x*Math.sin(a)+z*Math.cos(a);return [rx,(y-.7)*.92-rz*.39,rz*.92+(y-.7)*.39];}
        faces.map(f=>({...f,v:f.vertices.map(rotate)})).sort((a,b)=>b.v.reduce((s,v)=>s+v[2],0)/b.v.length-a.v.reduce((s,v)=>s+v[2],0)/a.v.length).forEach(f=>{
            ctx.beginPath();f.v.forEach(([x,y,z],i)=>{const perspective=8/(8+z),px=w/2+x*scale*perspective,py=h*.57-y*scale*perspective;i?ctx.lineTo(px,py):ctx.moveTo(px,py);});ctx.closePath();ctx.fillStyle=f.color;ctx.fill();ctx.strokeStyle='#172d2928';ctx.lineWidth=.7;ctx.stroke();
        });
        slider.value=Math.round(angle);output.value=`${Math.round(angle)}°`;
    }
    const set = value => {angle=(value%360+360)%360;draw();};
    function stop(){running=false;cancelAnimationFrame(frame);play.textContent='Tự động xoay';play.setAttribute('aria-pressed','false');}
    function animate(time){if(!running)return;if(previous)set(angle+Math.min(time-previous,50)*.018);previous=time;frame=requestAnimationFrame(animate);}
    play.addEventListener('click',()=>{if(running)stop();else{running=true;previous=0;play.textContent='Dừng xoay';play.setAttribute('aria-pressed','true');frame=requestAnimationFrame(animate);}});
    slider.addEventListener('input',()=>{stop();set(Number(slider.value));});
    viewer.querySelectorAll('[data-spin-step]').forEach(b=>b.addEventListener('click',()=>{stop();set(angle+Number(b.dataset.spinStep));}));
    viewer.querySelector('[data-spin-reset]').addEventListener('click',()=>{stop();zoom=1;set(35);});
    canvas.addEventListener('pointerdown',e=>{stop();drag=e.clientX;canvas.setPointerCapture(e.pointerId);});
    canvas.addEventListener('pointermove',e=>{if(drag===null)return;set(angle+(e.clientX-drag)*.6);drag=e.clientX;});
    ['pointerup','pointercancel','lostpointercapture'].forEach(type=>canvas.addEventListener(type,()=>drag=null));
    canvas.addEventListener('keydown',e=>{if(['ArrowLeft','ArrowRight'].includes(e.key)){e.preventDefault();stop();set(angle+(e.key==='ArrowLeft'?-10:10));}});
    canvas.addEventListener('wheel',e=>{e.preventDefault();zoom=Math.max(.65,Math.min(1.5,zoom-e.deltaY*.001));draw();},{passive:false});
    document.addEventListener('visibilitychange',()=>{if(document.hidden)stop();});
    new ResizeObserver(draw).observe(canvas);draw();
})();
