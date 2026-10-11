(() => {
    const $ = (id) => document.getElementById(id);
    const app = $('root');
    const stage = $('app');

    window.__viewport = window.__viewport || (() => ({ w: window.innerWidth, h: window.innerHeight }));
    function fit() {
        const v = window.__viewport();
        const s = Math.min(v.w / 1920, v.h / 1080);
        stage.style.transform = `translate(-50%, -50%) scale(${s})`;
    }
    window.addEventListener('resize', fit);
    fit();

    let state = {
        shop: null, tax: 0.1, currency: '$', imagePath: '', max: 99,
        catIndex: 0, focus: 0, cart: [], shift: false, busy: false,
    };

    const post = (name, data = {}) =>
        fetch(`https://${GetParentResourceName()}/${name}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify(data),
        }).catch(() => {});

    const money = (n) => `${state.currency}${Math.round(n).toLocaleString('en-US')}`;
    const imgSrc = (name) => state.imagePath.replace('%s', name);
    const currentItems = () => state.shop.categories[state.catIndex].items;

    function findItem(name) {
        for (const c of state.shop.categories) {
            const it = c.items.find((i) => i.name === name);
            if (it) return it;
        }
    }

    function renderCategories() {
        const box = $('categories');
        box.innerHTML = '';
        state.shop.categories.forEach((c, i) => {
            const d = document.createElement('div');
            d.className = 'cat' + (i === state.catIndex ? ' active' : '');
            d.innerHTML = `<i class="${c.icon}"></i><span>${c.label}</span>`;
            d.onclick = () => { state.catIndex = i; state.focus = 0; renderAll(); };
            box.appendChild(d);
        });
    }

    function renderItems() {
        const cat = state.shop.categories[state.catIndex];
        $('sectionLabel').textContent = cat.label;
        const box = $('items');
        box.innerHTML = '';
        cat.items.forEach((it, i) => {
            const d = document.createElement('div');
            d.className = 'item' + (i === state.focus ? ' focus' : '');
            d.innerHTML = `
                <div class="name">${it.label}</div>
                <div class="price">${money(it.price)}</div>
                <div class="img"><img src="${imgSrc(it.name)}" onerror="this.style.opacity=.15"></div>
                <div class="add">ADD TO CART</div>`;
            d.onmouseenter = () => { state.focus = i; updateFocus(); };
            d.onclick = (e) => addToCart(it.name, e.shiftKey ? 10 : 1);
            box.appendChild(d);
        });
    }

    function updateFocus() {
        [...$('items').children].forEach((el, i) => el.classList.toggle('focus', i === state.focus));
    }

    function renderCart() {
        const list = $('cartList');
        list.innerHTML = '';
        $('cartEmpty').classList.toggle('hidden', state.cart.length > 0);

        let subtotal = 0;
        state.cart.forEach((l) => {
            const it = findItem(l.name);
            const lineTotal = it.price * l.count;
            subtotal += lineTotal;
            const d = document.createElement('div');
            d.className = 'cart-line';
            d.innerHTML = `
                <span class="bar"></span>
                <img src="${imgSrc(l.name)}" onerror="this.style.display='none'">
                <span class="qty">${l.count}X</span>
                <span class="nm">${it.label}</span>
                <span class="lp">${money(lineTotal)}</span>
                <span class="qb" data-a="minus">−</span>
                <span class="qb" data-a="plus">+</span>`;
            d.querySelector('[data-a=minus]').onclick = (e) => changeQty(l.name, e.shiftKey ? -10 : -1);
            d.querySelector('[data-a=plus]').onclick = (e) => changeQty(l.name, e.shiftKey ? 10 : 1);
            list.appendChild(d);
        });

        const tax = Math.round(subtotal * state.tax);
        $('subtotal').textContent = money(subtotal);
        $('taxLabel').textContent = `Tax (${Math.round(state.tax * 100)}%)`;
        $('tax').textContent = money(tax);
        $('total').textContent = money(subtotal + tax);

        const disabled = state.cart.length === 0 || state.busy;
        $('bankPay').disabled = disabled;
        $('cashPay').disabled = disabled;
    }

    function renderAll() {
        $('brandShop').textContent = state.shop.label;
        $('topTitle').textContent = state.shop.label;
        renderCategories();
        renderItems();
        renderCart();
    }

    function addToCart(name, n = 1) { changeQty(name, n); }

    function changeQty(name, delta) {
        const idx = state.cart.findIndex((l) => l.name === name);
        if (idx === -1) {
            if (delta > 0) state.cart.push({ name, count: Math.min(delta, state.max) });
        } else {
            const c = state.cart[idx].count + delta;
            if (c <= 0) state.cart.splice(idx, 1);
            else state.cart[idx].count = Math.min(c, state.max);
        }
        renderCart();
    }

    function checkout(method) {
        if (!state.cart.length || state.busy) return;
        state.busy = true;
        renderCart();
        post('checkout', { cart: state.cart, method });
    }

    $('bankPay').onclick = () => checkout('bank');
    $('cashPay').onclick = () => checkout('cash');

    let toastTimer;
    function toast(msg, ok = true) {
        const t = $('toast');
        t.textContent = msg;
        t.className = 'toast' + (ok ? '' : ' error');
        clearTimeout(toastTimer);
        toastTimer = setTimeout(() => t.classList.add('hidden'), 2800);
    }

    window.addEventListener('keydown', (e) => {
        if (app.classList.contains('hidden')) return;
        const items = currentItems();
        const cols = 4;
        switch (e.key) {
            case 'Escape': post('close'); break;
            case 'ArrowRight': state.focus = Math.min(items.length - 1, state.focus + 1); updateFocus(); break;
            case 'ArrowLeft': state.focus = Math.max(0, state.focus - 1); updateFocus(); break;
            case 'ArrowDown': state.focus = Math.min(items.length - 1, state.focus + cols); updateFocus(); break;
            case 'ArrowUp': state.focus = Math.max(0, state.focus - cols); updateFocus(); break;
            case 'Tab':
                e.preventDefault();
                state.catIndex = (state.catIndex + 1) % state.shop.categories.length;
                state.focus = 0; renderAll();
                break;
            case 'Enter':
                if (items[state.focus]) addToCart(items[state.focus].name, e.shiftKey ? 10 : 1);
                break;
        }
        if (['ArrowRight', 'ArrowLeft', 'ArrowDown', 'ArrowUp'].includes(e.key)) {
            const el = $('items').children[state.focus];
            if (el) el.scrollIntoView({ block: 'nearest' });
        }
    });

    window.addEventListener('message', (e) => {
        const d = e.data;
        if (d.action === 'open') {
            state = {
                ...state,
                shop: d.shop, tax: d.tax, currency: d.currency,
                imagePath: d.imagePath, max: d.maxPerItem,
                catIndex: 0, focus: 0, cart: [], busy: false,
            };
            renderAll();
            fit();
            app.classList.remove('hidden');
        } else if (d.action === 'close') {
            app.classList.add('hidden');
            state.cart = [];
        } else if (d.action === 'result') {
            state.busy = false;
            toast(d.message, d.success);
            if (d.success) state.cart = [];
            renderCart();
        }
    });
})();
