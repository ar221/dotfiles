// Dictation Bridge — SillyTavern extension
// Connects ST's chat input to the self-hosted dictation server at
// https://<pc-ip>:8384. A mic button in the send bar opens the server UI
// (popup or modal iframe) with the active chat/persona/character IDs pre-
// filled, then receives the formatted text via window.postMessage and
// drops it into #send_textarea.
//
// Matching server-side embed contract (see humble-munching-island.md
// phase 2e) — both sides must agree:
//   server -> extension:
//     { type: 'dictation-ready' }
//     { type: 'dictation-result', text, raw?, mode?, formatting_skipped?, formatting_reason? }
//     { type: 'dictation-edit', text }        // optional live mirror
//   extension -> server:
//     { type: 'dictation-set-context', context: string }
//     { type: 'dictation-set-mode', mode: string }

import { eventSource, event_types, name1, this_chid, characters, user_avatar, chat } from '../../../../script.js';
import { extension_settings, getContext } from '../../../extensions.js';
import { selected_group, groups } from '../../../group-chats.js';

const MODULE = 'dictation-bridge';
const LOG = (...a) => console.log('[dictation-bridge]', ...a);
const WARN = (...a) => console.warn('[dictation-bridge]', ...a);
const ERR = (...a) => console.error('[dictation-bridge]', ...a);

const DEFAULTS = {
    serverUrl: 'https://192.168.50.110:8384',
    autoSend: false,
    appendMode: 'replace',       // 'replace' | 'append'
    openStyle: 'popup',          // 'popup' | 'iframe'
    liveMirror: false,           // dictation-edit -> textarea while typing on phone
    pushContext: true,           // send last AI message to server on ready
};

/** Active connection (popup window or iframe element). */
let activeTarget = null;
let activeIsIframe = false;
let activeModal = null;
let popupWatcher = null;

function settings() {
    if (!extension_settings[MODULE] || typeof extension_settings[MODULE] !== 'object') {
        extension_settings[MODULE] = structuredClone(DEFAULTS);
    } else {
        for (const [k, v] of Object.entries(DEFAULTS)) {
            if (extension_settings[MODULE][k] === undefined) extension_settings[MODULE][k] = v;
        }
    }
    return extension_settings[MODULE];
}

function saveSettings() {
    const ctx = getContext();
    ctx.saveSettingsDebounced?.();
}

/** Resolve server origin (scheme://host[:port]) for postMessage targeting. */
function serverOrigin() {
    try {
        return new URL(settings().serverUrl).origin;
    } catch {
        return '*';
    }
}

/** Best-effort current-context snapshot for query params. */
function currentContext() {
    const s = selected_group
        ? (groups?.find(g => g.id == selected_group) || null)
        : (characters?.[this_chid] || null);

    const chatId = selected_group
        ? (groups?.find(g => g.id == selected_group)?.chat_id ?? '')
        : (characters?.[this_chid]?.chat ?? '');

    const characterId = selected_group
        ? (selected_group || '')
        : (characters?.[this_chid]?.avatar || characters?.[this_chid]?.name || '');

    // Persona ID in ST is tracked via user_avatar (persona image filename).
    const personaId = user_avatar || name1 || '';

    // Last non-user message text for tonal context.
    let lastAi = '';
    if (Array.isArray(chat)) {
        for (let i = chat.length - 1; i >= 0; i--) {
            const m = chat[i];
            if (m && !m.is_user && !m.is_system && typeof m.mes === 'string' && m.mes.trim()) {
                lastAi = m.mes;
                break;
            }
        }
    }

    return { chatId, personaId, characterId, lastAi, groupName: s?.name || '' };
}

function buildEmbedUrl() {
    const cfg = settings();
    const ctx = currentContext();
    const base = cfg.serverUrl.replace(/\/+$/, '');
    const qp = new URLSearchParams({ embed: '1' });
    if (ctx.chatId) qp.set('chat', String(ctx.chatId));
    if (ctx.personaId) qp.set('persona', String(ctx.personaId));
    if (ctx.characterId) qp.set('character', String(ctx.characterId));
    return `${base}/?${qp.toString()}`;
}

