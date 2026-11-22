'use strict';
window.AC={
  money:v=>new Intl.NumberFormat('vi-VN',{style:'currency',currency:'VND',maximumFractionDigits:0}).format(v||0),
  esc:v=>String(v??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c])),
  date:v=>v?new Date(v).toLocaleString('vi-VN'):'—',
  async confirm(message){if(document.querySelector('dialog[open]'))return window.confirm(message);if(window.Swal)return (await Swal.fire({title:'Xác nhận thao tác',text:message,icon:'question',showCancelButton:true,confirmButtonText:'Xác nhận',cancelButtonText:'Quay lại',confirmButtonColor:'#087c82'})).isConfirmed;return window.confirm(message);},
  toast(message,error=false){const dialog=document.querySelector('dialog[open]');if(error&&dialog){let alert=dialog.querySelector('.form-alert');if(!alert){alert=document.createElement('p');alert.className='form-alert validation-errors';alert.setAttribute('role','alert');dialog.appendChild(alert);}alert.textContent=message;alert.scrollIntoView({block:'nearest'});return;}if(window.Swal){Swal.fire({toast:true,position:'bottom-end',icon:error?'error':'success',title:message,showConfirmButton:false,timer:4500,timerProgressBar:true});return;}const el=document.querySelector('#toast');el.textContent=message;el.classList.toggle('error',error);el.classList.add('show');clearTimeout(this.toastTimer);this.toastTimer=setTimeout(()=>el.classList.remove('show'),5000);},
  async api(path,method='GET',body){
    const loading=document.querySelector('#loading');if(loading)loading.hidden=false;
    try{const headers={};if(method!=='GET')headers['X-CSRF-TOKEN']=document.querySelector('meta[name=csrf-token]').content;if(body!==undefined&&!(body instanceof FormData))headers['Content-Type']='application/json';
      const r=await fetch('/gateway/'+path,{method,headers,body:body instanceof FormData?body:body===undefined?undefined:JSON.stringify(body)});
      if(!r.ok){let msg='Không thể xử lý yêu cầu.';try{const p=await r.json();msg=p.title||msg;if(p.errors)msg=Object.values(p.errors).flat().join(' ');}catch{}if(r.status===401)msg='Vui lòng đăng nhập lại để tiếp tục.';if(r.status===403)msg='Tài khoản không có quyền thực hiện thao tác này.';throw new Error(msg);}
      if(r.status===204||r.headers.get('content-length')==='0')return null;const text=await r.text();return text?JSON.parse(text):null;
    }finally{if(loading)loading.hidden=true;}
  },
  form(form){const data=Object.fromEntries(new FormData(form));form.querySelectorAll('[data-number]').forEach(e=>data[e.name]=Number(e.value));form.querySelectorAll('input[type=checkbox]').forEach(e=>data[e.name]=e.checked);form.querySelectorAll('input[type=datetime-local]').forEach(e=>data[e.name]=e.value?new Date(e.value).toISOString():null);return data;},
  compare(){try{return JSON.parse(sessionStorage.getItem('autocar.compare')||'[]').filter(x=>Number.isInteger(x)&&x>0).slice(0,3);}catch{return[];}},
  saveCompare(ids){sessionStorage.setItem('autocar.compare',JSON.stringify(ids));this.updateCompare();},
  updateCompare(){const n=this.compare().length;const el=document.querySelector('#compare-count');if(el)el.textContent=n?'('+n+')':'';},
  image(c){return c.images?.length?'/media'+c.images[0]:'/car-photo?brand='+encodeURIComponent(c.brand)+'&model='+encodeURIComponent(c.model);},
  card(c){return `<article class="car-card"><div class="car-image"><a href="/xe/${c.id}"><img src="${this.esc(this.image(c))}" alt="${this.esc(c.displayName)}" loading="lazy"></a><button class="favorite-btn" data-unfavorite="${c.id}" aria-label="Bỏ yêu thích">♥</button></div><div class="car-content"><p class="eyebrow">${this.esc(c.brand)}</p><h3><a href="/xe/${c.id}">${this.esc(c.model)}</a></h3><p>${this.esc(c.name)}</p><div class="car-price">${this.money(c.price)}</div><a href="/xe/${c.id}">Khám phá ↗</a></div></article>`;},
  empty(message='Chưa có dữ liệu.'){return `<div class="empty-state">${this.esc(message)}</div>`;},
  error(el,e,retry){el.innerHTML=`<div class="error-state"><strong>Chưa thể tải dữ liệu</strong><p>${this.esc(e.message)}</p><button class="btn retry-button">Thử lại</button></div>`;el.querySelector('button').onclick=retry;}
};
document.querySelector('.mobile-toggle')?.addEventListener('click',function(){const open=document.querySelector('.site-header').classList.toggle('menu-open');this.setAttribute('aria-expanded',String(open));});
document.querySelectorAll('.main-nav a').forEach(a=>{if(a.getAttribute('href')===location.pathname)a.classList.add('active');});
AC.updateCompare();
document.addEventListener('click',async e=>{
  const target=e.target.closest('button,a');if(!target)return;
  try{
    if(target.dataset.compare){e.preventDefault();const id=Number(target.dataset.compare),ids=AC.compare();if(ids.includes(id)){AC.saveCompare(ids.filter(x=>x!==id));AC.toast('Đã bỏ xe khỏi so sánh.');}else{if(ids.length>=3)throw new Error('Chỉ so sánh tối đa 3 xe.');ids.push(id);AC.saveCompare(ids);AC.toast('Đã thêm xe. Mở trang So sánh để xem.');}}
    if(target.dataset.favorite){await AC.api('favorites','POST',{carId:Number(target.dataset.favorite)});AC.toast('Đã lưu xe yêu thích.');target.textContent='♥';}
    if(target.dataset.unfavorite){await AC.api('favorites/'+target.dataset.unfavorite,'DELETE');target.closest('.car-card').remove();AC.toast('Đã bỏ yêu thích.');}
    if(target.dataset.open)document.getElementById(target.dataset.open)?.showModal();
    if(target.hasAttribute('data-close'))target.closest('dialog').close();
    if(target.dataset.gallery)document.querySelector('#main-car-image').src=target.dataset.gallery;
    if(target.hasAttribute('data-fullscreen')){const image=document.querySelector('#main-car-image');if(image.requestFullscreen)await image.requestFullscreen();else window.open(image.src,'_blank','noopener');}
  }catch(error){AC.toast(error.message,true);}
});
document.addEventListener('submit',async e=>{
 const form=e.target;if(!form.classList.contains('api-form'))return;e.preventDefault();const button=form.querySelector('button[type=submit],button:not([type])');if(button)button.disabled=true;
 try{await AC.api(form.dataset.endpoint,form.dataset.method||'POST',AC.form(form));AC.toast('Yêu cầu đã được lưu thành công.');form.closest('dialog')?.close();if(form.dataset.endpoint==='reviews')loadReviews();else form.reset();}catch(error){AC.toast(error.message,true);}finally{if(button)button.disabled=false;}
});
document.querySelector('#finance-form')?.addEventListener('submit',e=>{e.preventDefault();const f=Object.fromEntries(new FormData(e.target)),principal=Number(f.price)*(1-Number(f.down)/100),r=Number(f.rate)/1200,n=Number(f.months),monthly=r===0?principal/n:principal*r/(1-Math.pow(1+r,-n));document.querySelector('#finance-result').innerHTML=`<strong>${AC.money(monthly)} / tháng</strong><small>Tổng tiền lãi mô phỏng: ${AC.money(monthly*n-principal)}</small>`;});
async function loadReviews(){const el=document.querySelector('#reviews-list');if(!el)return;try{const rows=await AC.api('reviews?carId='+el.dataset.car);el.innerHTML=rows.length?rows.map(r=>`<article class="review-item"><strong>${AC.esc(r.author)}</strong><span>${'★'.repeat(r.rating)}</span><p>${AC.esc(r.comment)}</p><small>${AC.date(r.createdAt)}</small>${r.isMine?`<button class="text-button" data-remove-review="${r.id}">Xóa đánh giá</button>`:''}</article>`).join(''):AC.empty('Chưa có đánh giá từ người sở hữu.');el.querySelectorAll('[data-remove-review]').forEach(b=>b.onclick=async()=>{if(await AC.confirm('Xóa đánh giá này?')){try{await AC.api('reviews/'+b.dataset.removeReview,'DELETE');loadReviews();}catch(e){AC.toast(e.message,true);}}});}catch(e){AC.error(el,e,loadReviews);}}
loadReviews();
async function loadComparison(){const el=document.querySelector('#comparison');if(!el)return;try{const ids=AC.compare();if(ids.length<2){el.innerHTML=AC.empty('Chọn ít nhất 2 xe bằng nút “So sánh” trong bộ sưu tập.');return;}const cars=await Promise.all(ids.map(id=>AC.api('cars/'+id)));const fields=[['Giá minh họa','price'],['Năm sản xuất','year'],['Phiên bản','name'],['Kiểu dáng','bodyStyle'],['Nhiên liệu','fuel'],['Số chỗ','seats'],['Động cơ','engine'],['Công suất','power'],['Mô-men xoắn','torque'],['Hộp số','transmission'],['Dẫn động','drivetrain'],['Kích thước','dimensions'],['Tiêu hao / Phạm vi','consumption'],['Tồn kho','stock']];el.innerHTML=`<table class="compare-table"><thead><tr><th>Thông tin</th>${cars.map(c=>`<th><img src="${AC.esc(AC.image(c))}" alt="${AC.esc(c.model)}"><a href="/xe/${c.id}">${AC.esc(c.displayName)}</a><button class="text-button" data-remove-compare="${c.id}">Bỏ chọn ×</button></th>`).join('')}</tr></thead><tbody>${fields.map(([label,key])=>`<tr><th>${label}</th>${cars.map(c=>`<td>${key==='price'?AC.money(c[key]):AC.esc(c[key])}</td>`).join('')}</tr>`).join('')}</tbody></table>`;el.querySelectorAll('[data-remove-compare]').forEach(b=>b.onclick=()=>{AC.saveCompare(ids.filter(id=>id!==Number(b.dataset.removeCompare)));loadComparison();});}catch(e){AC.error(el,e,loadComparison);}}
loadComparison();
