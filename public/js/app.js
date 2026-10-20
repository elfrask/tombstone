/* Tombstone - landing: mejoras progresivas (sin dependencias). */
(function () {
    "use strict";

    var reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

    /* --- estado del servidor (usa la propia API del framework) ---------- */
    function checkStatus() {
        var el = document.querySelector("[data-status]");
        if (!el) return;
        fetch("/api/health", { headers: { Accept: "application/json" } })
            .then(function (r) { if (!r.ok) throw new Error(r.status); return r.json(); })
            .then(function (data) {
                el.dataset.state = "online";
                var label = el.querySelector("[data-status-text]");
                if (label) label.textContent = "servidor " + (data.server || "ok") + " · " + (data.status || "ok");
            })
            .catch(function () {
                el.dataset.state = "offline";
                var label = el.querySelector("[data-status-text]");
                if (label) label.textContent = "servidor sin respuesta";
            });
    }

    /* --- pestañas de codigo --------------------------------------------- */
    function initTabs() {
        var tabs = Array.prototype.slice.call(document.querySelectorAll(".tab[data-tab]"));
        var panes = Array.prototype.slice.call(document.querySelectorAll(".pane[data-pane]"));
        if (!tabs.length) return;
        tabs.forEach(function (tab) {
            tab.addEventListener("click", function () {
                var id = tab.dataset.tab;
                tabs.forEach(function (t) {
                    var on = t === tab;
                    t.classList.toggle("is-active", on);
                    t.setAttribute("aria-selected", on ? "true" : "false");
                });
                panes.forEach(function (p) {
                    p.classList.toggle("is-active", p.dataset.pane === id);
                });
            });
        });
    }

    /* --- copiar el snippet activo --------------------------------------- */
    function initCopy() {
        var btn = document.querySelector("[data-copy]");
        if (!btn) return;
        btn.addEventListener("click", function () {
            var pane = document.querySelector(".pane.is-active code") || document.querySelector(".pane.is-active");
            if (!pane) return;
            var text = pane.innerText;
            var done = function () {
                btn.classList.add("is-done");
                btn.textContent = "Copiado";
                window.setTimeout(function () { btn.classList.remove("is-done"); btn.textContent = "Copiar"; }, 1600);
            };
            if (navigator.clipboard && navigator.clipboard.writeText) {
                navigator.clipboard.writeText(text).then(done).catch(function () {});
            }
        });
    }

    /* --- reveal on scroll ----------------------------------------------- */
    function initReveal() {
        var items = Array.prototype.slice.call(document.querySelectorAll(".reveal"));
        if (!items.length) return;
        if (reduceMotion || !("IntersectionObserver" in window)) {
            items.forEach(function (el) { el.classList.add("is-in"); });
            return;
        }
        var io = new IntersectionObserver(function (entries) {
            entries.forEach(function (e) {
                if (e.isIntersecting) { e.target.classList.add("is-in"); io.unobserve(e.target); }
            });
        }, { rootMargin: "0px 0px -8% 0px", threshold: 0.08 });
        items.forEach(function (el) { io.observe(el); });
    }

    function boot() {
        checkStatus();
        initTabs();
        initCopy();
        initReveal();
        console.log("tombstone: landing lista");
    }

    if (document.readyState === "loading") {
        document.addEventListener("DOMContentLoaded", boot);
    } else {
        boot();
    }
})();