/** Ping the server's /health to give an early failure before opening UI. */
async function probeServer() {
    const cfg = settings();
    const url = `${cfg.serverUrl.replace(/\/+$/, '')}/health`;
    try {
        const res = await fetch(url, { method: 'GET', mode: 'cors', cache: 'no-store' });
        return res.ok;
    } catch (e) {
        // Self-signed cert will trip this on first visit. Caller decides how to react.
        WARN('server probe failed', e?.message || e);
        return false;
    }
}

/** Inject the mic button into the chat send bar. Idempotent. */
function injectMicButton() {
    if (document.getElementById('dictation_bridge_mic')) return;
    const host = document.getElementById('rightSendForm');
    if (!host) {
        WARN('rightSendForm not found — delaying mic button inject');
        setTimeout(injectMicButton, 500);
        return;
    }

    const btn = document.createElement('div');
    btn.id = 'dictation_bridge_mic';
    btn.className = 'fa-solid fa-microphone interactable dictation-bridge-mic';
    btn.setAttribute('title', 'Dictation bridge (open dictation UI)');
    btn.setAttribute('tabindex', '0');
    btn.addEventListener('click', onMicClick);
    btn.addEventListener('keydown', (e) => {
        if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); onMicClick(); }
    });

    // Sit to the left of the paper-plane send button if present, otherwise at the end.
    const sendBut = document.getElementById('send_but');
    if (sendBut && sendBut.parentElement === host) {
        host.insertBefore(btn, sendBut);
    } else {
        host.appendChild(btn);
    }
}

function setMicActive(active) {
    const btn = document.getElementById('dictation_bridge_mic');
    if (btn) btn.classList.toggle('dictation-bridge-mic--active', !!active);
}

async function onMicClick() {
    if (activeTarget) {
        // Toggle: already open -> focus or close.
        if (activeIsIframe) {
            closeActive();
        } else {
            try { activeTarget.focus(); } catch {}
        }
        return;
    }

    const ok = await probeServer();
    if (!ok) {
        const toast = window.toastr;
        const msg = 'Dictation server unreachable. Check serverUrl, accept the self-signed cert in a new tab, then retry.';
        if (toast?.error) toast.error(msg, 'Dictation Bridge');
        else alert(msg);
        return;
    }

    const url = buildEmbedUrl();
    if (settings().openStyle === 'iframe') {
        openIframe(url);
    } else {
        openPopup(url);
    }
    setMicActive(true);
}

function openPopup(url) {
    const w = 500, h = 900;
    const features = `width=${w},height=${h},menubar=no,toolbar=no,location=no,status=no,scrollbars=yes,resizable=yes`;
    const win = window.open(url, 'dictation_bridge', features);
    if (!win) {
        const toast = window.toastr;
        const msg = 'Popup blocked. Allow popups for SillyTavern or switch openStyle to "iframe".';
        if (toast?.error) toast.error(msg, 'Dictation Bridge');
        else alert(msg);
        setMicActive(false);
        return;
    }
    activeTarget = win;
    activeIsIframe = false;
    popupWatcher = setInterval(() => {
        if (!activeTarget || activeTarget.closed) closeActive();
    }, 500);
}

function openIframe(url) {
    const modal = document.createElement('div');
    modal.className = 'dictation-bridge-modal';
    modal.innerHTML = `
        <div class="dictation-bridge-backdrop"></div>
        <div class="dictation-bridge-frame-wrap">
            <div class="dictation-bridge-close" title="Close">&times;</div>
            <iframe class="dictation-bridge-iframe" src="${url}" allow="microphone; clipboard-write"></iframe>
        </div>
    `;
    modal.querySelector('.dictation-bridge-backdrop').addEventListener('click', closeActive);
    modal.querySelector('.dictation-bridge-close').addEventListener('click', closeActive);
    document.body.appendChild(modal);
    activeModal = modal;
    activeTarget = modal.querySelector('.dictation-bridge-iframe').contentWindow;
    activeIsIframe = true;
}

function closeActive() {
    if (popupWatcher) { clearInterval(popupWatcher); popupWatcher = null; }
    if (activeIsIframe && activeModal) {
        try { activeModal.remove(); } catch {}
    } else if (activeTarget && !activeTarget.closed) {
        try { activeTarget.close(); } catch {}
    }
    activeTarget = null;
    activeIsIframe = false;
    activeModal = null;
    setMicActive(false);
}

/** Ship tonal context to the server UI once it's ready. */
function pushContextIfEnabled() {
    if (!settings().pushContext) return;
    const { lastAi } = currentContext();
    if (!lastAi) return;
    postToServer({ type: 'dictation-set-context', context: lastAi });
}

function postToServer(payload) {
    if (!activeTarget) return;
    try {
        activeTarget.postMessage(payload, serverOrigin());
    } catch (e) {
        WARN('postToServer failed', e?.message || e);
    }
}

/** Write text into ST's chat input, firing the input event so ST picks it up. */
function writeToTextarea(text, { autoSend = false, appendMode = 'replace' } = {}) {
    const ta = document.getElementById('send_textarea');
    if (!ta) { WARN('send_textarea not found'); return; }
    const next = appendMode === 'append' && ta.value
        ? (ta.value.replace(/\s+$/, '') + '\n\n' + text)
        : text;
    ta.value = next;
    ta.dispatchEvent(new Event('input', { bubbles: true }));
    // ST auto-grows the textarea on input; focus helps visual feedback.
    try { ta.focus(); ta.setSelectionRange(next.length, next.length); } catch {}

    if (autoSend) {
        // Canonical ST path: click #send_but. This routes through sendTextareaMessage()
        // -> Generate(), preserving all the usual pre-send hooks.
        const btn = document.getElementById('send_but');
        if (btn) btn.click();
        else WARN('send_but not found, cannot auto-send');
    }
}

/** Global postMessage handler. */
function onWindowMessage(event) {
    if (!activeTarget) return;
    const origin = serverOrigin();
    if (origin !== '*' && event.origin !== origin) return;
    const data = event?.data;
    if (!data || typeof data !== 'object') return;
    const type = typeof data.type === 'string' ? data.type : '';
    if (!type.startsWith('dictation-')) return;

    switch (type) {
        case 'dictation-ready':
            LOG('server ready');
            pushContextIfEnabled();
            break;
        case 'dictation-result': {
            const text = String(data.text ?? '');
            if (!text) { WARN('dictation-result had empty text'); return; }
            const cfg = settings();
            writeToTextarea(text, { autoSend: cfg.autoSend, appendMode: cfg.appendMode });
            if (data.formatting_skipped && window.toastr) {
                const reason = data.formatting_reason ? `: ${data.formatting_reason}` : '';
                window.toastr.warning(`RP formatting skipped${reason}. Raw transcript used.`, 'Dictation Bridge');
            }
            // For popups, close so the user is back in ST. For iframes, leave open
            // so they can see the result — they close via the X or backdrop.
            if (!activeIsIframe) closeActive();
            break;
        }
        case 'dictation-edit':
            if (settings().liveMirror) {
                writeToTextarea(String(data.text ?? ''), { autoSend: false, appendMode: 'replace' });
            }
            break;
        default:
            // Unknown — ignore.
            break;
    }
}

// ─── Settings UI ───────────────────────────────────────────────────────────

function buildSettingsPanel() {
    const s = settings();
    const host = document.createElement('div');
    host.id = 'dictation_bridge_container';
    host.className = 'extension_container';
    host.innerHTML = `
        <div class="dictation_bridge_settings">
            <div class="inline-drawer">
                <div class="inline-drawer-toggle inline-drawer-header">
                    <b>Dictation Bridge</b>
                    <div class="inline-drawer-icon fa-solid fa-circle-chevron-down down"></div>
                </div>
                <div class="inline-drawer-content">
                    <label for="dictation_bridge_url">Server URL</label>
                    <input id="dictation_bridge_url" type="text" class="text_pole" placeholder="https://192.168.50.110:8384" />

                    <label for="dictation_bridge_open_style">Open style</label>
                    <select id="dictation_bridge_open_style" class="text_pole">
                        <option value="popup">Popup window (recommended for phone workflow)</option>
                        <option value="iframe">Modal iframe (in-page)</option>
                    </select>

                    <label for="dictation_bridge_append_mode">Text handling</label>
                    <select id="dictation_bridge_append_mode" class="text_pole">
                        <option value="replace">Replace textarea</option>
                        <option value="append">Append to textarea</option>
                    </select>

                    <label class="checkbox_label">
                        <input id="dictation_bridge_autosend" type="checkbox" />
                        <span>Auto-send after dictation</span>
                    </label>

                    <label class="checkbox_label">
                        <input id="dictation_bridge_push_context" type="checkbox" />
                        <span>Push last AI message as tonal context</span>
                    </label>

                    <label class="checkbox_label">
                        <input id="dictation_bridge_live_mirror" type="checkbox" />
                        <span>Live mirror edits from server (experimental)</span>
                    </label>

                    <small class="notes">
                        The dictation server must be running and reachable.
                        Self-signed cert: visit the URL once in a browser tab and accept the warning before using the mic button.
                    </small>
                </div>
            </div>
        </div>
    `;

    const anchor = document.getElementById('extensions_settings2') || document.getElementById('extensions_settings');
    if (!anchor) { WARN('extensions_settings(2) not found — retry'); setTimeout(buildSettingsPanel, 500); return; }
    anchor.appendChild(host);

    const urlEl = host.querySelector('#dictation_bridge_url');
    const openEl = host.querySelector('#dictation_bridge_open_style');
    const appendEl = host.querySelector('#dictation_bridge_append_mode');
    const autoEl = host.querySelector('#dictation_bridge_autosend');
    const pushEl = host.querySelector('#dictation_bridge_push_context');
    const mirrorEl = host.querySelector('#dictation_bridge_live_mirror');

    urlEl.value = s.serverUrl;
    openEl.value = s.openStyle;
    appendEl.value = s.appendMode;
    autoEl.checked = !!s.autoSend;
    pushEl.checked = !!s.pushContext;
    mirrorEl.checked = !!s.liveMirror;

    urlEl.addEventListener('change', () => { s.serverUrl = urlEl.value.trim() || DEFAULTS.serverUrl; saveSettings(); });
    openEl.addEventListener('change', () => { s.openStyle = openEl.value; saveSettings(); });
    appendEl.addEventListener('change', () => { s.appendMode = appendEl.value; saveSettings(); });
    autoEl.addEventListener('change', () => { s.autoSend = !!autoEl.checked; saveSettings(); });
    pushEl.addEventListener('change', () => { s.pushContext = !!pushEl.checked; saveSettings(); });
    mirrorEl.addEventListener('change', () => { s.liveMirror = !!mirrorEl.checked; saveSettings(); });
}

// ─── Bootstrap ─────────────────────────────────────────────────────────────

let initialized = false;

export async function init() {
    if (initialized) return;
    initialized = true;
    settings();
    window.addEventListener('message', onWindowMessage);
    buildSettingsPanel();
    // Inject now if DOM is ready, otherwise on app_ready.
    if (document.getElementById('rightSendForm')) {
        injectMicButton();
    } else {
        eventSource.on(event_types.APP_READY, injectMicButton);
    }
    LOG('initialized');
}

// Self-bootstrap for robustness in case hooks.activate isn't invoked for
// third-party extensions. init() is idempotent.
try {
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', () => init().catch(ERR));
    } else {
        init().catch(ERR);
    }
} catch (e) {
    ERR('bootstrap failed', e);
}
